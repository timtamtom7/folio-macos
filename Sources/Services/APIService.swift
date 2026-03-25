import Foundation

// MARK: - API Server (for third-party developers)

final class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.folio.app/v1"
    private var apiKey: String?
    
    private init() {
        // Load saved API key
        apiKey = UserDefaults.standard.string(forKey: "folio_api_key")
    }
    
    // MARK: - API Key Management
    
    func generateAPIKey() -> String {
        let key = "fap_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        apiKey = key
        UserDefaults.standard.set(key, forKey: "folio_api_key")
        return key
    }
    
    func revokeAPIKey() {
        apiKey = nil
        UserDefaults.standard.removeObject(forKey: "folio_api_key")
    }
    
    var hasAPIKey: Bool {
        apiKey != nil
    }
    
    // MARK: - API Endpoints
    
    struct APIArticle: Codable {
        let id: String
        let title: String
        let url: String
        let author: String?
        let feedId: String
        let publishedAt: String
        let isRead: Bool
        let isFavorite: Bool
    }
    
    struct APIFeed: Codable {
        let id: String
        let title: String
        let url: String
        let siteUrl: String?
        let addedAt: String
    }
    
    struct APIError: Error {
        let message: String
        let code: Int
    }
    
    // MARK: - API Methods
    
    func getArticles(limit: Int = 20, offset: Int = 0) throws -> [APIArticle] {
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .all)
        
        return Array(articles.dropFirst(offset).prefix(limit)).map { article in
            APIArticle(
                id: article.id.uuidString,
                title: article.title,
                url: article.url.absoluteString,
                author: article.author,
                feedId: article.feedId.uuidString,
                publishedAt: ISO8601DateFormatter().string(from: article.publishedAt),
                isRead: article.isRead,
                isFavorite: article.isFavorite
            )
        }
    }
    
    func getArticle(id: String) throws -> APIArticle? {
        guard let uuid = UUID(uuidString: id) else {
            throw APIError(message: "Invalid article ID", code: 400)
        }
        
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.searchArticles(query: "")
        
        guard let article = articles.first(where: { $0.id == uuid }) else {
            return nil
        }
        
        return APIArticle(
            id: article.id.uuidString,
            title: article.title,
            url: article.url.absoluteString,
            author: article.author,
            feedId: article.feedId.uuidString,
            publishedAt: ISO8601DateFormatter().string(from: article.publishedAt),
            isRead: article.isRead,
            isFavorite: article.isFavorite
        )
    }
    
    func markArticleRead(id: String, isRead: Bool) throws {
        guard let uuid = UUID(uuidString: id) else {
            throw APIError(message: "Invalid article ID", code: 400)
        }
        
        let articleStore = SQLiteArticleStore()
        if isRead {
            articleStore.markRead(articleId: uuid)
        } else {
            articleStore.toggleRead(articleId: uuid)
        }
    }
    
    func getFeeds() throws -> [APIFeed] {
        let feedStore = SQLiteFeedStore()
        let feeds = feedStore.getAllFeeds()
        
        return feeds.map { feed in
            APIFeed(
                id: feed.id.uuidString,
                title: feed.title,
                url: feed.url.absoluteString,
                siteUrl: feed.siteUrl?.absoluteString,
                addedAt: ISO8601DateFormatter().string(from: feed.addedAt)
            )
        }
    }
    
    func addFeed(url: String) throws -> APIFeed {
        guard let feedURL = URL(string: url) else {
            throw APIError(message: "Invalid feed URL", code: 400)
        }
        
        let feed = Feed(
            id: UUID(),
            url: feedURL,
            title: "New Feed",
            addedAt: Date()
        )
        
        let feedStore = SQLiteFeedStore()
        feedStore.saveFeed(feed)
        
        return APIFeed(
            id: feed.id.uuidString,
            title: feed.title,
            url: feed.url.absoluteString,
            siteUrl: feed.siteUrl?.absoluteString,
            addedAt: ISO8601DateFormatter().string(from: feed.addedAt)
        )
    }
    
    func getAnalytics() throws -> [String: Any] {
        let analyticsService = AnalyticsService.shared
        let stats = analyticsService.getStatistics()
        
        return [
            "totalArticlesRead": stats.totalArticlesRead,
            "totalMinutesRead": stats.totalMinutesRead,
            "averageArticlesPerDay": stats.averageArticlesPerDay,
            "currentStreak": stats.currentStreak,
            "longestStreak": stats.longestStreak
        ]
    }
}
