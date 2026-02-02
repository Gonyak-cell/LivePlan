목적

LivePlan의 문자열(앱/위젯/인텐트 메시지/온보딩/권한 문구)을 키 기반으로 일관 관리하고, 잠금화면 길이 제약/프라이버시 요건을 만족하도록 규칙을 고정한다.

적용 범위

App(UI) 문자열

위젯/Live Activity 표시 문자열

인텐트 반환 메시지 문자열

온보딩/설정/도움말 문자열

권한 설명 문구(Info.plist 포함)

상위 규칙 우선순위

product-decisions.md(프라이버시 기본값/표면 정책 확정)

lockscreen.md(표면/프라이버시)

intents.md(메시지 정책)

본 문서(strings-localization)

핵심 원칙(강행)

하드코딩 최소화

사용자에게 노출되는 문구는 원칙적으로 키 기반으로 관리한다(앱/위젯/인텐트).

예외는 디버그 로그(릴리즈엔 최소화)뿐.

용어 통일

"미완료/지연/임박/반복/대표 프로젝트/오늘 요약/프라이버시 모드" 표준 용어를 유지한다.

동의어/혼용 금지(예: 미완료 vs 남은 일 vs 할 일 수).

길이 예산 준수(잠금화면)

잠금화면 문구는 짧아야 하며, 말줄임을 전제로 설계한다.

Level 1/2에서는 원문 제목 노출 금지.

다국어 정책

Phase 1 기본: KR(필수) + EN(권장)

다른 언어(JP/ZH)는 Phase 2+에서만

길이 예산(표준, KR 기준)

위젯 Inline: 18자 내

위젯 Rectangular 1라인: 18~24자 내(말줄임 허용)

Live Activity 1라인: 20~28자 내(말줄임 허용)

인텐트 반환 메시지: 18~30자 내(가능하면 더 짧게)

키 네이밍 규칙

접두어로 표면을 구분한다.

app.* (앱 UI)

ls.* (lock screen: 위젯/Live Activity)

intent.* (인텐트 메시지)

onboarding.*

permission.*

예시

ls.summary.title

ls.counter.outstanding

intent.complete.success

onboarding.privacy.notice

표준 용어 사전(강행)
KR

outstandingTotal: 미완료

overdueCount: 지연

dueSoonCount: 임박

recurring: 반복

pinnedProject: 대표 프로젝트

todayOverview: 오늘 요약

privacyMode: 프라이버시 모드
EN

Remaining / Overdue / Due soon / Daily / Pinned project / Today / Privacy mode

문구 작성 규칙(잠금화면)

숫자 구분: "미완료 3 · 지연 1" 형태 권장

조사/서술어 최소화

"즉시 갱신" 약속 금지(위젯은 지연 가능)

권한 문구 규칙(Info.plist)

실제 사용하는 권한만 추가

문구는 "왜 필요한지" 1문장(사용자 관점)

프라이버시/잠금화면 노출과 충돌하는 표현 금지

검토/동기화 규칙

lockscreen-copy-lab 결과를 반영할 때, 키/길이 예산/프라이버시 레벨을 같이 확인한다.

인텐트 메시지는 error-and-messaging.md 표준과 일치해야 한다.

끝.
