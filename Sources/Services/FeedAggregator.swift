import Foundation

final class FeedAggregator: ObservableObject {
    static let shared = FeedAggregator()

    @Published var isAggregating = false

    private let feedStore = SQLiteFeedStore()
    private let articleStore = SQLiteArticleStore()

    enum FeedSource {
        case local
        case feedbin
        case feedly
    }

    struct FeedGroup: Identifiable {
        let id: UUID
        let title: String
        let source: FeedSource
        var articles: [Article]
        var unreadCount: Int
    }

    func merge(localFeeds: [Feed], feedbinFeeds: [Feed] = [], feedlyFeeds: [Feed] = []) -> [FeedGroup] {
        var groups: [FeedGroup] = []

        // Local feeds
        for feed in localFeeds {
            let articles = articleStore.getArticles(feedId: feed.id, categoryId: nil, filter: .all)
            let unread = articles.filter { !$0.isRead }.count
            groups.append(FeedGroup(
                id: feed.id,
                title: feed.displayTitle,
                source: .local,
                articles: articles,
                unreadCount: unread
            ))
        }

        // Feedbin feeds
        for feed in feedbinFeeds {
            let articles = articleStore.getArticles(feedId: feed.id, categoryId: nil, filter: .all)
            let unread = articles.filter { !$0.isRead }.count
            groups.append(FeedGroup(
                id: feed.id,
                title: feed.displayTitle + " (Feedbin)",
                source: .feedbin,
                articles: articles,
                unreadCount: unread
            ))
        }

        // Feedly feeds
        for feed in feedlyFeeds {
            let articles = articleStore.getArticles(feedId: feed.id, categoryId: nil, filter: .all)
            let unread = articles.filter { !$0.isRead }.count
            groups.append(FeedGroup(
                id: feed.id,
                title: feed.displayTitle + " (Feedly)",
                source: .feedly,
                articles: articles,
                unreadCount: unread
            ))
        }

        return groups
    }

    func deduplicateArticles(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        var result: [Article] = []

        for article in articles {
            let hash = article.url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? ""
            if !seen.contains(hash) {
                seen.insert(hash)
                result.append(article)
            }
        }

        return result
    }
}
