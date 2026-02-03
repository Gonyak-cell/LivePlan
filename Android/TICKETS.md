# LivePlan Android 개발 티켓

Last Updated: 2026-02-02 15:30:00

이 문서는 LivePlan Android 앱 개발을 위한 세부 티켓 목록입니다.
각 Phase별로 구분되어 있으며, 티켓은 우선순위와 의존성을 고려하여 순서대로 진행해야 합니다.

---

## 티켓 상태 범례

| 상태 | 의미 |
|------|------|
| 🔴 TODO | 시작 전 |
| 🟡 IN PROGRESS | 진행 중 |
| 🟢 DONE | 완료 |
| ⏸️ BLOCKED | 다른 티켓 대기 |

---

## Phase A: 기반 설정

### A-01: 멀티모듈 프로젝트 구조 설정
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: 없음

**설명**
- `:app`, `:core`, `:data`, `:widget`, `:shortcuts` 모듈 생성
- 모듈 간 의존성 설정

**완료 기준**
- [x] 5개 모듈 생성
- [x] 의존성 방향 올바르게 설정
- [x] 빌드 성공

**파일**
- `settings.gradle.kts`
- 각 모듈의 `build.gradle.kts`

---

### A-02: Gradle 의존성 설정
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: A-01

**설명**
- Version Catalog (libs.versions.toml) 설정
- 필수 라이브러리 추가 (Compose, Room, Hilt, Coroutines 등)

**완료 기준**
- [x] libs.versions.toml 생성
- [x] 모든 라이브러리 resolve 성공
- [ ] Hilt 설정 완료
- [ ] Room 설정 완료

**파일**
- `gradle/libs.versions.toml`
- 각 모듈의 `build.gradle.kts`

---

### A-03: CI 설정 (GitHub Actions)
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: A-02

**설명**
- PR 빌드 워크플로우 설정
- Unit 테스트 자동 실행

**완료 기준**
- [ ] `.github/workflows/android.yml` 생성
- [ ] PR 시 빌드 자동 실행
- [ ] Unit 테스트 자동 실행

**파일**
- `.github/workflows/android.yml`

---

### A-04: 코드 스타일/린트 설정
**상태**: 🔴 TODO
**우선순위**: 🟢 Low
**의존성**: A-01

**설명**
- ktlint 또는 detekt 설정
- Gradle lint 설정

**완료 기준**
- [ ] 린트 도구 설정
- [ ] `./gradlew lint` 통과

**파일**
- `.editorconfig`
- 린트 설정 파일

---

## Phase B: 도메인 포팅 (:core)

### B-01: 핵심 Enum 변환
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: A-01

**설명**
- Priority, WorkflowState, RecurrenceBehavior, RecurrenceKind, PrivacyMode, ProjectStatus enum 변환

**완료 기준**
- [x] 6개 enum class 생성
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/model/*.kt`

---

### B-02: 핵심 모델 변환
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: B-01

**설명**
- Project, Task, Section, Tag, CompletionLog, RecurrenceRule data class 변환

**완료 기준**
- [x] 6개 data class 생성
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/model/*.kt`

---

### B-03: Repository 인터페이스 정의
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: B-02

**설명**
- ProjectRepository, TaskRepository, CompletionLogRepository, SectionRepository, TagRepository 인터페이스 정의

**완료 기준**
- [x] 5개 Repository 인터페이스 생성
- [x] Flow 반환 타입 사용
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/repository/*.kt`

---

### B-04: AppError 정의
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: A-01

**설명**
- sealed class AppError 정의 (ValidationError, NotFoundError, StorageError 등)

**완료 기준**
- [x] AppError sealed class 생성
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/error/AppError.kt`

---

### B-05: DateKeyUtil 구현
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: A-01

**설명**
- dateKey 계산 유틸리티 (기기 타임존 기준 YYYY-MM-DD)

**완료 기준**
- [x] getTodayDateKey() 함수
- [x] getDateKey(timestamp) 함수
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/util/DateKeyUtil.kt`

---

### B-06: LockScreenSummary 및 SelectionPolicy 정의
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: B-02

**설명**
- 위젯 표시용 DTO (LockScreenSummary, TaskDisplayItem, Counters)
- SelectionPolicy enum

**완료 기준**
- [x] DTO 클래스 생성
- [x] SelectionPolicy enum 생성
- [x] 컴파일 성공

**파일**
- `core/src/main/kotlin/com/liveplan/core/selection/*.kt`

---

### B-07: OutstandingComputer 구현
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: B-06

**설명**
- 위젯 선정 알고리즘 구현 (computeOutstanding 함수)
- 우선순위 그룹 (G1~G6), tie-breaker 구현

**완료 기준**
- [x] computeOutstanding 함수 구현
- [ ] 우선순위 그룹 로직 완성
- [ ] tie-breaker 로직 완성
- [ ] 단위 테스트 작성

**파일**
- `core/src/main/kotlin/com/liveplan/core/selection/OutstandingComputer.kt`

---

### B-08: PrivacyMasker 구현
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: B-02

**설명**
- 프라이버시 모드에 따른 제목 마스킹 로직

**완료 기준**
- [x] mask() 함수 구현
- [x] 3가지 모드 (FULL/MASKED/COUNT_ONLY) 처리
- [ ] 단위 테스트 작성

**파일**
- `core/src/main/kotlin/com/liveplan/core/privacy/PrivacyMasker.kt`

---

### B-09: CompleteTaskUseCase 구현
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: B-03, B-04

**설명**
- 태스크 완료 처리 UseCase (oneOff/recurring 구분)

**완료 기준**
- [x] CompleteTaskUseCase 클래스 생성
- [ ] oneOff 완료 로직 완성
- [ ] recurring 완료 로직 완성
- [ ] 단위 테스트 작성

**파일**
- `core/src/main/kotlin/com/liveplan/core/usecase/CompleteTaskUseCase.kt`

---

### B-10: AddTaskUseCase 구현
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: B-03, B-04

**설명**
- 태스크 추가 UseCase

**완료 기준**
- [x] AddTaskUseCase 클래스 생성
- [ ] 입력 검증 로직 완성
- [ ] 단위 테스트 작성

**파일**
- `core/src/main/kotlin/com/liveplan/core/usecase/AddTaskUseCase.kt`

---

### B-11: 추가 UseCase 구현
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: B-09, B-10

**설명**
- UpdateTaskUseCase, StartTaskUseCase, AddProjectUseCase 등 추가 UseCase

**완료 기준**
- [ ] UpdateTaskUseCase
- [ ] StartTaskUseCase
- [ ] AddProjectUseCase
- [ ] DeleteTaskUseCase
- [ ] 각 UseCase 단위 테스트

**파일**
- `core/src/main/kotlin/com/liveplan/core/usecase/*.kt`

---

### B-12: QuickAddParser 구현
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: B-02

**설명**
- 빠른 입력 파싱 (내일/오늘, p1~p4, #tag, @project)

**완료 기준**
- [ ] QuickAddParser 클래스 생성
- [ ] 날짜 토큰 파싱
- [ ] 우선순위 토큰 파싱
- [ ] 태그/프로젝트 토큰 파싱
- [ ] 단위 테스트 작성

**파일**
- `core/src/main/kotlin/com/liveplan/core/parsing/QuickAddParser.kt`

---

### B-13: :core 단위 테스트 작성
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: B-07, B-08, B-09, B-10

**설명**
- OutstandingComputer, PrivacyMasker, UseCase 테스트
- 최소 회귀 세트 (B1~B7) 테스트

**완료 기준**
- [ ] OutstandingComputerTest
- [ ] PrivacyMaskerTest
- [ ] CompleteTaskUseCaseTest
- [ ] B1~B7 테스트 케이스
- [ ] 90% 커버리지

**파일**
- `core/src/test/kotlin/com/liveplan/core/*.kt`

---

## Phase C: 데이터 레이어 (:data)

### C-01: Room Database 설정
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: A-02

**설명**
- AppDatabase 클래스 생성
- TypeConverter 설정

**완료 기준**
- [x] AppDatabase 클래스 생성
- [ ] TypeConverter 완성 (List<String>, RecurrenceRule)
- [ ] 컴파일 성공

**파일**
- `data/src/main/kotlin/com/liveplan/data/database/AppDatabase.kt`

---

### C-02: Room Entity 정의
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: C-01

**설명**
- ProjectEntity, TaskEntity, CompletionLogEntity, SectionEntity, TagEntity

**완료 기준**
- [x] 5개 Entity 클래스 생성
- [x] 컴파일 성공

**파일**
- `data/src/main/kotlin/com/liveplan/data/database/entity/*.kt`

---

### C-03: DAO 구현
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: C-02

**설명**
- ProjectDao, TaskDao, CompletionLogDao, SectionDao, TagDao

**완료 기준**
- [x] 5개 DAO 인터페이스 생성
- [ ] CRUD 쿼리 완성
- [ ] Flow 반환 타입 사용
- [ ] 컴파일 성공

**파일**
- `data/src/main/kotlin/com/liveplan/data/database/dao/*.kt`

---

### C-04: Repository 구현체
**상태**: 🟢 DONE (부분)
**우선순위**: 🔴 Critical
**의존성**: C-03

**설명**
- ProjectRepositoryImpl, TaskRepositoryImpl, CompletionLogRepositoryImpl 등

**완료 기준**
- [x] ProjectRepositoryImpl
- [x] TaskRepositoryImpl
- [x] CompletionLogRepositoryImpl
- [ ] Entity ↔ Domain 변환 완성
- [ ] fail-safe 처리

**파일**
- `data/src/main/kotlin/com/liveplan/data/repository/*.kt`

---

### C-05: Hilt DI Module
**상태**: 🟢 DONE
**우선순위**: 🔴 Critical
**의존성**: C-04

**설명**
- DatabaseModule, RepositoryModule 설정

**완료 기준**
- [x] DatabaseModule 생성
- [x] RepositoryModule 생성
- [ ] 빌드 성공

**파일**
- `data/src/main/kotlin/com/liveplan/data/di/*.kt`

---

### C-06: DataStore (AppSettings)
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: A-02

**설명**
- DataStore Preferences로 AppSettings 저장

**완료 기준**
- [ ] AppSettingsDataStore 클래스 생성
- [ ] privacyMode, pinnedProjectId 등 저장
- [ ] 단위 테스트

**파일**
- `data/src/main/kotlin/com/liveplan/data/datastore/AppSettingsDataStore.kt`

---

### C-07: 마이그레이션 전략
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: C-01

**설명**
- Room 마이그레이션 설정 (schemaVersion 관리)

**완료 기준**
- [ ] Migration 클래스 구조 설정
- [ ] 마이그레이션 테스트

**파일**
- `data/src/main/kotlin/com/liveplan/data/database/migration/*.kt`

---

### C-08: :data 테스트 작성
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: C-03, C-04

**설명**
- DAO 테스트 (Room In-Memory)
- Repository 테스트

**완료 기준**
- [ ] TaskDaoTest
- [ ] ProjectDaoTest
- [ ] Repository round-trip 테스트
- [ ] 80% 커버리지

**파일**
- `data/src/androidTest/kotlin/com/liveplan/data/*.kt`

---

## Phase D: UI 핵심 (:app)

### D-01: Navigation 구조
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: A-02

**설명**
- Navigation Compose 설정
- Screen sealed class 정의

**완료 기준**
- [ ] Navigation.kt 생성
- [ ] NavHost 설정
- [ ] 컴파일 성공

**파일**
- `app/src/main/kotlin/com/liveplan/navigation/*.kt`

---

### D-02: 공통 컴포넌트
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-01

**설명**
- TaskRow, PriorityBadge, ProjectCard 등 공통 컴포넌트

**완료 기준**
- [ ] TaskRow Composable
- [ ] PriorityBadge Composable
- [ ] ProjectCard Composable
- [ ] 컴파일 성공

**파일**
- `app/src/main/kotlin/com/liveplan/ui/common/*.kt`

---

### D-03: ProjectListScreen
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-02

**설명**
- 프로젝트 목록 화면

**완료 기준**
- [ ] ProjectListScreen Composable
- [ ] ProjectListViewModel
- [ ] 프로젝트 목록 표시
- [ ] 프로젝트 생성 버튼

**파일**
- `app/src/main/kotlin/com/liveplan/ui/project/*.kt`
- `app/src/main/kotlin/com/liveplan/viewmodel/ProjectListViewModel.kt`

---

### D-04: ProjectDetailScreen (List 뷰)
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-03

**설명**
- 프로젝트 상세 화면 (태스크 리스트 뷰)

**완료 기준**
- [ ] ProjectDetailScreen Composable
- [ ] ProjectDetailViewModel
- [ ] 태스크 목록 표시
- [ ] 태스크 완료 체크

**파일**
- `app/src/main/kotlin/com/liveplan/ui/project/*.kt`
- `app/src/main/kotlin/com/liveplan/viewmodel/ProjectDetailViewModel.kt`

---

### D-05: TaskCreateDialog
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-04

**설명**
- 태스크 생성 다이얼로그

**완료 기준**
- [ ] TaskCreateDialog Composable
- [ ] 제목 입력
- [ ] 우선순위 선택
- [ ] 마감일 선택
- [ ] 반복 설정

**파일**
- `app/src/main/kotlin/com/liveplan/ui/task/*.kt`

---

### D-06: TaskDetailScreen
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-05

**설명**
- 태스크 상세/편집 화면

**완료 기준**
- [ ] TaskDetailScreen Composable
- [ ] TaskDetailViewModel
- [ ] 태스크 편집
- [ ] 태스크 삭제

**파일**
- `app/src/main/kotlin/com/liveplan/ui/task/*.kt`

---

### D-07: SettingsScreen
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-01

**설명**
- 설정 화면 (프라이버시 모드, 대표 프로젝트)

**완료 기준**
- [ ] SettingsScreen Composable
- [ ] 프라이버시 모드 설정
- [ ] 대표 프로젝트 선택

**파일**
- `app/src/main/kotlin/com/liveplan/ui/settings/*.kt`

---

### D-08: 다국어 리소스
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-02

**설명**
- strings.xml (EN, KR)

**완료 기준**
- [ ] values/strings.xml (EN)
- [ ] values-ko/strings.xml (KR)
- [ ] 모든 하드코딩 문자열 리소스화

**파일**
- `app/src/main/res/values/strings.xml`
- `app/src/main/res/values-ko/strings.xml`

---

### D-09: 테마 설정 (Material 3)
**상태**: 🟢 DONE (부분)
**우선순위**: 🟡 Medium
**의존성**: A-02

**설명**
- Material 3 테마 설정

**완료 기준**
- [x] Color.kt
- [x] Type.kt
- [x] Theme.kt
- [ ] 다크 모드 지원

**파일**
- `app/src/main/kotlin/com/liveplan/ui/theme/*.kt`

---

## Phase E: UI 확장

### E-01: KanbanBoardScreen
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-04

**설명**
- 칸반 보드 뷰 (TODO/DOING/DONE 컬럼)

**완료 기준**
- [ ] KanbanBoardScreen Composable
- [ ] 드래그 앤 드롭 (선택)
- [ ] 상태별 컬럼 표시

**파일**
- `app/src/main/kotlin/com/liveplan/ui/project/KanbanBoardScreen.kt`

---

### E-02: CalendarScreen
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-04

**설명**
- 캘린더 뷰 (dueAt 기준)

**완료 기준**
- [ ] CalendarScreen Composable
- [ ] 월간 캘린더 표시
- [ ] 태스크 마커 표시

**파일**
- `app/src/main/kotlin/com/liveplan/ui/project/CalendarScreen.kt`

---

### E-03: FilterListScreen + FilterBuilder
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-04

**설명**
- 필터 목록 및 생성 화면

**완료 기준**
- [ ] FilterListScreen
- [ ] FilterBuilderScreen
- [ ] Built-in 필터 (Today, Overdue, P1 등)

**파일**
- `app/src/main/kotlin/com/liveplan/ui/filter/*.kt`

---

### E-04: SearchScreen
**상태**: 🔴 TODO
**우선순위**: 🟢 Low
**의존성**: D-04

**설명**
- 로컬 검색 화면

**완료 기준**
- [ ] SearchScreen Composable
- [ ] 프로젝트/태스크 검색
- [ ] 검색 결과 하이라이트

**파일**
- `app/src/main/kotlin/com/liveplan/ui/search/*.kt`

---

### E-05: 빈 상태/에러 UI
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: D-02

**설명**
- 빈 상태, 에러 상태 UI 컴포넌트

**완료 기준**
- [ ] EmptyState Composable
- [ ] ErrorState Composable
- [ ] 각 화면에 적용

**파일**
- `app/src/main/kotlin/com/liveplan/ui/common/EmptyState.kt`
- `app/src/main/kotlin/com/liveplan/ui/common/ErrorState.kt`

---

## Phase F: 위젯 (:widget)

### F-01: Glance 기본 설정
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: A-02

**설명**
- GlanceAppWidget, GlanceAppWidgetReceiver 설정
- AndroidManifest 등록

**완료 기준**
- [ ] LivePlanWidget 클래스
- [ ] LivePlanWidgetReceiver 클래스
- [ ] AndroidManifest 등록
- [ ] 빌드 성공

**파일**
- `widget/src/main/kotlin/com/liveplan/widget/*.kt`
- `widget/src/main/AndroidManifest.xml`

---

### F-02: Medium 위젯 (4x2)
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: F-01, B-07

**설명**
- Top 3 태스크 + 카운트 표시

**완료 기준**
- [ ] MediumWidgetContent Composable
- [ ] OutstandingComputer 호출
- [ ] 태스크 3개 표시
- [ ] 카운트 표시 (미완료/지연)

**파일**
- `widget/src/main/kotlin/com/liveplan/widget/ui/*.kt`

---

### F-03: Small 위젯 (2x2)
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: F-02

**설명**
- 카운트 중심 위젯

**완료 기준**
- [ ] SmallWidgetContent Composable
- [ ] 미완료 수 표시
- [ ] 아이콘 표시

**파일**
- `widget/src/main/kotlin/com/liveplan/widget/ui/*.kt`

---

### F-04: WorkManager 갱신
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: F-02

**설명**
- 주기적 위젯 갱신 (30분)

**완료 기준**
- [ ] WidgetUpdateWorker 클래스
- [ ] PeriodicWorkRequest 설정
- [ ] 앱 시작 시 등록

**파일**
- `widget/src/main/kotlin/com/liveplan/widget/worker/*.kt`

---

### F-05: 위젯 프라이버시 모드 적용
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: F-02, B-08

**설명**
- PrivacyMasker 적용하여 제목 마스킹

**완료 기준**
- [ ] FULL 모드: 원문 표시
- [ ] MASKED 모드: "할 일 N" 표시
- [ ] COUNT_ONLY 모드: 카운트만 표시

**파일**
- `widget/src/main/kotlin/com/liveplan/widget/ui/*.kt`

---

## Phase G: 추가 기능 (:shortcuts)

### G-01: Quick Settings Tile
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: B-09

**설명**
- CompleteTaskTileService 구현

**완료 기준**
- [ ] CompleteTaskTileService 클래스
- [ ] AndroidManifest 등록
- [ ] 탭 시 CompleteNextTask 실행

**파일**
- `shortcuts/src/main/kotlin/com/liveplan/shortcuts/tiles/*.kt`
- `shortcuts/src/main/AndroidManifest.xml`

---

### G-02: App Shortcuts
**상태**: 🔴 TODO
**우선순위**: 🟡 Medium
**의존성**: D-05

**설명**
- Quick Add, Complete Next 단축키

**완료 기준**
- [ ] shortcuts.xml 생성
- [ ] Quick Add 단축키
- [ ] Complete Next 단축키
- [ ] AndroidManifest 등록

**파일**
- `app/src/main/res/xml/shortcuts.xml`
- `app/src/main/AndroidManifest.xml`

---

### G-03: Ongoing Notification
**상태**: 🔴 TODO
**우선순위**: 🟢 Low
**의존성**: D-04

**설명**
- 현재 진행 중 태스크 알림 (Live Activity 대체)

**완료 기준**
- [ ] NotificationChannel 설정
- [ ] Ongoing Notification 생성
- [ ] 완료 버튼 액션

**파일**
- `app/src/main/kotlin/com/liveplan/service/*.kt`

---

## Phase H: 릴리즈

### H-01: ProGuard/R8 설정
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: Phase D~G

**설명**
- 릴리즈 빌드 최적화 설정

**완료 기준**
- [ ] proguard-rules.pro 설정
- [ ] Release 빌드 성공
- [ ] 앱 크기 15MB 이하

**파일**
- `app/proguard-rules.pro`

---

### H-02: Play Store 메타데이터
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: H-01

**설명**
- 앱 설명, 스크린샷 준비

**완료 기준**
- [ ] 짧은 설명 (EN/KR)
- [ ] 전체 설명 (EN/KR)
- [ ] 개인정보처리방침 URL

**파일**
- Play Console 직접 입력

---

### H-03: 스크린샷 7장
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: H-01

**설명**
- 앱 스크린샷 촬영

**완료 기준**
- [ ] 프로젝트 목록
- [ ] 태스크 리스트
- [ ] 홈 화면 위젯
- [ ] 보드 뷰
- [ ] 태스크 생성
- [ ] 프라이버시 모드
- [ ] 설정 화면

**파일**
- 스크린샷 이미지 파일

---

### H-04: 내부 테스트 트랙
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: H-02, H-03

**설명**
- Play Console 내부 테스트 트랙 배포

**완료 기준**
- [ ] AAB 업로드
- [ ] 테스터 추가
- [ ] 내부 테스트 성공

---

### H-05: 프로덕션 출시
**상태**: 🔴 TODO
**우선순위**: 🔴 Critical
**의존성**: H-04

**설명**
- Play Store 프로덕션 출시

**완료 기준**
- [ ] 프로덕션 트랙 제출
- [ ] 심사 통과
- [ ] 출시 완료

---

## 부록: 티켓 의존성 그래프

```
A-01 ─┬─ A-02 ── A-03
      │    │
      │    └─ D-01 ── D-02 ─┬─ D-03 ── D-04 ─┬─ D-05 ── D-06
      │                     │                │
      │                     └─ E-05          └─ E-01, E-02, E-03, E-04
      │
      ├─ B-01 ── B-02 ── B-03 ── B-09 ── G-01
      │    │      │
      │    │      └─ B-06 ── B-07 ── F-02
      │    │
      │    └─ B-04
      │
      └─ C-01 ── C-02 ── C-03 ── C-04 ── C-05
                                    │
                                    └─ F-01 ── F-02 ── F-03
                                              │
                                              └─ F-04
```

---

*Last Updated: 2026-02-02 15:30:00*
