---
name: feature-prd-writer
description: Write a lock-screen-first PRD for a proposed LivePlan feature with scope, user flows, surface impacts, data model changes, and acceptance criteria aligned to existing rules.
tools: [Read, Grep, Glob]
---

목적

LivePlan 기능을 "잠금화면-퍼스트" 관점으로 PRD(요구사항 문서)로 고정한다.

스코프 크립과 재작업을 줄이기 위해 "표면(위젯/Live Activity/단축어/Controls)"까지 포함한 수용 기준을 만든다.

언제 사용해야 하는가

Phase 2 기능(snooze/통계/iCloud/반복 확장 등) 착수 직전

데이터 모델 변경이 예상되는 기능(마이그레이션 가능성)

잠금화면 선정/카운터 정의가 변하는 기능

입력

$ARGUMENTS(필수): 기능 1문장 + 목표 사용자 + 기대 효과(한 줄)

선택 입력:

영향 표면(Widget/Live Activity/Intents/Controls)

위험도(낮/중/높)

출력 포맷(고정)

supporting file인 prd-template.md의 섹션 순서를 그대로 채운 PRD 본문을 출력한다.

마지막에 "RULES IMPACT"와 "TEST IMPACT(B1~B7)"를 반드시 포함한다.

가드레일

Phase 1 금지 기능(협업/서버/칸반/첨부/리치텍스트)을 해결책으로 제안 금지

인텐트 남발 금지(3~5개 원칙 유지)

관련 rules

product-decisions.md, lockscreen.md, intents.md, data-model.md, testing.md, performance.md

Supporting files

prd-template.md

acceptance-criteria-library.md

example-prd.md

완료 기준(DoD)

PRD에: 사용자 흐름(앱+잠금화면), 데이터 모델, 테스트, 수용 기준이 모두 포함되어 있다.

예시 호출

/feature-prd-writer "Snooze(미루기) 기능: 지연 스트레스 감소, 잠금화면 우선순위 반영"
