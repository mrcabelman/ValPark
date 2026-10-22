import SwiftUI

struct SettingsView: View {
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(OrganizationStore.self)   private var orgStore
    @Environment(LocalizationManager.self) private var lm

    @State private var showOrganizations = false
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Language ─────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.language"]).font(.caption).foregroundStyle(.gray)
                            LanguageToggle()
                        }

                        // ── Profile ───────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.profile_section"]).font(.caption).foregroundStyle(.gray)
                            VStack(spacing: 0) {
                                HStack {
                                    Text(lm["settings.name"]).foregroundStyle(.white)
                                    Spacer()
                                    Text(auth.userProfile?.displayName ?? auth.currentUser?.displayName ?? "—")
                                        .foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                HStack {
                                    Text(lm["settings.email"]).foregroundStyle(.white)
                                    Spacer()
                                    Text(auth.userProfile?.email ?? auth.currentUser?.email ?? "—")
                                        .foregroundStyle(.gray).lineLimit(1).truncationMode(.middle)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // ── Organizations ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.orgs_section"]).font(.caption).foregroundStyle(.gray)
                            VStack(spacing: 0) {
                                // Current org (if any)
                                if let org = orgStore.currentOrg {
                                    NavigationLink(destination: OrgMembersView(org: org)) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(org.name).foregroundStyle(.white).font(.headline)
                                                Text(orgStore.isAdmin ? lm["orgs.role_admin"] : lm["orgs.role_member"])
                                                    .font(.caption).foregroundStyle(.gray)
                                            }
                                            Spacer()
                                            // Pending requests badge (admin only)
                                            if orgStore.isAdmin && !orgStore.joinRequests.isEmpty {
                                                Text("\(orgStore.joinRequests.count)")
                                                    .font(.caption.weight(.bold)).foregroundStyle(.black)
                                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                                    .background(Color.orange).clipShape(Capsule())
                                                    .padding(.trailing, 4)
                                            }
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.gray).font(.caption)
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                }

                                // Manage all orgs / create / join
                                Button { showOrganizations = true } label: {
                                    HStack {
                                        Text(lm["settings.manage_orgs"]).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.gray).font(.caption)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                }
                            }
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // ── App info ──────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.app_section"]).font(.caption).foregroundStyle(.gray)
                            VStack(spacing: 0) {
                                HStack {
                                    Text(lm["settings.version"]).foregroundStyle(.white)
                                    Spacer()
                                    Text("1.0.0").foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                HStack {
                                    Text(lm["settings.notifications"]).foregroundStyle(.white)
                                    Spacer()
                                    Label(lm["settings.disabled"], systemImage: "bell.slash")
                                        .font(.subheadline).foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // ── Sign Out ──────────────────────────────────────
                        Button { showSignOutConfirm = true } label: {
                            Text(lm["settings.sign_out"])
                                .font(.body.weight(.semibold)).foregroundStyle(.red)
                                .frame(maxWidth: .infinity).padding()
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red, lineWidth: 1))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(lm["settings.title"])
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showOrganizations) {
                OrganizationsView()
            }
            .confirmationDialog(lm["settings.sign_out_confirm"],
                                isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button(lm["settings.sign_out"], role: .destructive) {
                    orgStore.stopListening()
                    auth.signOut()
                }
                Button(lm["settings.cancel"], role: .cancel) {}
            }
        }
    }
}
