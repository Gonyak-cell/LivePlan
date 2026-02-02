# LivePlan - App Review Notes

> **Version**: 2.0
> **Created**: 2026-02-02

---

## App Purpose (1 sentence)

LivePlan is a task management app that displays today's tasks on the lock screen via widgets, helping users check their to-do list without unlocking the device.

---

## Feature Relationship: Required vs Optional

| Feature | Status | Description |
|---------|--------|-------------|
| **Lock Screen Widget** | Core | Summary of outstanding tasks (Top 3 + count) |
| **In-app Task Management** | Core | Create projects, add tasks, mark complete |
| **Live Activity** | Optional | Shows 1 task in Dynamic Island (8-hour limit) |
| **Shortcuts Automation** | Optional | Refresh Live Activity every 8 hours |
| **Controls (iOS 18+)** | Optional | Complete/Add buttons on lock screen |

**Note**: The app's core value is delivered through the Lock Screen Widget. Live Activity, Shortcuts, and Controls enhance the experience but are not required.

---

## Privacy Default

- **Default setting**: Privacy Mode Level 1 (Masked)
- Task titles are masked on the lock screen by default
- Only task counts are displayed until user explicitly enables full titles
- This protects sensitive information from being visible to others

---

## Reproduction Steps for Reviewers

### Prerequisites
- iPhone with iOS 17+ (iOS 18+ for Controls)
- Lock Screen Widget capability enabled

### Step-by-Step Guide

#### Step 1: Create a Project (Required)
1. Launch the app
2. Tap the **Projects** tab
3. Tap the **+** button (top right)
4. Enter project name: "Test Project"
5. Set start date to today
6. Tap **Save**

#### Step 2: Add Tasks (Required)
1. Tap on "Test Project" to open it
2. Tap the **+** button to add a task
3. Enter task title: "Test Task 1"
4. Select **Priority**: P1
5. Tap **Save**
6. Repeat to add 2-3 more tasks with different priorities

#### Step 3: Add Lock Screen Widget (Required)
1. Go to iPhone Home Screen
2. Long press → Edit → Customize Lock Screen
3. Tap the widget area below the time
4. Search for "LivePlan"
5. Add the rectangular widget (shows Top 3 tasks)
6. Tap Done

#### Step 4: Verify Widget Display
1. Lock the device
2. View the lock screen
3. Widget should display:
   - Top 3 tasks (masked by default, or with priority indicators)
   - Remaining count (e.g., "+2")
   - Counters (Outstanding, Overdue, Due Soon)

#### Step 5: Complete a Task
1. Open the app
2. Go to "Test Project"
3. Tap the checkbox next to "Test Task 1"
4. Task moves to completed section
5. Widget will update (may take a few minutes due to iOS widget refresh policy)

#### Step 6: Test View Modes (New in 2.0)
1. In Project Detail, tap the view switcher (top)
2. Switch to **Board** view: See To Do / Doing / Done columns
3. Switch to **Calendar** view: See tasks by due date
4. Switch back to **List** view

#### Step 7: Test Filters (New in 2.0)
1. Tap the **Filters** tab
2. Select "Today" filter: Shows today's tasks
3. Select "P1" filter: Shows high priority tasks only
4. Tap **+** to create a custom filter (optional)

### Optional Features Testing

#### Live Activity (Optional)
1. Go to **Settings** tab in the app
2. Enable Live Activity (if available)
3. Live Activity appears in Dynamic Island
4. Note: Expires after 8 hours (iOS limitation)

#### Shortcuts (Optional)
1. Open the **Shortcuts** app
2. Create new shortcut
3. Search for "LivePlan"
4. Available actions:
   - RefreshLiveActivity
   - CompleteNextTask
   - QuickAddTask
   - StartNextTask
5. Run the shortcut to test

#### Controls - iOS 18+ Only (Optional)
1. Go to Settings → Control Center
2. Add LivePlan controls (Complete, Add, Start)
3. Access from Lock Screen or Control Center
4. Tap to complete task or add new task

---

## Additional Notes for Reviewers

### Widget Refresh Timing
- iOS limits widget updates to approximately every 5 minutes
- Changes in the app may not appear immediately on the widget
- This is standard iOS behavior, not an app limitation

### No Account Required
- All data is stored locally on device
- No login, signup, or internet connection required
- App Group is used to share data between main app and widgets

### No In-App Purchases
- The app is completely free
- No ads, no subscriptions, no premium features

### Permissions Used
- None required for core functionality
- Live Activity requires user consent (optional feature)

---

## Demo Account

Not applicable - no account system.

---

## App Privacy

| Data Type | Collected | Usage |
|-----------|-----------|-------|
| User Content (Tasks) | Stored locally | Core functionality |
| Analytics | Not collected | - |
| Advertising | Not collected | - |
| Identifiers | Not collected | - |

All data stays on user's device. No network requests for data sync.

---

## Contact

For any questions during review:
- Email: [Contact Email]
- Response time: Within 24 hours

---

*This document follows appstore-submission.md guidelines (minimum 5 reproduction steps, clear required vs optional features, privacy default explanation).*
