import Foundation

/// 잠금화면 후보 선정 알고리즘
/// - lockscreen.md B 준수
/// - 순수 함수로 구현 (테스트 가능)
public struct OutstandingComputer: Sendable {
    public init() {}

    /// 잠금화면 표시 데이터 계산
    /// - Parameters:
    ///   - dateKey: 기준 날짜
    ///   - policy: 선정 정책
    ///   - privacyMode: 프라이버시 모드
    ///   - projects: 전체 프로젝트
    ///   - tasks: 전체 태스크
    ///   - completionLogs: 전체 완료 로그
    ///   - topN: 표시할 최대 수
    ///   - now: 현재 시간 (테스트용)
    public func compute(
        dateKey: DateKey,
        policy: SelectionPolicy,
        privacyMode: PrivacyMode,
        projects: [Project],
        tasks: [Task],
        completionLogs: [CompletionLog],
        topN: Int = SelectionConstants.widgetTopN,
        now: Date = Date()
    ) -> LockScreenSummary {
        // 1. 스코프 결정 및 폴백
        let (scopeProjectIds, fallbackReason) = determineScope(
            policy: policy,
            projects: projects
        )

        // 2. 후보 필터링
        let candidates = filterCandidates(
            tasks: tasks,
            projects: projects,
            completionLogs: completionLogs,
            scopeProjectIds: scopeProjectIds,
            dateKey: dateKey
        )

        // 3. 우선순위 정렬
        let sorted = sortByPriority(
            candidates: candidates,
            dateKey: dateKey,
            now: now
        )

        // 4. Top N 선정
        let topTasks = Array(sorted.prefix(topN))

        // 5. 카운터 계산
        let counters = computeCounters(
            candidates: candidates,
            tasks: tasks.filter { task in
                scopeProjectIds.isEmpty || scopeProjectIds.contains(task.projectId)
            },
            completionLogs: completionLogs,
            dateKey: dateKey,
            now: now
        )

        // 6. 프라이버시 적용
        let displayList = applyPrivacy(
            tasks: topTasks,
            privacyMode: privacyMode,
            dateKey: dateKey,
            now: now
        )

        return LockScreenSummary(
            displayList: displayList,
            counters: counters,
            fallbackReason: candidates.isEmpty ? (fallbackReason ?? .allCompleted) : fallbackReason
        )
    }
}

// MARK: - Private Implementation

private extension OutstandingComputer {
    /// 스코프 결정
    func determineScope(
        policy: SelectionPolicy,
        projects: [Project]
    ) -> (projectIds: Set<String>, fallbackReason: FallbackReason?) {
        switch policy {
        case .pinnedFirst(let pinnedId):
            guard let pinnedId else {
                // 핀 없음 -> todayOverview 폴백
                return ([], .noPinnedProject)
            }

            guard let pinnedProject = projects.first(where: { $0.id == pinnedId }) else {
                return ([], .noPinnedProject)
            }

            switch pinnedProject.status {
            case .active:
                return ([pinnedId], nil)
            case .archived:
                return ([], .pinnedProjectArchived)
            case .completed:
                return ([], .pinnedProjectCompleted)
            }

        case .todayOverview:
            // 전체 활성 프로젝트
            let activeIds = Set(projects.filter { $0.status == .active }.map { $0.id })
            return (activeIds, nil)
        }
    }

    /// 후보 필터링
    /// - lockscreen.md B: blocked 태스크는 Top1/CompleteNextTask 대상에서 제외
    func filterCandidates(
        tasks: [Task],
        projects: [Project],
        completionLogs: [CompletionLog],
        scopeProjectIds: Set<String>,
        dateKey: DateKey
    ) -> [Task] {
        let activeProjectIds = Set(projects.filter { $0.status == .active }.map { $0.id })

        return tasks.filter { task in
            // 스코프 검사 (빈 스코프는 전체 허용)
            guard scopeProjectIds.isEmpty || scopeProjectIds.contains(task.projectId) else {
                return false
            }

            // 활성 프로젝트만
            guard activeProjectIds.contains(task.projectId) else {
                return false
            }

            // blocked 태스크 제외 (M6-1: CompleteNextTask 정합성)
            guard !task.isBlocked else {
                return false
            }

            // 완료 여부 검사
            return !isCompleted(task: task, completionLogs: completionLogs, dateKey: dateKey)
        }
    }

    /// 완료 여부 검사
    /// - data-model.md B1/B2/B3 준수
    /// - oneOff (비반복): occurrenceKey="once"
    /// - habitReset (dailyRecurring): occurrenceKey=dateKey
    /// - rollover: occurrenceKey=dateKey(nextOccurrenceDueAt)
    func isCompleted(task: Task, completionLogs: [CompletionLog], dateKey: DateKey) -> Bool {
        // rollover 태스크 먼저 검사 (recurrenceRule이 있는 경우)
        if task.isRollover {
            // rollover: nextOccurrenceDueAt 기반 occurrenceKey로 완료 판정
            // nextOccurrenceDueAt이 이미 advance되었다면 현재 occurrence는 완료된 것
            // 하지만 advance 전에는 해당 occurrenceKey의 로그가 존재하는지 확인
            guard let nextDueAt = task.nextOccurrenceDueAt else {
                // nextOccurrenceDueAt이 없으면 미완료 상태
                return false
            }
            let occurrenceKey = DateKey.from(nextDueAt).value
            return completionLogs.contains { log in
                log.taskId == task.id && log.occurrenceKey == occurrenceKey
            }
        }

        // habitReset 또는 oneOff
        switch task.taskType {
        case .oneOff:
            // oneOff: occurrenceKey="once" 로그 존재 시 완료
            return completionLogs.contains { log in
                log.taskId == task.id && log.occurrenceKey == CompletionLog.oneOffOccurrenceKey
            }

        case .dailyRecurring:
            // dailyRecurring (habitReset): 오늘 dateKey 로그 존재 시 완료
            return completionLogs.contains { log in
                log.taskId == task.id && log.occurrenceKey == dateKey.value
            }
        }
    }

    /// 우선순위 정렬
    /// - lockscreen.md B 우선순위 그룹 준수
    /// - Tie-breaker:
    ///   1. dueAt 있는 항목: dueAt 오름차순
    ///   2. priority(P1→P4)
    ///   3. createdAt
    ///   4. id (결정론)
    func sortByPriority(candidates: [Task], dateKey: DateKey, now: Date) -> [Task] {
        candidates.sorted { lhs, rhs in
            let lhsGroup = priorityGroup(task: lhs, dateKey: dateKey, now: now)
            let rhsGroup = priorityGroup(task: rhs, dateKey: dateKey, now: now)

            // 그룹 우선
            if lhsGroup != rhsGroup {
                return lhsGroup < rhsGroup
            }

            // Tie-breaker 1: effectiveDueDate (rollover의 경우 nextOccurrenceDueAt 우선)
            let lhsDue = lhs.effectiveDueDate
            let rhsDue = rhs.effectiveDueDate
            if let lhsDue, let rhsDue {
                if lhsDue != rhsDue {
                    return lhsDue < rhsDue
                }
            } else if lhsDue != nil {
                return true
            } else if rhsDue != nil {
                return false
            }

            // Tie-breaker 2: priority (P1→P4, 숫자가 작을수록 우선)
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }

            // Tie-breaker 3: createdAt
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            // Tie-breaker 4: id (결정론)
            return lhs.id < rhs.id
        }
    }

    /// 우선순위 그룹 결정
    /// - lockscreen.md B 2.0 우선순위 그룹:
    ///   - G1(1): workflowState=doing (작업 중)
    ///   - G2(2): overdue (dueAt < now, rollover recurring 포함)
    ///   - G3(3): dueSoon (0 < dueAt-now ≤ 24h)
    ///   - G4(4): priority P1 (dueAt 없더라도)
    ///   - G5(5): habitReset recurring 중 오늘 미완료
    ///   - G6(6): 나머지 todo(oneOff/rollover 미완료)
    func priorityGroup(task: Task, dateKey: DateKey, now: Date) -> Int {
        // G1: doing (작업 중)
        if task.workflowState == .doing {
            return 1
        }

        // G2: overdue
        if isOverdue(task: task, now: now) {
            return 2
        }

        // G3: dueSoon
        if isDueSoon(task: task, now: now) {
            return 3
        }

        // G4: priority P1
        if task.priority == .p1 {
            return 4
        }

        // G5: habitReset recurring 오늘 미완료
        if task.isHabitReset {
            return 5
        }

        // G6: 나머지 (oneOff/rollover 미완료)
        return 6
    }

    /// overdue 판정 (rollover recurring 포함)
    /// - rollover의 경우 nextOccurrenceDueAt을 기준으로 판정
    func isOverdue(task: Task, now: Date) -> Bool {
        guard let dueDate = task.effectiveDueDate else { return false }
        return dueDate < now
    }

    /// dueSoon 판정 (24시간 이내)
    /// - rollover의 경우 nextOccurrenceDueAt을 기준으로 판정
    func isDueSoon(task: Task, now: Date) -> Bool {
        guard let dueDate = task.effectiveDueDate else { return false }
        let threshold = TimeInterval(SelectionConstants.dueSoonThresholdHours * 3600)
        let diff = dueDate.timeIntervalSince(now)
        return diff > 0 && diff <= threshold
    }

    /// 카운터 계산
    /// - 필수: outstandingTotal, overdueCount, dueSoonCount, recurringDone/Total
    /// - 선택: p1Count, doingCount, blockedCount
    func computeCounters(
        candidates: [Task],
        tasks: [Task],
        completionLogs: [CompletionLog],
        dateKey: DateKey,
        now: Date
    ) -> Counters {
        // 필수 카운터
        let overdueCount = candidates.filter { isOverdue(task: $0, now: now) }.count
        let dueSoonCount = candidates.filter { isDueSoon(task: $0, now: now) }.count

        let recurringTasks = tasks.filter { $0.isRecurring }
        let recurringTotal = recurringTasks.count
        let recurringDone = recurringTasks.filter { task in
            completionLogs.contains { log in
                log.taskId == task.id && log.occurrenceKey == dateKey.value
            }
        }.count

        // 선택 카운터 (lockscreen.md B 2.0)
        let p1Count = candidates.filter { $0.priority == .p1 }.count
        let doingCount = candidates.filter { $0.workflowState == .doing }.count
        let blockedCount = tasks.filter { $0.isBlocked }.count

        return Counters(
            outstandingTotal: candidates.count,
            overdueCount: overdueCount,
            dueSoonCount: dueSoonCount,
            recurringDone: recurringDone,
            recurringTotal: recurringTotal,
            p1Count: p1Count,
            doingCount: doingCount,
            blockedCount: blockedCount
        )
    }

    /// 프라이버시 적용
    func applyPrivacy(
        tasks: [Task],
        privacyMode: PrivacyMode,
        dateKey: DateKey,
        now: Date
    ) -> [DisplayTask] {
        tasks.enumerated().map { index, task in
            let displayTitle: String
            switch privacyMode {
            case .visible:
                displayTitle = task.title
            case .masked:
                displayTitle = "할 일 \(index + 1)"
            case .hidden:
                displayTitle = ""
            }

            return DisplayTask(
                id: task.id,
                displayTitle: displayTitle,
                isOverdue: isOverdue(task: task, now: now),
                isDueSoon: isDueSoon(task: task, now: now),
                isRecurring: task.isRecurring,
                isDoing: task.workflowState == .doing,
                priority: task.priority
            )
        }
    }
}
