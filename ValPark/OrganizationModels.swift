import Foundation

// MARK: - Role

enum MemberRole: String, Codable, CaseIterable {
    case admin  = "admin"
    case member = "member"
}

// MARK: - User Profile (stored at users/{uid})

struct UserProfile: Identifiable, Codable {
    var uid: String
    var displayName: String
    var email: String          // always lowercased
    var photoURL: String?
    var createdAt: Date

    var id: String { uid }
}

// MARK: - Organization (stored at organizations/{orgId})

struct Organization: Identifiable, Codable {
    var id: String
    var name: String
    var nameLower: String
    var createdBy: String      // uid of creator
    var createdAt: Date
    var parkingZones: [String]

    // Not persisted — populated from the accompanying membership document
    var myRole: MemberRole = .member

    init(id: String = UUID().uuidString,
         name: String,
         createdBy: String,
         parkingZones: [String] = []) {
        self.id          = id
        self.name        = name
        self.nameLower   = name.lowercased()
        self.createdBy   = createdBy
        self.createdAt   = Date()
        self.parkingZones = parkingZones
    }

    // Exclude myRole from Firestore encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, name, nameLower, createdBy, createdAt, parkingZones
    }
}

// MARK: - Membership (stored at organizations/{orgId}/members/{uid})

struct Membership: Identifiable, Codable {
    var uid: String
    var role: MemberRole
    var displayName: String
    var email: String
    var joinedAt: Date

    var id: String { uid }

    // Populated from the Firestore path when loading via collection-group query
    var orgId: String = ""

    enum CodingKeys: String, CodingKey {
        case uid, role, displayName, email, joinedAt
    }
}

// MARK: - Join Request (stored at organizations/{orgId}/joinRequests/{uid})

struct JoinRequest: Identifiable, Codable {
    var uid: String
    var displayName: String
    var email: String
    var requestedAt: Date

    var id: String { uid }
}
