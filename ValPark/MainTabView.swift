import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(LocalizationManager.self)  private var lm
    @Environment(OrganizationStore.self)    private var orgStore
    @Environment(TicketStore.self)          private var ticketStore

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
        // Start/restart the ticket listener whenever the active org changes
        .onChange(of: orgStore.currentOrg?.id) { _, newOrgId in
            if let orgId = newOrgId {
                ticketStore.listen(orgId: orgId)
            } else {
                ticketStore.stopListening()
            }
        }
        .onAppear {
            if let orgId = orgStore.currentOrg?.id {
                ticketStore.listen(orgId: orgId)
            }
        }
    }
}
