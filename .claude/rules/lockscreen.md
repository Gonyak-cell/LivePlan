목적

잠금화면 표면(위젯/Live Activity/Controls)에서 무엇을 어떻게 표시할지와 선정 알고리즘을 고정한다.

핵심 전제(시스템 제약)

위젯: 최소 갱신 간격(~5분) 제약이 있으므로 "즉시 반영"을 약속하지 않는다.

Live Activity: 최대 8시간 활성(단축어 갱신은 선택).

────────────────────────────────────────
A. 표면 정의(2.0 유지)
────────────────────────────────────────

Lock Screen Widget: Top 3 + 카운트(미완료/지연/임박/반복) 중심

Live Activity: 요약 + 1개 핵심(Top 1)

Controls(iOS18+): CompleteNextTask / QuickAddTask / RefreshLiveActivity / (옵션) StartNextTask

────────────────────────────────────────
B. 선정 알고리즘(2.0 개정)
────────────────────────────────────────

입력(최소)

pinnedProjectId, dateKey, privacyMode, selectionPolicy

projects/tasks/sections/tags/completionLogs

viewContext(optional): SavedView(definition) 적용 가능

출력

displayList(Top3), counters(최소), metadata(폴백 사유)

2.0 우선순위(추천 고정)

스코프 결정: pinnedFirst(기본) → pinned active면 pinned, 아니면 todayOverview 폴백

후보 필터(강행)

completed(완료) 제외(oneOff "once", recurring 현재 occurrenceKey 완료)

blocked 제외(Top1/CompleteNext 정합성 유지 목적)

archived/completed 프로젝트 제외

그룹 우선순위(Top3 선정)
G1: workflowState=doing (작업 중)
G2: overdue (dueAt < now, rollover recurring 포함)
G3: dueSoon (0 < dueAt-now ≤ 24h)
G4: priority P1 (dueAt 없더라도)
G5: habitReset recurring 중 오늘 미완료
G6: 나머지 todo(oneOff/rollover 미완료)

tie-breaker(결정론 강행)

dueAt 있는 항목: dueAt 오름차순

그 다음: priority(P1→P4)

그 다음: createdAt(없으면 id 기반 stableKey)

Top N 정책

위젯 Rectangular: Top3 + "+X"

Live Activity: Top1만

Controls: 표시 없음(명령)

카운터(2.0)

필수: outstandingTotal, overdueCount, dueSoonCount, recurringDone/Total

선택: P1Count, doingCount, blockedCount(잠금화면 공간 고려하여 위젯에서만 제한적으로)

프라이버시(2.0 유지)

Level 1/2에서 원문 제목 금지

Level 1에서는 "할 일 1/2/3" 또는 축약 규칙

Level 2는 카운트만

문구는 lockscreen-copy-lab + strings-localization 규칙을 따름.

끝.
