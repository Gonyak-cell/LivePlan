---
name: recurrence-engine
description: Change or validate daily recurring logic (template+log, dateKey, reset rules). Produces spec delta, invariants, migration needs, and a concrete test plan aligned with testing.md.
tools: [Read, Grep, Glob]
---

목적

매일 반복(dailyRecurring) 로직과 dateKey(YYYY-MM-DD) 계산/리셋 규칙을 변경하거나 검증할 때,

스펙 변경안(불변식 포함)

데이터 모델/마이그레이션 영향(schemaVersion)

필수 테스트 업데이트(최소 회귀 세트 유지)

잠금화면/인텐트 정합성 리스크
를 한 번에 산출한다.

언제 사용해야 하는가(트리거)

day boundary(자정→새벽 4시 등) 도입을 검토할 때

dateKey 계산을 바꾸거나 타임존 정책을 변경할 때

dailyRecurring 미체크 처리(실패 로그 도입 등)를 논의할 때

CompletionLog 구조/유니크 제약을 건드릴 때

"전날 미완료가 다음날에도 남는다/사라진다" UX를 바꾸려 할 때

입력

$ARGUMENTS(필수): 변경하려는 규칙 설명
예: "day boundary를 04:00으로 지원하고 싶다", "미체크도 로그로 남기고 싶다"

선택 입력(권장):

변경 이유(사용자 문제)

영향 표면(위젯/Live Activity/인텐트)

현재 규칙을 유지해야 하는 이유/제약

출력 포맷(고정, 반드시 이 순서)

CURRENT BASELINE (recurrence-spec.md 기준 요약)

PROPOSED CHANGE (변경안 5~10줄)

INVARIANTS (유지/추가/삭제되는 불변식)

DATA MODEL IMPACT (필드/구조/유니크 제약)

MIGRATION PLAN (schemaVersion, 변환 단계, 실패 시 폴백)

TEST PLAN (반드시 testing.md B1~B7에 매핑)

LOCKSCREEN & INTENTS CONSISTENCY (표시/완료 대상 정합성)

RISKS & ROLLBACK (리스크, 되돌리기 기준)

절차(단계별)

recurrence-spec.md(현재 확정 스펙)를 기준선으로 선언

변경 요구를 "정확한 규칙 문장"으로 재작성(모호함 제거)

불변식(특히 dailyRecurring의 "당일만 완료")이 유지되는지 확인

dateKey 산출 규칙 변경 여부를 판정

저장 스키마 영향이 있으면 schemaVersion 증가 + 마이그레이션 설계

testing.md의 필수 회귀(B1~B7)를 "변경 전/후"로 어떻게 만족할지 명시

lockscreen/intents와의 정합성(CompleteNextTask 대상 등) 체크

최소 롤백 계획을 제시(변경을 되돌릴 때 데이터 손실이 없게)

금지사항/가드레일

"인스턴스 생성 방식(매일 새로운 Task 생성)"을 Phase 1에서 제안 금지(템플릿+로그만).

dateKey 규칙 변경을 "테스트 없이" 진행하는 제안 금지.

타임존/DST 이슈를 무시한 설계 금지(최소 방어 정책 명시).

관련 rules

.claude/rules/data-model.md

.claude/rules/testing.md

.claude/rules/lockscreen.md

.claude/rules/performance.md

Supporting files

recurrence-spec.md: 현재 확정 스펙 원문(기준선)

recurrence-testcases.md: 필수 테스트 케이스 모음(회귀 세트)

완료 기준(DoD)

변경안이 "규칙 문장"으로 명확하며, 마이그레이션과 테스트에 구체적으로 매핑되어 있다.

예시 호출

/recurrence-engine "day boundary를 04:00으로 지원하고 싶다. 기존 로그는 어떻게 처리?"

/recurrence-engine "미체크도 실패 로그로 남기고 통계에 쓰고 싶다(Phase 2 가정)."
