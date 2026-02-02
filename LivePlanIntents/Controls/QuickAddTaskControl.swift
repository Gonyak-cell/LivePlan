import AppIntents
import SwiftUI

/// 빠른 태스크 추가 Control (iOS 18+)
@available(iOS 18.0, *)
struct QuickAddTaskControl: ControlWidget {
    static let kind: String = "com.liveplan.control.quickadd"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: QuickAddTaskIntent()) {
                Label("추가", systemImage: "plus.circle")
            }
        }
        .displayName("빠른 추가")
        .description("새 할 일을 추가합니다")
    }
}
