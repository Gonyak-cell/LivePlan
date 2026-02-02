---
name: store-assets-builder
description: Generate App Store screenshot storyboard (5-7), captions, short/long descriptions (KR/EN), keywords, and reviewer notes, aligned to LivePlan's optional Shortcuts refresh and privacy defaults.
tools: [Read, Grep, Glob]
---

목적

출시 직전, 스토어 자산(스크린샷 스토리/카피/설명/키워드)을 빠르게 생성한다.

입력

$ARGUMENTS(필수): 대상 언어(KR 또는 KR+EN) + 강조할 가치(잠금화면/반복/프라이버시/단축어)

출력(고정)

SCREENSHOT STORYBOARD(5~7장)

CAPTIONS(각 장)

SHORT DESCRIPTION / FULL DESCRIPTION(KR/EN)

KEYWORDS

APP REVIEW NOTES 초안(선택 기능 강조)

Supporting files

storyboard-template.md
