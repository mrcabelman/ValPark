import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

// MARK: - FirebaseAuthManager
//
// Replaces the hand-rolled AuthManager.swift.
// Handles email/password and Google sign-in via Firebase Auth.
// All org membership and ticket data keys off the Firebase UID.

@Observable
@MainActor
final class FirebaseAuthManager {

    // MARK: - Observed state

    var currentUser: User?        // Firebase Auth user
    var userProfile: UserProfile? // Corresponding Firestore document
    var isLoading = false
    var errorMessage: String?

    var isSignedIn: Bool       { currentUser != nil }
    /// Google-sign-in users have their email pre-verified by Google.
    var isEmailVerified: Bool  { currentUser?.isEmailVerified ?? false }

    // MARK: - Private

    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // MARK: - Init / Deinit

    init() {
        // Restore session and keep in sync with Firebase Auth state
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentUser = user
                if let uid = user?.uid {
                    await self.loadProfile(uid: uid)
                } else {
                    self.userProfile = nil
                }
            }
        }
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Email Sign-Up

    func signUp(email: String, password: String, displayName: String) async {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Write display name to Firebase Auth profile
            let req = result.user.createProfileChangeRequest()
            req.displayName = displayName
            try await req.commitChanges()

            // Send verification email
            try await result.user.sendEmailVerification()

            // Create Firestore user profile
            let profile = UserProfile(
                uid: result.user.uid,
                displayName: displayName,
                email: email.lowercased(),
                createdAt: Date()
            )
            try db.collection("users").document(result.user.uid).setData(from: profile)
            userProfile = profile
            currentUser = Auth.auth().currentUser
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Email Sign-In

    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            await loadProfile(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase not configured. Add GoogleService-Info.plist to the project."
            return
        }
        guard let rootVC = rootViewController() else {
            errorMessage = "Cannot present sign-in sheet."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Missing Google ID token."
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            currentUser = firebaseUser

            // Create Firestore profile on first sign-in
            let ref = db.collection("users").document(firebaseUser.uid)
            let snap = try await ref.getDocument()
            if !snap.exists {
                let profile = UserProfile(
                    uid: firebaseUser.uid,
                    displayName: firebaseUser.displayName ?? result.user.profile?.name ?? "Unknown",
                    email: (firebaseUser.email ?? "").lowercased(),
                    photoURL: firebaseUser.photoURL?.absoluteString,
                    createdAt: Date()
                )
                try ref.setData(from: profile)
                userProfile = profile
            } else {
                await loadProfile(uid: firebaseUser.uid)
            }
        } catch {
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    // MARK: - Email Verification

    /// Resend the verification email to the current user.
    func sendVerificationEmail() async {
        errorMessage = nil
        do {
            try await currentUser?.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Re-fetches the Firebase Auth user record to check if the email is now verified.
    /// Returns `true` if verified.
    @discardableResult
    func reloadUser() async -> Bool {
        do {
            try await currentUser?.reload()
            currentUser = Auth.auth().currentUser
            return currentUser?.isEmailVerified ?? false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            userProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    private func loadProfile(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            userProfile = try? doc.data(as: UserProfile.self)
        } catch {
            // Profile not found — happens mid-signup before the doc is created
        }
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
