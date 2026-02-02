import SwiftUI
import AppCore

/// 우선순위 선택 Picker
/// - M2-UI-1: Priority 편집 UI 컴포넌트
/// - ui-style.md 준수: SF Symbols 사용, Dynamic Type 지원
struct PriorityPickerView: View {
    @Binding var selection: Priority
    var style: PriorityPickerStyle = .segmented

    var body: some View {
        switch style {
        case .segmented:
            segmentedPicker
        case .menu:
            menuPicker
        case .inline:
            inlinePicker
        }
    }

    // MARK: - Segmented Style

    private var segmentedPicker: some View {
        Picker("우선순위", selection: $selection) {
            ForEach(Priority.allCases, id: \.self) { priority in
                Label {
                    Text(priority.label)
                } icon: {
                    Image(systemName: priority.iconName)
                }
                .tag(priority)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("우선순위 선택")
    }

    // MARK: - Menu Style

    private var menuPicker: some View {
        Menu {
            ForEach(Priority.allCases, id: \.self) { priority in
                Button {
                    selection = priority
                } label: {
                    Label {
                        Text("\(priority.label) - \(priority.descriptionKR)")
                    } icon: {
                        Image(systemName: priority.iconName)
                    }
                }
            }
        } label: {
            PriorityBadgeView(priority: selection, showLabel: true)
        }
        .accessibilityLabel("우선순위: \(selection.descriptionKR)")
        .accessibilityHint("탭하여 우선순위 변경")
    }

    // MARK: - Inline Style

    private var inlinePicker: some View {
        HStack(spacing: 8) {
            ForEach(Priority.allCases, id: \.self) { priority in
                Button {
                    selection = priority
                } label: {
                    PriorityBadgeView(
                        priority: priority,
                        isSelected: selection == priority
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(priority.descriptionKR) 우선순위")
                .accessibilityAddTraits(selection == priority ? .isSelected : [])
            }
        }
    }
}

// MARK: - Picker Style

enum PriorityPickerStyle {
    /// Segmented control (Form 내 사용)
    case segmented
    /// Dropdown menu (컴팩트한 공간)
    case menu
    /// Inline buttons (상세 화면)
    case inline
}

// MARK: - Priority Badge View

/// 우선순위 뱃지 (단독 표시용)
struct PriorityBadgeView: View {
    let priority: Priority
    var showLabel: Bool = false
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.iconName)
                .font(.caption)
                .foregroundStyle(priority.color)

            if showLabel {
                Text(priority.label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, showLabel ? 8 : 6)
        .padding(.vertical, 4)
        .background(backgroundView)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(priority.descriptionKR) 우선순위")
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6)
                .fill(priority.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(priority.color, lineWidth: 1)
                )
        } else if showLabel {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        }
    }
}

// MARK: - Priority UI Extensions

extension Priority {
    /// 우선순위별 색상
    var color: Color {
        switch self {
        case .p1: return .red
        case .p2: return .orange
        case .p3: return .yellow
        case .p4: return .gray
        }
    }

    /// 우선순위별 SF Symbol 아이콘
    var iconName: String {
        switch self {
        case .p1: return "flag.fill"
        case .p2: return "flag.fill"
        case .p3: return "flag"
        case .p4: return "flag"
        }
    }

    /// P4(기본값)가 아닌 경우에만 표시할지 여부
    var shouldDisplay: Bool {
        self != .p4
    }
}

// MARK: - Form Row Helper

/// Form 내 우선순위 선택 행
struct PriorityFormRow: View {
    @Binding var priority: Priority
    var label: String = "우선순위"

    var body: some View {
        Picker(label, selection: $priority) {
            ForEach(Priority.allCases, id: \.self) { p in
                HStack {
                    Image(systemName: p.iconName)
                        .foregroundStyle(p.color)
                    Text("\(p.label) - \(p.descriptionKR)")
                }
                .tag(p)
            }
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview("Badges") {
    VStack(spacing: 16) {
        Text("Priority Badges")
            .font(.headline)

        HStack(spacing: 12) {
            ForEach(Priority.allCases, id: \.self) { priority in
                PriorityBadgeView(priority: priority, showLabel: true)
            }
        }

        Divider()

        Text("Icon Only")
            .font(.subheadline)

        HStack(spacing: 12) {
            ForEach(Priority.allCases, id: \.self) { priority in
                PriorityBadgeView(priority: priority)
            }
        }

        Divider()

        Text("Selected State")
            .font(.subheadline)

        HStack(spacing: 12) {
            PriorityBadgeView(priority: .p1, isSelected: true)
            PriorityBadgeView(priority: .p2, isSelected: false)
            PriorityBadgeView(priority: .p3, isSelected: false)
            PriorityBadgeView(priority: .p4, isSelected: false)
        }
    }
    .padding()
}

// MARK: - Interactive Previews

private struct SegmentedPreview: View {
    @State private var priority: Priority = .p2

    var body: some View {
        Form {
            Section("Segmented Style") {
                PriorityPickerView(selection: $priority, style: .segmented)
            }

            Section("Current") {
                Text("선택: \(priority.label) - \(priority.descriptionKR)")
            }
        }
    }
}

private struct MenuPreview: View {
    @State private var priority: Priority = .p1

    var body: some View {
        VStack(spacing: 20) {
            Text("Menu Style")
                .font(.headline)

            PriorityPickerView(selection: $priority, style: .menu)

            Text("선택: \(priority.label)")
        }
        .padding()
    }
}

private struct InlinePreview: View {
    @State private var priority: Priority = .p3

    var body: some View {
        VStack(spacing: 20) {
            Text("Inline Style")
                .font(.headline)

            PriorityPickerView(selection: $priority, style: .inline)

            Text("선택: \(priority.label)")
        }
        .padding()
    }
}

private struct FormRowPreview: View {
    @State private var priority: Priority = .p4

    var body: some View {
        Form {
            PriorityFormRow(priority: $priority)
        }
    }
}

#Preview("Segmented") {
    SegmentedPreview()
}

#Preview("Menu") {
    MenuPreview()
}

#Preview("Inline") {
    InlinePreview()
}

#Preview("Form Row") {
    FormRowPreview()
}
