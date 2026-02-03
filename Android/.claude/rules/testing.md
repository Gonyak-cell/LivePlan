# testing.md

Last Updated: 2026-02-02 15:00:00

## 목적

LivePlan Android의 테스트 전략(계층/필수 케이스/수동 QA/회귀 방지 규칙)을 고정한다.

## 적용 범위

- `:core` 단위 테스트(최우선)
- `:data` 저장/마이그레이션 테스트
- 위젯 선정 알고리즘 테스트(순수 함수 기반)
- Compose UI 테스트
- 배포 전 수동 QA

## 핵심 원칙(요약)

- `:core` 규칙이 "정답"이며, 반드시 단위 테스트로 잠근다.
- 반복/리셋(dateKey)은 가장 높은 회귀 위험이므로, 테스트 케이스를 최소 세트로 고정.
- Storage는 round-trip + schemaVersion 마이그레이션을 테스트로 고정.
- 버그 수정은 재현 테스트부터(테스트 없이 버그 수정 금지).

────────────────────────────────────────
## A. 테스트 계층
────────────────────────────────────────

### A1. :core 모듈 테스트(필수, 최우선)

| 대상 | 도구 | 커버리지 목표 |
|------|------|-------------|
| UseCase | JUnit 5 + Mockk | 90% |
| OutstandingComputer | JUnit 5 | 100% |
| QuickAddParser | JUnit 5 | 90% |
| PrivacyMasker | JUnit 5 | 100% |

**권장 테스트 구조**
```
:core/src/test/kotlin/
├── DateKeyUtilTest.kt
├── CompletionRulesTest.kt
├── RecurrenceRulesTest.kt
├── OutstandingComputerTest.kt
├── PrivacyMaskerTest.kt
├── QuickAddParserTest.kt
└── usecase/
    ├── CompleteTaskUseCaseTest.kt
    └── AddTaskUseCaseTest.kt
```

### A2. :data 모듈 테스트

| 대상 | 도구 | 커버리지 목표 |
|------|------|-------------|
| DAO | Room In-Memory + JUnit 5 | 80% |
| Repository | JUnit 5 + Mockk | 70% |
| Migration | Room Testing | 필수 |

**필수 테스트**
- Round-trip: 저장 후 로드하여 동일성 확인
- 손상/읽기 실패 시 크래시 금지
- schemaVersion 마이그레이션 테스트

### A3. :app UI 테스트

| 대상 | 도구 | 범위 |
|------|------|------|
| 주요 화면 | Compose Testing | 핵심 플로우 |
| Navigation | Compose Testing | 화면 전환 |

### A4. :widget 테스트

- OutstandingComputer 결과 기반 표시 데이터 계약 테스트
- Glance UI는 수동 QA로 대체

────────────────────────────────────────
## B. "반복/리셋" 필수 테스트 케이스(체크리스트)
────────────────────────────────────────

**본 섹션의 테스트는 "삭제/축소 금지"의 최소 회귀 세트다.**

### B1. oneOff 완료 처리(영구 제거)

```kotlin
@Test
fun `oneOff 완료 시 outstanding에서 제외`() {
    // Given: oneOff 태스크 1개(미완료)
    // When: 완료 처리(CompletionLog 생성, occurrenceKey="once")
    // Then:
    //   - outstanding 목록에서 해당 태스크가 제거된다
    //   - counters.outstandingTotal이 1 감소한다
    //   - 중복 완료 호출 시에도 상태가 깨지지 않는다(멱등성)
}
```

### B2. dailyRecurring 완료 처리(당일만 완료)

```kotlin
@Test
fun `dailyRecurring 완료 시 오늘만 제외`() {
    // Given: dailyRecurring 태스크 1개, dateKey=오늘, 완료 로그 없음
    // When: 오늘 dateKey로 완료 처리
    // Then:
    //   - 오늘 outstanding에서 제거된다
    //   - counters.recurringDone 증가
    //   - 같은 dateKey로 중복 완료 시 로그 중복 생성 안됨
}
```

### B3. dailyRecurring 미완료로 날짜 변경 시 "표시에만 리셋"

```kotlin
@Test
fun `dailyRecurring 다음 날 리셋`() {
    // Given: dailyRecurring 태스크 1개, 전날 완료 로그 있음
    // When: dateKey를 "다음 날"로 변경하여 outstanding 계산
    // Then: 다음 날에는 "당일 미완료"로 다시 등장한다
}
```

### B4. 자정 경계(23:59 / 00:01)

```kotlin
@Test
fun `자정 경계에서 dateKey 전환`() {
    // Given: 23:59의 dateKey와 00:01의 dateKey
    // Then: dateKey 전환이 정확히 발생한다
}
```

### B5. 타임존 변경 시 dateKey 정책(최소 방어)

```kotlin
@Test
fun `타임존 변경 시 크래시 없음`() {
    // Given: 동일한 절대 시각에서 TimeZone A와 B로 dateKey 계산
    // Then: 크래시/중복 로그 생성 금지, (taskId, occurrenceKey) 유니크 유지
}
```

### B6. pinned project 유무 케이스

```kotlin
@Test
fun `pinned 없으면 todayOverview 폴백`() {
    // Given: pinnedProjectId가 null
    // Then: todayOverview로 폴백
}

@Test
fun `pinned가 archived면 today로 폴백`() {
    // Given: pinnedProjectId의 프로젝트가 ARCHIVED
    // Then: today로 폴백
}
```

### B7. privacyMode에 따른 출력 문자열

```kotlin
@Test
fun `privacyMode MASKED에서 제목 마스킹`() {
    // Given: privacyMode = MASKED
    // Then: 프로젝트명 숨김 + 태스크명 축약/익명화
}

@Test
fun `privacyMode COUNT_ONLY에서 제목 미노출`() {
    // Given: privacyMode = COUNT_ONLY
    // Then: 카운트만 표시, 제목 미노출
}
```

────────────────────────────────────────
## C. 수동 QA 시나리오(배포 전 필수)
────────────────────────────────────────

### C1. 위젯 표시/갱신

**준비**: 프로젝트 1개, 태스크 5개(1~2개 dueDate 포함), 반복 태스크 2개

**절차**
1. 홈 화면에 위젯 추가(2x2, 4x2)
2. 앱에서 태스크 1개 완료 처리
3. 위젯이 갱신되는지 확인
4. pinnedProjectId 변경 후 위젯 표시 스코프 변경 확인

**체크**
- Top N/카운트 표시 정상
- 빈 상태/프로젝트 없음에서도 크래시 없음

### C2. Quick Settings Tile

**절차**
1. Quick Settings에 타일 추가
2. 타일 탭하여 CompleteNextTask 실행
3. 성공/실패 피드백 확인

**체크**
- 멱등성 유지(반복 실행해도 상태 꼬임 없음)
- 데이터 없을 때 안전 메시지 반환

### C3. App Shortcuts

**절차**
1. 앱 아이콘 길게 눌러 Shortcuts 확인
2. Quick Add 실행
3. Complete Next 실행

**체크**
- 각 단축어 정상 동작
- 앱으로 적절히 이동

### C4. 프라이버시 모드 토글

**절차**
1. MASKED(기본)에서 위젯 표시 확인
2. FULL로 변경 후 제목 원문 노출 확인
3. COUNT_ONLY로 변경 후 카운트 중심 표시 확인

**체크**
- 모든 표면(위젯/타일 메시지)이 동일한 프라이버시 규칙 준수

────────────────────────────────────────
## D. 회귀 방지 규칙
────────────────────────────────────────

### D1. 규칙 변경 시 반드시 테스트 업데이트(강행)

- data-model.md 또는 widget.md 규칙 변경 → 관련 테스트 함께 수정/추가
- 규칙 변경 커밋에 최소 1개의 테스트 변경 포함 필수

### D2. bugfix는 "재현 테스트 먼저 작성"(강행)

1. 재현 테스트 작성(현재는 실패해야 함)
2. 수정 구현
3. 테스트 통과 확인

**"테스트 없이 버그만 수정" 금지**

### D3. 슬라이스 단위 커밋(권장)

- 한 커밋은 하나의 기능 슬라이스만 포함
- 테스트/코드/문서 변경은 동일 슬라이스 커밋에 포함

### D4. 최소 회귀 세트 유지(강행)

- B 섹션의 최소 회귀 세트는 삭제/무력화 금지
- 테스트가 취약해진 경우 "테스트 안정화" 별도 슬라이스로 처리

────────────────────────────────────────
## E. 테스트 의존성
────────────────────────────────────────

```kotlin
// :core/build.gradle.kts
dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("app.cash.turbine:turbine:1.0.0")
    testImplementation("com.google.truth:truth:1.1.5")
}

// :data/build.gradle.kts
dependencies {
    androidTestImplementation("androidx.room:room-testing:2.6.1")
    androidTestImplementation("androidx.test:runner:1.5.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
}

// :app/build.gradle.kts
dependencies {
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

끝.
