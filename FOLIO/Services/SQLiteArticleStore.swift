import Foundation
import SQLite

class SQLiteArticleStore {
    private var db: Connection? { DatabaseManager.shared.db }

    func saveArticle(_ article: Article) {
        guard let db = db else { return }

        let articles = Table("articles")
        let artId = Expression<String>("id")
        let artFeedId = Expression<String>("feed_id")
        let artTitle = Expression<String>("title")
        let artUrl = Expression<String>("url")
        let artAuthor = Expression<String?>("author")
        let artSummary = Expression<String?>("summary")
        let artContent = Expression<String?>("content")
        let artImageUrl = Expression<String?>("image_url")
        let artPublishedAt = Expression<String>("published_at")
        let artIsRead = Expression<Bool>("is_read")
        let artIsFavorite = Expression<Bool>("is_favorite")
        let artReadAt = Expression<String?>("read_at")

        do {
            // Only insert if URL doesn't already exist
            let existing = articles.filter(artUrl == article.url.absoluteString)
            if try db.pluck(existing) == nil {
                try db.run(articles.insert(
                    artId <- article.id.uuidString,
                    artFeedId <- article.feedId.uuidString,
                    artTitle <- article.title,
                    artUrl <- article.url.absoluteString,
                    artAuthor <- article.author,
                    artSummary <- article.summary,
                    artContent <- article.content,
                    artImageUrl <- article.imageUrl?.absoluteString,
                    artPublishedAt <- DatabaseManager.dateToString(article.publishedAt),
                    artIsRead <- article.isRead,
                    artIsFavorite <- article.isFavorite,
                    artReadAt <- article.readAt.map { DatabaseManager.dateToString($0) }
                ))
            }
        } catch {
            print("Failed to save article: \(error)")
        }
    }

    func getAllArticles() -> [Article] {
        guard let db = db else { return [] }
        return getArticles(query: Table("articles").order(Expression<String>("published_at").desc))
    }

    func getArticles(forFeed feedId: UUID) -> [Article] {
        guard let db = db else { return [] }
        let articles = Table("articles")
        let artFeedId = Expression<String>("feed_id")
        return getArticles(query: articles.filter(artFeedId == feedId.uuidString)
            .order(Expression<String>("published_at").desc))
    }

    private func getArticles(query: Table) -> [Article] {
        guard let db = db else { return [] }

        let articles = Table("articles")
        let artId = Expression<String>("id")
        let artFeedId = Expression<String>("feed_id")
        let artTitle = Expression<String>("title")
        let artUrl = Expression<String>("url")
        let artAuthor = Expression<String?>("author")
        let artSummary = Expression<String?>("summary")
        let artContent = Expression<String?>("content")
        let artImageUrl = Expression<String?>("image_url")
        let artPublishedAt = Expression<String>("published_at")
        let artIsRead = Expression<Bool>("is_read")
        let artIsFavorite = Expression<Bool>("is_favorite")
        let artReadAt = Expression<String?>("read_at")

        var result: [Article] = []
        do {
            for row in try db.prepare(query) {
                let article = Article(
                    id: UUID(uuidString: row[artId]) ?? UUID(),
                    feedId: UUID(uuidString: row[artFeedId]) ?? UUID(),
                    title: row[artTitle],
                    url: URL(string: row[artUrl])!,
                    author: row[artAuthor],
                    summary: row[artSummary],
                    content: row[artContent],
                    imageUrl: row[artImageUrl].flatMap { URL(string: $0) },
                    publishedAt: DatabaseManager.stringToDate(row[artPublishedAt]),
                    isRead: row[artIsRead],
                    isFavorite: row[artIsFavorite],
                    readAt: row[artReadAt].map { DatabaseManager.stringToDate($0) }
                )
                result.append(article)
            }
        } catch {
            print("Failed to fetch articles: \(error)")
        }
        return result
    }

    func markRead(articleId: UUID) {
        guard let db = db else { return }
        let articles = Table("articles")
        let artId = Expression<String>("id")
        let artIsRead = Expression<Bool>("is_read")
        let artReadAt = Expression<String?>("read_at")
        do {
            try db.run(articles.filter(artId == articleId.uuidString)
                .update(artIsRead <- true, artReadAt <- DatabaseManager.dateToString(Date())))
        } catch {
            print("Failed to mark read: \(error)")
        }
    }

    func markUnread(articleId: UUID) {
        guard let db = db else { return }
        let articles = Table("articles")
        let artId = Expression<String>("id")
        let artIsRead = Expression<Bool>("is_read")
        let artReadAt = Expression<String?>("read_at")
        do {
            try db.run(articles.filter(artId == articleId.uuidString)
                .update(artIsRead <- false, artReadAt <- nil))
        } catch {
            print("Failed to mark unread: \(error)")
        }
    }

    func toggleFavorite(articleId: UUID) {
        guard let db = db else { return }
        let articles = Table("articles")
        let artId = Expression<String>("id")
        let artIsFavorite = Expression<Bool>("is_favorite")
        do {
            if let row = try db.pluck(articles.filter(artId == articleId.uuidString)) {
                let current = row[artIsFavorite]
                try db.run(articles.filter(artId == articleId.uuidString)
                    .update(artIsFavorite <- !current))
            }
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }

    func deleteArticles(forFeed feedId: UUID) {
        guard let db = db else { return }
        let articles = Table("articles")
        let artFeedId = Expression<String>("feed_id")
        do {
            try db.run(articles.filter(artFeedId == feedId.uuidString).delete())
        } catch {
            print("Failed to delete articles: \(error)")
        }
    }
}
