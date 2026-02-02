---
name: decision-sync
description: Sync and validate decisions across rules by using product-decisions.md as source of truth. Finds contradictions, unresolved Open decisions, and proposes minimal edits + test updates.
tools: [Read, Grep, Glob]
---

목적

product-decisions.md를 기준으로 다른 rules 문서의 Open decisions/모순을 찾아 정리한다.

입력

$ARGUMENTS(선택): "이번에 바꾼 결정" 요약

출력(고정)

DECISIONS SNAPSHOT(product-decisions 요약)

CONTRADICTIONS(문서/섹션 단위)

OPEN DECISIONS LEFT(정리 필요)

PROPOSED MINIMAL PATCH LIST(어느 파일/어느 섹션)

REQUIRED TEST UPDATES(testing.md 매핑)

RISK NOTE(정합성 깨짐 위험)

Supporting files

decision-checklist.md
