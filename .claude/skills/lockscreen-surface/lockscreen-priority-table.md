우선순위 표준표(Phase 1 기본)

스코프 선택

selectionPolicy = pinnedFirst

pinnedProjectId가 active면 pinned 스코프 사용

없거나 비활성(archived/completed)이면 todayOverview로 폴백

후보 필터

프로젝트: active만

oneOff: 완료(CompletionLog 존재)면 제외

dailyRecurring: 오늘(dateKey) 완료면 제외(오늘 미완료만 포함)

그룹 우선순위(상위가 먼저)
G1: pinned 스코프 미완료(스코프가 pinned일 때)
G2: overdue (now > dueDate)
G3: dueSoon (0 < dueDate-now ≤ 24h)
G4: dailyRecurring 오늘 미완료
G5: 나머지 oneOff 미완료

그룹 내 정렬(권장)

dueDate 있는 항목: dueDate 오름차순

그 외: 생성 시각 또는 id 안정 정렬(결정 필요)

표면별 표시량

위젯(직사각): Top 3 + remaining 카운트

Live Activity: Top 1 또는 요약 1개

Controls: 표시 없음(명령만)