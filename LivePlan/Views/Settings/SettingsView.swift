import SwiftUI
import AppCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                // 프라이버시
                Section {
                    NavigationLink {
                        PrivacySettingView()
                    } label: {
                        HStack {
                            Label("프라이버시", systemImage: "eye.slash")
                            Spacer()
                            Text(appState.settings.privacyMode.descriptionKR)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("프라이버시")
                } footer: {
                    Text("잠금화면은 주변 사람이 볼 수 있습니다. 기본 설정에서는 할 일 제목이 숨겨집니다.")
                }

                // 대표 프로젝트
                Section {
                    NavigationLink {
                        PinnedProjectSettingView()
                    } label: {
                        HStack {
                            Label("대표 프로젝트", systemImage: "pin")
                            Spacer()
                            if let pinned = appState.pinnedProject {
                                Text(pinned.title)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("없음")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } footer: {
                    Text("잠금화면 위젯에 우선 표시할 프로젝트를 선택하세요.")
                }

                // 관리
                Section("관리") {
                    NavigationLink {
                        TagManageView()
                    } label: {
                        Label("태그 관리", systemImage: "tag")
                    }
                }

                // 도움말
                Section("도움말") {
                    NavigationLink {
                        WidgetGuideView()
                    } label: {
                        Label("위젯 설정 방법", systemImage: "apps.iphone")
                    }

                    NavigationLink {
                        ShortcutsGuideView()
                    } label: {
                        Label("단축어 설정 (선택)", systemImage: "command")
                    }
                }

                // 앱 정보
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("데이터 버전")
                        Spacer()
                        Text("v\(appState.settings.schemaVersion)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

// MARK: - PrivacySettingView

struct PrivacySettingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section {
                ForEach(PrivacyMode.allCases, id: \.self) { mode in
                    Button {
                        updatePrivacyMode(mode)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mode.descriptionKR)
                                    .foregroundStyle(.primary)

                                Text(privacyDescription(mode))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if appState.settings.privacyMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("잠금화면에서 표시되는 내용을 제어합니다. '제목 숨김'이 권장됩니다.")
            }
        }
        .navigationTitle("프라이버시")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyDescription(_ mode: PrivacyMode) -> String {
        switch mode {
        case .visible:
            return "할 일 제목이 그대로 표시됩니다"
        case .masked:
            return "할 일 1, 할 일 2... 형태로 표시됩니다"
        case .hidden:
            return "숫자만 표시됩니다"
        }
    }

    private func updatePrivacyMode(_ mode: PrivacyMode) {
        Task {
            var newSettings = appState.settings
            newSettings.privacyMode = mode
            await appState.saveSettings(newSettings)
        }
    }
}

// MARK: - PinnedProjectSettingView

struct PinnedProjectSettingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section {
                // 없음 옵션
                Button {
                    updatePinnedProject(nil)
                } label: {
                    HStack {
                        Text("없음")
                            .foregroundStyle(.primary)

                        Spacer()

                        if appState.settings.pinnedProjectId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // 프로젝트 목록
                ForEach(appState.activeProjects) { project in
                    Button {
                        updatePinnedProject(project.id)
                    } label: {
                        HStack {
                            Text(project.title)
                                .foregroundStyle(.primary)

                            Spacer()

                            if appState.settings.pinnedProjectId == project.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("대표 프로젝트")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func updatePinnedProject(_ projectId: String?) {
        Task {
            var newSettings = appState.settings
            newSettings.pinnedProjectId = projectId
            await appState.saveSettings(newSettings)
        }
    }
}

// MARK: - Guide Views

struct WidgetGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("잠금화면 위젯 추가 방법")
                    .font(.headline)

                GuideStep(number: 1, text: "잠금화면을 길게 누르세요")
                GuideStep(number: 2, text: "'사용자화'를 탭하세요")
                GuideStep(number: 3, text: "위젯 영역을 탭하세요")
                GuideStep(number: 4, text: "LivePlan을 찾아 추가하세요")

                Divider()

                Text("위젯은 iOS 정책에 따라 즉시 갱신되지 않을 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("위젯 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShortcutsGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("단축어 자동화 (선택)")
                    .font(.headline)

                Text("Live Activity는 최대 8시간 활성화됩니다. 단축어 자동화로 주기적 갱신을 설정할 수 있습니다.")

                Divider()

                Text("설정 방법")
                    .font(.subheadline.bold())

                GuideStep(number: 1, text: "단축어 앱을 열고 '자동화' 탭 선택")
                GuideStep(number: 2, text: "'새로운 자동화' 생성")
                GuideStep(number: 3, text: "'시간' 트리거 선택")
                GuideStep(number: 4, text: "LivePlan의 'Refresh Live Activity' 동작 추가")

                Divider()

                Text("이 기능은 선택 사항입니다. 위젯만으로도 핵심 기능이 유지됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("단축어")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
