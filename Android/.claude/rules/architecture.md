# architecture.md

Last Updated: 2026-02-02 15:00:00

## 목적

본 문서는 "Lock-screen-first 프로젝트/태스크 앱" Android 버전의 아키텍처 경계와 의존성 규칙을 고정하는 단일 기준(규칙) 문서입니다.

구현자는(Claude Code 포함) 본 문서의 MUST/MUST NOT 규칙을 우선 준수합니다. 세부 데이터 규칙은 data-model.md, 위젯 정책은 widget.md, 테스트 규칙은 testing.md를 따릅니다.

## 적용 범위

`:app` (메인 앱 모듈), `:core` (도메인 모듈), `:data` (영속화 모듈), `:widget` (Glance 위젯), `:shortcuts` (Quick Settings/App Shortcuts) 전반.

## 핵심 원칙(요약)

- **MUST**: 도메인 로직은 `:core` 모듈에만 둔다.
- **MUST NOT**: `:core`는 Android Framework, Jetpack Compose, Room, Hilt 등 플랫폼 프레임워크를 import 하지 않는다.
- **MUST**: `:app`/`:widget`/`:shortcuts`는 `:core`에만 의존한다(역의존 금지).
- **MUST**: 저장소(영속화) 구현은 `:data`에만 둔다(`:core`에는 인터페이스만 둔다).
- **MUST**: 위젯/타일에서는 "표현 + 최소 호출"만 수행하고, 무거운 연산·대량 IO·폴링을 금지한다.

## 비목표(Non-goals)

Phase 1에서는 아래를 구현하거나 설계를 확정하지 않는다:

- 협업(공유 프로젝트/팀/권한/멘션)
- 서버/계정 시스템(로그인/백엔드 동기화)
- 칸반 자동화 규칙 빌더
- 대규모 첨부(파일/이미지 다량 업로드, 클라우드 스토리지 연동)
- 리치 텍스트/블록 기반 문서 편집(Notion 스타일)

────────────────────────────────────────
## A. 모듈 구조(레이어드 아키텍처)
────────────────────────────────────────

### A1. 모듈/타깃 구성(권장)

```
:core (도메인)
    - model/          ← data class (10개)
    - repository/     ← Repository 인터페이스
    - usecase/        ← UseCase (12개)
    - selection/      ← OutstandingComputer
    - parsing/        ← QuickAddParser
    - privacy/        ← PrivacyMasker
    - filter/         ← 필터 로직
    - error/          ← 도메인 에러 정의

:data (영속화 구현)
    - database/       ← Room DB + DAO + Entity
    - repository/     ← Repository 구현체
    - datastore/      ← DataStore (AppSettings)
    - migration/      ← 스키마 마이그레이션

:app (메인 UI 타깃)
    - ui/             ← Jetpack Compose 화면
    - viewmodel/      ← ViewModel 계층
    - di/             ← Hilt DI 설정
    - navigation/     ← Navigation Compose

:widget (위젯)
    - receiver/       ← GlanceAppWidgetReceiver
    - ui/             ← Glance Composable
    - worker/         ← 주기적 갱신 Worker

:shortcuts (단축키/타일)
    - tiles/          ← Quick Settings Tiles
    - actions/        ← App Shortcuts
```

### A2. 의존 방향 규칙(절대 규칙)

```
:app
  ├── :core
  ├── :data
  ├── :widget
  └── :shortcuts

:data
  └── :core

:widget
  ├── :core
  └── :data

:shortcuts
  ├── :core
  └── :data
```

**:core MUST NOT import:**
- Android Framework (Context, Intent 등)
- Jetpack Compose
- Room, Hilt, DataStore
- kotlinx.coroutines.android (순수 kotlinx.coroutines는 허용)

**:data MAY import:**
- Room, DataStore, Hilt
- Android Context (저장소 접근용)

**:app/:widget/:shortcuts MAY import:**
- Jetpack Compose, Glance, WorkManager
- 단, 도메인 판단은 `:core` 호출을 통해 수행

### A3. 경계 분리 기준(무엇이 :core인가?)

**:core에 둬야 하는 것(예시)**
- "오늘(dateKey) 기준 미완료 계산"
- "매일 반복 완료 여부 판단"
- "위젯 표시 후보 선정(우선순위/Top N)"
- "완료 처리의 의미(일반 vs 반복)"
- "프라이버시 마스킹 로직"

**:core에 두면 안 되는 것(금지 예시)**
- 위젯/알림 UI 컴포넌트
- Quick Settings Tile 등록 코드
- Room Entity, DAO
- Hilt Module
- Context 의존 코드

────────────────────────────────────────
## B. 데이터 흐름(Data flow)
────────────────────────────────────────

### B1. Write Path(쓰기 경로) — 표준 흐름(강제)

**트리거(입력)**
- App(UI)에서 사용자 입력
- Shortcuts/Tiles에서 액션 호출

**처리**
1. UI/Shortcuts는 `:core`의 use-case를 호출한다.
2. `:core`는 변경된 도메인 상태를 계산한다(불변식 검증 포함).
3. `:core`는 Repository 인터페이스를 통해 commit(저장)을 요청한다.
4. `:data`의 구현체가 Room DB에 저장한다.
5. 저장 성공 후, 필요 시 "위젯 갱신 트리거"를 호출한다.

### B2. Read Path(읽기 경로) — 위젯 기준

- 데이터 소스는 Room DB를 단일 진실원천으로 삼는다.
- 위젯/타일은 직접 도메인 판단을 하지 않고, `:core`의 "순수 계산 함수"에 입력을 넣어 표시용 DTO(요약)를 얻는다.
- 읽기 실패/데이터 없음의 폴백: 크래시 금지, "빈 상태"로 안전하게 표시.

────────────────────────────────────────
## C. 저장소 경계(Repository/Service)
────────────────────────────────────────

### C1. :core의 저장소 인터페이스(프로토콜) 원칙

**:core는 아래만 알고 있어야 한다:**
- load/save API의 "의미"
- 저장 실패 시 도메인 레벨에서 어떻게 처리할지(에러 타입)

**:core는 아래를 몰라야 한다:**
- Room Entity, DAO, TypeConverter
- 파일 경로, SQLite 구조
- 동시성/트랜잭션 구현

### C2. :data의 책임(구현체 전용)

- Room Database, DAO 정의
- Entity ↔ Domain Model 변환
- schemaVersion 관리 및 마이그레이션
- DataStore (AppSettings)

────────────────────────────────────────
## D. 위젯/타일 운영 원칙
────────────────────────────────────────

### D1. "표현(View) + 최소 호출" 원칙(강행)

- 위젯은 표시용 데이터(요약 DTO)를 읽고 렌더링만 한다.
- 위젯 내부에 "복잡한 선정 알고리즘/반복 리셋 로직"을 직접 구현하지 않는다.
- Quick Settings Tile은 "명령(완료/추가 등)"만 수행하고, 결과는 다음 갱신에 반영.

### D2. 무거운 연산/IO 금지

**위젯/타일에서 금지되는 대표 행위**
- 대량 데이터 스캔
- 네트워크 호출
- 타이머 기반 폴링

**허용되는 행위**
- Room DB에서 캐시된 요약 데이터 읽기
- 경량 계산 + 렌더링

### D3. 갱신 정책

- WorkManager 주기: 최소 15분, 권장 30분
- 앱 내부 데이터 변경 시 즉시 위젯 갱신 트리거 가능

────────────────────────────────────────
## E. 코딩 표준(최소)
────────────────────────────────────────

### E1. 네이밍 규칙(권장)

- **:core 모델**: `Project`, `Task`, `RecurrenceRule`, `CompletionLog` 등 명사형
- **Use-case**: `CompleteTaskUseCase`, `AddTaskUseCase` 등 동사+명사
- **Repository 인터페이스**: `TaskRepository`, `ProjectRepository` 등
- **DTO**: `LockScreenSummary`, `TaskDisplayItem` 등

### E2. 에러 처리 원칙

**도메인 에러(:core)**
- sealed class `AppError`로 정의
- 입력 검증 실패, 불변식 위반 등

**인프라 에러(:data)**
- SQLite 에러, 마이그레이션 실패

**UI 에러(:app)**
- 사용자 메시지로 변환

### E3. 로깅/진단

- 디버그 빌드에서만 verbose 로그 허용
- 릴리즈 빌드에서는 최소 로그
- 민감정보(프로젝트/태스크 제목)는 로그에 남기지 않음

────────────────────────────────────────
## F. 외부 의존성 정책
────────────────────────────────────────

### F1. 승인된 의존성(Phase 1)

| 영역 | 라이브러리 | 용도 |
|------|-----------|------|
| UI | Jetpack Compose + Material 3 | 표준 |
| 상태 관리 | ViewModel + StateFlow | 표준 |
| DI | Hilt | 표준 |
| 저장소 | Room Database | 복잡한 쿼리 |
| 설정 | DataStore Preferences | 경량 설정 |
| 비동기 | Coroutines + Flow | 표준 |
| 위젯 | Glance 1.0 | Compose 위젯 |
| 백그라운드 | WorkManager | 주기적 작업 |
| 테스트 | JUnit 5 + Mockk + Turbine | Flow 테스트 |

### F2. 금지되는 의존성(Phase 1)

- 분석/트래킹/광고 SDK
- 네트워크 기반 데이터베이스 SDK
- 대형 UI 프레임워크(전체 테마 대체)

끝.
