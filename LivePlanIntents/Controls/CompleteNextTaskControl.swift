import AppIntents
import SwiftUI

/// 다음 태스크 완료 Control (iOS 18+)
/// - intents.md 준수: iOS 18+ Controls
@available(iOS 18.0, *)
struct CompleteNextTaskControl: ControlWidget {
    static let kind: String = "com.liveplan.control.complete"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: CompleteNextTaskIntent()) {
                Label("완료", systemImage: "checkmark.circle")
            }
        }
        .displayName("할 일 완료")
        .description("다음 할 일을 완료합니다")
    }
}
