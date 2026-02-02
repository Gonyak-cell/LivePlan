---
name: ios-architecture-guard
description: Review a proposed change/diff for architecture boundary violations, dependency creep, extension heaviness, and protected-file risk. Produces PASS/WARN/FAIL with actionable remediation.
tools: [Read, Grep, Glob]
---

목적

입력($ARGUMENTS)으로 주어진 변경(설명 또는 diff 요약)을 기준으로, 다음을 사전에 차단/경고한다.

레이어 의존 방향 위반(AppCore의 UI import 등)

확장 타깃(Widget/Live Activity/Controls/Intents)에서 도메인 로직·무거운 연산 수행

외부 의존성 도입/확대(앱 무게 증가)

보호 파일(entitlements/Info.plist/project.pbxproj 등) 변경 위험

결과는 "PASS/WARN/FAIL"과 함께 "즉시 수정 가능한 조치(Remediation)"를 제공한다.

언제 사용해야 하는가(트리거)

새 기능/리팩터 구현 전에 계획(Plan)이 나왔을 때

커밋 직전(변경 범위를 최종 점검)

"확장 타깃(위젯/인텐트) 관련 코드"를 건드렸을 때

"외부 라이브러리/패키지 추가"를 검토할 때

"프로젝트 설정/권한/서명" 파일을 만져야 할 때

입력

$ARGUMENTS(필수): 아래 중 하나를 포함

변경 요약(예: "CompleteNextTask 인텐트 추가, AppCore에 선정 함수 추가")

git diff 요약(텍스트로 붙여넣기)

변경 파일 목록(예: AppCore/…, AppExtensions/…, AppIntents/…)

선택 입력(권장): "변경 목적", "외부 의존성 추가 여부", "보호 파일 수정 여부"

출력 포맷(고정, 반드시 이 순서)

VERDICT: PASS | WARN | FAIL

SUMMARY: 변경 요약 3줄 이내

FINDINGS: (표 형식 대신 항목 리스트)

[SEVERITY: BLOCKER/MAJOR/MINOR] 문제 설명

근거: 어떤 규칙(architecture.md/performance.md 등) 위반인지

RISKS: (기술 부채/성능/회귀/심사 리스크)

REMEDIATION PLAN: (즉시 조치 순서)

REQUIRED TEST/DOC UPDATES: (testing.md/rules 동기화)

IF NEW DEPENDENCY: dependency-approval.md에 채워야 할 항목 목록

절차(단계별 체크리스트)

변경의 영향 범위를 레이어로 분류

AppCore / AppStorage / App(UI) / Extensions / Intents / Protected files

아키텍처 핵심 규칙 점검(architecture.md)

AppCore가 UI 프레임워크를 import 하는지

Extensions/Intents가 AppCore 외 다른 모듈에 직접 의존하는지

도메인 판단이 UI/확장에 중복 구현되어 있는지

확장 타깃 성능 규칙 점검(performance.md)

확장에서 무거운 연산/IO/폴링/네트워크가 있는지

표시용 데이터가 과도하게 커졌는지

저장/마이그레이션 영향 점검(data-model.md)

schemaVersion 필요 여부

로그/스냅샷 크기 증가 위험

보호 파일 변경 여부 점검(architecture.md의 보호 파일 정책)

외부 의존성 점검(기본 금지, 예외 승인)

테스트 영향 점검(testing.md)

반복/리셋/선정/인텐트 대상 변경 시 필수 회귀 세트 유지 여부

금지사항/가드레일

"대충 괜찮음" 같은 결론 금지. 반드시 PASS/WARN/FAIL 중 하나를 명시하고 근거/조치를 제시한다.

AppCore 규칙 위반이 있으면 원칙적으로 FAIL(예외는 없음).

보호 파일 변경이 기능 변경과 섞여 있으면 WARN 이상으로 보고하고 "별도 커밋 분리"를 요구한다.

관련 rules(반드시 참조)

.claude/rules/architecture.md

.claude/rules/performance.md

.claude/rules/data-model.md

.claude/rules/testing.md

.claude/rules/lockscreen.md

.claude/rules/intents.md

Supporting files

architecture-checklist.md: 점검 항목 표준 체크리스트

dependency-approval.md: 외부 의존성 예외 승인 양식

완료 기준(DoD)

VERDICT가 명확하고, BLOCKER/MAJOR/MINOR가 구분되어 있으며, 즉시 실행 가능한 REMEDIATION이 포함된다.

예시 호출

/ios-architecture-guard "AppExtensions에서 표시용 계산을 추가하려는데 성능/경계 위반 없는지 점검"

/ios-architecture-guard "git diff 요약: AppCore에 dateKey 계산 유틸 추가, Intents에 CompleteNextTask 추가"
