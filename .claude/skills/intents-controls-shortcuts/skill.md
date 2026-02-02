---
name: intents-controls-shortcuts
description: Single entry point to design/modify App Intents, Shortcuts automation, and iOS18 Controls mapping with strict idempotency, fallback, and privacy rules aligned with intents.md/lockscreen.md.
tools: [Read, Grep, Glob]
---

목적

App Intents/Shortcuts/Controls 변경을 "한 문서/한 규약"으로 통제한다.

변경 시 반드시 산출해야 하는 것

인텐트 계약(입력/출력/에러/메시지)

멱등성 규칙(중복 실행 안전)

폴백 UX(iOS 17 vs iOS 18+)

단축어 자동화(8시간 갱신) 사용 예

lockscreen 우선순위/프라이버시와의 정합성

언제 사용해야 하는가(트리거)

인텐트 추가/삭제/파라미터 변경

Controls에 새 버튼을 매핑하거나 동작을 변경

단축어 자동화 안내 문구/절차를 바꾸려 할 때

CompleteNextTask 대상 선정이 바뀔 가능성이 있을 때

입력

$ARGUMENTS(필수): 변경하고 싶은 인텐트/컨트롤/단축어 요구사항
예: "RefreshLiveActivity에 displayMode 추가, Controls에 CompleteNextTask 버튼"

선택 입력

대상 OS(iOS 17 포함 여부)

프라이버시(override 허용 여부)

기본 프로젝트 정책(QuickAdd: inbox vs pinned)

출력 포맷(고정)

INTENT CATALOG DELTA (intents-catalog.md에 반영될 변경)

CONTRACTS (각 인텐트별: 입력/출력/에러/메시지)

IDEMPOTENCY RULES (각 인텐트별 noop 조건 포함)

SHORTCUTS SETUP (8시간 갱신 예 포함)

CONTROLS MAPPING (iOS18+ 버튼/토글 매핑)

FALLBACK UX (iOS 17 동작 정의)

REQUIRED RULE/TEST UPDATES (intents.md/testing.md/lockscreen.md)

RISKS & ROLLBACK

절차

현재 intents.md를 기준선으로 "허용 인텐트 수(3~5)" 및 기본 정책 확인

변경 요구를 "인텐트 계약"으로 구체화(파라미터/기본값/폴백)

멱등성/폴백/프라이버시를 각 인텐트에 대해 명시

Controls 매핑(iOS 18+)은 "최대 3개 버튼" 원칙 유지

단축어 자동화(8시간 갱신) 안내를 shortucs-setup.md에 맞춰 산출

변경이 lockscreen 우선순위/CompleteNextTask 대상에 영향을 주는지 점검

필요한 테스트(특히 testing.md B1~B7) 업데이트 요구사항 명시

금지사항/가드레일

인텐트 수를 5개 초과로 늘리는 제안 금지(Phase 1).

인텐트가 도메인 로직을 직접 구현하는 제안 금지(AppCore use-case 호출만).

프라이버시 모드 기본값(마스킹 ON)을 깨는 제안 금지(필요하면 Open decision으로 승격).

8시간 갱신이 "무거운 작업"을 하도록 만드는 제안 금지(읽기+선정+표시 업데이트만).

관련 rules

.claude/rules/intents.md

.claude/rules/lockscreen.md

.claude/rules/testing.md

.claude/rules/performance.md

Supporting files

intents-catalog.md: 허용 인텐트 목록/기본값/에러 메시지 표준

shortcuts-setup.md: 사용자가 단축어 자동화를 구성하는 안내서

controls-mapping.md: Controls 버튼 → 인텐트 매핑 표

완료 기준(DoD)

인텐트 계약/멱등성/폴백/단축어/컨트롤 매핑이 서로 모순 없이 정리되어 있다.

예시 호출

/intents-controls-shortcuts "CompleteNextTask에 allowRecurring=false 옵션을 추가하고 iOS17/18 폴백 정의"

/intents-controls-shortcuts "RefreshLiveActivity를 8시간 자동화로 쓰는 가이드 문구 작성"
