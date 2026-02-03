# LivePlan iOS → Android 변환 계획서

> **작성일**: 2026-02-02
> **최종 업데이트**: 2026-02-02 14:35:42
> **원본 앱**: LivePlan (Swift/SwiftUI iOS 앱)
> **대상 플랫폼**: Android (Kotlin + Jetpack Compose)

---

## 📋 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [iOS 프로젝트 구조 분석](#2-ios-프로젝트-구조-분석)
3. [기술 스택 매핑](#3-기술-스택-매핑)
4. [Android 프로젝트 구조](#4-android-프로젝트-구조)
5. [레이어별 변환 전략](#5-레이어별-변환-전략)
6. [데이터 모델 변환](#6-데이터-모델-변환)
7. [UI 변환 가이드](#7-ui-변환-가이드)
8. [위젯 변환](#8-위젯-변환)
9. [에러 처리 전략](#9-에러-처리-전략)
10. [테스트 전략](#10-테스트-전략)
11. [다국어 처리](#11-다국어-처리)
12. [CI/CD 파이프라인](#12-cicd-파이프라인)
13. [마일스톤 계획](#13-마일스톤-계획)
14. [예상 일정](#14-예상-일정)
15. [필요 도구 및 설정](#15-필요-도구-및-설정)

---

## 1. 프로젝트 개요

### 1.1 앱 소개

**LivePlan**은 잠금화면 위젯으로 오늘의 할 일을 확인할 수 있는 태스크 관리 앱입니다.

### 1.2 핵심 기능 목록

| # | 기능 | 설명 | Android 구현 난이도 |
|---|------|------|-------------------|
| 1 | 프로젝트 관리 | 프로젝트별 태스크 구분 | ⭐ 쉬움 |
| 2 | 태스크 관리 | CRUD, 우선순위, 상태 | ⭐ 쉬움 |
| 3 | 섹션/태그 | 태스크 그룹화 및 분류 | ⭐ 쉬움 |
| 4 | 뷰 전환 | 리스트/보드/캘린더 | ⭐⭐ 보통 |
| 5 | 반복 태스크 | 습관(habitReset)/롤오버(rollover) 방식 | ⭐⭐ 보통 |
| 6 | 필터 & 검색 | 사용자 정의 필터, 로컬 검색 | ⭐⭐ 보통 |
| 7 | 홈 화면 위젯 | 태스크 요약 표시 (Top 3 + 카운트) | ⭐⭐⭐ 어려움 |
| 8 | 프라이버시 모드 | 제목 마스킹 (Level 0/1/2) | ⭐ 쉬움 |
| 9 | Live Activity | 다이나믹 아일랜드 | ❌ Android에 없음 |
| 10 | Controls | 잠금화면 버튼 | ⭐⭐ Quick Settings Tile |
| 11 | 단축어 연동 | App Intents | ⭐⭐ App Shortcuts |

### 1.3 iOS 전용 기능 (Android 대체)

| iOS 기능 | Android 대체 방안 | 비고 |
|---------|------------------|------|
| Live Activity (다이나믹 아일랜드) | Ongoing Notification (상단 고정 알림) | 시간 제한 없음 |
| WidgetKit | Glance (Jetpack Compose 위젯) | 홈 화면 중심 |
| App Intents | App Shortcuts + Google Assistant Actions | |
| Controls (iOS 18) | Quick Settings Tile (API 24+) | |

### 1.4 재사용 가능 비율 분석

| 영역 | 재사용률 | 설명 |
|------|---------|------|
| 도메인 로직 (AppCore) | ~90% | Kotlin 변환만 필요 |
| 저장소 (AppStorage) | ~50% | JSON 스키마 동일, 구현체 재작성 |
| UI | ~0% | 완전 재작성 (SwiftUI → Compose) |
| 위젯 | ~30% | 표시 로직 재사용, UI 재작성 |

---

## 2. iOS 프로젝트 구조 분석

### 2.1 모듈별 현황

| 모듈 | 파일 수 | 역할 |
|------|---------|------|
| AppCore | 45 | 순수 도메인 로직 (플랫폼 독립) |
| AppStorage | 15 | JSON 파일 기반 영속화 |
| LivePlan (App) | 29 | SwiftUI UI |
| WidgetExtension | 5 | 잠금화면 위젯 (WidgetKit) |
| LivePlanIntents | 10 | App Intents + Controls (iOS 18) |

### 2.2 iOS 원본 구조

```
LivePlan/
├── AppCore/              ← 도메인 로직 (Swift Package)
│   └── Sources/
│       └── AppCore/
│           ├── Models/       ← 데이터 모델 (10개)
│           ├── Repositories/ ← 저장소 인터페이스
│           ├── UseCases/     ← 비즈니스 로직 (12개)
│           ├── Filters/      ← 필터 정의
│           ├── Selection/    ← 잠금화면 선택 로직 (OutstandingComputer)
│           ├── Parsing/      ← QuickAddParser
│           └── Privacy/      ← PrivacyMasker
├── AppStorage/           ← 저장소 구현 (Swift Package)
│   ├── DataSnapshot/
│   └── Migration/
├── LivePlan/             ← 메인 앱 (SwiftUI)
│   └── Views/            ← 29개 화면
├── LivePlanWidgetExtension/  ← 위젯
└── LivePlanIntents/      ← App Intents
```

### 2.3 변환 대상 목록

**모델 (10개)**
- Project, Task, CompletionLog, Section, Tag
- Priority, WorkflowState, RecurrenceRule, SavedView, AppSettings

**UseCase (12개)**
- CompleteTaskUseCase, AddTaskUseCase, UpdateTaskUseCase, StartTaskUseCase
- ApplyFilterUseCase, OutstandingComputer, QuickAddParser, PrivacyMasker 등

---

## 3. 기술 스택 매핑

### 3.1 언어 및 프레임워크

| iOS | Android | 비고 |
|-----|---------|------|
| Swift 5.9 | Kotlin 1.9+ | 문법 유사 |
| SwiftUI | Jetpack Compose | UI 패러다임 동일 (선언형) |
| Combine | Kotlin Flow | 반응형 프로그래밍 |
| async/await | suspend fun + Coroutines | 비동기 처리 |
| struct (데이터 모델) | data class | |
| Codable | kotlinx.serialization | |
| Sendable | @Immutable | |

### 3.2 데이터 저장

| iOS | Android | 비고 |
|-----|---------|------|
| FileManager (JSON) | Room Database | SQLite 기반, 복잡한 쿼리 지원 |
| UserDefaults | DataStore Preferences | 설정 저장 |
| App Groups | SharedPreferences + ContentProvider | 앱-위젯 데이터 공유 |

### 3.3 아키텍처

| iOS | Android |
|-----|---------|
| Swift Package (AppCore) | Module (`:core`) |
| Swift Package (AppStorage) | Module (`:data`) |
| Repository Pattern | Repository Pattern (동일) |
| UseCase Pattern | UseCase Pattern (동일) |

### 3.4 확정 기술 스택

| 영역 | 라이브러리 | 이유 |
|------|-----------|------|
| UI | Jetpack Compose + Material 3 | 표준 |
| 상태 관리 | ViewModel + StateFlow | 표준 |
| DI | Hilt | 표준 |
| 저장소 | Room Database | 복잡한 쿼리, 관계형 데이터 |
| 설정 | DataStore Preferences | 경량 설정 |
| 직렬화 | kotlinx.serialization | |
| 비동기 | Coroutines + Flow | 표준 |
| 위젯 | Glance 1.0 | Compose 기반 |
| 백그라운드 | WorkManager | |
| 네비게이션 | Navigation Compose | |
| 테스트 | JUnit 5 + Mockk + Turbine | Flow 테스트 포함 |
| Crash | Firebase Crashlytics | 무료/경량 |

---

## 4. Android 프로젝트 구조

### 4.1 멀티 모듈 구조

```
LivePlan-Android/
├── app/                          ← 메인 앱 모듈
│   └── src/main/
│       ├── kotlin/
│       │   └── com/liveplan/
│       │       ├── ui/               ← Jetpack Compose 화면
│       │       │   ├── common/       ← 공통 컴포넌트
│       │       │   ├── project/      ← 프로젝트 관련 화면
│       │       │   ├── task/         ← 태스크 관련 화면
│       │       │   ├── filter/       ← 필터/검색 화면
│       │       │   └── settings/     ← 설정 화면
│       │       ├── viewmodel/        ← ViewModel 계층
│       │       ├── di/               ← Hilt DI 설정
│       │       └── navigation/       ← Navigation Compose
│       └── res/
│           ├── values/strings.xml        ← EN 기본
│           └── values-ko/strings.xml     ← KR
│
├── core/                         ← 도메인 모듈 (AppCore 포팅)
│   └── src/main/kotlin/
│       └── com/liveplan/core/
│           ├── model/            ← data class (10개)
│           ├── repository/       ← Repository 인터페이스
│           ├── usecase/          ← UseCase (12개)
│           ├── selection/        ← OutstandingComputer
│           ├── parsing/          ← QuickAddParser
│           ├── privacy/          ← PrivacyMasker
│           ├── filter/           ← 필터 로직
│           └── error/            ← 도메인 에러 정의
│
├── data/                         ← 데이터 모듈 (AppStorage 포팅)
│   └── src/main/kotlin/
│       └── com/liveplan/data/
│           ├── database/         ← Room DB + DAO
│           ├── repository/       ← Repository 구현체
│           ├── datastore/        ← DataStore (AppSettings)
│           └── migration/        ← 스키마 마이그레이션
│
├── widget/                       ← 위젯 모듈
│   └── src/main/kotlin/
│       └── com/liveplan/widget/
│           ├── receiver/         ← GlanceAppWidgetReceiver
│           ├── ui/               ← Glance Composable
│           └── worker/           ← 주기적 갱신 Worker
│
└── shortcuts/                    ← 단축키/타일 모듈
    └── src/main/kotlin/
        └── com/liveplan/shortcuts/
            ├── tiles/            ← Quick Settings Tiles
            └── actions/          ← App Actions
```

### 4.2 모듈 의존성

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

---

## 5. 레이어별 변환 전략

### 5.1 AppCore → :core 모듈

**변환 매핑**

| iOS (Swift) | Android (Kotlin) |
|-------------|------------------|
| struct (데이터 모델) | data class |
| Codable | kotlinx.serialization |
| async/await | suspend fun + Coroutines |
| Sendable | @Immutable 또는 불변 클래스 |
| 순수 함수 | 동일 (변경 불필요) |

**장점**: AppCore는 플랫폼 독립적으로 설계되어 로직 90% 재사용 가능

### 5.2 AppStorage → :data 모듈

| iOS | Android 옵션 | 채택 |
|-----|-------------|------|
| JSON 파일 | Room Database | ✅ 복잡한 쿼리, 관계형 데이터 |
| JSON 파일 | DataStore (Proto) | 설정 전용 |
| App Group 공유 | ContentProvider | 위젯 공유용 |
| FileManager | Context.filesDir | 내부 저장소 |

**마이그레이션 전략**
- schemaVersion 개념 유지
- DataSnapshot → Room Entity + TypeConverter

### 5.3 SwiftUI → Jetpack Compose

| SwiftUI | Jetpack Compose |
|---------|-----------------|
| @StateObject | ViewModel + StateFlow |
| @EnvironmentObject | CompositionLocalProvider |
| @Published | MutableStateFlow |
| List | LazyColumn |
| NavigationStack | Navigation Compose |
| Form / Section | Column + Card |
| Picker | DropdownMenu / ExposedDropdownMenuBox |
| Dynamic Type | MaterialTheme.typography |

### 5.4 WidgetKit → Glance API

| iOS WidgetKit | Android Glance |
|---------------|----------------|
| TimelineProvider | GlanceAppWidgetReceiver |
| accessoryRectangular | 4x2 위젯 |
| accessoryInline | 1x1 또는 텍스트 위젯 |
| accessoryCircular | 원형 위젯 (Wear OS 스타일) |
| 5분 갱신 제한 | 15분 (WorkManager 권장 30분) |

### 5.5 App Intents → Android Shortcuts

| iOS | Android |
|-----|---------|
| @AppIntent | ShortcutInfo + Intent |
| AppIntents.perform() | BroadcastReceiver 또는 Activity |
| Controls (iOS 18) | Quick Settings Tiles (API 24+) |
| Shortcuts 자동화 | Tasker 연동 또는 AlarmManager |

**인텐트 전환 (4개)**
- CompleteNextTaskIntent → Shortcut + Widget Button
- QuickAddTaskIntent → App Action + Voice Input
- RefreshLiveActivityIntent → WorkManager periodic task
- StartNextTaskIntent → Shortcut

### 5.6 Live Activity → 대안 (Android에 직접 대응 없음)

| iOS Live Activity | Android 대안 |
|-------------------|-------------|
| 잠금화면 카드 | Ongoing Notification (Foreground Service) |
| 동적 업데이트 | Notification 업데이트 |
| 8시간 제한 | 제한 없음 (배터리 최적화 주의) |

---

## 6. 데이터 모델 변환

### 6.1 전체 모델 변환표

| iOS (Swift) | Android (Kotlin) | 타입 변환 |
|-------------|------------------|----------|
| `String` | `String` | 동일 |
| `Int` | `Int` | 동일 |
| `Bool` | `Boolean` | 이름만 다름 |
| `Date` | `Long` | timestamp로 변환 |
| `Date?` | `Long?` | nullable |
| `[String]` | `List<String>` | JSON으로 Room 저장 |
| `enum` | `enum class` | 거의 동일 |
| `struct` | `data class` | 동일 개념 |
| `Codable` | `@Entity` | Room Entity |

### 6.2 변환할 모델 목록

| iOS 모델 | Android 모델 | Room Entity | 비고 |
|---------|-------------|-------------|------|
| Task.swift | Task.kt | ✅ | 핵심 |
| Project.swift | Project.kt | ✅ | 핵심 |
| CompletionLog.swift | CompletionLog.kt | ✅ | 완료 기록 |
| Section.swift | Section.kt | ✅ | 프로젝트 내 그룹 |
| Tag.swift | Tag.kt | ✅ | 다대다 분류 |
| Priority.swift | Priority.kt | enum class | P1~P4 |
| WorkflowState.swift | WorkflowState.kt | enum class | todo/doing/done |
| RecurrenceRule.swift | RecurrenceRule.kt | data class | 반복 규칙 |
| SavedView.swift | SavedView.kt | ✅ | 필터/저장된 뷰 |
| AppSettings.swift | AppSettings.kt | DataStore | 설정 |

### 6.3 Task 모델 변환

**iOS Swift**
```swift
public struct Task: Identifiable, Codable {
    public let id: String
    public var projectId: String
    public var title: String
    public var priority: Priority
    public var workflowState: WorkflowState
    public var dueDate: Date?
    public var sectionId: String?
    public var tagIds: [String]
    public var note: String?
    public var recurrenceRule: RecurrenceRule?
    public var recurrenceBehavior: RecurrenceBehavior
    public var blockedByTaskIds: [String]
    // ...
}
```

**Android Kotlin**
```kotlin
@Entity(tableName = "tasks")
data class Task(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    var title: String,
    val priority: Priority = Priority.P4,
    val workflowState: WorkflowState = WorkflowState.TODO,
    val dueDate: Long? = null,  // Date → Long (timestamp)
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val sectionId: String? = null,
    val tagIds: String = "",  // List<String> → JSON String
    val note: String? = null,
    val recurrenceRule: String? = null,  // JSON으로 저장
    val recurrenceBehavior: RecurrenceBehavior = RecurrenceBehavior.HABIT_RESET,
    val blockedByTaskIds: String = "",  // JSON으로 저장
) {
    val isDone: Boolean get() = workflowState == WorkflowState.DONE
    val isRecurring: Boolean get() = recurrenceRule != null
}
```

### 6.4 Priority Enum 변환

**iOS**
```swift
public enum Priority: Int, Codable {
    case p1 = 1, p2 = 2, p3 = 3, p4 = 4
    public static let defaultPriority: Priority = .p4
}
```

**Android**
```kotlin
enum class Priority(val value: Int) {
    P1(1), P2(2), P3(3), P4(4);

    companion object {
        val DEFAULT = P4
        fun fromValue(value: Int) = entries.find { it.value == value } ?: DEFAULT
    }
}
```

### 6.5 WorkflowState Enum 변환

**iOS**
```swift
public enum WorkflowState: String, Codable {
    case todo, doing, done
    public static let defaultState: WorkflowState = .todo
}
```

**Android**
```kotlin
enum class WorkflowState {
    TODO, DOING, DONE;

    companion object {
        val DEFAULT = TODO
    }

    val isActive: Boolean get() = this != DONE
}
```

### 6.6 RecurrenceBehavior Enum

```kotlin
enum class RecurrenceBehavior {
    HABIT_RESET,  // 체크 안 해도 다음 날 새로 (기본)
    ROLLOVER;     // 미완료는 지연으로 남아있음

    companion object {
        val DEFAULT = HABIT_RESET
    }
}
```

---

## 7. UI 변환 가이드

### 7.1 SwiftUI → Jetpack Compose 매핑

| SwiftUI | Jetpack Compose |
|---------|-----------------|
| `VStack` | `Column` |
| `HStack` | `Row` |
| `ZStack` | `Box` |
| `List` | `LazyColumn` |
| `ForEach` | `items()` |
| `NavigationView` | `Scaffold` + `NavHost` |
| `NavigationLink` | `navController.navigate()` |
| `@State` | `remember { mutableStateOf() }` |
| `@StateObject` | `viewModel()` |
| `@Binding` | 매개변수로 전달 |
| `.padding()` | `Modifier.padding()` |
| `.background()` | `Modifier.background()` |
| `Button` | `Button` |
| `TextField` | `OutlinedTextField` |
| `Toggle` | `Switch` |
| `Picker` | `DropdownMenu` |
| `DatePicker` | `DatePickerDialog` |
| `Sheet` | `ModalBottomSheet` |
| `Alert` | `AlertDialog` |

### 7.2 화면 변환 목록 (29개)

| iOS View | Android Composable | 우선순위 |
|----------|-------------------|---------|
| ContentView | MainScreen | 🔴 높음 |
| ProjectListView | ProjectListScreen | 🔴 높음 |
| ProjectDetailView | ProjectDetailScreen | 🔴 높음 |
| ProjectBoardView | KanbanBoardScreen | 🟡 중간 |
| ProjectCalendarView | CalendarScreen | 🟡 중간 |
| TaskCreateView | TaskCreateDialog | 🔴 높음 |
| TaskDetailView | TaskDetailScreen | 🔴 높음 |
| TaskRowView | TaskRow | 🔴 높음 |
| FilterListView | FilterListScreen | 🟡 중간 |
| FilterBuilderView | FilterBuilderScreen | 🟡 중간 |
| SearchView | SearchScreen | 🟡 중간 |
| SettingsView | SettingsScreen | 🟢 낮음 |

### 7.3 Navigation 구조

```kotlin
// Navigation.kt
sealed class Screen(val route: String) {
    object ProjectList : Screen("projects")
    object ProjectDetail : Screen("project/{projectId}") {
        fun createRoute(projectId: String) = "project/$projectId"
    }
    object TaskCreate : Screen("task/create/{projectId}") {
        fun createRoute(projectId: String) = "task/create/$projectId"
    }
    object TaskDetail : Screen("task/{taskId}") {
        fun createRoute(taskId: String) = "task/$taskId"
    }
    object Settings : Screen("settings")
    object Search : Screen("search")
    object FilterBuilder : Screen("filter/builder")
}

@Composable
fun LivePlanNavHost(navController: NavHostController) {
    NavHost(navController, startDestination = Screen.ProjectList.route) {
        composable(Screen.ProjectList.route) {
            ProjectListScreen(navController)
        }
        composable(
            Screen.ProjectDetail.route,
            arguments = listOf(navArgument("projectId") { type = NavType.StringType })
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getString("projectId") ?: return@composable
            ProjectDetailScreen(projectId, navController)
        }
        // ...
    }
}
```

### 7.4 TaskRow 컴포넌트

**iOS: TaskRowView.swift**
```swift
struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
            }

            VStack(alignment: .leading) {
                Text(task.title)
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            PriorityBadge(priority: task.priority)
        }
        .padding()
    }
}
```

**Android: TaskRow.kt**
```kotlin
@Composable
fun TaskRow(
    task: Task,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onToggle) {
            Icon(
                imageVector = if (task.isDone)
                    Icons.Filled.CheckCircle
                else
                    Icons.Outlined.Circle,
                contentDescription = "완료 토글"
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = task.title,
                style = MaterialTheme.typography.bodyLarge
            )
            task.dueDate?.let { dueDate ->
                Text(
                    text = formatDate(dueDate),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        PriorityBadge(priority = task.priority)
    }
}

@Composable
fun PriorityBadge(priority: Priority) {
    val color = when (priority) {
        Priority.P1 -> Color.Red
        Priority.P2 -> Color(0xFFFF9800)
        Priority.P3 -> Color(0xFF2196F3)
        Priority.P4 -> Color.Gray
    }

    Box(
        modifier = Modifier
            .size(8.dp)
            .background(color, CircleShape)
    )
}
```

---

## 8. 위젯 변환

### 8.1 iOS WidgetKit vs Android Glance

| 항목 | iOS WidgetKit | Android Glance |
|------|--------------|----------------|
| UI 프레임워크 | SwiftUI | Jetpack Compose |
| 갱신 방식 | Timeline | WorkManager |
| 최소 갱신 간격 | 5분 | 15분 (권장 30분) |
| 잠금화면 지원 | iOS 16+ | Android 12+ (제한적) |
| 데이터 공유 | App Groups | ContentProvider |

### 8.2 위젯 종류

| iOS 위젯 | Android 위젯 | 크기 |
|---------|-------------|------|
| accessoryCircular | 없음 (Android 미지원) | - |
| accessoryRectangular | 소형 위젯 | 2x1 |
| accessoryInline | 없음 | - |
| systemSmall | 소형 위젯 | 2x2 |
| systemMedium | 중형 위젯 | 4x2 |

### 8.3 Glance 위젯 구현

```kotlin
// LivePlanWidget.kt
class LivePlanWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            LivePlanWidgetContent()
        }
    }
}

@Composable
fun LivePlanWidgetContent() {
    val context = LocalContext.current
    val repository = // Hilt를 통해 가져오거나 직접 생성
    val tasks by repository.getOutstandingTasks().collectAsState(emptyList())

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(GlanceTheme.colors.background)
            .padding(12.dp)
    ) {
        Text(
            text = context.getString(R.string.widget_title_today),
            style = TextStyle(
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
                color = GlanceTheme.colors.onBackground
            )
        )

        Spacer(modifier = GlanceModifier.height(8.dp))

        tasks.take(3).forEach { task ->
            TaskWidgetRow(task)
        }

        if (tasks.size > 3) {
            Text(
                text = "+${tasks.size - 3}개 더",
                style = TextStyle(color = ColorProvider(Color.Gray))
            )
        }

        if (tasks.isEmpty()) {
            Text(
                text = context.getString(R.string.widget_empty),
                style = TextStyle(color = ColorProvider(Color.Gray))
            )
        }
    }
}

// LivePlanWidgetReceiver.kt
class LivePlanWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LivePlanWidget()
}
```

### 8.4 위젯 갱신 구현

```kotlin
// WidgetUpdateWorker.kt
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        // 위젯 데이터 갱신
        LivePlanWidget().updateAll(applicationContext)
        return Result.success()
    }
}

// 주기적 갱신 설정
fun scheduleWidgetUpdate(context: Context) {
    val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
        30, TimeUnit.MINUTES  // 30분마다 갱신
    ).build()

    WorkManager.getInstance(context)
        .enqueueUniquePeriodicWork(
            "widget_update",
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
}
```

### 8.5 Quick Settings Tile (iOS Controls 대체)

```kotlin
// CompleteTaskTileService.kt
class CompleteTaskTileService : TileService() {

    @Inject
    lateinit var completeNextTaskUseCase: CompleteNextTaskUseCase

    override fun onClick() {
        CoroutineScope(Dispatchers.IO).launch {
            val result = completeNextTaskUseCase()
            result.onSuccess {
                // 성공 시 Tile 상태 업데이트
                qsTile?.let { tile ->
                    tile.state = Tile.STATE_ACTIVE
                    tile.updateTile()
                }
            }
        }
    }

    override fun onStartListening() {
        // 타일이 표시될 때 상태 업데이트
        qsTile?.let { tile ->
            tile.label = getString(R.string.tile_complete_task)
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
        }
    }
}
```

### 8.6 App Shortcuts

```xml
<!-- res/xml/shortcuts.xml -->
<shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
    <shortcut
        android:shortcutId="quick_add"
        android:enabled="true"
        android:icon="@drawable/ic_add"
        android:shortcutShortLabel="@string/quick_add_short"
        android:shortcutLongLabel="@string/quick_add_long">
        <intent
            android:action="android.intent.action.VIEW"
            android:targetPackage="com.liveplan"
            android:targetClass="com.liveplan.ui.task.QuickAddActivity" />
    </shortcut>

    <shortcut
        android:shortcutId="complete_next"
        android:enabled="true"
        android:icon="@drawable/ic_check"
        android:shortcutShortLabel="@string/complete_next_short"
        android:shortcutLongLabel="@string/complete_next_long">
        <intent
            android:action="com.liveplan.COMPLETE_NEXT_TASK"
            android:targetPackage="com.liveplan"
            android:targetClass="com.liveplan.shortcuts.CompleteNextTaskReceiver" />
    </shortcut>
</shortcuts>
```

### 8.7 Ongoing Notification (iOS Live Activity 대체)

```kotlin
// LivePlanNotificationService.kt
class LivePlanNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "liveplan_ongoing"
        const val NOTIFICATION_ID = 1
    }

    private fun createOngoingNotification(task: Task): Notification {
        val completeIntent = Intent(this, CompleteTaskReceiver::class.java).apply {
            action = "COMPLETE_TASK"
            putExtra("taskId", task.id)
        }
        val completePendingIntent = PendingIntent.getBroadcast(
            this, 0, completeIntent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_in_progress))
            .setContentText(task.title)
            .setSmallIcon(R.drawable.ic_task)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                R.drawable.ic_check,
                getString(R.string.action_complete),
                completePendingIntent
            )
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

---

## 9. 에러 처리 전략

### 9.1 에러 타입 정의

```kotlin
// :core 모듈
sealed class AppError : Exception() {
    // 도메인 에러
    data class ValidationError(override val message: String) : AppError()
    data class NotFoundError(val entityType: String, val id: String) : AppError()
    object EmptyTitleError : AppError()
    object NoTaskToCompleteError : AppError()

    // 저장소 에러
    data class StorageError(override val cause: Throwable) : AppError()
    data class MigrationError(val fromVersion: Int, val toVersion: Int) : AppError()

    // UI 에러
    data class UnexpectedError(override val cause: Throwable) : AppError()
}
```

### 9.2 UseCase Result 패턴

```kotlin
// UseCase는 항상 Result<T> 반환
class AddTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository
) {
    suspend operator fun invoke(
        projectId: String,
        title: String,
        priority: Priority = Priority.P4,
        dueDate: Long? = null
    ): Result<Task> {
        // 입력 검증
        if (title.isBlank()) {
            return Result.failure(AppError.EmptyTitleError)
        }

        return try {
            val task = Task(
                projectId = projectId,
                title = title.trim(),
                priority = priority,
                dueDate = dueDate
            )
            taskRepository.addTask(task)
            Result.success(task)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
```

### 9.3 ViewModel 에러 처리

```kotlin
@HiltViewModel
class TaskViewModel @Inject constructor(
    private val addTaskUseCase: AddTaskUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow<TaskUiState>(TaskUiState.Idle)
    val uiState: StateFlow<TaskUiState> = _uiState.asStateFlow()

    fun addTask(projectId: String, title: String) {
        viewModelScope.launch {
            _uiState.value = TaskUiState.Loading

            addTaskUseCase(projectId, title)
                .onSuccess { task ->
                    _uiState.value = TaskUiState.Success(task)
                }
                .onFailure { error ->
                    _uiState.value = TaskUiState.Error(error.toUserMessage())
                }
        }
    }
}

sealed class TaskUiState {
    object Idle : TaskUiState()
    object Loading : TaskUiState()
    data class Success(val task: Task) : TaskUiState()
    data class Error(val message: String) : TaskUiState()
}

// 에러 메시지 변환
fun Throwable.toUserMessage(): String = when (this) {
    is AppError.EmptyTitleError -> "제목을 입력해주세요"
    is AppError.NoTaskToCompleteError -> "완료할 항목이 없습니다"
    is AppError.NotFoundError -> "${entityType}을(를) 찾을 수 없습니다"
    is AppError.StorageError -> "데이터를 저장하지 못했습니다"
    else -> "알 수 없는 오류가 발생했습니다"
}
```

### 9.4 Fail-safe 정책 (필수)

```kotlin
// 저장소 로드 실패 시 빈 상태 반환 (크래시 금지)
class TaskRepositoryImpl @Inject constructor(
    private val taskDao: TaskDao
) : TaskRepository {

    override fun getAllTasks(): Flow<List<Task>> {
        return taskDao.getAllTasks()
            .catch { e ->
                Log.e("TaskRepository", "Failed to load tasks", e)
                emit(emptyList()) // Fail-safe: 빈 리스트 반환
            }
    }
}

// 위젯에서 데이터 로드 실패 시 안전한 폴백
@Composable
fun LivePlanWidgetContent() {
    val tasks = try {
        // 데이터 로드 시도
        repository.getOutstandingTasks()
    } catch (e: Exception) {
        emptyList() // 폴백
    }

    if (tasks.isEmpty()) {
        Text(text = stringResource(R.string.widget_empty))
    } else {
        // 정상 표시
    }
}
```

---

## 10. 테스트 전략

### 10.1 테스트 계층

| 계층 | 대상 | 도구 | 커버리지 목표 |
|------|------|------|-------------|
| Unit | :core 모듈 | JUnit 5 + Mockk | 90% |
| Unit | :data 모듈 | JUnit 5 + Room In-Memory | 80% |
| Integration | Repository | JUnit 5 | 70% |
| UI | 주요 화면 | Compose Testing | 주요 플로우 |

### 10.2 :core 모듈 테스트 (필수)

```kotlin
// OutstandingComputerTest.kt
class OutstandingComputerTest {

    private lateinit var computer: OutstandingComputer

    @BeforeEach
    fun setup() {
        computer = OutstandingComputer()
    }

    @Test
    fun `oneOff 완료 시 outstanding에서 제외`() {
        // Given
        val task = Task(id = "1", title = "Test", projectId = "p1")
        val log = CompletionLog(taskId = "1", occurrenceKey = "once")

        // When
        val result = computer.compute(
            dateKey = "2026-02-02",
            tasks = listOf(task),
            completionLogs = listOf(log)
        )

        // Then
        assertThat(result.displayList).isEmpty()
        assertThat(result.counters.outstandingTotal).isEqualTo(0)
    }

    @Test
    fun `dailyRecurring 완료 시 오늘만 제외`() {
        // Given
        val task = Task(
            id = "1",
            title = "Daily Task",
            projectId = "p1",
            recurrenceRule = """{"kind":"daily"}""",
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET
        )
        val log = CompletionLog(taskId = "1", occurrenceKey = "2026-02-02")

        // When
        val result = computer.compute(
            dateKey = "2026-02-02",
            tasks = listOf(task),
            completionLogs = listOf(log)
        )

        // Then
        assertThat(result.displayList).isEmpty()
        assertThat(result.counters.recurringDone).isEqualTo(1)
    }

    @Test
    fun `dailyRecurring 다음 날 리셋`() {
        // Given
        val task = Task(
            id = "1",
            title = "Daily Task",
            projectId = "p1",
            recurrenceRule = """{"kind":"daily"}"""
        )
        val log = CompletionLog(taskId = "1", occurrenceKey = "2026-02-01") // 어제 완료

        // When
        val result = computer.compute(
            dateKey = "2026-02-02", // 오늘
            tasks = listOf(task),
            completionLogs = listOf(log)
        )

        // Then
        assertThat(result.displayList).hasSize(1) // 오늘은 미완료로 표시
    }
}
```

### 10.3 Room DAO 테스트

```kotlin
@RunWith(AndroidJUnit4::class)
class TaskDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var taskDao: TaskDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).build()
        taskDao = database.taskDao()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun insertAndRetrieveTask() = runTest {
        val task = Task(id = "1", projectId = "p1", title = "Test")
        taskDao.insert(task)

        val tasks = taskDao.getTasksByProject("p1").first()
        assertThat(tasks).containsExactly(task)
    }
}
```

### 10.4 Flow 테스트 (Turbine)

```kotlin
@Test
fun `task 추가 시 Flow 업데이트`() = runTest {
    val task = Task(id = "1", projectId = "p1", title = "Test")

    taskDao.getTasksByProject("p1").test {
        assertThat(awaitItem()).isEmpty()

        taskDao.insert(task)
        assertThat(awaitItem()).containsExactly(task)

        cancelAndIgnoreRemainingEvents()
    }
}
```

### 10.5 테스트 의존성

```kotlin
// build.gradle.kts (:core)
dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("app.cash.turbine:turbine:1.0.0")
    testImplementation("com.google.truth:truth:1.1.5")
}

// build.gradle.kts (:data)
dependencies {
    androidTestImplementation("androidx.room:room-testing:2.6.1")
    androidTestImplementation("androidx.test:runner:1.5.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
}
```

---

## 11. 다국어 처리

### 11.1 리소스 구조

```
res/
├── values/
│   └── strings.xml        (EN 기본)
└── values-ko/
    └── strings.xml        (KR)
```

### 11.2 문자열 키 규칙 (iOS strings-localization.md 준수)

| 접두어 | 용도 | 예시 |
|--------|------|------|
| `app.*` | 앱 UI | `app.project.create` |
| `widget.*` | 위젯 | `widget.title.today` |
| `notification.*` | 알림 | `notification.in_progress` |
| `error.*` | 에러 메시지 | `error.empty_title` |
| `action.*` | 액션 버튼 | `action.complete` |

### 11.3 strings.xml (EN)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- App -->
    <string name="app_name">LivePlan</string>
    <string name="app_project_create">Create Project</string>
    <string name="app_task_add">Add Task</string>

    <!-- Widget -->
    <string name="widget_title_today">Today</string>
    <string name="widget_empty">Add tasks to get started</string>
    <string name="widget_remaining">%d remaining</string>
    <string name="widget_overdue">%d overdue</string>

    <!-- Notification -->
    <string name="notification_in_progress">In Progress</string>
    <string name="notification_channel_ongoing">Current Task</string>

    <!-- Actions -->
    <string name="action_complete">Complete</string>
    <string name="action_start">Start</string>
    <string name="action_cancel">Cancel</string>
    <string name="action_save">Save</string>

    <!-- Errors -->
    <string name="error_empty_title">Please enter a title</string>
    <string name="error_no_task">No task to complete</string>
    <string name="error_load_failed">Failed to load data. Please check in the app.</string>
    <string name="error_save_failed">Failed to save</string>

    <!-- Shortcuts -->
    <string name="quick_add_short">Quick Add</string>
    <string name="quick_add_long">Quickly add a new task</string>
    <string name="complete_next_short">Complete</string>
    <string name="complete_next_long">Complete the next task</string>

    <!-- Tile -->
    <string name="tile_complete_task">Complete Task</string>

    <!-- Privacy -->
    <string name="privacy_notice">Your lock screen can be seen by others nearby.</string>
</resources>
```

### 11.4 strings.xml (KR)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- App -->
    <string name="app_name">LivePlan</string>
    <string name="app_project_create">프로젝트 만들기</string>
    <string name="app_task_add">할 일 추가</string>

    <!-- Widget -->
    <string name="widget_title_today">오늘 할 일</string>
    <string name="widget_empty">할 일을 추가하세요</string>
    <string name="widget_remaining">미완료 %d</string>
    <string name="widget_overdue">지연 %d</string>

    <!-- Notification -->
    <string name="notification_in_progress">현재 진행 중</string>
    <string name="notification_channel_ongoing">현재 작업</string>

    <!-- Actions -->
    <string name="action_complete">완료</string>
    <string name="action_start">시작</string>
    <string name="action_cancel">취소</string>
    <string name="action_save">저장</string>

    <!-- Errors -->
    <string name="error_empty_title">제목을 입력해주세요</string>
    <string name="error_no_task">완료할 항목이 없습니다</string>
    <string name="error_load_failed">데이터를 불러오지 못했습니다. 앱에서 확인해주세요.</string>
    <string name="error_save_failed">저장에 실패했습니다</string>

    <!-- Shortcuts -->
    <string name="quick_add_short">빠른 추가</string>
    <string name="quick_add_long">새 할 일 빠르게 추가</string>
    <string name="complete_next_short">완료</string>
    <string name="complete_next_long">다음 할 일 완료</string>

    <!-- Tile -->
    <string name="tile_complete_task">태스크 완료</string>

    <!-- Privacy -->
    <string name="privacy_notice">잠금화면은 주변 사람이 볼 수 있습니다.</string>
</resources>
```

### 11.5 길이 예산 (잠금화면)

| 표면 | 최대 길이 (KR) |
|------|---------------|
| 위젯 1라인 | 18~24자 (말줄임 허용) |
| 알림 제목 | 20자 |
| 알림 내용 | 40자 |
| 타일 라벨 | 12자 |

---

## 12. CI/CD 파이프라인

### 12.1 GitHub Actions 설정

```yaml
# .github/workflows/android.yml
name: Android CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Run Lint
        run: ./gradlew lint

      - name: Run Unit Tests
        run: ./gradlew test

      - name: Build Debug APK
        run: ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk

  instrumented-tests:
    runs-on: ubuntu-latest
    needs: build

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle

      - name: Run Instrumented Tests
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          arch: x86_64
          script: ./gradlew connectedCheck
```

### 12.2 릴리즈 워크플로우

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build Release AAB
        run: ./gradlew bundleRelease
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.liveplan
          releaseFiles: app/build/outputs/bundle/release/app-release.aab
          track: internal
```

---

## 13. 마일스톤 계획

### 13.1 Phase A: 기반 설정 (Week 1)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| A-01 | 프로젝트 생성 + 멀티모듈 | 빌드 성공 |
| A-02 | Gradle 의존성 설정 | 모든 라이브러리 resolve |
| A-03 | CI 설정 (GitHub Actions) | PR 빌드 성공 |
| A-04 | 코드 스타일/린트 설정 | ktlint 통과 |

### 13.2 Phase B: 도메인 포팅 (Week 2)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| B-01 | 모델 10개 Kotlin 변환 | 컴파일 성공 |
| B-02 | Enum 변환 (Priority, WorkflowState 등) | |
| B-03 | Repository 인터페이스 정의 | |
| B-04 | UseCase 12개 포팅 | |
| B-05 | OutstandingComputer 포팅 | |
| B-06 | QuickAddParser 포팅 | |
| B-07 | PrivacyMasker 포팅 | |
| B-08 | 단위 테스트 작성 | 90% 커버리지 |

### 13.3 Phase C: 데이터 레이어 (Week 3)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| C-01 | Room Database 설정 | |
| C-02 | DAO 5개 구현 | |
| C-03 | Repository 구현체 | |
| C-04 | DataStore (AppSettings) | |
| C-05 | 마이그레이션 전략 (schemaVersion) | |
| C-06 | 저장소 테스트 | 80% 커버리지 |

### 13.4 Phase D: UI 핵심 (Week 4-5)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| D-01 | Navigation 구조 | |
| D-02 | 공통 컴포넌트 (TaskRow, PriorityBadge 등) | |
| D-03 | ProjectListScreen | |
| D-04 | ProjectDetailScreen (List 뷰) | |
| D-05 | TaskCreateDialog | |
| D-06 | TaskDetailScreen | |
| D-07 | SettingsScreen | |
| D-08 | 다국어 리소스 (strings.xml KR/EN) | |
| D-09 | 테마 설정 (Material 3) | |

### 13.5 Phase E: UI 확장 (Week 6)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| E-01 | KanbanBoardScreen | |
| E-02 | CalendarScreen | |
| E-03 | FilterListScreen + FilterBuilder | |
| E-04 | SearchScreen | |
| E-05 | 빈 상태/에러 UI | |
| E-06 | UI 테스트 | 주요 플로우 |

### 13.6 Phase F: 위젯 (Week 7)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| F-01 | Glance 기본 설정 | |
| F-02 | Medium 위젯 (Top 3 + 카운트) | |
| F-03 | Small 위젯 | |
| F-04 | WorkManager 갱신 | |
| F-05 | 프라이버시 모드 적용 | |
| F-06 | 위젯 테스트 | |

### 13.7 Phase G: 추가 기능 (Week 7-8)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| G-01 | Quick Settings Tile | |
| G-02 | App Shortcuts | |
| G-03 | Ongoing Notification | |
| G-04 | 에러 처리/Crashlytics | |

### 13.8 Phase H: 릴리즈 (Week 8)

| 티켓 | 내용 | 완료 기준 |
|------|------|----------|
| H-01 | ProGuard/R8 설정 | |
| H-02 | Play Store 메타데이터 | |
| H-03 | 스크린샷 7장 | |
| H-04 | 내부 테스트 트랙 | |
| H-05 | 프로덕션 출시 | |

---

## 14. 예상 일정

### 14.1 전체 일정 (8주)

| 주차 | Phase | 완료 기준 |
|------|-------|----------|
| Week 1 | A: 기반 설정 | 프로젝트 빌드 성공 |
| Week 2 | B: 도메인 포팅 | 도메인 테스트 통과 |
| Week 3 | C: 데이터 레이어 | 저장소 테스트 통과 |
| Week 4-5 | D: UI 핵심 | MVP UI 동작 |
| Week 6 | E: UI 확장 | 전체 UI 완료 |
| Week 7 | F+G: 위젯/추가 기능 | 위젯/타일 동작 |
| Week 8 | H: 릴리즈 | Play Store 제출 |

### 14.2 우선순위별 작업

**🔴 필수 (MVP) - 4주 내 완료 목표**
- 프로젝트/태스크 CRUD
- 리스트 뷰
- 반복 태스크 (habitReset)
- 프라이버시 모드
- 홈 화면 위젯 (Medium)
- 로컬 저장

**🟡 중요 (v1.0)**
- Board/Calendar 뷰
- 필터/검색
- 롤오버 반복
- 섹션/태그

**🟢 선택 (v1.1+)**
- Quick Settings Tile
- App Shortcuts
- Ongoing Notification
- 고급 필터

### 14.3 예상 공수

| Phase | 예상 작업량 | 비고 |
|-------|-----------|------|
| A: 기반 설정 | 낮음 | |
| B: 도메인 포팅 | 중간 | 로직 90% 재사용 |
| C: 데이터 레이어 | 중간 | |
| D+E: UI 구현 | 높음 | 29개 화면 재작성 |
| F: 위젯 | 중간 | |
| G: 추가 기능 | 낮음 | |
| H: 릴리즈 | 낮음 | |

---

## 15. 필요 도구 및 설정

### 15.1 개발 환경

| 도구 | 버전 | 용도 |
|------|------|------|
| Android Studio | Hedgehog (2023.1.1)+ | IDE |
| JDK | 17+ | 빌드 |
| Kotlin | 1.9.20+ | 언어 |
| Gradle | 8.2+ | 빌드 시스템 |

### 15.2 필수 라이브러리 설정

```kotlin
// build.gradle.kts (프로젝트 레벨)
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
    id("com.google.dagger.hilt.android") version "2.48" apply false
    id("com.google.devtools.ksp") version "1.9.20-1.0.14" apply false
}

// build.gradle.kts (:app)
dependencies {
    // Compose
    implementation("androidx.compose.ui:ui:1.5.4")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.48")
    ksp("com.google.dagger:hilt-compiler:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Glance (위젯)
    implementation("androidx.glance:glance-appwidget:1.0.0")

    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics-ktx:18.6.0")

    // Testing
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("app.cash.turbine:turbine:1.0.0")
    testImplementation("com.google.truth:truth:1.1.5")
}
```

### 15.3 Android Studio 설치 방법

```
1. https://developer.android.com/studio 접속
2. "Download Android Studio" 클릭
3. 설치 파일 실행
4. 기본 설정으로 설치 진행
5. 설치 완료 후 SDK 자동 다운로드 대기
```

### 15.4 첫 프로젝트 생성 방법

```
1. Android Studio 실행
2. "New Project" 클릭
3. "Empty Compose Activity" 선택
4. 프로젝트 정보 입력:
   - Name: LivePlan
   - Package name: com.liveplan
   - Language: Kotlin
   - Minimum SDK: API 26 (Android 8.0)
5. "Finish" 클릭
```

### 15.5 테스트 기기

- 실제 Android 기기 (권장)
- 또는 Android Emulator
  - Android Studio 내장 AVD Manager에서 생성
  - Pixel 6 + API 34 권장

---

## 16. 주요 차이점 및 고려사항

### 16.1 플랫폼 차이

| 항목 | iOS | Android |
|------|-----|---------|
| 잠금화면 위젯 | 네이티브 지원 | 홈 화면 위젯만 |
| Live Activity | 지원 | 없음 (Notification 대체) |
| Controls | iOS 18+ | Quick Settings Tile |
| 자동화 | Shortcuts 앱 | Tasker 등 서드파티 |
| 백그라운드 제한 | 8시간 | 배터리 최적화 (더 엄격) |

### 16.2 UX 조정 필요

- **Back 버튼**: Android 네비게이션 패턴 적용
- **Material Design 3**: iOS 스타일 → Material 컴포넌트
- **위젯 배치**: 잠금화면 아닌 홈 화면 중심
- **알림 채널**: 알림 우선순위/카테고리 설정

### 16.3 성능 고려사항

- **위젯 갱신 간격**: 최소 15분 (권장 30분)
- **백그라운드 제한**: Doze 모드, 배터리 최적화 대응
- **Room vs JSON**: 복잡한 쿼리는 Room이 유리
- **ProGuard**: 난독화 + 최적화 필수

---

## 📝 다음 단계

1. **iOS 버전 먼저 테스트** - 앱이 정상 작동하는지 확인
2. **Android Studio 설치** - 개발 환경 준비
3. **Phase A 시작** - 프로젝트 생성 및 기반 설정
4. **병행 개발** - iOS 버그 수정과 Android 개발 동시 진행

---

*이 계획서는 LivePlan iOS 프로젝트 분석을 바탕으로 작성되었습니다.*
*Last Updated: 2026-02-02 14:35:42*
