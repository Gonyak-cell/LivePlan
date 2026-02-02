import SwiftUI
import AppCore

/// 마감일 범위 선택 Picker
struct DueRangePickerView: View {
    @Binding var selection: DueRange?

    var body: some View {
        Picker("마감일", selection: $selection) {
            Text("전체").tag(nil as DueRange?)
            ForEach(DueRange.allCases, id: \.self) { range in
                Text(range.descriptionKR).tag(range as DueRange?)
            }
        }
    }
}

// MARK: - Inline Style

extension DueRangePickerView {
    /// 인라인 스타일 (가로 배열)
    static func inline(selection: Binding<DueRange?>) -> some View {
        DueRangePickerView(selection: selection)
            .pickerStyle(.segmented)
    }
}

// MARK: - Preview

#Preview {
    Form {
        DueRangePickerView(selection: .constant(.today))
    }
}
