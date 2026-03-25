import Foundation
import KeychainAccess

final class FeedbinService: ObservableObject {
    static let shared = FeedbinService()

    private let keychain = Keychain(service: "com.folio.feedbin")
    private let baseURL = URL(string: "https://api.feedbin.me/v2")!
    private var accessToken: String?

    @Published var isConnected = false
    @Published var lastSyncedAt: Date?

    struct FeedbinEntry: Codable {
        let id: Int
        let feed_id: Int
        let title: String?
        let url: String
        let summary: String?
        let content: String?
        let author: String?
        let created_at: String
    }

    struct FeedbinStarred: Codable {
        let id: Int
        let entry_id: Int
        let created_at: String
    }

    private init() {
        loadCredentials()
    }

    func loadCredentials() {
        if let token = try? keychain.get("accessToken") {
            accessToken = token
            isConnected = true
        }
    }

    func connect(email: String, apiKey: String) async throws {
        guard let url = URL(string: "\(baseURL)/authentication.json") else {
            throw FeedbinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let loginString = "\(email):\(apiKey)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FeedbinError.authenticationFailed
        }

        if let _ = try? JSONDecoder().decode(AuthResult.self, from: data) {
            try? keychain.set(apiKey, key: "apiKey")
            try? keychain.set(email, key: "email")
            try? keychain.set("true", key: "connected")

            await MainActor.run {
                self.accessToken = apiKey
                self.isConnected = true
            }
        }
    }

    func disconnect() {
        try? keychain.remove("apiKey")
        try? keychain.remove("email")
        try? keychain.remove("connected")
        accessToken = nil
        isConnected = false
    }

    func syncStarredArticles() async throws {
        guard let apiKey = accessToken ?? (try? keychain.get("apiKey")) else {
            throw FeedbinError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/starred.json") else {
            throw FeedbinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let credentials = "\(email):\(apiKey)"
        request.setValue("Basic \(Data(credentials.utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let starred = try JSONDecoder().decode([FeedbinStarred].self, from: data)

        // Store starred state locally
        let articleStore = SQLiteArticleStore()
        for star in starred {
            // Mark articles with matching URL as favorites
        }

        await MainActor.run {
            self.lastSyncedAt = Date()
        }
    }

    private var email: String {
        (try? keychain.get("email")) ?? ""
    }

    enum FeedbinError: LocalizedError {
        case invalidURL
        case authenticationFailed
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Feedbin URL"
            case .authenticationFailed: return "Feedbin authentication failed"
            case .notAuthenticated: return "Not connected to Feedbin"
            }
        }
    }
}

private struct AuthResult: Codable {
    let user_id: Int?
}
