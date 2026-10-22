import SwiftUI

struct SignUpView: View {
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var confirm     = ""
    @State private var showPassword = false

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirm
    }

    private var passwordMismatch: Bool {
        !confirm.isEmpty && password != confirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Name
                        SectionHeader(title: lm["signup.name_label"])
                        FormTextField(placeholder: lm["signup.name_placeholder"], text: $displayName)

                        // Email
                        SectionHeader(title: lm["signup.email_label"])
                        FormTextField(placeholder: lm["signup.email_placeholder"], text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        // Password
                        SectionHeader(title: lm["signup.password_label"])
                        PasswordField(placeholder: lm["signup.password_placeholder"],
                                      text: $password, show: $showPassword)

                        // Confirm password
                        SectionHeader(title: lm["signup.confirm_label"])
                        PasswordField(placeholder: lm["signup.confirm_placeholder"],
                                      text: $confirm, show: $showPassword)
                        if passwordMismatch {
                            Text(lm["signup.mismatch"])
                                .font(.caption).foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Error
                        if let err = auth.errorMessage {
                            Text(err)
                                .font(.caption).foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Sign Up button
                        Button {
                            Task { await auth.signUp(email: email, password: password,
                                                     displayName: displayName.trimmingCharacters(in: .whitespaces)) }
                        } label: {
                            Group {
                                if auth.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text(lm["signup.btn"])
                                        .font(.body.weight(.semibold)).foregroundStyle(.black)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(isValid && !auth.isLoading ? Color.green : Color.green.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isValid || auth.isLoading)
                        .padding(.top, 4)

                        Text(lm["signup.terms"])
                            .font(.caption).foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle(lm["signup.title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm["add.cancel"]) { dismiss() }.foregroundStyle(.green)
                }
            }
        }
    }
}

// MARK: - Reusable password field

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack {
            Group {
                if show {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(height: 48)
        .background(Color(UIColor.systemGray6).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .tint(.green)
    }
}
