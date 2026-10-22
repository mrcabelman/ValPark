import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct ValParkApp: App {

    @State private var lm          = LocalizationManager()
    @State private var authManager = FirebaseAuthManager()
    @State private var orgStore    = OrganizationStore()
    @State private var ticketStore = TicketStore()

    init() {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(lm)
                .environment(authManager)
                .environment(orgStore)
                .environment(ticketStore)
                .task { NotificationManager.requestPermission() }
        }
    }
}

// MARK: - RootView  (auth-state router)

struct RootView: View {
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(OrganizationStore.self)   private var orgStore

    var body: some View {
        Group {
            if !auth.isSignedIn {
                // 1. Not signed in → show sign-in / sign-up
                WelcomeView()

            } else if !auth.isEmailVerified {
                // 2. Signed in but email not yet verified (email/password users only;
                //    Google users are always verified by Google)
                VerifyEmailView()

            } else if orgStore.myOrgs.isEmpty {
                // 3. Verified but no org membership yet → onboarding
                OrganizationsView()

            } else {
                // 4. Fully set up → main app
                MainTabView()
            }
        }
        // Start org listener as soon as we have a signed-in, verified user
        .onChange(of: auth.currentUser?.uid) { _, uid in
            if let uid {
                orgStore.startListening(uid: uid)
            } else {
                orgStore.stopListening()
            }
        }
        .onAppear {
            if let uid = auth.currentUser?.uid, auth.isEmailVerified {
                orgStore.startListening(uid: uid)
            }
        }
    }
}
