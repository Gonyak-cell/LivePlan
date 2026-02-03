---
name: test-author
description: Produce a concrete test plan (and optional test skeletons) for a proposed change. Enforces 'feature change = tests' and preserves recurrence/reset regression suite.
tools: [Read, Grep, Glob]
---

## 목적

제안된 변경에 대한 구체적인 테스트 계획(및 선택적 테스트 스켈레톤)을 작성한다.

"기능 변경 = 테스트"를 강제하고, 반복/리셋 회귀 테스트 세트를 보존한다.

## 언제 사용해야 하는가(트리거)

- 새 기능 구현 전
- 버그 수정 전 (재현 테스트 필요)
- 기존 로직 변경 전

## 입력

- **$ARGUMENTS**: 변경 설명 또는 기능 요구사항

## 출력 포맷

```
## Test Plan: [요약]

### Affected Areas
| 영역 | 영향 | 테스트 필요 여부 |
|------|------|-----------------|
| :core | [설명] | ✅/❌ |
| :data | [설명] | ✅/❌ |
| :app | [설명] | ✅/❌ |
| :widget | [설명] | ✅/❌ |

### Required Tests

#### Unit Tests (:core)
1. [테스트명] - [목적]
2. [테스트명] - [목적]

#### DAO Tests (:data)
1. [테스트명] - [목적]

#### UI Tests (:app)
1. [테스트명] - [목적]

### Test Skeletons (선택)

```kotlin
// [파일명].kt
@Test
fun `[테스트명]`() {
    // Given
    // When
    // Then
}
```

### Regression Check
[최소 회귀 세트(B1~B7) 영향 여부]

### Manual QA (if needed)
1. [수동 테스트 단계]
```

## 최소 회귀 세트 (삭제 금지)

| ID | 테스트 | 설명 |
|----|--------|------|
| B1 | oneOff 완료 | 영구 제거 확인 |
| B2 | dailyRecurring 완료 | 당일만 제거 확인 |
| B3 | dailyRecurring 리셋 | 다음 날 다시 등장 확인 |
| B4 | 자정 경계 | dateKey 전환 확인 |
| B5 | 타임존 변경 | 크래시 없음 확인 |
| B6 | pinned 유무 | 폴백 확인 |
| B7 | privacyMode | 마스킹 확인 |

## 테스트 명명 규칙

```kotlin
// 백틱과 한글 설명 사용 권장
@Test
fun `oneOff 완료 시 outstanding에서 제외`() { }

@Test
fun `dailyRecurring 다음 날 리셋`() { }
```

## 관련 rules

- Android/.claude/rules/testing.md
- Android/.claude/rules/data-model.md
