---
name: selection-algorithm-tuner
description: Tune lock-screen selection ranking (priority groups, tie-breakers, counters) while preserving determinism and alignment between displayList[0] and CompleteNextTask. Outputs spec delta + test plan.
tools: [Read, Grep, Glob]
---

목적

LivePlan의 핵심 기능인 "잠금화면 Top N 선정"을 튜닝한다.

결과물은 "우선순위 표(그룹/정렬/tie-breaker) 변경안 + 테스트 계획 + 인텐트 정합성 체크"다.

언제 사용해야 하는가(트리거)

사용자/본인이 "왜 이게 맨 위지?"를 느낄 때

dueSoon/overdue 정의 변경

snooze/priority/focus 같은 새 상태 도입

pinned 폴백 정책 변경

CompleteNextTask가 예상과 다르게 동작한다고 느낄 때(표시↔완료 정합성 점검)

입력

$ARGUMENTS(필수):

튜닝 목표(예: "지연 항목을 더 강하게", "반복을 덜 방해하게")

스코프(핀/오늘)

제약(Top N 유지, privacyMode 유지 등)

선택 입력

현재 불만/관찰(구체 사례 2~3개)

변경 가능한 것/불가한 것(예: dueSoon 24h 고정)

출력 포맷(고정)

BASELINE (product-decisions.md + lockscreen.md 기준선)

TUNING GOAL (목표를 정량 규칙으로 변환)

PROPOSED PRIORITY TABLE DELTA (그룹 순서/정의 변경)

TIE-BREAKERS (동률 처리 규칙; 결정론적 보장)

COUNTERS IMPACT (outstanding/overdue/dueSoon/recurring)

INTENTS CONSISTENCY (CompleteNextTask 대상 = displayList[0] 강제)

EXAMPLES (scenario-pack.md의 예시 형식으로 3~5개)

TEST PLAN (testing.md B1~B7 매핑 + 추가 계약 테스트)

RISKS & ROLLBACK (되돌리기 기준)

절차(단계별)

product-decisions.md의 확정값(Top N, dueSoon 기준, pinned 폴백)을 기준선으로 선언

튜닝 목표를 "규칙 문장"으로 변환(모호함 제거)

lockscreen-priority-table(우선순위 표준표) 관점에서 변경안을 작성

tie-breakers-catalog.md 중 적합한 규칙을 선택(항상 결정론적)

CompleteNextTask 정합성 체크(표시 1순위와 완료 대상 일치)

test-mapping.md 템플릿으로 테스트 계획 작성

변경이 과하면 "대안(더 작은 변화)"도 1개 제시

금지사항/가드레일

"랜덤/비결정론적 정렬" 금지(동일 입력 → 동일 출력 필수)

표시 우선순위와 완료 대상이 달라지는 설계 금지

Phase 1 스코프(협업/서버/칸반/첨부/리치텍스트)로 확장하는 해결책 금지

관련 rules

.claude/rules/product-decisions.md

.claude/rules/lockscreen.md

.claude/rules/intents.md

.claude/rules/testing.md

Supporting files

tuning-worksheet.md

tie-breakers-catalog.md

scenario-pack.md

완료 기준(DoD)

우선순위/동률 처리/테스트 계획이 일관되고, 인텐트 정합성이 명확히 검증되어 있다.

예시 호출

/selection-algorithm-tuner "목표: 지연(overdue)을 항상 맨 위로. 스코프: pinnedFirst. 제약: Top 3 유지, dueSoon=24h 유지."

/selection-algorithm-tuner "목표: 반복 항목이 너무 상단에 떠서 방해됨. 반복은 카운터 중심으로 낮추고 싶다."
