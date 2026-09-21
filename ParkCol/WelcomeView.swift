import SwiftUI

struct WelcomeView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / wordmark
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.green)
                            .frame(width: 88, height: 88)
                        Image(systemName: "car.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.black)
                    }

                    Text("ParkCol")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)

                    Text(lm["welcome.subtitle"])
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Error message
                    if let err = auth.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Google Sign-In button
                    Button {
                        Task { await auth.signIn() }
                    } label: {
                        HStack(spacing: 12) {
                            if auth.isLoading {
                                ProgressView()
                                    .tint(.black)
                                Text(lm["welcome.signing_in"])
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.black)
                            } else {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title3)
                                    .foregroundStyle(.black)
                                Text(lm["welcome.sign_in"])
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(auth.isLoading)
                    .padding(.horizontal, 32)

                    // Language toggle
                    LanguageToggle()
                        .padding(.top, 8)
                }
                .padding(.bottom, 52)
            }
        }
    }
}

/// Minimal EN / ES toggle used on the welcome screen and in settings.
struct LanguageToggle: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LocalizationManager.Language.allCases) { lang in
                Button {
                    lm.language = lang
                } label: {
                    Text(lang.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(lm.language == lang ? .black : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(lm.language == lang ? Color.green : Color.clear)
                        .clipShape(Capsule())
                }
                .animation(.easeInOut(duration: 0.2), value: lm.language)
            }
        }
        .padding(4)
        .background(Color(UIColor.systemGray6).opacity(0.3))
        .clipShape(Capsule())
    }
}
