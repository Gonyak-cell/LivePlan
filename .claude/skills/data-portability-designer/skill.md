---
name: data-portability-designer
description: Design serverless export/import for LivePlan with versioned schema, privacy considerations, conflict resolution, and QA/test plan aligned to data-model and performance rules.
tools: [Read, Grep, Glob]
---

목적

서버 없이 Export/Import를 설계해 사용자의 "데이터 신뢰"를 기능으로 만든다(iCloud 전 단계).

입력

$ARGUMENTS(필수): Export/Import 목표(예: JSON 내보내기, 기기 교체) + 지원 범위(프로젝트/태스크/로그 포함 여부)

출력(고정)

EXPORT FORMAT(스키마/버전)

IMPORT POLICY(충돌/중복/ID)

PRIVACY NOTES(민감정보/보관)

UX FLOW(내보내기/가져오기 UI)

TEST PLAN(round-trip, 손상, 버전)

PERFORMANCE NOTES(용량/로그)

관련 rules

data-model.md, performance.md, testing.md, error-and-messaging.md

Supporting files

export-schema.md

import-conflict-policy.md

portability-qa.md
