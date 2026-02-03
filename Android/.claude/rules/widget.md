# widget.md

Last Updated: 2026-02-02 15:00:00

## 목적

홈 화면 위젯(Glance)에서 무엇을 어떻게 표시할지와 선정 알고리즘을 고정한다.

iOS의 lockscreen.md에 대응하며, Android 플랫폼 특성(홈 화면 위젯 중심, 잠금화면 제한적)을 반영한다.

## 핵심 전제(시스템 제약)

- **위젯 갱신**: 최소 15분, 권장 30분 (WorkManager)
- **잠금화면 위젯**: Android 12+ 일부 지원, 대부분 홈 화면 위젯 사용
- **Ongoing Notification**: Live Activity 대체로 사용 가능

────────────────────────────────────────
## A. 표면 정의
────────────────────────────────────────

### A1. 홈 화면 위젯

| 크기 | 용도 | 표시 내용 |
|------|------|----------|
| Small (2x2) | 카운트 중심 | 미완료 수 + 아이콘 |
| Medium (4x2) | Top 3 + 카운트 | 태스크 3개 + 통계 |
| Large (4x4) | 상세 목록 | 태스크 5~7개 + 통계 |

### A2. Quick Settings Tile

| 타일 | 기능 |
|------|------|
| CompleteTaskTile | 다음 태스크 완료 |
| QuickAddTile (선택) | 빠른 추가 화면 열기 |

### A3. Ongoing Notification (Live Activity 대체)

| 표시 | 내용 |
|------|------|
| 제목 | "현재 진행 중" 또는 태스크 제목 |
| 본문 | 프로젝트명 또는 요약 |
| 액션 | 완료 버튼 |

────────────────────────────────────────
## B. 선정 알고리즘
────────────────────────────────────────

### B1. 입력(최소)

```kotlin
data class SelectionInput(
    val dateKey: String,
    val pinnedProjectId: String?,
    val privacyMode: PrivacyMode,
    val selectionPolicy: SelectionMode,
    val projects: List<Project>,
    val tasks: List<Task>,
    val completionLogs: List<CompletionLog>
)
```

### B2. 출력

```kotlin
data class LockScreenSummary(
    val displayList: List<TaskDisplayItem>,  // Top N
    val counters: Counters,
    val fallbackReason: FallbackReason?
)

data class Counters(
    val outstandingTotal: Int,
    val overdueCount: Int,
    val dueSoonCount: Int,
    val recurringDone: Int,
    val recurringTotal: Int,
    val p1Count: Int,
    val doingCount: Int,
    val blockedCount: Int
)
```

### B3. 우선순위(권장 고정)

**스코프 결정**
1. pinnedFirst(기본) → pinned active면 pinned, 아니면 todayOverview 폴백

**후보 필터(강행)**
- completed(완료) 제외
  - oneOff: occurrenceKey="once" 로그 존재
  - recurring: 현재 occurrenceKey 완료
- blocked 제외 (Top1/CompleteNext 정합성 유지)
- archived/completed 프로젝트 제외

**그룹 우선순위(Top N 선정)**
```
G1: workflowState=DOING (작업 중)
G2: overdue (dueAt < now, rollover recurring 포함)
G3: dueSoon (0 < dueAt-now ≤ 24h)
G4: priority P1 (dueAt 없더라도)
G5: habitReset recurring 중 오늘 미완료
G6: 나머지 todo(oneOff/rollover 미완료)
```

**tie-breaker(결정론 강행)**
1. dueAt 있는 항목: dueAt 오름차순
2. priority (P1 → P4)
3. createdAt (없으면 id 기반 stableKey)

### B4. Top N 정책

| 위젯 크기 | Top N | 표시 |
|----------|-------|------|
| Small | 0 | 카운트만 |
| Medium | 3 | Top 3 + "+X" |
| Large | 5~7 | Top 5~7 + "+X" |

### B5. 카운터

**필수**: outstandingTotal, overdueCount, dueSoonCount, recurringDone/Total

**선택**: p1Count, doingCount, blockedCount (위젯 공간 고려)

────────────────────────────────────────
## C. 프라이버시
────────────────────────────────────────

### C1. 프라이버시 모드 정의

| 모드 | 표시 내용 |
|------|----------|
| FULL (Level 0) | 제목 원문 (길이 제한/말줄임 적용) |
| MASKED (Level 1) | 프로젝트명 숨김 + 태스크명 "할 일 1/2/3" |
| COUNT_ONLY (Level 2) | 카운트만, 제목 미표시 |

**기본값**: MASKED (Level 1)

### C2. 마스킹 규칙

```kotlin
fun mask(task: Task, index: Int, privacyMode: PrivacyMode): String {
    return when (privacyMode) {
        PrivacyMode.FULL -> task.title.take(24)
        PrivacyMode.MASKED -> "할 일 ${index + 1}"
        PrivacyMode.COUNT_ONLY -> ""
    }
}
```

### C3. 알림 메시지 프라이버시

| 모드 | CompleteTask 성공 메시지 |
|------|------------------------|
| FULL | "완료: {title}" |
| MASKED | "완료했습니다" |
| COUNT_ONLY | "완료했습니다" |

────────────────────────────────────────
## D. 위젯 갱신 정책
────────────────────────────────────────

### D1. 갱신 트리거

| 트리거 | 갱신 방식 |
|--------|----------|
| 앱 내 데이터 변경 | 즉시 갱신 요청 |
| WorkManager 주기 | 30분마다 |
| 시스템 재부팅 | BOOT_COMPLETED 수신 시 |

### D2. 갱신 코드 예시

```kotlin
// 앱에서 즉시 갱신
fun updateWidgets(context: Context) {
    val glanceId = GlanceAppWidgetManager(context)
        .getGlanceIds(LivePlanWidget::class.java)
    glanceId.forEach { id ->
        LivePlanWidget().update(context, id)
    }
}

// WorkManager 주기적 갱신
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        LivePlanWidget().updateAll(applicationContext)
        return Result.success()
    }
}
```

### D3. 갱신 실패 폴백

- 데이터 로드 실패 시: "앱을 열어 확인" 표시
- 빈 데이터 시: "할 일을 추가하세요" 표시

────────────────────────────────────────
## E. 정합성 규칙
────────────────────────────────────────

### E1. CompleteNextTask 정합성(강행)

**대상 = computeOutstanding의 displayList[0]**

- blocked 태스크는 displayList 후보에서 제외
- 위젯 Top1과 타일/단축어의 CompleteNext 대상이 항상 일치

### E2. 폴백 사유 추적

```kotlin
enum class FallbackReason {
    PINNED_NOT_FOUND,
    PINNED_ARCHIVED,
    PINNED_COMPLETED,
    NO_ACTIVE_PROJECTS,
    NO_OUTSTANDING_TASKS
}
```

끝.
