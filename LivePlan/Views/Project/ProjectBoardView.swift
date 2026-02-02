import SwiftUI
import AppCore

/// 보드 뷰 - WorkflowState 기반 3컬럼 레이아웃
/// - product-decisions.md 1.2: Board 뷰 (상태 컬럼)
/// - 읽기 전용 (상태 변경은 M2-UI-9 이후 추가)
struct ProjectBoardView: View {
    let tasks: [Task]
    let isTaskCompleted: (Task) -> Bool
    let onToggleComplete: (Task) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(WorkflowState.boardOrdered, id: \.self) { state in
                    BoardColumnView(
                        state: state,
                        tasks: tasksFor(state: state),
                        isTaskCompleted: isTaskCompleted,
                        onToggleComplete: onToggleComplete
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func tasksFor(state: WorkflowState) -> [Task] {
        tasks.filter { $0.workflowState == state }
    }
}

// MARK: - BoardColumnView

struct BoardColumnView: View {
    let state: WorkflowState
    let tasks: [Task]
    let isTaskCompleted: (Task) -> Bool
    let onToggleComplete: (Task) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 컬럼 헤더
            HStack {
                Text(state.descriptionKR)
                    .font(.headline)

                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)

            // 태스크 카드 목록
            if tasks.isEmpty {
                emptyColumnView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(tasks) { task in
                            BoardCardView(
                                task: task,
                                isCompleted: isTaskCompleted(task),
                                onToggleComplete: { onToggleComplete(task) }
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 260)
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyColumnView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.tertiary)

            Text("항목 없음")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - BoardCardView

struct BoardCardView: View {
    let task: Task
    let isCompleted: Bool
    let onToggleComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                Spacer()

                // 완료 버튼
                Button {
                    onToggleComplete()
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(isCompleted)
            }

            // 메타데이터
            HStack(spacing: 8) {
                // 반복 표시
                if task.isRecurring {
                    Label("반복", systemImage: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }

                // 마감일 표시
                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(dueDateColor(dueDate))
                }

                // 우선순위 표시 (P1~P3만)
                if task.priority != .p4 {
                    Text(task.priority.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(priorityColor(task.priority))
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 8)
    }

    private func dueDateColor(_ dueDate: Date) -> Color {
        if dueDate < Date() {
            return .red
        } else if dueDate.timeIntervalSinceNow < 86400 {
            return .orange
        }
        return .secondary
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .p1: return .red
        case .p2: return .orange
        case .p3: return .yellow
        case .p4: return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Board View") {
    let sampleTasks = [
        Task(projectId: "p1", title: "할 일 1", workflowState: .todo),
        Task(projectId: "p1", title: "할 일 2", workflowState: .todo, priority: .p1),
        Task(projectId: "p1", title: "할 일 3", taskType: .dailyRecurring, workflowState: .todo),
        Task(projectId: "p1", title: "진행 중인 일", workflowState: .doing),
        Task(projectId: "p1", title: "완료된 일 1", workflowState: .done),
        Task(projectId: "p1", title: "완료된 일 2", workflowState: .done),
    ]

    return ProjectBoardView(
        tasks: sampleTasks,
        isTaskCompleted: { $0.workflowState == .done },
        onToggleComplete: { _ in }
    )
}

#Preview("Empty Board") {
    ProjectBoardView(
        tasks: [],
        isTaskCompleted: { _ in false },
        onToggleComplete: { _ in }
    )
}
