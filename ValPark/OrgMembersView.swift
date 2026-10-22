import SwiftUI

// Admin-only management view for an organization.
// Accessible from Settings → Manage Organization.
// Regular members see a read-only member list.

struct OrgMembersView: View {
    let org: Organization
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    @State private var addEmail   = ""
    @State private var addAsAdmin = false
    @State private var newZone    = ""
    @FocusState private var zoneFieldFocused: Bool
    @FocusState private var emailFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Pending join requests (admin only) ────────────────
                    if orgStore.isAdmin && !orgStore.joinRequests.isEmpty {
                        sectionLabel(lm["members.requests_section"])
                        VStack(spacing: 0) {
                            ForEach(orgStore.joinRequests) { req in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(req.displayName).foregroundStyle(.white).font(.headline)
                                        Text(req.email).foregroundStyle(.gray).font(.caption)
                                    }
                                    Spacer()
                                    Button(lm["members.deny"]) {
                                        orgStore.denyRequest(req, orgId: org.id)
                                    }
                                    .font(.subheadline).foregroundStyle(.red)
                                    .padding(.trailing, 8)

                                    Button(lm["members.approve"]) {
                                        Task { await orgStore.approveRequest(req, orgId: org.id) }
                                    }
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.black)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                if req.id != orgStore.joinRequests.last?.id {
                                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color(UIColor.systemGray6).opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // ── Members list ──────────────────────────────────────
                    sectionLabel(lm["members.members_section"])
                    if orgStore.members.isEmpty {
                        Text(lm["members.no_members"])
                            .foregroundStyle(.gray).font(.subheadline)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(orgStore.members) { member in
                                MemberRowView(member: member, orgId: org.id,
                                              isCurrentUser: member.uid == auth.currentUser?.uid)
                                if member.id != orgStore.members.last?.id {
                                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color(UIColor.systemGray6).opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // ── Add member by email (admin only) ──────────────────
                    if orgStore.isAdmin {
                        sectionLabel(lm["members.add_section"])
                        VStack(alignment: .leading, spacing: 12) {
                            FormTextField(placeholder: lm["members.add_email_placeholder"], text: $addEmail)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($emailFieldFocused)

                            HStack {
                                Text(lm["members.add_as_admin"])
                                    .foregroundStyle(.white)
                                Spacer()
                                Toggle("", isOn: $addAsAdmin).tint(.green).labelsHidden()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color(UIColor.systemGray6).opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                Task {
                                    await orgStore.addMember(email: addEmail, asAdmin: addAsAdmin, orgId: org.id)
                                    if orgStore.errorMessage == nil {
                                        addEmail = ""
                                        addAsAdmin = false
                                        emailFieldFocused = false
                                    }
                                }
                            } label: {
                                Group {
                                    if orgStore.isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text(lm["members.add_btn"])
                                            .font(.body.weight(.semibold)).foregroundStyle(.black)
                                    }
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(!addEmail.isEmpty && !orgStore.isLoading
                                            ? Color.green : Color.green.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(addEmail.isEmpty || orgStore.isLoading)
                        }

                        if let err = orgStore.errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }

                    // ── Parking zones (admin only) ────────────────────────
                    if orgStore.isAdmin {
                        sectionLabel(lm["settings.zones"])
                        if let zones = orgStore.currentOrg?.parkingZones, !zones.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(zones, id: \.self) { zone in
                                    HStack {
                                        Label(zone, systemImage: "mappin").foregroundStyle(.white)
                                        Spacer()
                                        Button(lm["settings.remove"]) {
                                            orgStore.removeZone(zone, orgId: org.id)
                                        }
                                        .font(.subheadline).foregroundStyle(.red)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    if zone != zones.last {
                                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color(UIColor.systemGray6).opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        HStack(spacing: 10) {
                            FormTextField(placeholder: lm["settings.new_zone"], text: $newZone)
                                .focused($zoneFieldFocused)
                            Button(lm["settings.add"]) {
                                orgStore.addZone(newZone, orgId: org.id)
                                newZone = ""
                                zoneFieldFocused = false
                            }
                            .font(.body.weight(.semibold)).foregroundStyle(.black)
                            .frame(width: 72, height: 48)
                            .background(newZone.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.green.opacity(0.4) : Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .disabled(newZone.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(org.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.gray)
    }
}

// MARK: - Member row

struct MemberRowView: View {
    let member: Membership
    let orgId: String
    let isCurrentUser: Bool
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(LocalizationManager.self) private var lm

    @State private var showRemoveConfirm = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.headline).foregroundStyle(.white)
                    if isCurrentUser {
                        Text(lm["members.you_badge"])
                            .font(.caption2.weight(.semibold)).foregroundStyle(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green).clipShape(Capsule())
                    }
                }
                Text(member.email).font(.caption).foregroundStyle(.gray)
            }
            Spacer()

            // Role badge / toggle (admin only)
            if orgStore.isAdmin && !isCurrentUser {
                VStack(spacing: 4) {
                    Button {
                        Task { await orgStore.toggleRole(membership: member, orgId: orgId) }
                    } label: {
                        Text(member.role == .admin ? lm["members.remove_admin"] : lm["members.make_admin"])
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(member.role == .admin ? .orange : .green)
                    }

                    Button {
                        showRemoveConfirm = true
                    } label: {
                        Text(lm["settings.remove"])
                            .font(.caption.weight(.semibold)).foregroundStyle(.red)
                    }
                }
            } else {
                // Role badge (read-only)
                Text(member.role == .admin ? lm["orgs.role_admin"] : lm["orgs.role_member"])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(member.role == .admin ? .orange : .gray)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((member.role == .admin ? Color.orange : Color.gray).opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .confirmationDialog(lm["members.remove_confirm"], isPresented: $showRemoveConfirm,
                            titleVisibility: .visible) {
            Button(lm["settings.remove"], role: .destructive) {
                Task { await orgStore.removeMember(uid: member.uid, orgId: orgId) }
            }
            Button(lm["details.keep"], role: .cancel) {}
        }
    }
}
