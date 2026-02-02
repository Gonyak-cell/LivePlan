import SwiftUI
import AppCore

struct TaskRowView: View {
    let task: Task
    let isCompleted: Bool
    let tags: [Tag]  // M2-UI-6: tagIds 기반 태그 표시
    let onToggle: () -> Void

    /// 태그 없이 초기화 (하위 호환성)
    init(task: Task, isCompleted: Bool, onToggle: @escaping () -> Void) {
        self.task = task
        self.isCompleted = isCompleted
        self.tags = []
        self.onToggle = onToggle
    }

    /// 태그 포함 초기화 (M2-UI-6)
    init(task: Task, isCompleted: Bool, tags: [Tag], onToggle: @escaping () -> Void) {
        self.task = task
        self.isCompleted = isCompleted
        self.tags = tags
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: 12) {
            // 체크 버튼
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)

            // 태스크 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 우선순위 표시 (P4 기본값은 숨김)
                    if task.priority.shouldDisplay {
                        PriorityBadgeView(priority: task.priority)
                    }

                    // 진행 중 상태 표시
                    if task.workflowState == .doing {
                        WorkflowStateBadgeView()
                    }

                    Text(task.title)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if task.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                // M2-UI-6: 태그 칩 표시 (최대 2개 + "+N")
                if !tags.isEmpty {
                    TagChipsView(tags: tags, maxDisplayCount: 2)
                }

                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)

                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundStyle(dueDateColor(dueDate))
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func dueDateColor(_ dueDate: Date) -> Color {
        if dueDate < Date() {
            return .red // overdue
        } else if dueDate.timeIntervalSinceNow < 86400 {
            return .orange // due soon
        }
        return .secondary
    }
}

// MARK: - WorkflowState Badge

/// 진행 중 상태 뱃지
/// - M2-UI-4: doing 상태 시각적 구분
/// - lockscreen.md: doing 우선 노출 정책과 일관된 표시
private struct WorkflowStateBadgeView: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "play.fill")
                .font(.caption2)
            Text("진행 중")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(.blue)
        )
        .accessibilityLabel("진행 중")
    }
}

// MARK: - Preview

#Preview {
    List {
        TaskRowView(
            task: Task(projectId: "p1", title: "일반 할 일", taskType: .oneOff),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "완료된 할 일", taskType: .oneOff),
            isCompleted: true,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "반복 할 일", taskType: .dailyRecurring),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "마감 있는 할 일", taskType: .oneOff, dueDate: Date().addingTimeInterval(3600)),
            isCompleted: false,
            onToggle: {}
        )

        // Priority 테스트 케이스
        TaskRowView(
            task: Task(projectId: "p1", title: "P1 긴급", taskType: .oneOff, priority: .p1),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "P2 높음", taskType: .oneOff, priority: .p2),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "P3 보통", taskType: .oneOff, priority: .p3),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "P4 기본 (표시 안 됨)", taskType: .oneOff, priority: .p4),
            isCompleted: false,
            onToggle: {}
        )

        // 복합 케이스: P1 + 반복 + 마감
        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "복합: P1 긴급 반복",
                taskType: .dailyRecurring,
                dueDate: Date().addingTimeInterval(-3600),
                priority: .p1
            ),
            isCompleted: false,
            onToggle: {}
        )

        // WorkflowState 테스트 케이스 (M2-UI-4)
        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "진행 중인 할 일",
                taskType: .oneOff,
                workflowState: .doing
            ),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "P1 긴급 + 진행 중",
                taskType: .oneOff,
                priority: .p1,
                workflowState: .doing
            ),
            isCompleted: false,
            onToggle: {}
        )

        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "반복 + 진행 중",
                taskType: .dailyRecurring,
                workflowState: .doing
            ),
            isCompleted: false,
            onToggle: {}
        )

        // M2-UI-6: 태그 표시 테스트 케이스
        TaskRowView(
            task: Task(projectId: "p1", title: "태그 1개", taskType: .oneOff),
            isCompleted: false,
            tags: [Tag(name: "업무", colorToken: "blue")],
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "태그 2개", taskType: .oneOff),
            isCompleted: false,
            tags: [
                Tag(name: "업무", colorToken: "blue"),
                Tag(name: "긴급", colorToken: "red")
            ],
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "태그 3개 (+1 표시)", taskType: .oneOff),
            isCompleted: false,
            tags: [
                Tag(name: "업무", colorToken: "blue"),
                Tag(name: "긴급", colorToken: "red"),
                Tag(name: "회의", colorToken: "purple")
            ],
            onToggle: {}
        )

        TaskRowView(
            task: Task(projectId: "p1", title: "태그 5개 (+3 표시)", taskType: .oneOff),
            isCompleted: false,
            tags: [
                Tag(name: "업무", colorToken: "blue"),
                Tag(name: "긴급", colorToken: "red"),
                Tag(name: "회의", colorToken: "purple"),
                Tag(name: "개인", colorToken: "green"),
                Tag(name: "리뷰", colorToken: "orange")
            ],
            onToggle: {}
        )

        // 복합 케이스: P1 + 태그 + 마감
        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "P1 + 태그 + 마감",
                taskType: .oneOff,
                dueDate: Date().addingTimeInterval(3600),
                priority: .p1
            ),
            isCompleted: false,
            tags: [
                Tag(name: "긴급", colorToken: "red"),
                Tag(name: "업무", colorToken: "blue")
            ],
            onToggle: {}
        )

        // 복합 케이스: 진행중 + 태그 + 반복
        TaskRowView(
            task: Task(
                projectId: "p1",
                title: "진행중 + 태그 + 반복",
                taskType: .dailyRecurring,
                workflowState: .doing
            ),
            isCompleted: false,
            tags: [
                Tag(name: "습관", colorToken: "green"),
                Tag(name: "건강", colorToken: "orange"),
                Tag(name: "운동", colorToken: "blue")
            ],
            onToggle: {}
        )
    }
}
