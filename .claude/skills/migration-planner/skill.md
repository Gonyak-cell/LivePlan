---
name: migration-planner
description: Plan schemaVersion migrations for LivePlan (n->n+1) with fail-safe behavior, test data strategy, and minimal change sets aligned to AppStorage rules.
tools: [Read, Grep, Glob]
---

목적

schemaVersion 변경이 발생할 때, 마이그레이션 설계/테스트/실패 폴백을 템플릿화한다.

입력

$ARGUMENTS(필수): 바뀌는 스키마(필드 추가/삭제/의미 변경) + 목표 버전

출력(고정)

MIGRATION SUMMARY(n->n+1)

DATA TRANSFORM RULES

FAIL-SAFE POLICY(읽기 실패 시)

TEST DATA PLAN(샘플 n 데이터)

REQUIRED TESTS(round-trip/migration/fail-safe)

ROLLBACK CONSIDERATIONS

Supporting files

migration-template.md

fail-safe-checklist.md
