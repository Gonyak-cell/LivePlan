import SwiftUI
import AppCore

/// 태그 칩 뷰 (단일 태그 표시용)
/// - M2-UI-5: Tag 관리 UI 컴포넌트
/// - ui-style.md 준수: SF Symbols 사용, Dynamic Type 지원
struct TagChipView: View {
    let tag: Tag
    var isSelected: Bool = false
    var showRemoveButton: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.displayLabel)
                .font(.caption)
                .fontWeight(.medium)

            if showRemoveButton {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("태그 제거")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundView)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tag.name) 태그")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6)
                .fill(tagColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(tagColor, lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        }
    }

    private var tagColor: Color {
        tag.colorToken.flatMap { Color(tokenName: $0) } ?? .blue
    }
}

// MARK: - Tag Color Extension

extension Color {
    /// colorToken 이름으로 Color 생성
    init?(tokenName: String) {
        switch tokenName.lowercased() {
        case "red": self = .red
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "green": self = .green
        case "blue": self = .blue
        case "purple": self = .purple
        case "pink": self = .pink
        case "gray": self = .gray
        default: return nil
        }
    }
}

// MARK: - Tag Chip Collection View

/// 여러 태그를 칩 형태로 표시하는 Flow Layout
struct TagChipsView: View {
    let tags: [Tag]
    var isCompact: Bool = false
    var maxDisplayCount: Int? = nil
    var onTagTap: ((Tag) -> Void)? = nil

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            FlowLayout(spacing: 6) {
                ForEach(displayTags) { tag in
                    if let onTap = onTagTap {
                        Button {
                            onTap(tag)
                        } label: {
                            TagChipView(tag: tag)
                        }
                        .buttonStyle(.plain)
                    } else {
                        TagChipView(tag: tag)
                    }
                }

                if let remaining = remainingCount, remaining > 0 {
                    Text("+\(remaining)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }

    private var displayTags: [Tag] {
        if let max = maxDisplayCount, tags.count > max {
            return Array(tags.prefix(max))
        }
        return tags
    }

    private var remainingCount: Int? {
        guard let max = maxDisplayCount, tags.count > max else { return nil }
        return tags.count - max
    }
}

// MARK: - Simple Flow Layout

/// 간단한 FlowLayout (태그 칩 나열용)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // 다음 줄로 이동
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = max(totalHeight, currentY + lineHeight)
        }

        return ArrangementResult(
            positions: positions,
            size: CGSize(width: totalWidth, height: totalHeight)
        )
    }

    private struct ArrangementResult {
        let positions: [CGPoint]
        let size: CGSize
    }
}

// MARK: - Editable Tag Chips View

/// 태그 편집이 가능한 칩 목록 (선택된 태그 표시 + 제거)
struct EditableTagChipsView: View {
    @Binding var selectedTagIds: [String]
    let allTags: [Tag]
    var onAddTap: (() -> Void)? = nil

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(selectedTags) { tag in
                TagChipView(
                    tag: tag,
                    isSelected: true,
                    showRemoveButton: true,
                    onRemove: { removeTag(tag) }
                )
            }

            if let onAdd = onAddTap {
                Button(action: onAdd) {
                    Label("추가", systemImage: "plus")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(.secondary)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("태그 추가")
            }
        }
    }

    private var selectedTags: [Tag] {
        allTags.filter { selectedTagIds.contains($0.id) }
    }

    private func removeTag(_ tag: Tag) {
        selectedTagIds.removeAll { $0 == tag.id }
    }
}

// MARK: - Preview

#Preview("Single Chips") {
    VStack(spacing: 16) {
        Text("Tag Chips")
            .font(.headline)

        HStack(spacing: 8) {
            TagChipView(tag: Tag(name: "업무"))
            TagChipView(tag: Tag(name: "긴급", colorToken: "red"), isSelected: true)
            TagChipView(tag: Tag(name: "개인", colorToken: "blue"))
        }

        Divider()

        Text("With Remove Button")
            .font(.subheadline)

        HStack(spacing: 8) {
            TagChipView(
                tag: Tag(name: "제거가능"),
                isSelected: true,
                showRemoveButton: true,
                onRemove: { print("removed") }
            )
        }
    }
    .padding()
}

#Preview("Tag Collection") {
    let sampleTags = [
        Tag(name: "업무", colorToken: "blue"),
        Tag(name: "긴급", colorToken: "red"),
        Tag(name: "개인", colorToken: "green"),
        Tag(name: "회의", colorToken: "purple"),
        Tag(name: "리뷰", colorToken: "orange")
    ]

    VStack(alignment: .leading, spacing: 20) {
        Text("All Tags")
            .font(.headline)

        TagChipsView(tags: sampleTags)

        Divider()

        Text("Max 3 Tags")
            .font(.headline)

        TagChipsView(tags: sampleTags, maxDisplayCount: 3)
    }
    .padding()
}

private struct EditablePreview: View {
    @State private var selectedIds: [String] = []
    let allTags = [
        Tag(id: "1", name: "업무", colorToken: "blue"),
        Tag(id: "2", name: "긴급", colorToken: "red"),
        Tag(id: "3", name: "개인", colorToken: "green")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Editable Tags")
                .font(.headline)

            EditableTagChipsView(
                selectedTagIds: $selectedIds,
                allTags: allTags,
                onAddTap: {
                    // 데모: 순환 추가
                    let nextTag = allTags.first { !selectedIds.contains($0.id) }
                    if let tag = nextTag {
                        selectedIds.append(tag.id)
                    }
                }
            )

            Text("선택됨: \(selectedIds.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Editable") {
    EditablePreview()
}
