---
name: snooze-and-overdue-policy
description: Define Snooze and Overdue semantics for LivePlan with state transitions, lock-screen priority impact, intent consistency, and required migrations/tests.
tools: [Read, Grep, Glob]
---

목적

Snooze(미루기)와 Overdue(지연)의 의미/표시/완료 처리 규칙을 문서+테스트로 고정한다(Phase 2용).

입력

$ARGUMENTS(필수): snooze 기간(오늘만/내일/사용자 선택), 잠금화면에서 보일지 여부

출력(고정)

STATE TRANSITIONS(미루기/복귀/완료)

SELECTION PRIORITY DELTA(우선순위 표 변경)

COUNTERS DELTA(지연/임박/미루기 카운트)

INTENTS IMPACT(CompleteNext 대상 정합성)

DATA MODEL & MIGRATION(schemaVersion)

TEST PLAN(회귀 + 신규 케이스)

Supporting files

snooze-state-machine.md

snooze-testcases.md
