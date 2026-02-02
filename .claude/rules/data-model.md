목적

LivePlan의 데이터 모델(엔티티/필드/제약)과 불변식을 고정한다.

Phase 2에서는 "Sections/Tags/Priority/WorkflowState/Dependencies-lite/Notes/SavedView/Recurrence 확장"을 포함한다.

적용 범위

AppCore/AppStorage/App/UI/Extensions/Intents 전반

핵심 원칙(요약)

도메인 규칙은 AppCore에만 둔다(architecture.md).

반복은 "템플릿 + 로그"를 유지하되, Phase 2에서 RecurrenceRule과 behavior를 확장한다.

CompletionLog는 유니크 제약을 반드시 유지한다(중복 완료/데이터 꼬임 방지).

저장 스키마에는 schemaVersion을 포함하고, 스키마 변경 시 마이그레이션을 제공한다.

비목표

협업(assignee/권한/코멘트), 파일 첨부, Notion 블록 기반 문서, 서버 동기화는 Phase 2 범위 밖.

────────────────────────────────────────
A. 핵심 엔티티 정의(필드/의미/제약)
────────────────────────────────────────

A1. Project
필수

id, title, startDate
선택

dueDate

note: String?(텍스트/Markdown, Notion-lite)
상태

status: active/archived/completed
파생/설정

pinnedProjectId는 AppSettings에서 관리(권장)

제약

dueDate < startDate 금지

archived/completed 프로젝트는 기본적으로 잠금화면 후보에서 제외(lockscreen.md)

A2. Section (신규, 2.0)
정의

프로젝트 내부 그룹(섹션). Todoist의 섹션/Asana의 섹션/컬럼 역할을 "리스트 그룹핑"으로만 제공.
필수

id, projectId, title
선택

orderIndex(Int)
제약

projectId는 존재하는 Project를 참조

섹션 삭제 시 소속 태스크는 "미분류(섹션 없음)"로 이동(데이터 손실 금지)

A3. Tag/Label (신규, 2.0)
정의

태스크의 다대다 분류.
필수

id, name
선택

colorToken(선택, Phase 2에서는 실제 색 지정은 보류 가능)
제약

name은 사용자 편의상 "대소문자 무시 유니크"를 권장(강행까지는 아님)

A4. Task
필수

id, projectId, title
기본 속성(2.0 확장)

sectionId: String? (없으면 미분류)

tagIds: [String] (0개 이상)

priority: enum P1/P2/P3/P4 (기본 P4)

workflowState: enum todo/doing/done (기본 todo)

startAt: Date? (timeline/캘린더 확장 대비, 2.0에서는 optional)

dueAt: Date? (dueSoon/overdue 기준)

note: String? (태스크 노트, Notion-lite)

blockedByTaskIds: [String] (Dependencies-lite, 동일 프로젝트 내)

반복(2.0)

recurrenceRule: RecurrenceRule? (없으면 비반복)

recurrenceBehavior: enum habitReset / rollover (기본값은 product-decisions.md에 따름)

nextOccurrenceDueAt: Date? (rollover용, 성능/결정론을 위해 저장)

habitReset에는 필수 아님(당일 dateKey 기준 계산)

제약

sectionId가 있으면 같은 projectId의 섹션이어야 함

blockedByTaskIds는 같은 projectId의 태스크만 허용(교차 프로젝트 종속성은 Phase 3+)

blockedByTaskIds에 자기 자신 포함 금지, 사이클은 Phase 2에서 "검출되면 저장 거부(간단)" 권장

workflowState=done의 의미는 "완료"와 일치해야 함

oneOff: CompletionLog 존재 → workflowState를 done으로 정규화 가능

recurring: "현재 occurrence 완료"의 의미와 동기화 필요(아래 CompletionLog/Recurrence 규칙 참조)

A5. RecurrenceRule (신규, 2.0)
목적

매일 외 반복을 표현.
필드(권장 최소)

kind: daily / weekly / monthly

interval: Int (기본 1)

weekdays: Set<Mon..Sun> (weekly일 때)

timeOfDay: (hour, minute) optional

anchorDate: Date (반복 기준점)

제약

kind=weekly인데 weekdays가 비어있으면 금지

interval <= 0 금지

A6. CompletionLog (확장, 2.0)
정의

"태스크 완료"의 기록. 2.0부터는 recurring behavior를 지원하기 위해 "occurrenceKey"를 추가한다.
필수

taskId

completedAt

occurrenceKey: String

oneOff: "once" 고정

habitReset: dateKey(YYYY-MM-DD)

rollover: "해당 occurrence의 dueAt 기반 dateKey"(예: 2026-02-01)
불변식(강행)

(taskId, occurrenceKey) 유니크

oneOff는 occurrenceKey="once"만 허용

A7. SavedView(Filter) (신규, 2.0)
정의

필터/저장된 뷰. Todoist 필터 개념을 벤치마크하되, 2.0에서는 "조건 조합"만 제공(쿼리 언어는 Phase 3).
필수

id, name

scope: global / project(projectId)

viewType: list / board / calendar

definition: FilterDefinition
FilterDefinition(최소)

includeProjects: [projectId]?

includeTags: [tagId]?

includeSections: [sectionId]?

priorityAtMost: P? / priorityAtLeast: P?

stateIn: {todo, doing}? (done 제외가 기본)

dueRange: today / next7 / overdue / none

includeRecurring: Bool

excludeBlocked: Bool (기본 true)

A8. AppSettings (2.0 확장)
필수/권장

schemaVersion: Int

privacyMode: L0/L1/L2 (기본 L1)

pinnedProjectId: String?

lockscreenSelectionMode: pinnedFirst / todayOverview / auto

defaultProjectViewType: list/board/calendar (기본 list)

quickAddParsingEnabled: Bool (기본 true)

remindersEnabled: Bool (Phase 2.1 옵션)

Inbox 정책(2.0 유지)

숨김 Inbox 프로젝트를 1개 유지(QuickAdd 폴백)

────────────────────────────────────────
B. 불변식(Invariants) — 반드시 테스트로 잠글 것
────────────────────────────────────────

B1. oneOff 완료 의미

CompletionLog(taskId, occurrenceKey="once") 존재 → 완료

완료된 oneOff는 outstanding 후보에서 제외

workflowState=done으로 정규화 가능(하지만 정답은 CompletionLog)

B2. recurring 완료 의미 — habitReset

오늘 dateKey에 해당하는 occurrenceKey(dateKey) 로그 존재 → 오늘 완료

다음 날에는 자동 미완료로 계산(전날 미체크 누적 없음)

B3. recurring 완료 의미 — rollover

Task.nextOccurrenceDueAt이 "현재 occurrence"의 dueAt을 표현

occurrenceKey = dateKey(nextOccurrenceDueAt)

그 occurrenceKey 로그가 존재하면 완료로 간주하고, completion 시 nextOccurrenceDueAt을 다음 occurrence로 advance

미완료 상태에서 dueAt이 지나면 overdue로 남아있음(사라지지 않음)

B4. Dependencies-lite

blockedByTaskIds가 존재하는 태스크는 "기본적으로 잠금화면 Top1/CompleteNextTask 대상에서 제외"(정합성 유지 목적)

단, 앱 UI/보드/리스트에서는 blocked 표시를 해야 함

B5. dateKey/타임존

dateKey는 사용자 기기 타임존 기준(최소 방어: 크래시/중복 로그 금지)

────────────────────────────────────────
C. 잠금화면 후보 계산(도메인 관점)
────────────────────────────────────────

computeOutstanding(dateKey, pinnedProjectId, privacyMode, selectionPolicy, viewContext, …) 형태의 순수 함수 유지

입력에 SavedView(Filter) 적용 가능(2.0)

출력은 displayList(Top3), counters(outstanding/overdue/dueSoon/recurringDone/recurringTotal/P1Count/doingCount/blockedCount) 중 필요 최소만 lockscreen에 사용

정합성(강행)

CompleteNextTask의 대상 = computeOutstanding의 displayList[0]와 동일(항상)

────────────────────────────────────────
D. 마이그레이션/버전 정책(2.0)
────────────────────────────────────────

schemaVersion 증가 필요(Sections/Tags/Priority/WorkflowState/CompletionLog.occurrenceKey 등)

마이그레이션에서 해야 할 핵심

기존 CompletionLog에 occurrenceKey 부여

oneOff → "once"

dailyRecurring reset → 기존 dateKey를 occurrenceKey로 이동

Task.priority 기본값 P4 부여

Task.workflowState 기본 todo 부여

Inbox 프로젝트 보장(없으면 생성)

읽기 실패 시 fail-safe(빈 상태) 유지(performance/testing 규칙 준수)

끝.
