import AppIntents
import SwiftUI

/// 다음 태스크 시작 Control (iOS 18+)
/// - intents.md 준수: iOS 18+ Controls
@available(iOS 18.0, *)
struct StartNextTaskControl: ControlWidget {
    static let kind: String = "com.liveplan.control.start"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: StartNextTaskIntent()) {
                Label("시작", systemImage: "play.fill")
            }
        }
        .displayName("할 일 시작")
        .description("다음 할 일을 시작합니다")
    }
}
