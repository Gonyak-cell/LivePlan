허용 인텐트 카탈로그(Phase 1)

RefreshLiveActivity

목적: Live Activity 표시 상태 갱신(8시간 단축어 자동화 호출)

입력: displayMode(pinnedSummary/todaySummary/focusOne), privacyOverride(기본 nil)

출력: 성공/실패 메시지(짧게)

멱등성: 동일 상태 재실행 시 noop 허용

폴백: pinned 없으면 todaySummary

CompleteNextTask

목적: 우선순위 1개 완료(잠금화면/Controls)

입력: scope(pinned/today), allowRecurring(true/false)

출력: 완료된 항목의 마스킹된 제목 + 성공 메시지 또는 “없음”

멱등성: 완료 로그 중복 생성 금지

정합성: displayList[0]과 완료 대상 일치(lockscreen.md)

QuickAddTask

목적: 빠른 추가(인박스 또는 pinned)

입력: text(필수), type(oneOff/dailyRecurring), projectId(optional)

출력: 생성 성공/실패 메시지

기본 프로젝트: pinned 우선, 없으면 Inbox(권장)

추가 인텐트(Phase 2 후보, Open decision)

SetPinnedProject

TogglePrivacyMode

에러 메시지 표준(짧고 안전)

데이터 없음/로드 실패: “데이터를 불러오지 못했습니다. 앱을 열어 확인해주세요.”

프로젝트 없음: “프로젝트를 찾을 수 없습니다.”

완료할 항목 없음: “완료할 항목이 없습니다.”

입력 없음: “내용을 입력해주세요.”