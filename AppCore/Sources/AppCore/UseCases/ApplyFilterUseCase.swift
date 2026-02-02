import Foundation

/// 필터 적용 UseCase
/// - FilterDefinition을 태스크 목록에 적용
/// - 조건은 AND 조합으로 적용
/// - data-model.md / product-decisions.md 4.1 준수
public struct ApplyFilterUseCase: Sendable {

    // MARK: - Initializer

    public init() {}

    // MARK: - Apply Filter

    /// 필터를 태스크 목록에 적용
    /// - Parameters:
    ///   - filter: 필터 정의
    ///   - tasks: 태스크 목록
    ///   - projects: 프로젝트 목록 (상태 확인용)
    ///   - completionLogs: 완료 로그 (완료 상태 확인용)
    ///   - dateKey: 오늘 날짜 키 (habitReset 완료 확인용)
    /// - Returns: 필터링된 태스크 목록
    public func execute(
        filter: FilterDefinition,
        tasks: [Task],
        projects: [Project],
        completionLogs: [CompletionLog],
        dateKey: DateKey
    ) -> [Task] {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let completedTaskIds = completedOneOffTaskIds(from: completionLogs)
        let todayCompletedRecurringIds = completedRecurringTaskIds(
            from: completionLogs,
            dateKey: dateKey
        )

        return tasks.filter { task in
            // 1. 프로젝트 필터
            if let projectIds = filter.includeProjectIds, !projectIds.isEmpty {
                guard projectIds.contains(task.projectId) else { return false }
            }

            // 2. 섹션 필터
            if let sectionIds = filter.includeSectionIds, !sectionIds.isEmpty {
                guard let sectionId = task.sectionId, sectionIds.contains(sectionId) else {
                    return false
                }
            }

            // 3. 태그 필터 (태스크가 지정된 태그 중 하나라도 가지고 있어야 함)
            if let tagIds = filter.includeTagIds, !tagIds.isEmpty {
                let hasMatchingTag = task.tagIds.contains { tagIds.contains($0) }
                guard hasMatchingTag else { return false }
            }

            // 4. 우선순위 필터 (priorityAtLeast)
            if let atLeast = filter.priorityAtLeast {
                // P1이 가장 높음 (rawValue가 작음)
                guard task.priority.rawValue <= atLeast.rawValue else { return false }
            }

            // 5. 우선순위 필터 (priorityAtMost)
            if let atMost = filter.priorityAtMost {
                guard task.priority.rawValue >= atMost.rawValue else { return false }
            }

            // 6. 상태 필터
            if let states = filter.stateIn, !states.isEmpty {
                guard states.contains(task.workflowState) else { return false }
            } else {
                // 기본: done 제외
                guard task.workflowState != .done else { return false }
            }

            // 7. 마감일 범위 필터
            if let dueRange = filter.dueRange {
                guard matchesDueRange(task: task, range: dueRange, dateKey: dateKey) else {
                    return false
                }
            }

            // 8. 반복 태스크 필터
            if let includeRecurring = filter.includeRecurring {
                if includeRecurring {
                    guard task.isRecurring else { return false }
                } else {
                    guard !task.isRecurring else { return false }
                }
            }

            // 9. 차단된 태스크 제외
            if filter.excludeBlocked {
                // blockedByTaskIds 중 미완료 태스크가 있으면 제외
                let hasUncompletedBlocker = task.blockedByTaskIds.contains { blockerId in
                    !isTaskCompleted(
                        taskId: blockerId,
                        tasks: tasks,
                        completedOneOffIds: completedTaskIds,
                        todayCompletedRecurringIds: todayCompletedRecurringIds
                    )
                }
                guard !hasUncompletedBlocker else { return false }
            }

            // 10. 완료된 oneOff 태스크 제외
            if task.isOneOff {
                guard !completedTaskIds.contains(task.id) else { return false }
            }

            // 11. 오늘 완료된 habitReset 반복 태스크 제외
            if task.isHabitReset {
                guard !todayCompletedRecurringIds.contains(task.id) else { return false }
            }

            // 12. 프로젝트 상태 확인 (archived/completed 제외)
            if let project = projectMap[task.projectId] {
                guard project.status.isActive else { return false }
            }

            return true
        }
    }

    // MARK: - Private Helpers

    private func completedOneOffTaskIds(from logs: [CompletionLog]) -> Set<String> {
        Set(logs.filter { $0.occurrenceKey == "once" }.map { $0.taskId })
    }

    private func completedRecurringTaskIds(
        from logs: [CompletionLog],
        dateKey: DateKey
    ) -> Set<String> {
        Set(
            logs
                .filter { $0.occurrenceKey == dateKey.value }
                .map { $0.taskId }
        )
    }

    private func isTaskCompleted(
        taskId: String,
        tasks: [Task],
        completedOneOffIds: Set<String>,
        todayCompletedRecurringIds: Set<String>
    ) -> Bool {
        guard let task = tasks.first(where: { $0.id == taskId }) else {
            return true // 존재하지 않으면 완료로 간주
        }

        if task.isOneOff {
            return completedOneOffIds.contains(taskId)
        } else if task.isHabitReset {
            return todayCompletedRecurringIds.contains(taskId)
        } else {
            // rollover의 경우 workflowState로 판단
            return task.workflowState == .done
        }
    }

    private func matchesDueRange(task: Task, range: DueRange, dateKey: DateKey) -> Bool {
        let effectiveDue = task.effectiveDueDate

        switch range {
        case .today:
            guard let due = effectiveDue else { return false }
            return Calendar.current.isDate(due, inSameDayAs: dateKey.date)

        case .next7:
            guard let due = effectiveDue else { return false }
            let today = dateKey.date
            let next7 = Calendar.current.date(byAdding: .day, value: 7, to: today)!
            return due >= today && due <= next7

        case .overdue:
            guard let due = effectiveDue else { return false }
            return due < dateKey.date

        case .none:
            return effectiveDue == nil

        case .any:
            return effectiveDue != nil
        }
    }
}

// MARK: - Convenience Extensions

extension ApplyFilterUseCase {
    /// 간단한 필터 적용 (현재 날짜 기준)
    public func execute(
        filter: FilterDefinition,
        tasks: [Task],
        projects: [Project],
        completionLogs: [CompletionLog]
    ) -> [Task] {
        execute(
            filter: filter,
            tasks: tasks,
            projects: projects,
            completionLogs: completionLogs,
            dateKey: DateKey.today()
        )
    }
}

// MARK: - Filter Result Metadata

/// 필터 결과 메타데이터
public struct FilterResultMetadata: Sendable {
    /// 총 태스크 수
    public let totalCount: Int

    /// 필터링 후 태스크 수
    public let filteredCount: Int

    /// 제외된 태스크 수
    public var excludedCount: Int { totalCount - filteredCount }

    /// 필터링 비율 (0.0 ~ 1.0)
    public var filterRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(filteredCount) / Double(totalCount)
    }
}

extension ApplyFilterUseCase {
    /// 필터 적용 + 메타데이터 반환
    public func executeWithMetadata(
        filter: FilterDefinition,
        tasks: [Task],
        projects: [Project],
        completionLogs: [CompletionLog],
        dateKey: DateKey
    ) -> (tasks: [Task], metadata: FilterResultMetadata) {
        let filtered = execute(
            filter: filter,
            tasks: tasks,
            projects: projects,
            completionLogs: completionLogs,
            dateKey: dateKey
        )
        let metadata = FilterResultMetadata(
            totalCount: tasks.count,
            filteredCount: filtered.count
        )
        return (filtered, metadata)
    }
}
