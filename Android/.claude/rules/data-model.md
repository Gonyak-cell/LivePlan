# data-model.md

Last Updated: 2026-02-02 15:00:00

## 목적

LivePlan Android의 데이터 모델(엔티티/필드/제약)과 불변식을 고정한다.

iOS 버전의 data-model.md와 동일한 도메인 규칙을 Android(Kotlin)로 표현한다.

## 적용 범위

`:core`/`:data`/`:app`/`:widget`/`:shortcuts` 전반

## 핵심 원칙(요약)

- 도메인 규칙은 `:core`에만 둔다(architecture.md).
- 반복은 "템플릿 + 로그" 패턴 유지.
- CompletionLog는 유니크 제약을 반드시 유지한다(중복 완료/데이터 꼬임 방지).
- Room Database에 schemaVersion을 포함하고, 스키마 변경 시 마이그레이션 제공.

────────────────────────────────────────
## A. 핵심 엔티티 정의
────────────────────────────────────────

### A1. Project

```kotlin
data class Project(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val startDate: Long,                    // timestamp (필수)
    val dueDate: Long? = null,              // timestamp (선택)
    val status: ProjectStatus = ProjectStatus.ACTIVE,
    val note: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

enum class ProjectStatus { ACTIVE, ARCHIVED, COMPLETED }
```

**제약**
- dueDate < startDate 금지
- ARCHIVED/COMPLETED 프로젝트는 위젯 후보에서 제외

### A2. Section

```kotlin
data class Section(
    val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    val title: String,
    val orderIndex: Int = 0,
    val createdAt: Long = System.currentTimeMillis()
)
```

**제약**
- projectId는 존재하는 Project 참조 필수
- 섹션 삭제 시 소속 태스크는 "미분류"로 이동

### A3. Tag

```kotlin
data class Tag(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val colorToken: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)
```

### A4. Task

```kotlin
data class Task(
    val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    val title: String,
    val sectionId: String? = null,
    val tagIds: List<String> = emptyList(),
    val priority: Priority = Priority.P4,
    val workflowState: WorkflowState = WorkflowState.TODO,
    val startAt: Long? = null,
    val dueAt: Long? = null,
    val note: String? = null,
    val recurrenceRule: RecurrenceRule? = null,
    val recurrenceBehavior: RecurrenceBehavior = RecurrenceBehavior.HABIT_RESET,
    val nextOccurrenceDueAt: Long? = null,
    val blockedByTaskIds: List<String> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    val isRecurring: Boolean get() = recurrenceRule != null
    val isDone: Boolean get() = workflowState == WorkflowState.DONE
}
```

**제약**
- sectionId가 있으면 같은 projectId의 섹션이어야 함
- blockedByTaskIds는 같은 projectId의 태스크만 허용
- blockedByTaskIds에 자기 자신 포함 금지

### A5. Priority / WorkflowState / RecurrenceBehavior

```kotlin
enum class Priority(val value: Int) {
    P1(1), P2(2), P3(3), P4(4);
    companion object {
        val DEFAULT = P4
        fun fromValue(value: Int) = entries.find { it.value == value } ?: DEFAULT
    }
}

enum class WorkflowState {
    TODO, DOING, DONE;
    companion object { val DEFAULT = TODO }
    val isActive: Boolean get() = this != DONE
}

enum class RecurrenceBehavior {
    HABIT_RESET,  // 체크 안 해도 다음 날 새로 (기본)
    ROLLOVER;     // 미완료는 지연으로 남아있음
    companion object { val DEFAULT = HABIT_RESET }
}
```

### A6. RecurrenceRule

```kotlin
data class RecurrenceRule(
    val kind: RecurrenceKind,
    val interval: Int = 1,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val timeOfDay: Pair<Int, Int>? = null,  // (hour, minute)
    val anchorDate: Long
)

enum class RecurrenceKind { DAILY, WEEKLY, MONTHLY }
```

**제약**
- kind=WEEKLY인데 weekdays 비어있으면 금지
- interval <= 0 금지

### A7. CompletionLog

```kotlin
data class CompletionLog(
    val id: String = UUID.randomUUID().toString(),
    val taskId: String,
    val completedAt: Long = System.currentTimeMillis(),
    val occurrenceKey: String  // oneOff: "once", habitReset: dateKey, rollover: dueAt dateKey
)
```

**불변식(강행)**
- `(taskId, occurrenceKey)` 유니크
- oneOff는 occurrenceKey="once"만 허용

### A8. AppSettings

```kotlin
data class AppSettings(
    val schemaVersion: Int = 1,
    val privacyMode: PrivacyMode = PrivacyMode.MASKED,
    val pinnedProjectId: String? = null,
    val selectionMode: SelectionMode = SelectionMode.PINNED_FIRST,
    val defaultProjectViewType: ViewType = ViewType.LIST,
    val quickAddParsingEnabled: Boolean = true
)

enum class PrivacyMode { FULL, MASKED, COUNT_ONLY }
enum class SelectionMode { PINNED_FIRST, TODAY_OVERVIEW, AUTO }
enum class ViewType { LIST, BOARD, CALENDAR }
```

────────────────────────────────────────
## B. 불변식(Invariants) — 반드시 테스트로 잠글 것
────────────────────────────────────────

### B1. oneOff 완료 의미

- CompletionLog(taskId, occurrenceKey="once") 존재 → 완료
- 완료된 oneOff는 outstanding 후보에서 제외
- workflowState=DONE으로 정규화 가능

### B2. recurring 완료 의미 — habitReset

- 오늘 dateKey에 해당하는 occurrenceKey(dateKey) 로그 존재 → 오늘 완료
- 다음 날에는 자동 미완료로 계산(전날 미체크 누적 없음)

### B3. recurring 완료 의미 — rollover

- nextOccurrenceDueAt이 "현재 occurrence"의 dueAt 표현
- occurrenceKey = dateKey(nextOccurrenceDueAt)
- 해당 occurrenceKey 로그 존재하면 완료, 완료 시 nextOccurrenceDueAt을 다음 occurrence로 advance

### B4. Dependencies-lite

- blockedByTaskIds 존재 태스크는 "기본적으로 위젯 Top1/CompleteNextTask 대상에서 제외"

### B5. dateKey/타임존

- dateKey는 사용자 기기 타임존 기준(최소 방어: 크래시/중복 로그 금지)
- 형식: "YYYY-MM-DD"

────────────────────────────────────────
## C. 위젯 후보 계산(도메인 관점)
────────────────────────────────────────

```kotlin
fun computeOutstanding(
    dateKey: String,
    pinnedProjectId: String?,
    privacyMode: PrivacyMode,
    selectionPolicy: SelectionMode,
    projects: List<Project>,
    tasks: List<Task>,
    sections: List<Section>,
    tags: List<Tag>,
    completionLogs: List<CompletionLog>
): LockScreenSummary
```

**출력**
- displayList(Top3)
- counters(outstanding/overdue/dueSoon/recurringDone/recurringTotal/P1Count/doingCount)

**정합성(강행)**
- CompleteNextTask의 대상 = computeOutstanding의 displayList[0]와 동일

────────────────────────────────────────
## D. Room Entity 매핑
────────────────────────────────────────

### D1. Entity 변환 규칙

| Domain Model | Room Entity | 비고 |
|--------------|-------------|------|
| `List<String>` (tagIds 등) | `String` (JSON) | TypeConverter |
| `RecurrenceRule` | `String` (JSON) | TypeConverter |
| `Long` (timestamp) | `Long` | 동일 |
| `enum` | `String` | 이름으로 저장 |

### D2. 마이그레이션 정책

- schemaVersion 증가 시 Migration 클래스 작성 필수
- 읽기 실패 시 fail-safe(빈 상태) 유지
- 자동 초기화(데이터 삭제)는 사용자 동의 없이 수행 금지

끝.
