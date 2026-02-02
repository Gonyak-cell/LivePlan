import SwiftUI
import AppCore

/// 워크플로우 상태 다중선택 뷰
struct WorkflowStatePickerView: View {
    @Binding var selection: Set<WorkflowState>?

    private var effectiveSelection: Set<WorkflowState> {
        selection ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(WorkflowState.allCases, id: \.self) { state in
                Toggle(isOn: binding(for: state)) {
                    HStack {
                        Circle()
                            .fill(color(for: state))
                            .frame(width: 12, height: 12)
                        Text(state.descriptionKR)
                    }
                }
            }
        }
    }

    private func binding(for state: WorkflowState) -> Binding<Bool> {
        Binding(
            get: { effectiveSelection.contains(state) },
            set: { isSelected in
                var newSelection = effectiveSelection
                if isSelected {
                    newSelection.insert(state)
                } else {
                    newSelection.remove(state)
                }
                selection = newSelection.isEmpty ? nil : newSelection
            }
        )
    }

    private func color(for state: WorkflowState) -> Color {
        switch state {
        case .todo: return .gray
        case .doing: return .blue
        case .done: return .green
        }
    }
}

// MARK: - WorkflowState Extension

extension WorkflowState {
    /// 사용자 표시용 설명 (KR)
    var descriptionKR: String {
        switch self {
        case .todo: return "할 일"
        case .doing: return "진행 중"
        case .done: return "완료"
        }
    }

    /// 사용자 표시용 설명 (EN)
    var descriptionEN: String {
        switch self {
        case .todo: return "To Do"
        case .doing: return "Doing"
        case .done: return "Done"
        }
    }
}

// MARK: - Preview

#Preview {
    Form {
        Section("상태 선택") {
            WorkflowStatePickerView(selection: .constant([.todo, .doing]))
        }
    }
}
