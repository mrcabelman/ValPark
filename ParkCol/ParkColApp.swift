import SwiftUI
import SwiftData

@main
struct ParkColApp: App {
    @State private var auth = AuthManager()
    @State private var lm   = LocalizationManager()
    @State private var appSettings = AppSettings()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ParkingTicket.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Could not create ModelContainer: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
            .environment(auth)
            .environment(lm)
            .environment(appSettings)
            // On every sign-in, pull settings from Google Drive
            .onChange(of: auth.isSignedIn) { _, signedIn in
                if signedIn { Task { await syncFromCloud() } }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func syncFromCloud() async {
        guard let token = await auth.validAccessToken() else { return }
        if let cloud = await CloudSyncManager.load(accessToken: token) {
            await MainActor.run { appSettings.applyCloudSettings(cloud, lm: lm) }
        }
    }
}
