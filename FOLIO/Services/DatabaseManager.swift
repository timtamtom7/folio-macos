import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var db: Connection?

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folioDir = appSupport.appendingPathComponent("FOLIO", isDirectory: true)

        do {
            try fileManager.createDirectory(at: folioDir, withIntermediateDirectories: true)
            let dbPath = folioDir.appendingPathComponent("folio.db").path
            db = try Connection(dbPath)
            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        let categories = Table("categories")
        let catId = Expression<String>("id")
        let catName = Expression<String>("name")
        let catSortOrder = Expression<Int>("sort_order")
        let catColorHex = Expression<String>("color_hex")

        try db.run(categories.create(ifNotExists: true) { t in
            t.column(catId, primaryKey: true)
            t.column(catName)
            t.column(catSortOrder, defaultValue: 0)
            t.column(catColorHex, defaultValue: "#4A90D9")
        })

        let feeds = Table("feeds")
        let feedId = Expression<String>("id")
        let feedUrl = Expression<String>("url")
        let feedTitle = Expression<String>("title")
        let feedSiteUrl = Expression<String?>("site_url")
        let feedIconUrl = Expression<String?>("icon_url")
        let feedCategoryId = Expression<String?>("category_id")
        let feedAddedAt = Expression<String>("added_at")
        let feedLastFetchedAt = Expression<String?>("last_fetched_at")
        let feedErrorMessage = Expression<String?>("error_message")

        try db.run(feeds.create(ifNotExists: true) { t in
            t.column(feedId, primaryKey: true)
            t.column(feedUrl, unique: true)
            t.column(feedTitle)
            t.column(feedSiteUrl)
            t.column(feedIconUrl)
            t.column(feedCategoryId)
            t.column(feedAddedAt)
            t.column(feedLastFetchedAt)
            t.column(feedErrorMessage)
        })

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

        try db.run(articles.create(ifNotExists: true) { t in
            t.column(artId, primaryKey: true)
            t.column(artFeedId)
            t.column(artTitle)
            t.column(artUrl, unique: true)
            t.column(artAuthor)
            t.column(artSummary)
            t.column(artContent)
            t.column(artImageUrl)
            t.column(artPublishedAt)
            t.column(artIsRead, defaultValue: false)
            t.column(artIsFavorite, defaultValue: false)
            t.column(artReadAt)
            t.foreignKey(artFeedId, references: feeds, artId, delete: .cascade)
        })

        // Indexes
        try? db.run(articles.createIndex(artFeedId, ifNotExists: true))
        try? db.run(articles.createIndex(artPublishedAt, ifNotExists: true))
    }

    static func dateToString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    static func stringToDate(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date()
    }
}
