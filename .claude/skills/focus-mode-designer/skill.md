---
name: focus-mode-designer
description: Design a lightweight focus mode for LivePlan where one selected task is surfaced via Live Activity (summary + one key) with privacy defaults and optional shortcuts/controls.
tools: [Read, Grep, Glob]
---

목적

Live Activity를 "정당한 1개 핵심(현재 태스크)" 기능으로 만드는 Focus Mode를 설계한다.

입력

$ARGUMENTS(필수): focus의 정의(타이머 없음/있음), 선택 방식(핀/오늘 Top1 등)

출력(고정)

STATE MODEL(focusTaskId, startedAt, endedAt 등)

LIVE ACTIVITY DISPLAY RULES(요약 + 1개 핵심)

PRIVACY RULES(Level 1 기본)

INTENTS/CONTROLS HOOKS(최소)

TEST & QA(회귀 영향)

관련 rules

lockscreen.md, intents.md, data-model.md, performance.md, testing.md

Supporting files

focus-state-machine.md

focus-display-spec.md
