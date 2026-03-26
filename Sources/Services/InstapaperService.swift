import Foundation

final class InstapaperService {
    private let baseURL = URL(string: "https://www.instapaper.com/api/1.1")!
    private let keychainService = "com.folio.instapaper"

    struct Bookmark: Codable {
        let bookmark_id: Int
        let url: String
        let title: String?
        let description: String?
        let progress: Double?
        let progress_time: String?
    }

    struct BookmarksListResponse: Codable {
        let bookmarks: [Bookmark]?
        let error: Int?
        let error_message: String?
    }

    struct AuthResponse: Codable {
        let token: String?
        let secret: String?
        let user_id: Int?
        let error: Int?
        let error_message: String?
    }

    func verifyCredentials(username: String, password: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/account/verify_credentials") else {
            throw InstapaperError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return true
            } else if httpResponse.statusCode == 401 {
                return false
            }
        }
        return false
    }

    func importBookmarks(username: String, password: String) async throws -> [Bookmark] {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent("bookmarks/list"), resolvingAgainstBaseURL: false) else {
            throw InstapaperError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "have", value: "0")
        ]
        guard let url = urlComponents.url else { throw InstapaperError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw InstapaperError.apiError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(BookmarksListResponse.self, from: data)

        if let error = result.error, error != 0 {
            throw InstapaperError.apiError
        }

        return result.bookmarks ?? []
    }

    func addBookmark(url: URL, title: String?, username: String, password: String) async throws {
        guard let reqUrl = URL(string: "\(baseURL)/bookmarks/add") else {
            throw InstapaperError.invalidURL
        }

        var request = URLRequest(url: reqUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let loginString = "\(username):\(password)"
        request.setValue("Basic \(loginString.data(using: .utf8)!.base64EncodedString())", forHTTPHeaderField: "Authorization")
        let body = "url=\((url.absoluteString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&title=\((title ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw InstapaperError.apiError
        }
    }

    enum InstapaperError: LocalizedError {
        case invalidURL
        case apiError
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Instapaper URL"
            case .apiError: return "Instapaper API error"
            case .invalidCredentials: return "Invalid Instapaper credentials"
            }
        }
    }
}
