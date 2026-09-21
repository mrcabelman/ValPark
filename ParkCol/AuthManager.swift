import Foundation
import AuthenticationServices
import CryptoKit
import Observation

// MARK: - Models

struct GoogleUser: Codable, Equatable {
    let id: String
    let email: String
    let name: String
    let pictureURL: String?
}

enum AuthError: LocalizedError {
    case notConfigured
    case missingCode
    case tokenExchangeFailed(String)
    case userInfoDecodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Client ID not set. Open AuthManager.swift and replace REPLACE_WITH_YOUR_CLIENT_ID."
        case .missingCode:
            return "Authorization code missing from Google response."
        case .tokenExchangeFailed(let msg):
            return "Token exchange failed: \(msg)"
        case .userInfoDecodingFailed:
            return "Could not read user info from Google."
        }
    }
}

// MARK: - AuthManager

@Observable @MainActor
final class AuthManager: NSObject {

    // ─────────────────────────────────────────────────────────────
    //  SETUP REQUIRED
    //  1. Go to console.cloud.google.com → APIs & Services → Credentials
    //  2. Create OAuth 2.0 Client ID → iOS application
    //  3. Enter bundle ID: com.thelab.parkcol.ParkCol
    //  4. Paste the generated client ID below (looks like XXXXX.apps.googleusercontent.com)
    //  5. In Xcode: Target → Info → URL Types → add the REVERSED client ID
    //     e.g. if client ID is "12345-abc.apps.googleusercontent.com"
    //     the URL scheme is "com.googleusercontent.apps.12345-abc"
    // ─────────────────────────────────────────────────────────────
    static var clientID = "REPLACE_WITH_YOUR_CLIENT_ID.apps.googleusercontent.com"

    private var reversedClientID: String {
        Self.clientID.components(separatedBy: ".").reversed().joined(separator: ".")
    }

    // Observed state
    var currentUser: GoogleUser?
    var isLoading = false
    var errorMessage: String?

    var isSignedIn: Bool { currentUser != nil }

    // Stored tokens (UserDefaults – upgrade to Keychain for production)
    @ObservationIgnored private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "gAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "gAccessToken") }
    }
    @ObservationIgnored private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "gRefreshToken") }
        set { UserDefaults.standard.set(newValue, forKey: "gRefreshToken") }
    }
    @ObservationIgnored private var authSession: ASWebAuthenticationSession?
    @ObservationIgnored private let contextProvider = _AuthContextProvider()

    override init() {
        super.init()
        // Restore saved user
        if let data = UserDefaults.standard.data(forKey: "gUser"),
           let user = try? JSONDecoder().decode(GoogleUser.self, from: data) {
            currentUser = user
        }
    }

    // MARK: - Public API

    func signIn() async {
        guard !Self.clientID.hasPrefix("REPLACE") else {
            errorMessage = AuthError.notConfigured.errorDescription
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let (user, tokens) = try await performSignIn()
            persist(user: user, tokens: tokens)
            currentUser = user
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User dismissed – no error shown
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        currentUser = nil
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "gUser")
    }

    /// Returns a valid access token, silently refreshing if needed.
    func validAccessToken() async -> String? {
        if let token = accessToken { return token }
        guard let refresh = refreshToken else { return nil }
        return await refreshAccessToken(using: refresh)
    }

    // MARK: - Private sign-in flow

    private func performSignIn() async throws -> (GoogleUser, TokenResponse) {
        let verifier = PKCE.verifier()
        let challenge = PKCE.challenge(from: verifier)

        let authURL = buildAuthURL(challenge: challenge)
        let callbackURL = try await openBrowser(url: authURL)

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw AuthError.missingCode }

        let tokens = try await exchangeCode(code, verifier: verifier)
        let user = try decodeIDToken(tokens.id_token)
        return (user, tokens)
    }

    private func buildAuthURL(challenge: String) -> URL {
        var c = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        c.queryItems = [
            URLQueryItem(name: "client_id",             value: Self.clientID),
            URLQueryItem(name: "redirect_uri",          value: "\(reversedClientID):/oauth2redirect"),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: "openid email profile https://www.googleapis.com/auth/drive.appdata"),
            URLQueryItem(name: "code_challenge",        value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type",           value: "offline"),
            URLQueryItem(name: "prompt",                value: "consent"),
        ]
        return c.url!
    }

    private func openBrowser(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: reversedClientID
            ) { callbackURL, error in
                if let error { continuation.resume(throwing: error) }
                else if let url = callbackURL { continuation.resume(returning: url) }
            }
            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = true
            authSession = session
            session.start()
        }
    }

    private func exchangeCode(_ code: String, verifier: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var c = URLComponents()
        c.queryItems = [
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "client_id",     value: Self.clientID),
            URLQueryItem(name: "redirect_uri",  value: "\(reversedClientID):/oauth2redirect"),
            URLQueryItem(name: "grant_type",    value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier),
        ]
        request.httpBody = c.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw AuthError.tokenExchangeFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func refreshAccessToken(using refreshToken: String) async -> String? {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var c = URLComponents()
        c.queryItems = [
            URLQueryItem(name: "client_id",     value: Self.clientID),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "grant_type",    value: "refresh_token"),
        ]
        request.httpBody = c.percentEncodedQuery?.data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONDecoder().decode(RefreshResponse.self, from: data) else { return nil }

        accessToken = json.access_token
        return json.access_token
    }

    private func decodeIDToken(_ token: String) throws -> GoogleUser {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { throw AuthError.userInfoDecodingFailed }

        var b64 = parts[1]
        while b64.count % 4 != 0 { b64 += "=" }
        guard let data = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub   = json["sub"]   as? String,
              let email = json["email"] as? String,
              let name  = json["name"]  as? String
        else { throw AuthError.userInfoDecodingFailed }

        return GoogleUser(id: sub, email: email, name: name, pictureURL: json["picture"] as? String)
    }

    private func persist(user: GoogleUser, tokens: TokenResponse) {
        accessToken  = tokens.access_token
        refreshToken = tokens.refresh_token ?? refreshToken
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "gUser")
        }
    }
}

// MARK: - Supporting types

private struct TokenResponse: Decodable {
    let access_token: String
    let id_token: String
    let refresh_token: String?
}

private struct RefreshResponse: Decodable {
    let access_token: String
}

private enum PKCE {
    static func verifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func challenge(from verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// Separate NSObject subclass so AuthManager doesn't need to be NSObject
private final class _AuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
