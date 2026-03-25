import Foundation
import AppIntents

// MARK: - Get Unread Articles Intent

struct GetUnreadArticlesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Unread Articles"
    static var description = IntentDescription("Returns a list of unread articles from FOLIO")
    
    @Parameter(title: "Number of Articles", default: 10)
    var limit: Int
    
    @Parameter(title: "Feed Name", default: nil)
    var feedName: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$limit) unread articles") {
            \.$feedName
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[ArticleInfo]> {
        let articleStore = SQLiteArticleStore()
        let feedStore = SQLiteFeedStore()
        
        let articles: [Article]
        
        if let feedName = feedName {
            let feeds = feedStore.getAllFeeds()
            if let feed = feeds.first(where: { $0.title.lowercased() == feedName.lowercased() }) {
                articles = articleStore.getArticles(feedId: feed.id, categoryId: nil, filter: .all)
                    .filter { !$0.isRead }
                    .prefix(limit)
                    .map { $0 }
            } else {
                articles = []
            }
        } else {
            articles = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .all)
                .filter { !$0.isRead }
                .prefix(limit)
                .map { $0 }
        }
        
        let articleInfos = articles.map { article in
            ArticleInfo(
                id: article.id.uuidString,
                title: article.title,
                url: article.url.absoluteString,
                author: article.author,
                publishedAt: article.publishedAt
            )
        }
        
        return .result(value: articleInfos)
    }
}

struct ArticleInfo: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Article"
    
    var id: String
    var title: String
    var url: String
    var author: String?
    var publishedAt: Date
    
    static var defaultQuery = ArticleInfoQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ArticleInfoQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ArticleInfo] {
        return []
    }
    
    func suggestedEntities() async throws -> [ArticleInfo] {
        return []
    }
}

// MARK: - Mark Article Read Intent

struct MarkArticleReadIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Article as Read"
    static var description = IntentDescription("Marks an article as read in FOLIO")
    
    @Parameter(title: "Article URL")
    var articleURL: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Mark article as read: \(\.$articleURL)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let url = URL(string: articleURL) else {
            return .result(dialog: "Invalid article URL")
        }
        
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.searchArticles(query: "")
        if let article = articles.first(where: { $0.url == url }) {
            articleStore.markRead(articleId: article.id)
            return .result(dialog: "Marked '\(article.title)' as read")
        }
        
        return .result(dialog: "Article not found")
    }
}

// MARK: - Mark Article Unread Intent

struct MarkArticleUnreadIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Article as Unread"
    static var description = IntentDescription("Marks an article as unread in FOLIO")
    
    @Parameter(title: "Article URL")
    var articleURL: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Mark article as unread: \(\.$articleURL)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let url = URL(string: articleURL) else {
            return .result(dialog: "Invalid article URL")
        }
        
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.searchArticles(query: "")
        if let article = articles.first(where: { $0.url == url }) {
            articleStore.toggleRead(articleId: article.id)
            return .result(dialog: "Marked '\(article.title)' as unread")
        }
        
        return .result(dialog: "Article not found")
    }
}

// MARK: - Add Feed Intent

struct AddFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Feed"
    static var description = IntentDescription("Adds a new RSS feed to FOLIO")
    
    @Parameter(title: "Feed URL")
    var feedURL: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add feed: \(\.$feedURL)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let url = URL(string: feedURL) else {
            return .result(dialog: "Invalid feed URL")
        }
        
        let feedService = FeedService()
        do {
            let articles = try await feedService.fetchFeed(url: url)
            if let firstArticle = articles.first {
                let feed = Feed(
                    id: UUID(),
                    url: url,
                    title: firstArticle.title,
                    siteUrl: url,
                    addedAt: Date()
                )
                let feedStore = SQLiteFeedStore()
                feedStore.saveFeed(feed)
                return .result(dialog: "Added feed: \(feed.title)")
            }
            return .result(dialog: "Feed added but no articles found")
        } catch {
            return .result(dialog: "Failed to add feed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Refresh Feeds Intent

struct RefreshFeedsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Feeds"
    static var description = IntentDescription("Refreshes all feeds in FOLIO")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Refresh all feeds")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Would trigger feed refresh here
        return .result(dialog: "Refreshing feeds...")
    }
}

// MARK: - Get Favorites Intent

struct GetFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Favorites"
    static var description = IntentDescription("Returns favorite articles from FOLIO")
    
    @Parameter(title: "Number of Articles", default: 10)
    var limit: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$limit) favorite articles")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[ArticleInfo]> {
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .all)
            .filter { $0.isFavorite }
            .prefix(limit)
            .map { $0 }
        
        let articleInfos = articles.map { article in
            ArticleInfo(
                id: article.id.uuidString,
                title: article.title,
                url: article.url.absoluteString,
                author: article.author,
                publishedAt: article.publishedAt
            )
        }
        
        return .result(value: articleInfos)
    }
}

// MARK: - Search Articles Intent

struct SearchArticlesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Articles"
    static var description = IntentDescription("Searches articles in FOLIO")
    
    @Parameter(title: "Search Query")
    var query: String
    
    @Parameter(title: "Number of Results", default: 10)
    var limit: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$query)") {
            \.$limit
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[ArticleInfo]> {
        let articleStore = SQLiteArticleStore()
        let results = articleStore.searchArticles(query: query)
            .prefix(limit)
            .map { $0 }
        
        let articleInfos = results.map { article in
            ArticleInfo(
                id: article.id.uuidString,
                title: article.title,
                url: article.url.absoluteString,
                author: article.author,
                publishedAt: article.publishedAt
            )
        }
        
        return .result(value: articleInfos)
    }
}

// MARK: - App Shortcuts Provider

struct FOLIOShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetUnreadArticlesIntent(),
            phrases: [
                "Get unread articles in \(.applicationName)",
                "Show my \(.applicationName) unread articles",
                "What am I reading in \(.applicationName)"
            ],
            shortTitle: "Get Unread Articles",
            systemImageName: "newspaper"
        )
        
        AppShortcut(
            intent: RefreshFeedsIntent(),
            phrases: [
                "Refresh \(.applicationName) feeds",
                "Update feeds in \(.applicationName)"
            ],
            shortTitle: "Refresh Feeds",
            systemImageName: "arrow.clockwise"
        )
    }
}
