목적

App Intents/Shortcuts/Controls의 제공 범위와 계약(멱등성/폴백/메시지/프라이버시)을 고정한다.

핵심 원칙

인텐트 개수는 2.0에서도 "핵심 5개 이하" 유지(유지보수/UX 비용 폭증 방지).

모든 인텐트는 멱등적이어야 한다(중복 실행 안전).

인텐트는 AppCore use-case 호출만(도메인 판단 복제 금지).

Level 1/2에서 원문 노출 금지(error-and-messaging/strings-localization 준수).

────────────────────────────────────────
A. 제공 인텐트(2.0)
────────────────────────────────────────

필수 4개

RefreshLiveActivity(displayMode: pinnedSummary/todaySummary/focusOne)

CompleteNextTask(scope: pinned/today, allowRecurring: Bool)

QuickAddTask(text: String, parse: Bool=true, scopeProjectId?: String, type?: oneOff/recurring, priority?: P, tags?: [tag])

StartNextTask(scope: pinned/today)

목적: displayList[0]를 workflowState=doing으로 설정(보드/작업중 흐름)

옵션(2.1)
5) TogglePrivacyMode 또는 SetPinnedProject(둘 중 하나만 추가 권장)

────────────────────────────────────────
B. 계약/폴백(요지)
────────────────────────────────────────

CompleteNextTask 정합성(강행)

대상 = computeOutstanding의 displayList[0]

blocked 태스크는 displayList 후보에서 제외되어야 함(정합성 유지)

QuickAddTask 파싱(2.0)

parse=true면 제한된 토큰 파싱(내일/요일/오후3시, p1, #tag, @project, /section)

파싱 실패 시: 제목만 생성하고 나머지 미적용(크래시/실패 금지)

기본 프로젝트: pinned 우선, 없으면 Inbox

StartNextTask(2.0)

displayList[0]를 doing으로 전환(이미 doing이면 noop)

Level 1/2 메시지: "시작했습니다" 등 짧게

RefreshLiveActivity(2.0)

단축어 8시간 갱신은 선택 기능(가이드 제공)

실행은 경량(읽기+선정+표시 업데이트)만(performance.md)

iOS 17 폴백

Controls 없음 → 위젯 탭 → 앱

인텐트는 Shortcuts에서 호출 가능

끝.
