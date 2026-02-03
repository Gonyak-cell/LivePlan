---
name: spec-slicer
description: Break a feature request into at most 3 commit-sized slices with files, tests, DoD, and rollback points. Use manually before implementing a feature.
tools: [Read, Grep, Glob]
---

## 목적

입력($ARGUMENTS)으로 들어온 기능/요구사항을 "최대 3개"의 커밋 가능한 슬라이스로 분해한다.

각 슬라이스는 반드시: 변경 파일 후보 + 최소 테스트 2개 + DoD + 롤백 포인트를 포함한다.

## 언제 사용해야 하는가(트리거)

- 새 기능을 시작하기 직전
- 리팩터/스코프 확장이 들어오기 직전
- "하나의 작업에 너무 많은 파일이 얽힌다"는 느낌이 들 때

## 입력

- **$ARGUMENTS**: 기능 설명(필수)
- **추가 힌트(선택)**: 영향 범위(:core/:data/:app/:widget/:shortcuts)와 위험도(낮음/중간/높음)

## 출력 포맷(반드시 고정)

아래 순서로만 출력한다:

1. **ASSUMPTIONS(가정)**
2. **SLICE 1**
3. **SLICE 2(있으면)**
4. **SLICE 3(있으면)**
5. **GLOBAL RISKS & ROLLBACK(공통 리스크/롤백)**

### 각 SLICE 필드

- **Title**: 짧게
- **Scope**: 무엇을/무엇을 하지 않는지
- **Files to touch**: 파일 후보
- **Tests**: 최소 2개 (정상/경계)
- **DoD**: 빌드/테스트/수동 확인
- **Rollback point**: 되돌리기 기준

## 절차(단계별)

1. $ARGUMENTS를 1문장 목표로 재진술
2. :core/:data/:app/:widget/:shortcuts 영향 여부를 판정
3. 구현 순서를 고려해 슬라이스를 최대 3개로 분해
4. 각 슬라이스마다 최소 테스트 2개를 지정
5. Gradle 설정/AndroidManifest 변경이 필요하면 "별도 슬라이스"로 분리 표시

## 금지사항/가드레일

- 한 슬라이스에 신규 외부 의존성 추가 금지
- :core에 Android Framework import 금지
- 설정 파일 변경을 기능 슬라이스에 섞지 말 것

## 관련 rules

- Android/.claude/rules/architecture.md
- Android/.claude/rules/data-model.md
- Android/.claude/rules/widget.md
- Android/.claude/rules/testing.md
- Android/.claude/rules/performance.md

## 예시 호출

```
/spec-slicer "프로젝트에 startDate/dueDate 추가하고 위젯 우선순위에 반영"
/spec-slicer "Quick Settings Tile 추가, CompleteNextTask 기능 매핑"
```
