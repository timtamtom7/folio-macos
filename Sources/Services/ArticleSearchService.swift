import Foundation
import SQLite

final class ArticleSearchService {
    private var db: Connection? { DatabaseManager.shared.getConnection() }

    func search(query: String, scope: SearchScope = .all, feedId: UUID? = nil, categoryId: UUID? = nil) -> [Article] {
        guard let db = db, !query.isEmpty else { return [] }

        let articles = Table("articles")
        let id = SQLite.Expression<String>("id")
        let fkFeedId = SQLite.Expression<String>("feed_id")
        let articleTitle = SQLite.Expression<String>("title")
        let articleUrl = SQLite.Expression<String>("url")
        let author = SQLite.Expression<String?>("author")
        let summary = SQLite.Expression<String?>("summary")
        let content = SQLite.Expression<String?>("content")
        let imageUrl = SQLite.Expression<String?>("image_url")
        let publishedAt = SQLite.Expression<String>("published_at")
        let isRead = SQLite.Expression<Bool>("is_read")
        let isFavorite = SQLite.Expression<Bool>("is_favorite")
        let readAt = SQLite.Expression<String?>("read_at")

        let formatter = ISO8601DateFormatter()
        let pattern = "%\(query)%"

        var queryBuilder = articles.filter(articleTitle.like(pattern) || content.like(pattern) || summary.like(pattern))

        if let feedId = feedId, scope != .all {
            queryBuilder = queryBuilder.filter(fkFeedId == feedId.uuidString)
        }

        let searchQuery = queryBuilder.order(SQLite.Expression<String>("published_at").desc).limit(50)

        var results: [Article] = []
        do {
            for row in try db.prepare(searchQuery) {
                guard let articleUrl = URL(string: row[articleUrl]) else { continue }
                let article = Article(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    feedId: UUID(uuidString: row[fkFeedId]) ?? UUID(),
                    title: row[articleTitle],
                    url: articleUrl,
                    author: row[author],
                    summary: row[summary],
                    content: row[content],
                    imageUrl: row[imageUrl].flatMap { URL(string: $0) },
                    publishedAt: formatter.date(from: row[publishedAt]) ?? Date(),
                    isRead: row[isRead],
                    isFavorite: row[isFavorite],
                    readAt: row[readAt].flatMap { formatter.date(from: $0) }
                )
                results.append(article)
            }
        } catch {
            print("ArticleSearchService error: \(error)")
        }
        return results
    }

    enum SearchScope: String, CaseIterable {
        case all = "All"
        case currentFeed = "Current Feed"
        case currentCategory = "Current Category"
    }
}

final class RecentSearchesStore {
    private let key = "recentSearches"
    static let maxRecent = 10

    var recentSearches: [String] {
        get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
        set {
            UserDefaults.standard.set(Array(newValue.prefix(Self.maxRecent)), forKey: key)
        }
    }

    func add(_ query: String) {
        var searches = recentSearches.filter { $0 != query }
        searches.insert(query, at: 0)
        recentSearches = searches
    }

    func clear() {
        recentSearches = []
    }
}
