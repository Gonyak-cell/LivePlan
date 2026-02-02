import AppIntents
import SwiftUI

/// Live Activity 갱신 Control (iOS 18+)
@available(iOS 18.0, *)
struct RefreshActivityControl: ControlWidget {
    static let kind: String = "com.liveplan.control.refresh"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: RefreshLiveActivityIntent()) {
                Label("갱신", systemImage: "arrow.clockwise")
            }
        }
        .displayName("활동 갱신")
        .description("Live Activity를 갱신합니다")
    }
}
