import Foundation
import SQLite

class SQLiteArticleStore {
    private var db: Connection? { DatabaseManager.shared.getConnection() }

    func saveArticle(_ article: Article, feedId: UUID) {
        guard let db = db else { return }

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

        do {
            try db.run(articles.insert(or: .ignore,
                id <- article.id.uuidString,
                fkFeedId <- feedId.uuidString,
                articleTitle <- article.title,
                articleUrl <- article.url.absoluteString,
                author <- article.author,
                summary <- article.summary,
                content <- article.content,
                imageUrl <- article.imageUrl?.absoluteString,
                publishedAt <- formatter.string(from: article.publishedAt),
                isRead <- article.isRead,
                isFavorite <- article.isFavorite,
                readAt <- article.readAt.map { formatter.string(from: $0) }
            ))
        } catch {
            print("Error saving article: \(error)")
        }
    }

    func getArticles(feedId: UUID?, categoryId: UUID?, filter: ArticleListViewModel.FilterMode) -> [Article] {
        guard let db = db else { return [] }

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

        var query = articles.order(SQLite.Expression<String>("published_at").desc)

        if let feedId = feedId {
            query = query.filter(fkFeedId == feedId.uuidString)
        }

        switch filter {
        case .unread:
            query = query.filter(isRead == false)
        case .favorites:
            query = query.filter(isFavorite == true)
        default:
            break
        }

        var result: [Article] = []
        do {
            for row in try db.prepare(query.limit(50)) {
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
                result.append(article)
            }
        } catch {
            print("Error getting articles: \(error)")
        }
        return result
    }

    func markRead(articleId: UUID) {
        guard let db = db else { return }

        let articles = Table("articles")
        let id = SQLite.Expression<String>("id")
        let isRead = SQLite.Expression<Bool>("is_read")
        let readAt = SQLite.Expression<String?>("read_at")

        let formatter = ISO8601DateFormatter()

        let articleRow = articles.filter(id == articleId.uuidString)
        do {
            try db.run(articleRow.update(
                isRead <- true,
                readAt <- formatter.string(from: Date())
            ))
        } catch {
            print("Error marking article as read: \(error)")
        }
    }

    func toggleRead(articleId: UUID) {
        guard let db = db else { return }

        let articles = Table("articles")
        let id = SQLite.Expression<String>("id")
        let isRead = SQLite.Expression<Bool>("is_read")
        let readAt = SQLite.Expression<String?>("read_at")

        let formatter = ISO8601DateFormatter()

        let articleRow = articles.filter(id == articleId.uuidString)
        do {
            if let row = try db.pluck(articleRow) {
                let currentlyRead = row[isRead]
                try db.run(articleRow.update(
                    isRead <- !currentlyRead,
                    readAt <- currentlyRead ? nil : formatter.string(from: Date())
                ))
            }
        } catch {
            print("Error toggling read state: \(error)")
        }
    }

    func toggleFavorite(articleId: UUID) {
        guard let db = db else { return }

        let articles = Table("articles")
        let id = SQLite.Expression<String>("id")
        let isFavorite = SQLite.Expression<Bool>("is_favorite")

        let articleRow = articles.filter(id == articleId.uuidString)
        do {
            if let row = try db.pluck(articleRow) {
                try db.run(articleRow.update(isFavorite <- !row[isFavorite]))
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    func getUnreadCount() -> Int {
        guard let db = db else { return 0 }

        let articles = Table("articles")
        let isRead = SQLite.Expression<Bool>("is_read")

        do {
            return try db.scalar(articles.filter(isRead == false).count)
        } catch {
            print("Error getting unread count: \(error)")
            return 0
        }
    }

    func getUnreadCount(forFeed feedId: UUID) -> Int {
        guard let db = db else { return 0 }

        let articles = Table("articles")
        let fkFeedId = SQLite.Expression<String>("feed_id")
        let isRead = SQLite.Expression<Bool>("is_read")

        do {
            return try db.scalar(articles.filter(fkFeedId == feedId.uuidString && isRead == false).count)
        } catch {
            print("Error getting unread count for feed: \(error)")
            return 0
        }
    }

    func deleteArticles(forFeed feedId: UUID) {
        guard let db = db else { return }

        let articles = Table("articles")
        let fkFeedId = SQLite.Expression<String>("feed_id")

        let articleRows = articles.filter(fkFeedId == feedId.uuidString)
        do {
            try db.run(articleRows.delete())
        } catch {
            print("Error deleting articles: \(error)")
        }
    }

    func searchArticles(query: String) -> [Article] {
        guard let db = db else { return [] }

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
        let searchQuery = articles.filter(articleTitle.like(pattern) || content.like(pattern) || summary.like(pattern))
            .order(SQLite.Expression<String>("published_at").desc)
            .limit(50)

        var result: [Article] = []
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
                result.append(article)
            }
        } catch {
            print("Error searching articles: \(error)")
        }
        return result
    }
}
