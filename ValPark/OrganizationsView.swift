import SwiftUI

// Shown in two contexts:
//   1. After sign-in when the user belongs to no orgs (onboarding empty state)
//   2. From Settings → Organizations (to manage all orgs)

struct OrganizationsView: View {
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    @State private var showCreate   = false
    @State private var showJoin     = false
    @State private var isOnboarding = false   // set true when no orgs exist

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if orgStore.myOrgs.isEmpty && !orgStore.isLoading {
                    // Empty-state onboarding
                    VStack(spacing: 0) {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 36)).foregroundStyle(.green)
                        }
                        .padding(.bottom, 24)
                        Text(lm["orgs.empty_title"])
                            .font(.title3.weight(.bold)).foregroundStyle(.white)
                            .padding(.bottom, 8)
                        Text(lm["orgs.empty_body"])
                            .font(.subheadline).foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                        actionButtons.padding(.horizontal, 24).padding(.bottom, 52)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Org list
                            if !orgStore.myOrgs.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(orgStore.myOrgs) { org in
                                        OrgRowView(org: org)
                                        if org.id != orgStore.myOrgs.last?.id {
                                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(UIColor.systemGray6).opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            actionButtons
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(lm["orgs.title"])
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showCreate) { CreateOrgSheet() }
        .sheet(isPresented: $showJoin)   { JoinOrgSheet() }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { showCreate = true } label: {
                Label(lm["orgs.create_btn"], systemImage: "plus")
                    .font(.body.weight(.semibold)).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button { showJoin = true } label: {
                Label(lm["orgs.join_btn"], systemImage: "person.badge.plus")
                    .font(.body.weight(.semibold)).foregroundStyle(.green)
                    .frame(maxWidth: .infinity).padding()
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green, lineWidth: 1))
            }
        }
    }
}

// MARK: - Org row

struct OrgRowView: View {
    let org: Organization
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(org.name).font(.headline).foregroundStyle(.white)
                    if orgStore.currentOrg?.id == org.id {
                        Text(lm["orgs.active_badge"])
                            .font(.caption2.weight(.semibold)).foregroundStyle(.black)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green).clipShape(Capsule())
                    }
                }
                Text(org.myRole == .admin ? lm["orgs.role_admin"] : lm["orgs.role_member"])
                    .font(.caption).foregroundStyle(.gray)
            }
            Spacer()
            Button {
                orgStore.selectOrg(org)
            } label: {
                Text(lm["orgs.switch_btn"])
                    .font(.caption.weight(.semibold)).foregroundStyle(.green)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Create org sheet

struct CreateOrgSheet: View {
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    @State private var orgName = ""

    private var isValid: Bool { !orgName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: lm["orgs.create_name_label"])
                    FormTextField(placeholder: lm["orgs.create_name_placeholder"], text: $orgName)
                        .autocorrectionDisabled()

                    Text(lm["orgs.create_hint"])
                        .font(.caption).foregroundStyle(.gray)

                    if let err = orgStore.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            await orgStore.createOrg(
                                name: orgName,
                                uid: auth.currentUser?.uid ?? "",
                                displayName: auth.userProfile?.displayName ?? "",
                                email: auth.userProfile?.email ?? ""
                            )
                            if orgStore.errorMessage == nil { dismiss() }
                        }
                    } label: {
                        Group {
                            if orgStore.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(lm["orgs.create_btn"])
                                    .font(.body.weight(.semibold)).foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(isValid && !orgStore.isLoading ? Color.green : Color.green.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isValid || orgStore.isLoading)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(lm["orgs.create_sheet_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm["add.cancel"]) {
                        orgStore.errorMessage = nil
                        dismiss()
                    }.foregroundStyle(.green)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Join org sheet

struct JoinOrgSheet: View {
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    @State private var searchName  = ""
    @State private var requestSent = false

    private var isValid: Bool { !searchName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {

                    SectionHeader(title: lm["orgs.join_name_label"])
                    FormTextField(placeholder: lm["orgs.join_name_placeholder"], text: $searchName)
                        .autocorrectionDisabled()

                    Text(lm["orgs.join_hint"])
                        .font(.caption).foregroundStyle(.gray)

                    if let err = orgStore.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }

                    if requestSent {
                        Label(lm["orgs.request_sent"], systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }

                    Button {
                        Task {
                            await orgStore.requestToJoin(
                                orgName: searchName,
                                uid: auth.currentUser?.uid ?? "",
                                displayName: auth.userProfile?.displayName ?? "",
                                email: auth.userProfile?.email ?? ""
                            )
                            if orgStore.errorMessage == nil {
                                requestSent = true
                            }
                        }
                    } label: {
                        Group {
                            if orgStore.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(lm["orgs.join_btn"])
                                    .font(.body.weight(.semibold)).foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(isValid && !orgStore.isLoading && !requestSent
                                    ? Color.green : Color.green.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isValid || orgStore.isLoading || requestSent)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(lm["orgs.join_sheet_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm["add.cancel"]) {
                        orgStore.errorMessage = nil
                        dismiss()
                    }.foregroundStyle(.green)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
