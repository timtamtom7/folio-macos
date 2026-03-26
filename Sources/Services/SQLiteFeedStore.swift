import Foundation
import SQLite

class SQLiteFeedStore {
    private var db: Connection? { DatabaseManager.shared.getConnection() }

    func saveFeed(_ feed: Feed) {
        guard let db = db else { return }

        let feeds = Table("feeds")
        let id = SQLite.Expression<String>("id")
        let url = SQLite.Expression<String>("url")
        let title = SQLite.Expression<String>("title")
        let siteUrl = SQLite.Expression<String?>("site_url")
        let iconUrl = SQLite.Expression<String?>("icon_url")
        let categoryId = SQLite.Expression<String?>("category_id")
        let addedAt = SQLite.Expression<String>("added_at")
        let lastFetchedAt = SQLite.Expression<String?>("last_fetched_at")
        let errorMessage = SQLite.Expression<String?>("error_message")

        let formatter = ISO8601DateFormatter()

        do {
            try db.run(feeds.insert(or: .replace,
                id <- feed.id.uuidString,
                url <- feed.url.absoluteString,
                title <- feed.title,
                siteUrl <- feed.siteUrl?.absoluteString,
                iconUrl <- feed.iconUrl?.absoluteString,
                categoryId <- feed.categoryId?.uuidString,
                addedAt <- formatter.string(from: feed.addedAt),
                lastFetchedAt <- feed.lastFetchedAt.map { formatter.string(from: $0) },
                errorMessage <- feed.errorMessage
            ))
        } catch {
            print("Error saving feed: \(error)")
        }
    }

    func updateFeed(_ feed: Feed) {
        guard let db = db else { return }

        let feeds = Table("feeds")
        let id = SQLite.Expression<String>("id")
        let title = SQLite.Expression<String>("title")
        let siteUrl = SQLite.Expression<String?>("site_url")
        let iconUrl = SQLite.Expression<String?>("icon_url")
        let categoryId = SQLite.Expression<String?>("category_id")
        let lastFetchedAt = SQLite.Expression<String?>("last_fetched_at")
        let errorMessage = SQLite.Expression<String?>("error_message")

        let formatter = ISO8601DateFormatter()

        let feedRow = feeds.filter(id == feed.id.uuidString)
        do {
            try db.run(feedRow.update(
                title <- feed.title,
                siteUrl <- feed.siteUrl?.absoluteString,
                iconUrl <- feed.iconUrl?.absoluteString,
                categoryId <- feed.categoryId?.uuidString,
                lastFetchedAt <- feed.lastFetchedAt.map { formatter.string(from: $0) },
                errorMessage <- feed.errorMessage
            ))
        } catch {
            print("Error updating feed: \(error)")
        }
    }

    func deleteFeed(_ feedId: UUID) {
        guard let db = db else { return }

        let feeds = Table("feeds")
        let id = SQLite.Expression<String>("id")

        let feedRow = feeds.filter(id == feedId.uuidString)
        do {
            try db.run(feedRow.delete())
        } catch {
            print("Error deleting feed: \(error)")
        }
    }

    func getAllFeeds() -> [Feed] {
        guard let db = db else { return [] }

        let feeds = Table("feeds")
        let id = SQLite.Expression<String>("id")
        let url = SQLite.Expression<String>("url")
        let title = SQLite.Expression<String>("title")
        let siteUrl = SQLite.Expression<String?>("site_url")
        let iconUrl = SQLite.Expression<String?>("icon_url")
        let categoryId = SQLite.Expression<String?>("category_id")
        let addedAt = SQLite.Expression<String>("added_at")
        let lastFetchedAt = SQLite.Expression<String?>("last_fetched_at")
        let errorMessage = SQLite.Expression<String?>("error_message")

        let formatter = ISO8601DateFormatter()

        var result: [Feed] = []
        do {
            for row in try db.prepare(feeds) {
                let feedUrl = URL(string: row[url])
                guard let feedUrl = feedUrl else { continue }
                let feed = Feed(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    url: feedUrl,
                    title: row[title],
                    siteUrl: row[siteUrl].flatMap { URL(string: $0) },
                    iconUrl: row[iconUrl].flatMap { URL(string: $0) },
                    categoryId: row[categoryId].flatMap { UUID(uuidString: $0) },
                    addedAt: formatter.date(from: row[addedAt]) ?? Date(),
                    lastFetchedAt: row[lastFetchedAt].flatMap { formatter.date(from: $0) },
                    errorMessage: row[errorMessage]
                )
                result.append(feed)
            }
        } catch {
            print("Error getting feeds: \(error)")
        }
        return result
    }

    func saveCategory(_ category: Category) {
        guard let db = db else { return }

        let categories = Table("categories")
        let id = SQLite.Expression<String>("id")
        let name = SQLite.Expression<String>("name")
        let sortOrder = SQLite.Expression<Int>("sort_order")
        let colorHex = SQLite.Expression<String>("color_hex")

        do {
            try db.run(categories.insert(or: .replace,
                id <- category.id.uuidString,
                name <- category.name,
                sortOrder <- category.sortOrder,
                colorHex <- category.colorHex
            ))
        } catch {
            print("Error saving category: \(error)")
        }
    }

    func deleteCategory(_ categoryId: UUID) {
        guard let db = db else { return }

        let categories = Table("categories")
        let id = SQLite.Expression<String>("id")

        let categoryRow = categories.filter(id == categoryId.uuidString)
        do {
            try db.run(categoryRow.delete())
        } catch {
            print("Error deleting category: \(error)")
        }
    }

    func getAllCategories() -> [Category] {
        guard let db = db else { return [] }

        let categories = Table("categories")
        let id = SQLite.Expression<String>("id")
        let name = SQLite.Expression<String>("name")
        let sortOrder = SQLite.Expression<Int>("sort_order")
        let colorHex = SQLite.Expression<String>("color_hex")

        var result: [Category] = []
        do {
            for row in try db.prepare(categories.order(sortOrder)) {
                let category = Category(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    name: row[name],
                    sortOrder: row[sortOrder],
                    colorHex: row[colorHex]
                )
                result.append(category)
            }
        } catch {
            print("Error getting categories: \(error)")
        }
        return result
    }

    func moveFeedsToUncategorized(categoryId: UUID) {
        guard let db = db else { return }

        let feeds = Table("feeds")
        let catId = SQLite.Expression<String?>("category_id")

        let feedRows = feeds.filter(catId == categoryId.uuidString)
        do {
            try db.run(feedRows.update(catId <- nil))
        } catch {
            print("Error moving feeds to uncategorized: \(error)")
        }
    }
}
