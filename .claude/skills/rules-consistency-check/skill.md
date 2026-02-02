---
name: rules-consistency-check
description: Cross-check core invariants across rules (lockscreen selection vs CompleteNextTask, privacy levels, Top N, dateKey/recurrence) and produce PASS/WARN/FAIL with actionable fixes.
tools: [Read, Grep, Glob]
---

목적

rules 간 핵심 교차 불변식이 깨졌는지 자동 점검한다.

입력

$ARGUMENTS(선택): 최근 변경 요약

출력(고정)

VERDICT: PASS/WARN/FAIL

CORE INVARIANTS CHECK

displayList[0] ↔ CompleteNextTask 대상

privacyMode Level 1/2 원문 노출 금지

Top N 정책(위젯/Live Activity)

dateKey/반복 리셋 정의

FINDINGS(위반/위험)

FIX PLAN(최소 수정 순서)

TEST/QA IMPACT

Supporting files

cross-invariants.md
