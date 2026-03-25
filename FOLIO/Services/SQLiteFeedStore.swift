import Foundation
import SQLite

class SQLiteFeedStore {
    private var db: Connection? { DatabaseManager.shared.db }

    // MARK: - Feeds

    func saveFeed(_ feed: Feed) {
        guard let db = db else { return }

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

        do {
            try db.run(feeds.insert(or: .replace,
                feedId <- feed.id.uuidString,
                feedUrl <- feed.url.absoluteString,
                feedTitle <- feed.title,
                feedSiteUrl <- feed.siteUrl?.absoluteString,
                feedIconUrl <- feed.iconUrl?.absoluteString,
                feedCategoryId <- feed.categoryId?.uuidString,
                feedAddedAt <- DatabaseManager.dateToString(feed.addedAt),
                feedLastFetchedAt <- feed.lastFetchedAt.map { DatabaseManager.dateToString($0) },
                feedErrorMessage <- feed.errorMessage
            ))
        } catch {
            print("Failed to save feed: \(error)")
        }
    }

    func getAllFeeds() -> [Feed] {
        guard let db = db else { return [] }

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

        var result: [Feed] = []
        do {
            for row in try db.prepare(feeds) {
                let feed = Feed(
                    id: UUID(uuidString: row[feedId]) ?? UUID(),
                    url: URL(string: row[feedUrl])!,
                    title: row[feedTitle],
                    siteUrl: row[feedSiteUrl].flatMap { URL(string: $0) },
                    iconUrl: row[feedIconUrl].flatMap { URL(string: $0) },
                    categoryId: row[feedCategoryId].flatMap { UUID(uuidString: $0) },
                    addedAt: DatabaseManager.stringToDate(row[feedAddedAt]),
                    lastFetchedAt: row[feedLastFetchedAt].map { DatabaseManager.stringToDate($0) },
                    errorMessage: row[feedErrorMessage]
                )
                result.append(feed)
            }
        } catch {
            print("Failed to fetch feeds: \(error)")
        }
        return result
    }

    func deleteFeed(id: UUID) {
        guard let db = db else { return }
        let feeds = Table("feeds")
        let feedId = Expression<String>("id")
        do {
            try db.run(feeds.filter(feedId == id.uuidString).delete())
        } catch {
            print("Failed to delete feed: \(error)")
        }
    }

    func updateFeedLastFetched(feedId: UUID) {
        guard let db = db else { return }
        let feeds = Table("feeds")
        let idCol = Expression<String>("id")
        let lastFetchedAt = Expression<String?>("last_fetched_at")
        do {
            try db.run(feeds.filter(idCol == feedId.uuidString)
                .update(lastFetchedAt <- DatabaseManager.dateToString(Date())))
        } catch {
            print("Failed to update feed: \(error)")
        }
    }

    // MARK: - Categories

    func saveCategory(_ category: Category) {
        guard let db = db else { return }

        let categories = Table("categories")
        let catId = Expression<String>("id")
        let catName = Expression<String>("name")
        let catSortOrder = Expression<Int>("sort_order")
        let catColorHex = Expression<String>("color_hex")

        do {
            try db.run(categories.insert(or: .replace,
                catId <- category.id.uuidString,
                catName <- category.name,
                catSortOrder <- category.sortOrder,
                catColorHex <- category.colorHex
            ))
        } catch {
            print("Failed to save category: \(error)")
        }
    }

    func getAllCategories() -> [Category] {
        guard let db = db else { return [] }

        let categories = Table("categories")
        let catId = Expression<String>("id")
        let catName = Expression<String>("name")
        let catSortOrder = Expression<Int>("sort_order")
        let catColorHex = Expression<String>("color_hex")

        var result: [Category] = []
        do {
            for row in try db.prepare(categories.order(catSortOrder)) {
                let category = Category(
                    id: UUID(uuidString: row[catId]) ?? UUID(),
                    name: row[catName],
                    sortOrder: row[catSortOrder],
                    colorHex: row[catColorHex]
                )
                result.append(category)
            }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
        return result
    }

    func deleteCategory(id: UUID) {
        guard let db = db else { return }
        let categories = Table("categories")
        let catId = Expression<String>("id")
        // Also update feeds to uncategorized
        let feeds = Table("feeds")
        let feedCategoryId = Expression<String?>("category_id")
        do {
            try db.run(feeds.filter(feedCategoryId == id.uuidString)
                .update(feedCategoryId <- nil))
            try db.run(categories.filter(catId == id.uuidString).delete())
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
}
