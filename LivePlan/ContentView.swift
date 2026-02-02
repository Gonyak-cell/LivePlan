import SwiftUI
import AppCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab = .projects

    enum Tab {
        case projects
        case today
        case search
        case filters
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ProjectListView()
                .tabItem {
                    Label("프로젝트", systemImage: "folder")
                }
                .tag(Tab.projects)

            TodayView()
                .tabItem {
                    Label("오늘", systemImage: "calendar")
                }
                .tag(Tab.today)

            SearchView()
                .tabItem {
                    Label("검색", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            FilterListView()
                .tabItem {
                    Label("필터", systemImage: "line.3.horizontal.decrease.circle")
                }
                .tag(Tab.filters)

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .overlay {
            if appState.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
