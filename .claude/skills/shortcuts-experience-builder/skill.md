---
name: shortcuts-experience-builder
description: Design practical Shortcuts/Automation recipes for LivePlan using existing intents. Produces 3 user-ready recipes with parameters, privacy-safe messages, and troubleshooting.
tools: [Read, Grep, Glob]
---

목적

LivePlan 인텐트를 기반으로 "사용자가 실제로 설정 가능한" 단축어/자동화 레시피를 만든다.

입력

$ARGUMENTS(필수): 원하는 사용자 시나리오(예: 8시간 갱신, 출근 전 QuickAdd 등)

선택 입력: iOS 버전, privacyMode 레벨, pinned 유무 가정

출력(고정)

RECIPE 1: 8-hour RefreshLiveActivity

RECIPE 2: Quick capture(QuickAddTask)

RECIPE 3: Daily review(주의 포함)

PRIVACY NOTES

FAILURE & RECOVERY

UPDATE CHECKLIST(어느 문서/가이드 업데이트할지)

관련 rules

product-decisions.md, intents.md, lockscreen.md, error-and-messaging.md

Supporting files

recipe-template.md

troubleshooting.md

예시 호출

/shortcuts-experience-builder "8시간 갱신 + 출근 전 QuickAdd + 취침 전 오늘 요약 확인"
