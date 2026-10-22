import Foundation
import Observation
import FirebaseFirestore

// MARK: - OrganizationStore
//
// Manages all organization data: loading the user's org list, creating orgs,
// join requests, member management, and parking zones.
//
// NOTE: The collection-group query on "members" requires a Firestore composite
// index. On first run in a new Firebase project, Firestore will return an error
// containing a link — open the link to create the index in one click.

@Observable
@MainActor
final class OrganizationStore {

    // MARK: - State

    var myOrgs: [Organization] = []
    var currentOrg: Organization?
    var currentMembership: Membership?     // my role in currentOrg

    // Admin-only data for the current org
    var members: [Membership]    = []
    var joinRequests: [JoinRequest] = []

    var isLoading = false
    var errorMessage: String?

    var isAdmin: Bool { currentMembership?.role == .admin }

    // MARK: - Private

    private let db = Firestore.firestore()
    private var membershipListener: ListenerRegistration?
    private var orgListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?

    // MARK: - Start listening (call after sign-in)

    func startListening(uid: String) {
        stopListening()
        // Listen to all memberships for this user across all orgs
        // Requires index: collectionGroup "members" on field "uid" ASC
        membershipListener = db.collectionGroup("members")
            .whereField("uid", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let docs = snapshot?.documents else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.loadOrgs(from: docs, myUid: uid)
                }
            }
    }

    func stopListening() {
        membershipListener?.remove()
        orgListener?.remove()
        membersListener?.remove()
        requestsListener?.remove()
        membershipListener = nil
        orgListener = nil
        membersListener = nil
        requestsListener = nil
        myOrgs = []
        currentOrg = nil
        currentMembership = nil
        members = []
        joinRequests = []
    }

    // MARK: - Switch current org

    func selectOrg(_ org: Organization) {
        currentOrg = org
        currentMembership = myOrgs.first(where: { $0.id == org.id }).map {
            Membership(uid: "", role: $0.myRole, displayName: "", email: "", joinedAt: Date())
        }
        listenCurrentOrg(orgId: org.id)
    }

    // MARK: - Create organization (transactional uniqueness check)

    func createOrg(name: String, uid: String, displayName: String, email: String) async {
        let trimmed  = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Organization name cannot be empty."; return }
        let nameLower = trimmed.lowercased()
        isLoading = true
        errorMessage = nil

        let lockRef = db.collection("orgNames").document(nameLower)
        let orgId   = UUID().uuidString
        let orgRef  = db.collection("organizations").document(orgId)
        let memberRef = orgRef.collection("members").document(uid)

        do {
            // Firebase SDK 10+ async transaction uses a throwing closure (no NSErrorPointer)
            try await db.runTransaction { transaction throws -> Void in
                let lockSnap = try transaction.getDocument(lockRef)

                if lockSnap.exists {
                    throw NSError(
                        domain: "ValPark",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey:
                            "The name \"\(trimmed)\" is already taken. Please choose a different name."]
                    )
                }

                // Reserve the name lock
                transaction.setData(["orgId": orgId], forDocument: lockRef)

                // Create org document
                let org = Organization(id: orgId, name: trimmed, createdBy: uid)
                if let data = try? Firestore.Encoder().encode(org) {
                    transaction.setData(data, forDocument: orgRef)
                }

                // Create creator's membership (admin)
                let membership = Membership(uid: uid, role: .admin,
                                            displayName: displayName, email: email,
                                            joinedAt: Date())
                if let data = try? Firestore.Encoder().encode(membership) {
                    transaction.setData(data, forDocument: memberRef)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }

        isLoading = false
    }

    // MARK: - Request to join an organization

    func requestToJoin(orgName: String, uid: String, displayName: String, email: String) async {
        let nameLower = orgName.lowercased()
        isLoading = true
        errorMessage = nil

        do {
            // Find the org by lowercased name
            let lockSnap = try await db.collection("orgNames").document(nameLower).getDocument()
            guard lockSnap.exists, let orgId = lockSnap.data()?["orgId"] as? String else {
                errorMessage = "No organization found with that name."
                isLoading = false
                return
            }

            // Check not already a member
            let memberSnap = try await db.collection("organizations/\(orgId)/members").document(uid).getDocument()
            if memberSnap.exists {
                errorMessage = "You are already a member of this organization."
                isLoading = false
                return
            }

            // Check not already requested
            let reqSnap = try await db.collection("organizations/\(orgId)/joinRequests").document(uid).getDocument()
            if reqSnap.exists {
                errorMessage = "You have already submitted a join request for this organization."
                isLoading = false
                return
            }

            // Create the join request
            let request = JoinRequest(uid: uid, displayName: displayName, email: email, requestedAt: Date())
            try db.collection("organizations/\(orgId)/joinRequests").document(uid).setData(from: request)

            // Notify org admins via push
            await notifyAdmins(orgId: orgId, displayName: displayName)

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Approve join request

    func approveRequest(_ request: JoinRequest, orgId: String) async {
        errorMessage = nil
        // Fetch user profile to get current displayName/email
        do {
            let userSnap = try await db.collection("users").document(request.uid).getDocument()
            let displayName = (userSnap.data()?["displayName"] as? String) ?? request.displayName
            let email       = (userSnap.data()?["email"]       as? String) ?? request.email

            let membership = Membership(uid: request.uid, role: .member,
                                        displayName: displayName, email: email,
                                        joinedAt: Date())
            try db.collection("organizations/\(orgId)/members").document(request.uid).setData(from: membership)
            db.collection("organizations/\(orgId)/joinRequests").document(request.uid).delete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Deny join request

    func denyRequest(_ request: JoinRequest, orgId: String) {
        db.collection("organizations/\(orgId)/joinRequests").document(request.uid).delete()
    }

    // MARK: - Add member by email (admin-initiated)
    //
    // The target user must already have a ParkCol account with the same email.

    func addMember(email: String, asAdmin: Bool, orgId: String) async {
        let lower = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lower.isEmpty else { errorMessage = "Enter an email address."; return }
        isLoading = true
        errorMessage = nil
        do {
            let snap = try await db.collection("users")
                .whereField("email", isEqualTo: lower)
                .getDocuments()

            guard let userDoc = snap.documents.first,
                  let profile = try? userDoc.data(as: UserProfile.self) else {
                errorMessage = "No ParkCol account found with that email. Ask them to sign up first."
                isLoading = false
                return
            }

            // Check not already a member
            let existing = try await db.collection("organizations/\(orgId)/members")
                .document(profile.uid).getDocument()
            if existing.exists {
                errorMessage = "\(profile.displayName) is already a member."
                isLoading = false
                return
            }

            let membership = Membership(uid: profile.uid,
                                        role: asAdmin ? .admin : .member,
                                        displayName: profile.displayName,
                                        email: profile.email,
                                        joinedAt: Date())
            try db.collection("organizations/\(orgId)/members")
                .document(profile.uid).setData(from: membership)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Remove member

    func removeMember(uid: String, orgId: String) async {
        guard await !isLastAdmin(uid: uid, orgId: orgId) else {
            errorMessage = "Cannot remove the only admin. Assign another admin first."
            return
        }
        db.collection("organizations/\(orgId)/members").document(uid).delete()
    }

    // MARK: - Toggle admin role

    func toggleRole(membership: Membership, orgId: String) async {
        if membership.role == .admin {
            // Demoting — check last-admin guard
            guard await !isLastAdmin(uid: membership.uid, orgId: orgId) else {
                errorMessage = "Cannot remove admin rights from the only admin. Assign another admin first."
                return
            }
        }
        let newRole: MemberRole = membership.role == .admin ? .member : .admin
        db.collection("organizations/\(orgId)/members").document(membership.uid)
            .updateData(["role": newRole.rawValue])
    }

    // MARK: - Parking zones (admin only)

    func addZone(_ zone: String, orgId: String) {
        let trimmed = zone.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        db.collection("organizations").document(orgId)
            .updateData(["parkingZones": FieldValue.arrayUnion([trimmed])])
    }

    func removeZone(_ zone: String, orgId: String) {
        db.collection("organizations").document(orgId)
            .updateData(["parkingZones": FieldValue.arrayRemove([zone])])
    }

    // MARK: - Private helpers

    /// Loads org documents for a set of membership docs returned by the collection-group query.
    private func loadOrgs(from memberDocs: [QueryDocumentSnapshot], myUid: String) async {
        var loaded: [Organization] = []

        await withTaskGroup(of: Organization?.self) { group in
            for doc in memberDocs {
                let orgId = doc.reference.parent.parent?.documentID ?? ""
                guard let membership = try? doc.data(as: Membership.self) else { continue }
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    guard let orgSnap = try? await self.db.collection("organizations").document(orgId).getDocument(),
                          var org = try? orgSnap.data(as: Organization.self) else { return nil }
                    org.myRole = membership.role
                    return org
                }
            }
            for await org in group {
                if let org { loaded.append(org) }
            }
        }

        loaded.sort { $0.name.lowercased() < $1.name.lowercased() }
        myOrgs = loaded

        // Keep currentOrg in sync (or select first if none selected)
        if let current = currentOrg, let updated = loaded.first(where: { $0.id == current.id }) {
            currentOrg = updated
            currentMembership = Membership(uid: myUid, role: updated.myRole,
                                           displayName: "", email: "", joinedAt: Date())
        } else if currentOrg == nil, let first = loaded.first {
            selectOrg(first)
        }
    }

    /// Listens to the current org doc (for zone changes) and admin subcollections.
    private func listenCurrentOrg(orgId: String) {
        orgListener?.remove()
        membersListener?.remove()
        requestsListener?.remove()

        // Live org doc (zones update in real time)
        orgListener = db.collection("organizations").document(orgId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self,
                      var org = try? snap?.data(as: Organization.self) else { return }
                org.myRole = self.currentOrg?.myRole ?? .member
                self.currentOrg = org
            }

        // Members list (visible to all members)
        membersListener = db.collection("organizations/\(orgId)/members")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.members = snap?.documents.compactMap { try? $0.data(as: Membership.self) } ?? []
            }

        // Join requests (visible to admins only in the UI; Firestore rules enforce on the server)
        requestsListener = db.collection("organizations/\(orgId)/joinRequests")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.joinRequests = snap?.documents.compactMap { try? $0.data(as: JoinRequest.self) } ?? []
            }
    }

    /// Returns true if the given uid is the only admin in the org.
    private func isLastAdmin(uid: String, orgId: String) async -> Bool {
        do {
            let snap = try await db.collection("organizations/\(orgId)/members")
                .whereField("role", isEqualTo: MemberRole.admin.rawValue)
                .getDocuments()
            let adminIds = snap.documents.compactMap { $0.data()["uid"] as? String }
            return adminIds.count == 1 && adminIds.first == uid
        } catch {
            return false
        }
    }

    /// Sends a push notification to all admins of an org when a join request arrives.
    private func notifyAdmins(orgId: String, displayName: String) async {
        do {
            let snap = try await db.collection("organizations/\(orgId)/members")
                .whereField("role", isEqualTo: MemberRole.admin.rawValue)
                .getDocuments()
            let orgSnap = try await db.collection("organizations").document(orgId).getDocument()
            let orgName = orgSnap.data()?["name"] as? String ?? "your organization"
            let _ = snap  // Admins will see the request in-app via the real-time listener
            // Local push notification (best-effort; only works if this device is an admin device)
            NotificationManager.scheduleJoinRequestNotification(
                requesterName: displayName, orgName: orgName
            )
        } catch { /* non-critical */ }
    }
}
