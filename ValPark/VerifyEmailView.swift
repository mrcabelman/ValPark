import SwiftUI

// Shown after email/password sign-up until the user verifies their email.
// Auto-polls Firebase every 4 seconds. User can also tap "I've Verified My Email"
// to force an immediate check.

struct VerifyEmailView: View {
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    @State private var resentEmail    = false
    @State private var isChecking     = false
    @State private var pollTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                }
                .padding(.bottom, 28)

                Text(lm["verify.title"])
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                Text(lm["verify.body"])
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)

                Spacer()

                VStack(spacing: 14) {
                    // Error
                    if let err = auth.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }

                    // Confirm button (manual reload)
                    Button {
                        Task {
                            isChecking = true
                            await auth.reloadUser()
                            isChecking = false
                        }
                    } label: {
                        Group {
                            if isChecking {
                                ProgressView().tint(.black)
                            } else {
                                Text(lm["verify.confirmed_btn"])
                                    .font(.body.weight(.semibold)).foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)

                    // Resend button
                    Button {
                        Task {
                            await auth.sendVerificationEmail()
                            resentEmail = true
                        }
                    } label: {
                        Text(resentEmail ? lm["verify.resent"] : lm["verify.resend_btn"])
                            .font(.subheadline)
                            .foregroundStyle(resentEmail ? .gray : .green)
                    }
                    .disabled(resentEmail)

                    // Sign out
                    Button {
                        auth.signOut()
                    } label: {
                        Text(lm["settings.sign_out"])
                            .font(.subheadline).foregroundStyle(.gray)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear { startPolling() }
        .onDisappear { pollTask?.cancel() }
    }

    // MARK: - Auto-poll

    private func startPolling() {
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
                guard !Task.isCancelled else { break }
                await auth.reloadUser()
                // If verified, ParkColApp routing detects it and navigates away automatically
            }
        }
    }
}
