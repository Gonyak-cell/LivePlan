---
name: release-lite
description: Pre-release checklist for TestFlight/App Store submission. Verifies privacy defaults, permission strings, versioning policy, and generates KR/EN release notes + App Review notes.
tools: [Read, Grep, Glob]
---

목적

TestFlight/App Store 제출 직전에 "가볍게" 확인해야 할 필수 항목을 일괄 점검하고, 제출용 문서(릴리즈 노트/심사관 메모/권한 문구)를 생성한다.

본 스킬은 배포/업로드를 실제로 수행하지 않는다(수동 작업).

핵심: 프라이버시 기본값(마스킹 ON), 권한 문구, 잠금화면 표면 정책이 제출 시점에 흔들리지 않도록 한다.

언제 사용해야 하는가(트리거)

TestFlight 첫 배포 전

App Store 심사 제출 전

Info.plist 권한 문구를 변경했거나 확장 타깃 권한을 추가했을 때

Live Activity/위젯/인텐트가 변경되어 심사관 안내가 필요할 때

입력

$ARGUMENTS(선택): 이번 릴리즈의 변경 요약(없으면 git log 요약을 기준으로 작성)

선택 입력(권장):

버전/빌드 넘버 예정 값

추가된 권한(알림/사진/백그라운드 등)

출력 포맷(고정)

RELEASE CHECKLIST RESULT (PASS/WARN)

VERSIONING NOTES (버전/빌드 정책)

PRIVACY DEFAULTS (잠금화면 마스킹/노출 점검)

PERMISSION STRINGS REVIEW (Info.plist 문구 점검표)

RELEASE NOTES (KR)

RELEASE NOTES (EN)

APP REVIEW NOTES (심사관에게 설명할 사용 방법)

REQUIRED MANUAL QA (qa-scenarios.md 참조)

절차

release-checklist.md의 항목을 순서대로 점검

privacy-strings.md의 권한 키가 실제로 필요한지/문구가 적절한지 검토

lockscreen.md/intents.md의 정책과 제출 문서(심사관 안내)가 모순 없는지 확인

릴리즈 노트(한/영) 작성

App Review Notes 템플릿을 채움(단축어 8시간 갱신 전제 포함)

배포 전 수동 QA 요구사항을 마지막에 재확인

금지사항/가드레일

권한 문구/프라이버시 기본값을 "대충" 처리하는 제안 금지.

심사관이 이해할 수 없는 전문용어 남발 금지(짧고 명확).

실제 업로드/배포 조작은 이 스킬 범위 밖(수동).

관련 rules

.claude/rules/lockscreen.md

.claude/rules/intents.md

.claude/rules/performance.md

.claude/rules/testing.md

Supporting files

release-checklist.md

app-review-notes-template.md

privacy-strings.md

완료 기준(DoD)

체크리스트 결과 + 권한 문구 점검 + 릴리즈 노트(한/영) + 심사관 메모 초안이 모두 생성되어 있다.

예시 호출

/release-lite "v0.3: CompleteNextTask 옵션 추가, 위젯 카운터 수정"

/release-lite "TestFlight 첫 배포 준비"
