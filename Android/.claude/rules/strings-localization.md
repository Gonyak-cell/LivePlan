# strings-localization.md

Last Updated: 2026-02-02 15:00:00

## 목적

LivePlan Android의 문자열(앱/위젯/알림/타일)을 리소스 기반으로 일관 관리하고, 위젯 길이 제약/프라이버시 요건을 만족하도록 규칙을 고정한다.

## 적용 범위

- App UI 문자열 (strings.xml)
- 위젯 표시 문자열
- 알림(Notification) 메시지
- Quick Settings Tile 라벨
- App Shortcuts 라벨

## 핵심 원칙(강행)

### 1. 하드코딩 최소화

- 사용자에게 노출되는 문구는 strings.xml로 관리
- 예외는 디버그 로그뿐

### 2. 용어 통일

**표준 용어 (KR/EN)**
| KR | EN | 의미 |
|-----|-----|------|
| 미완료 | Remaining | outstanding count |
| 지연 | Overdue | overdue count |
| 임박 | Due soon | due within 24h |
| 반복 | Recurring | recurring task |
| 대표 프로젝트 | Pinned project | pinned |
| 오늘 할 일 | Today | today overview |
| 프라이버시 모드 | Privacy mode | privacy setting |

**동의어/혼용 금지**: "미완료 vs 남은 일 vs 할 일 수" 혼용 금지

### 3. 길이 예산 준수(위젯)

| 표면 | 최대 길이 (KR) |
|------|---------------|
| 위젯 1라인 태스크 | 18~24자 (말줄임 허용) |
| 알림 제목 | 20자 |
| 알림 내용 | 40자 |
| 타일 라벨 | 12자 |
| Shortcut 라벨 | 15자 |

### 4. 다국어 정책

- Phase 1: KR(필수) + EN(기본)
- 다른 언어(JP/ZH)는 Phase 2+

────────────────────────────────────────
## A. 리소스 구조
────────────────────────────────────────

```
res/
├── values/
│   └── strings.xml        (EN 기본)
└── values-ko/
    └── strings.xml        (KR)
```

────────────────────────────────────────
## B. 키 네이밍 규칙
────────────────────────────────────────

| 접두어 | 용도 | 예시 |
|--------|------|------|
| `app_*` | 앱 UI | `app_project_create` |
| `widget_*` | 위젯 | `widget_title_today` |
| `notification_*` | 알림 | `notification_in_progress` |
| `tile_*` | Quick Settings | `tile_complete_task` |
| `shortcut_*` | App Shortcuts | `shortcut_quick_add` |
| `error_*` | 에러 메시지 | `error_empty_title` |
| `action_*` | 액션 버튼 | `action_complete` |

────────────────────────────────────────
## C. 표준 문자열 목록
────────────────────────────────────────

### C1. 앱 UI (app_*)

```xml
<!-- EN -->
<string name="app_name">LivePlan</string>
<string name="app_project_create">Create Project</string>
<string name="app_project_list">Projects</string>
<string name="app_task_add">Add Task</string>
<string name="app_task_complete">Complete</string>
<string name="app_settings">Settings</string>
<string name="app_privacy_mode">Privacy Mode</string>
<string name="app_pinned_project">Pinned Project</string>

<!-- KR -->
<string name="app_name">LivePlan</string>
<string name="app_project_create">프로젝트 만들기</string>
<string name="app_project_list">프로젝트</string>
<string name="app_task_add">할 일 추가</string>
<string name="app_task_complete">완료</string>
<string name="app_settings">설정</string>
<string name="app_privacy_mode">프라이버시 모드</string>
<string name="app_pinned_project">대표 프로젝트</string>
```

### C2. 위젯 (widget_*)

```xml
<!-- EN -->
<string name="widget_title_today">Today</string>
<string name="widget_empty">Add tasks to get started</string>
<string name="widget_remaining">%d remaining</string>
<string name="widget_overdue">%d overdue</string>
<string name="widget_due_soon">%d due soon</string>
<string name="widget_open_app">Open app</string>

<!-- KR -->
<string name="widget_title_today">오늘 할 일</string>
<string name="widget_empty">할 일을 추가하세요</string>
<string name="widget_remaining">미완료 %d</string>
<string name="widget_overdue">지연 %d</string>
<string name="widget_due_soon">임박 %d</string>
<string name="widget_open_app">앱 열기</string>
```

### C3. 알림 (notification_*)

```xml
<!-- EN -->
<string name="notification_channel_ongoing">Current Task</string>
<string name="notification_in_progress">In Progress</string>
<string name="notification_completed">Completed</string>
<string name="notification_complete_success">Task completed</string>

<!-- KR -->
<string name="notification_channel_ongoing">현재 작업</string>
<string name="notification_in_progress">현재 진행 중</string>
<string name="notification_completed">완료됨</string>
<string name="notification_complete_success">완료했습니다</string>
```

### C4. 타일/단축키 (tile_*, shortcut_*)

```xml
<!-- EN -->
<string name="tile_complete_task">Complete Task</string>
<string name="shortcut_quick_add_short">Quick Add</string>
<string name="shortcut_quick_add_long">Quickly add a new task</string>
<string name="shortcut_complete_short">Complete</string>
<string name="shortcut_complete_long">Complete the next task</string>

<!-- KR -->
<string name="tile_complete_task">태스크 완료</string>
<string name="shortcut_quick_add_short">빠른 추가</string>
<string name="shortcut_quick_add_long">새 할 일 빠르게 추가</string>
<string name="shortcut_complete_short">완료</string>
<string name="shortcut_complete_long">다음 할 일 완료</string>
```

### C5. 에러 메시지 (error_*)

```xml
<!-- EN -->
<string name="error_empty_title">Please enter a title</string>
<string name="error_no_task">No task to complete</string>
<string name="error_load_failed">Failed to load data. Please check in the app.</string>
<string name="error_save_failed">Failed to save</string>
<string name="error_project_not_found">Project not found</string>

<!-- KR -->
<string name="error_empty_title">제목을 입력해주세요</string>
<string name="error_no_task">완료할 항목이 없습니다</string>
<string name="error_load_failed">데이터를 불러오지 못했습니다. 앱에서 확인해주세요.</string>
<string name="error_save_failed">저장에 실패했습니다</string>
<string name="error_project_not_found">프로젝트를 찾을 수 없습니다</string>
```

### C6. 액션 버튼 (action_*)

```xml
<!-- EN -->
<string name="action_complete">Complete</string>
<string name="action_start">Start</string>
<string name="action_cancel">Cancel</string>
<string name="action_save">Save</string>
<string name="action_delete">Delete</string>
<string name="action_edit">Edit</string>

<!-- KR -->
<string name="action_complete">완료</string>
<string name="action_start">시작</string>
<string name="action_cancel">취소</string>
<string name="action_save">저장</string>
<string name="action_delete">삭제</string>
<string name="action_edit">수정</string>
```

────────────────────────────────────────
## D. 프라이버시 안내 문구
────────────────────────────────────────

```xml
<!-- EN -->
<string name="privacy_notice">Your home screen can be seen by others nearby.</string>
<string name="privacy_mode_full">Show full titles</string>
<string name="privacy_mode_masked">Mask task titles</string>
<string name="privacy_mode_count_only">Show counts only</string>

<!-- KR -->
<string name="privacy_notice">홈 화면은 주변 사람이 볼 수 있습니다.</string>
<string name="privacy_mode_full">제목 전체 표시</string>
<string name="privacy_mode_masked">제목 마스킹</string>
<string name="privacy_mode_count_only">숫자만 표시</string>
```

────────────────────────────────────────
## E. 마스킹된 태스크 제목
────────────────────────────────────────

```xml
<!-- MASKED 모드에서 사용 -->
<string name="masked_task_1">할 일 1</string>
<string name="masked_task_2">할 일 2</string>
<string name="masked_task_3">할 일 3</string>
<string name="masked_task_n">할 일 %d</string>

<!-- EN -->
<string name="masked_task_1">Task 1</string>
<string name="masked_task_2">Task 2</string>
<string name="masked_task_3">Task 3</string>
<string name="masked_task_n">Task %d</string>
```

끝.
