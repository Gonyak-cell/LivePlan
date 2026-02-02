---
name: lockscreen-surface
description: Design or modify lock-screen display policy (priority, Top N, masking, counters) across Widget/Live Activity/Controls, aligned with lockscreen.md. Produces spec delta + QA steps.
tools: [Read, Grep, Glob]
---

목적

잠금화면 표시 정책을 변경/추가할 때, lockscreen.md에 맞춰

우선순위/정렬/필터 규칙(표준표 포함)

Top N/카운트 정의

프라이버시 마스킹/문구 사전 업데이트

수동 QA 시나리오(배포 전)
를 일괄 산출한다.

언제 사용해야 하는가(트리거)

"지연/임박" 표시 기준을 바꾸려 할 때

Top N 개수/표시 형태를 바꾸려 할 때

privacyMode 레벨/마스킹 방식 변경

pinned 폴백 정책 변경

Live Activity 카드에 표시할 "핵심 1개" 정의를 바꾸려 할 때

CompleteNextTask 대상 선정이 바뀔 가능성이 있을 때(표시-행동 정합성)

입력

$ARGUMENTS(필수): 바꾸려는 표시 규칙 + 대상 표면
예: "위젯에서 overdue를 우선 표시하고, Live Activity는 focusOne만 유지"

선택 입력:

표면: Widget / Live Activity / Controls 중 해당

원하는 Top N 값(기본 3 유지/변경)

privacyMode 변경 여부

출력 포맷(고정)

CHANGE SUMMARY (무엇이 바뀌는지)

SURFACES AFFECTED (Widget / Live Activity / Controls)

PRIORITY TABLE UPDATE (lockscreen-priority-table.md에 반영될 표 형태 텍스트)

COUNTERS DEFINITION (outstanding/overdue/dueSoon/recurring)

PRIVACY & COPY UPDATE (lockscreen-copy.md 반영 내용)

REQUIRED CODE TOUCHPOINTS (AppCore 선정 함수, UI/Extensions, Intents)

MANUAL QA STEPS (잠금화면에서 확인 단계)

RISKS & ROLLBACK

절차

현재 lockscreen.md의 우선순위/Top N/프라이버시 기준을 기준선으로 요약

변경 요청을 "우선순위 표"와 "카운터 정의"로 구체화

표면별 제약 확인

위젯: 요약 중심, 즉시 갱신 보장 X

Live Activity: 요약 + 1개 핵심

Controls: 명령만, 리스트 금지

privacyMode 레벨별 출력 차이를 문구로 고정

"표시 대상(displayList 1순위)"과 "완료 대상(CompleteNextTask)" 정합성 점검

배포 전 수동 QA 체크리스트 작성

금지사항/가드레일

잠금화면에서 "상세 목록/스크롤"을 요구하는 정책 금지.

privacyMode 기본값(마스킹 ON)을 깨는 변경 금지(변경 필요 시 Open decision으로 승격).

표면별로 서로 다른 우선순위/정렬 규칙 금지(단일성 원칙).

관련 rules

.claude/rules/lockscreen.md

.claude/rules/intents.md

.claude/rules/data-model.md

.claude/rules/testing.md

Supporting files

lockscreen-copy.md: 문구 사전(한국어 템플릿)

lockscreen-priority-table.md: 우선순위 표준표(그룹/정렬 규칙)

완료 기준(DoD)

우선순위 표와 문구/프라이버시가 서로 모순 없이 정리되고, 수동 QA 단계가 포함된다.

예시 호출

/lockscreen-surface "dueSoon(24h) 대신 날짜 기반(오늘/내일)으로 바꾸고 위젯 카운터를 수정"

/lockscreen-surface "Live Activity는 focusOne만, 위젯은 pinnedFirst 유지"
