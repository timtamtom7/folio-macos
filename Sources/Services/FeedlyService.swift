import Foundation
import KeychainAccess
import AppKit

final class FeedlyService: ObservableObject {
    static let shared = FeedlyService()

    private let keychain = Keychain(service: "com.folio.feedly")
    private let clientId = "foliords"
    private let redirectURI = "foliords://auth/feedly"
    private let authURL = URL(string: "https://feedly.com/v3/auth/auth")!

    @Published var isConnected = false
    @Published var lastSyncedAt: Date?
    @Published var userId: String?

    private init() {
        loadCredentials()
    }

    func loadCredentials() {
        if let connected = try? keychain.get("connected"), connected == "true",
           let userId = try? keychain.get("userId") {
            self.userId = userId
            self.isConnected = true
        }
    }

    func startOAuth() {
        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "https://cloud.feedly.com/subscriptions")
        ]
        NSWorkspace.shared.open(components.url!)
    }

    func handleOAuthCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw FeedlyError.invalidCallback
        }

        // Exchange code for token (would need a server-side component in production)
        // For now, store the code and show connected state
        try? keychain.set(code, key: "authCode")
        try? keychain.set("true", key: "connected")

        await MainActor.run {
            self.isConnected = true
            self.userId = "feedly_user"
        }
    }

    func disconnect() {
        try? keychain.remove("accessToken")
        try? keychain.remove("refreshToken")
        try? keychain.remove("connected")
        try? keychain.remove("userId")
        isConnected = false
        userId = nil
    }

    func getAccessToken() -> String? {
        try? keychain.get("accessToken")
    }

    func getRefreshToken() -> String? {
        try? keychain.get("refreshToken")
    }

    func refreshAccessTokenIfNeeded() async throws {
        guard let refresh = getRefreshToken() else { return }

        guard var components = URLComponents(url: URL(string: "https://cloud.feedly.com/v3/auth/token")!, resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [
            URLQueryItem(name: "refresh_token", value: refresh),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: clientId)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(FeedlyTokenResponse.self, from: data)

        try? keychain.set(result.accessToken, key: "accessToken")
        if let newRefresh = result.refreshToken {
            try? keychain.set(newRefresh, key: "refreshToken")
        }
    }

    func syncCategories() async throws {
        guard let token = getAccessToken() else { throw FeedlyError.notAuthenticated }

        guard let url = URL(string: "https://cloud.feedly.com/v3/categories") else {
            throw FeedlyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let categories = try JSONDecoder().decode([FeedlyCategory].self, from: data)

        for category in categories {
            let cat = Category(
                id: UUID(),
                name: category.label ?? category.id,
                sortOrder: 0,
                colorHex: "#007AFF"
            )
            SQLiteFeedStore().saveCategory(cat)
        }
    }

    struct FeedlyCategory: Codable {
        let id: String
        let label: String?
    }

    struct FeedlyTokenResponse: Codable {
        let accessToken: String
        let refreshToken: String?
        let tokenType: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
        }
    }

    enum FeedlyError: LocalizedError {
        case invalidURL
        case invalidCallback
        case notAuthenticated
        case tokenRefreshFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Feedly URL"
            case .invalidCallback: return "Invalid OAuth callback"
            case .notAuthenticated: return "Not connected to Feedly"
            case .tokenRefreshFailed: return "Failed to refresh Feedly token"
            }
        }
    }
}
