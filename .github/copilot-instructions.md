# LivePlan Copilot Instructions

**Last Updated**: 2026-02-02 | **Phase**: 1 (MVP Phase 2 Roadmap in Docs/)

## Quick Start

This is a **lock-screen-first iOS app** for project/task management. The codebase is organized as:
- **AppCore** (domain logic, no UI frameworks)
- **AppStorage** (JSON file persistence + migrations)  
- **App** (SwiftUI main app)
- **LivePlanIntents** (App Intents for Shortcuts/Controls)
- **LivePlanWidgetExtension** (Lock Screen widgets)

**Architecture Rule**: AppCore imports NO UI frameworks. Storage lives in AppStorage. Extensions inherit from AppCore only.

---

## Essential Architecture

### Module Dependency Flow
```
LivePlan (UI) ─────┐
LivePlanIntents ───┼──→ AppCore ──→ (NO UI frameworks)
LivePlanWidget ────┘      ↓
                      AppStorage ──→ AppCore
```

**Key Constraints**:
1. **AppCore** = pure domain. Must NOT import SwiftUI, WidgetKit, ActivityKit, AppIntents.
2. **AppStorage** = persistence only. Implements repository protocols from AppCore.
3. **Extensions/Intents** = minimal UI + single AppCore call. No complex logic.
4. **AppState** (LivePlanApp.swift) = dependency injector. Holds repositories + use cases.

### Critical Data Model Invariants

**Project**:
- Must have `id`, `title`, `startDate` (required); `dueDate`, `note`, `status` (optional)
- Rule: `dueDate >= startDate` (validated in model)
- Status: `active|archived|completed`

**Task**:
- Must have `id`, `projectId`, `title`, `taskType` (required)
- TaskType: `oneOff` (delete on complete) | `dailyRecurring` (reset each day)
- No completion log duplication: use `(taskId, occurrenceKey)` unique constraint

**CompletionLog**:
- Always use `occurrenceKey`: "once" for oneOff, "YYYY-MM-DD" for dailyRecurring
- Immutable: id is computed from `(taskId, occurrenceKey)`
- Prevents duplicate marking & enables recurring reset logic

**AppSettings**:
- Includes `pinnedProjectId`, `privacyMode`, `currentSchemaVersion`
- Controls UI defaults and lock screen behavior

---

## Lock Screen Algorithm (Critical)

The **OutstandingComputer** selects which tasks appear on lock screen. It's a **pure function** (testable, no I/O):

```swift
OutstandingComputer().compute(
  dateKey, policy, privacyMode, projects, tasks, completionLogs
) → LockScreenSummary
```

**Selection priority** (in order):
1. **G1**: `workflowState == doing` (in progress)
2. **G2**: `dueDate < now` (overdue)
3. **G3**: `0 < dueDate - now ≤ 24h` (due soon)
4. **G4**: `priority == P1` (high priority, regardless of due date)
5. **G5**: dailyRecurring `habitReset` incomplete today
6. **G6**: other `todo` (oneOff/rollover uncompleted)

**Filtering rules**:
- Exclude `completed` tasks
- Exclude `blocked` tasks (blocked status planned Phase 2)
- Exclude archived/completed projects
- Tie-break by `dueAt` (ascending), then `priority`, then `createdAt`

**Output**: `displayList` (Top 3), `counters`, `fallbackReason`

---

## Use Cases & Repositories

All business logic flows through **use cases** (AppCore). Repositories are injected (interface-based):

### Key Use Cases
- **AddProjectUseCase** → calls `ProjectRepository.save()`
- **AddTaskUseCase** → validates title, resolves projectId (pinned→Inbox fallback), saves task
- **CompleteTaskUseCase** → creates CompletionLog, prevents duplicate completion
- **OutstandingComputer** → pure function (no I/O)

### Repository Pattern
```swift
// AppCore defines protocols (D1)
public protocol ProjectRepository: Sendable {
  func loadAll() async throws -> [Project]
  func save(_ project: Project) async throws
  func getOrCreateInbox() async throws -> Project
}

// AppStorage implements (D2)
struct FileProjectRepository: ProjectRepository { ... }
```

All UI accesses data via `AppState` repositories, not directly.

---

## File Structure Guide

| Path | Purpose | Rules |
|------|---------|-------|
| [AppCore/Sources/AppCore/Models/](AppCore/Sources/AppCore/Models/) | Data entities (Task, Project, etc.) | Must be Codable, Sendable, include validation |
| [AppCore/Sources/AppCore/UseCases/](AppCore/Sources/AppCore/UseCases/) | Business logic | Pure functions or value types; inject repositories |
| [AppCore/Sources/AppCore/Selection/](AppCore/Sources/AppCore/Selection/) | Lock screen algorithm | OutstandingComputer (pure), SelectionPolicy, LockScreenSummary |
| [AppStorage/Sources/AppStorage/](AppStorage/Sources/AppStorage/) | Persistence | FileBasedStorage (atomic writes), repositories, migrations |
| [LivePlan/Views/](LivePlan/Views/) | SwiftUI UI | Call use cases via AppState; @EnvironmentObject(appState) |
| [LivePlanIntents/](LivePlanIntents/) | App Intents | Thin wrappers around AppCore use cases + privacy |
| [LivePlanWidgetExtension/Views/](LivePlanWidgetExtension/Views/) | Lock screen widgets | Read-only; call OutstandingComputer |

---

## Common Workflows

### Adding a New Field to Task
1. Update [AppCore/Sources/AppCore/Models/Task.swift](AppCore/Sources/AppCore/Models/Task.swift) (add field + init)
2. Update tests in [AppCore/Tests/AppCoreTests/](AppCore/Tests/AppCoreTests/) if field affects business logic
3. If stored: update [AppStorage/Sources/AppStorage/DataSnapshot.swift](AppStorage/Sources/AppStorage/DataSnapshot.swift)
4. If migrating data: increment `currentSchemaVersion` in [AppCore/Sources/AppCore/Models/AppSettings.swift](AppCore/Sources/AppCore/Models/AppSettings.swift), add migration in [AppStorage/Sources/AppStorage/Migration/MigrationEngine.swift](AppStorage/Sources/AppStorage/Migration/MigrationEngine.swift)
5. Update documentation in [.claude/rules/data-model.md](.claude/rules/data-model.md)

### Adding a Lock Screen Intent
1. Create intent class in [LivePlanIntents/](LivePlanIntents/) (implement AppIntents protocol)
2. Add logic to [AppCore/UseCases/](AppCore/UseCases/) if needed
3. Test against `OutstandingComputer` output (ensure displayList[0] matches intent target)
4. Update [.claude/rules/intents.md](.claude/rules/intents.md)
5. Update [.claude/rules/lockscreen.md](.claude/rules/lockscreen.md) if selection policy changes

### Testing Lock Screen Selection
Tests live in [AppCore/Tests/AppCoreTests/OutstandingSelectionTests.swift](AppCore/Tests/AppCoreTests/OutstandingSelectionTests.swift). All selection logic is pure, so:
1. Create task/project fixtures
2. Call `OutstandingComputer().compute(...)`
3. Assert `displayList` order matches priority rules
4. Verify `counters` math

No mocking needed—OutstandingComputer is a value type.

---

## Architectural Rules (Enforce These)

| Rule | Violation Example | Fix |
|------|-------------------|-----|
| AppCore NO UI imports | `import SwiftUI` in AppCore | Remove; move to UI layer |
| Repositories in AppCore, implementations in AppStorage | `FileProjectRepository` in AppCore | Move to AppStorage; keep protocol in AppCore |
| All completion logs have unique `(taskId, occurrenceKey)` | Saving duplicate log | Check CompletionLogRepository before save |
| OutstandingComputer is pure (no I/O, no state) | Calling async function inside | Make synchronous; accept data as parameters |
| Extensions only call AppCore, not App | Importing `LivePlan` in widget | Use AppState repos via AppGroupContainer |
| All repositories are Sendable | Non-Sendable closure in repo | Use @Sendable or refactor |

---

## Key Decision Points & Rationale

### Why no CoreData?
JSON + FileBasedStorage is simpler, easier to migrate, and meets Phase 1 scope. CoreData added in Phase 2+ if needed.

### Why OutstandingComputer is pure?
Testability + determinism. Extensions (widget, Live Activity) call it offline; Intents can stub data. Avoids flaky timing tests.

### Why occurrenceKey?
Recurring tasks need "reset per day" logic. occurrenceKey = dateKey for that day's instance. Prevents data loss on schema changes.

### Why Inbox project?
Fallback when user taps QuickAdd with no pinned project. Ensures tasks always belong to *some* project.

---

## Testing Strategy

**Must Have**:
1. **AppCore tests** (`.../AppCoreTests/`) → invariant validation + use case logic
2. **Selection algorithm tests** → priority group order, tie-breaker logic, filtering
3. **Storage round-trip tests** → save → load → verify equality
4. **Schema migration tests** → v1 → v2 data integrity

**Example Test Pattern**:
```swift
func testOutstandingComputesG2BeforeG3() {
  let now = Date()
  let overdue = Task(dueDate: Date(timeIntervalSinceNow: -3600)) // -1h
  let dueSoon = Task(dueDate: Date(timeIntervalSinceNow: 3600))  // +1h
  
  let result = OutstandingComputer().compute(
    dateKey: DateKey(now), policy: .todayOverview, privacyMode: .public,
    projects: [project], tasks: [overdue, dueSoon], completionLogs: []
  )
  
  XCTAssert(result.displayList[0].id == overdue.id, "Overdue (G2) before dueSoon (G3)")
}
```

---

## Documentation Files (Reference)

Read these for detailed rules:
- [.claude/rules/architecture.md](.claude/rules/architecture.md) → module boundaries, constraints
- [.claude/rules/data-model.md](.claude/rules/data-model.md) → entity definitions, invariants
- [.claude/rules/lockscreen.md](.claude/rules/lockscreen.md) → selection algorithm, priority groups
- [.claude/rules/intents.md](.claude/rules/intents.md) → supported Shortcuts, idempotency
- [.claude/rules/testing.md](.claude/rules/testing.md) → test layers, must-have cases
- [Docs/PHASE2_ROADMAP.md](Docs/PHASE2_ROADMAP.md) → upcoming features (M1–M8)

---

## Common Pitfalls

1. **Forgetting `occurrenceKey`**: Always include it in CompletionLog. Use helpers: `CompletionLog.forOneOff(...)`, `CompletionLog.forDailyRecurring(taskId:dateKey:)`.
2. **Calling async in OutstandingComputer**: Pure function only. Pass all data as parameters.
3. **Skipping validation**: Always check `project.isValid` (dueDate ≥ startDate).
4. **Not handling Inbox fallback**: Use `ProjectRepository.getOrCreateInbox()` when projectId is nil.
5. **Forgetting @Sendable**: All repo types must be Sendable (actor + value types).
6. **Adding UI imports to AppCore**: Will break separation of concerns and extension targets.

---

## Build & Test Commands

```bash
# Build everything
xcodebuild -scheme LivePlan build

# Run unit tests
xcodebuild -scheme LivePlan test

# Run AppCore tests only
xcodebuild -scheme AppCore test

# Install to simulator
xcodebuild -scheme LivePlan -destination 'platform=iOS Simulator,name=iPhone 15' install
```

(Add to CI/CD or run before commit.)

---

## When in Doubt

1. **Check the rules** in `.claude/rules/` (architecture, data-model, lockscreen, intents)
2. **Look at existing tests** in `AppCoreTests/` for patterns
3. **Trace the dependency flow** via AppState → repositories → use cases → AppCore models
4. **Verify OutstandingComputer logic** for any lock screen changes
5. **Ensure Sendable** on all async types (actor, protocols, @Sendable closures)

---

**For Phase 2+**: Refer to [Docs/PHASE2_ROADMAP.md](Docs/PHASE2_ROADMAP.md) for expansions (Sections, Tags, Priority, WorkflowState, Recurrence, etc.).
