---
name: lockscreen-copy-lab
description: Generate lock-screen copy (KR/EN) optimized for Widget/Live Activity/Controls with privacy levels, length budgets, and consistent terminology. Outputs a ready-to-paste copy set and update checklist.
tools: [Read, Grep, Glob]
---

목적

LivePlan의 잠금화면(위젯/Live Activity/인텐트 메시지) 문구를 "짧고, 일관되고, 프라이버시 안전하게" 생성/튜닝한다.

산출물은 "바로 붙여넣을 수 있는 문구 세트(KR/EN)"와 "어느 파일을 업데이트할지 체크리스트"다.

언제 사용해야 하는가(트리거)

lockscreen.md의 Top N/카운트/우선순위/프라이버시 규칙이 바뀔 때

dueSoon/overdue 정의가 바뀔 때

새 상태(예: snooze, focus mode, inbox 안내)를 도입할 때

인텐트 반환 메시지(CompleteNextTask/QuickAddTask) 문구를 바꿀 때

"짧은 문구가 필요하지만 매번 땜질하는 느낌"이 들 때

입력

$ARGUMENTS(필수): 다음을 포함해 한 문장으로 기술

변경 대상 표면: Widget / Live Activity / Intents(메시지) 중 무엇인지

표시 데이터: Top N / counters / 상태(빈 상태, 오류, 폴백 등)

언어: KR만 또는 KR+EN

선택 입력

privacyMode 적용 레벨(0/1/2 중 어떤 레벨 중심인지)

길이 제약(특정 위젯 패밀리 등)

"톤"(중립/간결/설명형)

출력 포맷(고정, 반드시 이 순서)

ASSUMPTIONS (product-decisions.md 기준값 재확인)

LENGTH BUDGET (length-budget.md 기반 요약)

TERMINOLOGY (glossary.md 기반)

COPY SET — KR

Widget: Inline / Rectangular(Top N) / Empty / Error / Fallback

Live Activity: Summary / FocusOne / Empty / Error

Intents messages: Refresh / Complete / QuickAdd (privacyMode별)

COPY SET — EN (요청된 경우만)

PRIVACY CHECK (Level 0/1/2 별 노출 점검)

UPDATE CHECKLIST (어느 파일을 바꿀지)

.claude/rules/lockscreen.md 섹션 F

.claude/skills/lockscreen-surface/lockscreen-copy.md

(필요 시) .claude/rules/intents.md 메시지 표준

TEST/QA NOTES (testing.md C와 연결)

절차(단계별)

product-decisions.md에서 privacyMode 기본값/Top N/dueSoon 기준을 확인

lockscreen.md의 표면 정의(Widget/Live Activity/Controls)와 정합되게 문구를 설계

length-budget.md 예산 안에서 문구를 생성(말줄임/숫자 형식 포함)

glossary.md의 용어를 강제("미완료/지연/임박/반복" 표준화)

privacyMode Level 1/2에서 원문 제목 노출이 없도록 최종 검증

"바로 붙여넣을 문구 세트"와 "업데이트 파일 체크리스트"를 함께 출력

금지사항/가드레일

Level 1/2에서 프로젝트/태스크 원문을 포함하는 문구 생성 금지

"즉시 갱신"을 약속하는 표현 금지(위젯은 즉시 반영 보장 X)

표면별로 동일 개념을 다른 용어로 표현 금지(용어 사전 준수)

관련 rules

.claude/rules/product-decisions.md

.claude/rules/lockscreen.md

.claude/rules/intents.md

.claude/rules/testing.md

Supporting files

length-budget.md

glossary.md

examples.md

완료 기준(DoD)

KR(필수) + EN(선택) 문구가 표면별/프라이버시 레벨별로 완결되어 있고, 업데이트 체크리스트가 포함된다.

예시 호출

/lockscreen-copy-lab "Widget+Intents 문구 정리: 미완료/지연/반복 카운터 + 빈 상태 + 에러, KR+EN, privacy Level 1 기본"

/lockscreen-copy-lab "Live Activity focusOne 문구만 개선, KR, privacy Level 2 중심"
