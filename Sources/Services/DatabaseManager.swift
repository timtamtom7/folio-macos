import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?
    private let dbPath: String

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folioDir = appSupport.appendingPathComponent("FOLIO")
        try? FileManager.default.createDirectory(at: folioDir, withIntermediateDirectories: true)
        dbPath = folioDir.appendingPathComponent("folio.db").path
    }

    func setup() {
        do {
            db = try Connection(dbPath)
            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    func getConnection() -> Connection? {
        return db
    }

    private func createTables() throws {
        guard let db = db else { return }

        let categories = Table("categories")
        let feeds = Table("feeds")
        let articles = Table("articles")

        let id = SQLite.Expression<String>("id")
        let name = SQLite.Expression<String>("name")
        let sortOrder = SQLite.Expression<Int>("sort_order")
        let colorHex = SQLite.Expression<String>("color_hex")

        let url = SQLite.Expression<String>("url")
        let title = SQLite.Expression<String>("title")
        let siteUrl = SQLite.Expression<String?>("site_url")
        let iconUrl = SQLite.Expression<String?>("icon_url")
        let categoryId = SQLite.Expression<String?>("category_id")
        let addedAt = SQLite.Expression<String>("added_at")
        let lastFetchedAt = SQLite.Expression<String?>("last_fetched_at")
        let errorMessage = SQLite.Expression<String?>("error_message")

        let feedId = SQLite.Expression<String>("feed_id")
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

        try db.run(categories.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(sortOrder, defaultValue: 0)
            t.column(colorHex, defaultValue: "#4A90D9")
        })

        try db.run(feeds.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(url, unique: true)
            t.column(title)
            t.column(siteUrl)
            t.column(iconUrl)
            t.column(categoryId)
            t.column(addedAt)
            t.column(lastFetchedAt)
            t.column(errorMessage)
        })

        try db.run(articles.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(feedId)
            t.column(articleTitle)
            t.column(articleUrl, unique: true)
            t.column(author)
            t.column(summary)
            t.column(content)
            t.column(imageUrl)
            t.column(publishedAt)
            t.column(isRead, defaultValue: false)
            t.column(isFavorite, defaultValue: false)
            t.column(readAt)
        })

        try db.run(articles.createIndex(feedId, ifNotExists: true))
        try db.run(articles.createIndex(publishedAt, ifNotExists: true))

        // Annotations table
        let annotations = Table("annotations")
        let annotationId = SQLite.Expression<String>("id")
        let annotationArticleId = SQLite.Expression<String>("article_id")
        let annotationContent = SQLite.Expression<String>("content")
        let highlightColor = SQLite.Expression<String?>("highlight_color")
        let selectedText = SQLite.Expression<String?>("selected_text")
        let annotationCreatedAt = SQLite.Expression<String>("created_at")
        let annotationUpdatedAt = SQLite.Expression<String>("updated_at")

        try db.run(annotations.create(ifNotExists: true) { t in
            t.column(annotationId, primaryKey: true)
            t.column(annotationArticleId)
            t.column(annotationContent)
            t.column(highlightColor)
            t.column(selectedText)
            t.column(annotationCreatedAt)
            t.column(annotationUpdatedAt)
        })

        try db.run(annotations.createIndex(annotationArticleId, ifNotExists: true))

        // Reading sessions table
        let sessions = Table("reading_sessions")
        let sessionId = SQLite.Expression<String>("id")
        let sessionArticleId = SQLite.Expression<String>("article_id")
        let startedAt = SQLite.Expression<String>("started_at")
        let durationSec = SQLite.Expression<Int>("duration_seconds")
        let completedReading = SQLite.Expression<Bool>("completed_reading")

        try db.run(sessions.create(ifNotExists: true) { t in
            t.column(sessionId, primaryKey: true)
            t.column(sessionArticleId)
            t.column(startedAt)
            t.column(durationSec, defaultValue: 0)
            t.column(completedReading, defaultValue: false)
        })
    }
}
