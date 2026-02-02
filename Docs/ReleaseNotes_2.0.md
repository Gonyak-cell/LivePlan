# LivePlan 2.0 릴리즈 노트

> **버전**: 2.0.0
> **날짜**: 2026-02-02

---

## App Store "새로운 기능" (KR)

```
LivePlan 2.0 - 더 강력해진 태스크 관리

새로운 기능:
- 보드 뷰: 할 일/진행 중/완료를 한눈에 확인
- 캘린더 뷰: 마감일 기준 월간 일정 보기
- 우선순위: P1~P4로 중요한 일 먼저 처리
- 태그 & 섹션: 유연한 분류와 그룹핑
- 필터: 오늘/임박/지연/우선순위별 필터, 사용자 정의 저장
- 검색: 프로젝트/태스크/태그 빠른 검색
- 반복 확장: 주간/월간 반복 지원
- 프로젝트 노트: 프로젝트에 메모 추가

개선:
- 잠금화면 선정 알고리즘 개선 (진행 중 > 지연 > 임박 > P1 순)
- 프라이버시 모드 유지 (기본 마스킹)
- Live Activity/Controls 안정성 향상

선택 기능(단축어/Controls)은 필수가 아닙니다.
위젯만으로도 핵심 기능을 사용할 수 있습니다.
```

---

## App Store "What's New" (EN)

```
LivePlan 2.0 - Enhanced Task Management

New Features:
- Board View: See To Do, Doing, Done at a glance
- Calendar View: Monthly schedule by due date
- Priority: P1-P4 to focus on what matters
- Tags & Sections: Flexible categorization and grouping
- Filters: Today, Upcoming, Overdue, P1, and custom filters
- Search: Quick search across projects, tasks, and tags
- Recurring: Weekly and monthly recurrence support
- Project Notes: Add notes to your projects

Improvements:
- Enhanced lock screen selection (Doing > Overdue > Due Soon > P1)
- Privacy mode maintained (default masking)
- Live Activity/Controls stability improvements

Shortcuts and Controls are optional.
Core features work with widgets alone.
```

---

## TestFlight 릴리즈 노트 (KR)

```
LivePlan 2.0.0 (빌드 XX)

테스트 포인트:
1. 보드 뷰에서 태스크 상태 변경 (드래그)
2. 캘린더 뷰에서 날짜별 태스크 확인
3. 우선순위(P1~P4) 설정 및 표시
4. 필터 생성/저장/적용
5. 잠금화면 위젯 표시 확인
6. 프라이버시 모드 토글 (마스킹)

알려진 이슈:
- 위젯은 iOS 정책상 즉시 갱신되지 않습니다

피드백: [피드백 URL]
```

---

## TestFlight Release Notes (EN)

```
LivePlan 2.0.0 (Build XX)

Test Points:
1. Change task status in Board View (drag)
2. Check tasks by date in Calendar View
3. Set and display priority (P1-P4)
4. Create/save/apply filters
5. Verify lock screen widget display
6. Toggle privacy mode (masking)

Known Issues:
- Widget updates are limited by iOS policy

Feedback: [Feedback URL]
```

---

## 내부 변경 사항 (개발 참조용)

### 데이터 모델 (M1)
- Priority enum (P1~P4)
- WorkflowState enum (todo/doing/done)
- RecurrenceRule 모델 (daily/weekly/monthly)
- RecurrenceBehavior (habitReset/rollover)
- Section 모델
- Tag 모델
- Task 확장 필드 (sectionId, tagIds, priority, workflowState, blockedByTaskIds, note)
- Project 확장 필드 (note)
- SchemaVersion 2 + 마이그레이션 v1→v2

### UI (M2)
- TaskDetailView (상세/편집)
- SectionManageView (섹션 CRUD)
- TagManageView (태그 CRUD)
- ProjectNoteView (프로젝트 노트)
- PriorityPickerView
- SettingsView 확장

### 뷰 전환 (M3)
- ProjectBoardView (보드 뷰)
- ProjectCalendarView (캘린더 뷰)
- 뷰 타입 전환 UI

### 필터/검색 (M4)
- FilterDefinition, SavedView 모델
- ApplyFilterUseCase
- Built-in 필터 6개
- LocalSearchEngine
- FilterListView/CreateView/DetailView/BuilderView

### 선정 알고리즘 (M6)
- 우선순위 그룹 G1~G6 (doing > overdue > dueSoon > P1 > habitReset > 나머지)
- blocked 태스크 제외
- 확장 카운터 (p1Count, doingCount, blockedCount)
- rollover 완료 로직

### 인텐트 (M7)
- StartNextTaskIntent (진행 중 전환)
- StartNextTaskControl (iOS 18+)
- 프라이버시 메시지 업데이트

---

## 마이그레이션 안내

- 기존 데이터는 자동으로 v2 스키마로 마이그레이션됩니다
- 기존 매일 반복 태스크는 habitReset 동작 유지
- 새로운 필드(priority, workflowState 등)는 기본값으로 설정됩니다
- 데이터 손실 없음

---

*이 문서는 appstore-submission.md 및 product-decisions.md 규칙을 따릅니다.*
