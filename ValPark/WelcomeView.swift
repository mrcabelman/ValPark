import SwiftUI

struct WelcomeView: View {
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    @State private var email    = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp   = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 72)

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
                        Text("ValPark")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(.white)
                        Text(lm["welcome.subtitle"])
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 52)

                    // Sign-in form
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: lm["signup.email_label"])
                        FormTextField(placeholder: lm["signup.email_placeholder"], text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        SectionHeader(title: lm["signup.password_label"])
                        PasswordField(placeholder: lm["signup.password_placeholder"],
                                      text: $password, show: $showPassword)

                        // Error
                        if let err = auth.errorMessage {
                            Text(err)
                                .font(.caption).foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Sign In button
                        Button {
                            Task { await auth.signIn(email: email, password: password) }
                        } label: {
                            Group {
                                if auth.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text(lm["welcome.sign_in_email"])
                                        .font(.body.weight(.semibold)).foregroundStyle(.black)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(!email.isEmpty && !password.isEmpty && !auth.isLoading
                                        ? Color.green : Color.green.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(email.isEmpty || password.isEmpty || auth.isLoading)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                        Text(lm["welcome.or"]).font(.caption).foregroundStyle(.gray).padding(.horizontal, 8)
                        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 20)

                    // Google Sign-In
                    Button {
                        Task { await auth.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.title3).foregroundStyle(.black)
                            Text(lm["welcome.sign_in"])
                                .font(.body.weight(.semibold)).foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Sign up link
                    Button { showSignUp = true } label: {
                        HStack(spacing: 4) {
                            Text(lm["welcome.no_account"]).foregroundStyle(.gray)
                            Text(lm["welcome.sign_up_link"]).foregroundStyle(.green)
                        }
                        .font(.subheadline)
                    }

                    Spacer().frame(height: 24)

                    // Language toggle
                    LanguageToggle()
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 52)
                }
            }
        }
        .sheet(isPresented: $showSignUp) { SignUpView() }
    }
}

// MARK: - EN / ES language toggle (also used in Settings)

struct LanguageToggle: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        @Bindable var blm = lm
        HStack(spacing: 2) {
            ForEach(LocalizationManager.Language.allCases) { lang in
                Button {
                    blm.language = lang
                } label: {
                    Text(lang.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(blm.language == lang ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(blm.language == lang ? Color.green : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .animation(.easeInOut(duration: 0.18), value: blm.language)
                }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
