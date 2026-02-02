---
name: onboarding-permissions-script
description: Generate onboarding and permission prompt scripts for LivePlan (KR/EN), emphasizing lock-screen-first setup, privacy defaults, and optional features (Live Activity/Shortcuts/Controls).
tools: [Read, Grep, Glob]
---

목적

사용자가 "설정 실패"로 이탈하지 않도록, 온보딩/권한 안내/도움말 문구를 짧고 명확하게 설계한다.

입력

$ARGUMENTS(필수): 온보딩 목표(예: 2분 내 위젯 확인) + 지원 언어(KR 또는 KR+EN)

출력(고정)

ONBOARDING STEPS(3~5 화면)

PERMISSION COPY(필요 시만)

SETTINGS HELP LINKS(위젯/Live Activity/단축어)

PRIVACY DEFAULT EXPLANATION

QA CHECKLIST(온보딩 수동 검증)

관련 rules

ux-flow-and-copy.md, product-decisions.md, lockscreen.md, strings-localization.md, appstore-submission.md

Supporting files

onboarding-template.md

permission-copy-library.md

help-center-snippets.md
