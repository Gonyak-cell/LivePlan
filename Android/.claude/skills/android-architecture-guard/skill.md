---
name: android-architecture-guard
description: Review a proposed change/diff for architecture boundary violations, dependency creep, extension heaviness, and Gradle config risk. Produces PASS/WARN/FAIL with actionable remediation.
tools: [Read, Grep, Glob]
---

## 목적

제안된 변경/diff가 아키텍처 경계 위반, 의존성 침투, 위젯 과부하, 설정 파일 리스크가 없는지 검토한다.

## 언제 사용해야 하는가(트리거)

- PR/diff 리뷰 전
- 새 모듈 추가 시
- 외부 라이브러리 도입 제안 시
- Gradle 설정 변경 시

## 입력

- **$ARGUMENTS**: 검토 대상 (파일 경로, diff, 또는 기능 설명)

## 출력 포맷

```
## Architecture Review: [대상]

### Summary
[PASS / WARN / FAIL] - [한 줄 요약]

### Boundary Check
| 모듈 | 위반 여부 | 상세 |
|------|----------|------|
| :core | ✅/⚠️/❌ | ... |
| :data | ✅/⚠️/❌ | ... |
| :app | ✅/⚠️/❌ | ... |
| :widget | ✅/⚠️/❌ | ... |
| :shortcuts | ✅/⚠️/❌ | ... |

### Dependency Check
[외부 의존성 추가 여부, 승인 필요 여부]

### Widget/Tile Performance Check
[무거운 연산, IO, 네트워크 호출 여부]

### Config File Risk
[build.gradle.kts, AndroidManifest.xml 변경 여부]

### Remediation
[WARN/FAIL인 경우 구체적인 수정 방안]
```

## 체크 항목

### 1. 모듈 경계 위반

| 검사 | 규칙 |
|------|------|
| :core | Android Framework import 금지 |
| :core | Room/Hilt/DataStore import 금지 |
| :data | :core 외 모듈 의존 금지 |
| :widget | 무거운 연산 금지 |
| :shortcuts | 무거운 연산 금지 |

### 2. 의존성 침투

- 신규 외부 라이브러리 추가 시 승인 프로세스 필요
- 금지된 의존성: 광고 SDK, 트래킹 SDK, 대형 UI 프레임워크

### 3. 위젯/타일 성능

- Room 쿼리 복잡도 확인
- 동기 작업 여부 확인
- 메모리 사용량 예상

### 4. 설정 파일 리스크

- build.gradle.kts 변경은 별도 커밋 권장
- AndroidManifest.xml 권한 추가는 주의

## 관련 rules

- Android/.claude/rules/architecture.md
- Android/.claude/rules/performance.md
