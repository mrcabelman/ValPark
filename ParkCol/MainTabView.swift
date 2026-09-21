import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        TabView(selection: $selectedTab) {
            ActiveView()
                .tabItem { Label(lm["tab.active"],   systemImage: "bolt.fill") }
                .tag(0)

            HistoryView()
                .tabItem { Label(lm["tab.history"],  systemImage: "clock") }
                .tag(1)

            SettingsView()
                .tabItem { Label(lm["tab.settings"], systemImage: "gearshape") }
                .tag(2)
        }
        .tint(.green)
        .preferredColorScheme(.dark)
    }
}
