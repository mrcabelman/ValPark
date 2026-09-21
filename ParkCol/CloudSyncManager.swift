import Foundation

// Syncs AppSettings to the user's Google Drive App Data folder.
// Stores a single file named "parkcol_settings.json" that is private
// to this app and invisible to the user in Google Drive.

struct CloudSyncManager {

    struct SyncedSettings: Codable {
        var parkingZones: [String]
        var language: String
    }

    private static let fileName = "parkcol_settings.json"
    private static let baseURL  = "https://www.googleapis.com"

    // MARK: - Public

    static func load(accessToken: String) async -> SyncedSettings? {
        guard let fileID = await findFileID(token: accessToken) else { return nil }
        return await downloadFile(id: fileID, token: accessToken)
    }

    static func save(_ settings: SyncedSettings, accessToken: String) async {
        if let fileID = await findFileID(token: accessToken) {
            await updateFile(id: fileID, settings: settings, token: accessToken)
        } else {
            await createFile(settings: settings, token: accessToken)
        }
    }

    // MARK: - Drive API helpers

    private static func findFileID(token: String) async -> String? {
        var c = URLComponents(string: "\(baseURL)/drive/v3/files")!
        c.queryItems = [
            URLQueryItem(name: "spaces", value: "appDataFolder"),
            URLQueryItem(name: "q",      value: "name='\(fileName)'"),
            URLQueryItem(name: "fields", value: "files(id)"),
        ]
        var req = URLRequest(url: c.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let resp = try? JSONDecoder().decode(FileListResponse.self, from: data),
              let first = resp.files.first else { return nil }
        return first.id
    }

    private static func downloadFile(id: String, token: String) async -> SyncedSettings? {
        let url = URL(string: "\(baseURL)/drive/v3/files/\(id)?alt=media")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return try? JSONDecoder().decode(SyncedSettings.self, from: data)
    }

    private static func createFile(settings: SyncedSettings, token: String) async {
        guard let body = try? JSONEncoder().encode(settings) else { return }
        let boundary = "ParkColBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

        let url = URL(string: "\(baseURL)/upload/drive/v3/files?uploadType=multipart")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let meta = #"{"name":""# + fileName + #"","parents":["appDataFolder"]}"#
        var mp = Data()
        mp.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        mp.append(meta.data(using: .utf8)!)
        mp.append("\r\n--\(boundary)\r\nContent-Type: application/json\r\n\r\n".data(using: .utf8)!)
        mp.append(body)
        mp.append("\r\n--\(boundary)--".data(using: .utf8)!)
        req.httpBody = mp

        _ = try? await URLSession.shared.data(for: req)
    }

    private static func updateFile(id: String, settings: SyncedSettings, token: String) async {
        guard let body = try? JSONEncoder().encode(settings) else { return }
        let url = URL(string: "\(baseURL)/upload/drive/v3/files/\(id)?uploadType=media")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        _ = try? await URLSession.shared.data(for: req)
    }
}

private struct FileListResponse: Decodable {
    let files: [DriveFile]
}
private struct DriveFile: Decodable {
    let id: String
}
