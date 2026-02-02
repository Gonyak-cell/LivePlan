import SwiftUI

/// 빈 상태 뷰
/// - ui-style.md D 준수: 빈 상태는 반드시 정의
struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        title: "프로젝트가 없습니다",
        message: "새 프로젝트를 만들어 시작하세요",
        actionTitle: "프로젝트 만들기",
        action: {}
    )
}
