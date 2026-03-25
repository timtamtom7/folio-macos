import Foundation
import Combine
import AppKit

@MainActor
class FOLIOAppState: ObservableObject {
    static let shared = FOLIOAppState()

    // Feed store
    @Published var feeds: [Feed] = []
    @Published var categories: [Category] = []
    @Published var selectedFeedId: UUID?
    @Published var selectedCategoryId: UUID?

    // Article store
    @Published var articles: [Article] = []
    @Published var selectedArticleId: UUID?

    // UI state
    @Published var showAddFeedSheet = false
    @Published var isRefreshing = false
    @Published var searchText = ""
    @Published var articleFilter: ArticleFilter = .all

    enum ArticleFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case favorites = "Favorites"
    }

    private let feedStore = SQLiteFeedStore()
    private let articleStore = SQLiteArticleStore()
    private let feedService = FeedService()
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }

    var filteredArticles: [Article] {
        var result = articles

        if let feedId = selectedFeedId {
            result = result.filter { $0.feedId == feedId }
        }

        switch articleFilter {
        case .all:
            break
        case .unread:
            result = result.filter { !$0.isRead }
        case .favorites:
            result = result.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.summary ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.publishedAt > $1.publishedAt }
    }

    init() {
        loadData()
        startBackgroundRefresh()
        setupBindings()
    }

    private func setupBindings() {
        $selectedFeedId
            .dropFirst()
            .sink { [weak self] feedId in
                if let feedId = feedId {
                    Task { await self?.loadArticles(forFeed: feedId) }
                }
            }
            .store(in: &cancellables)
    }

    func loadData() {
        feeds = feedStore.getAllFeeds()
        categories = feedStore.getAllCategories()
        articles = articleStore.getAllArticles()
    }

    func loadArticles(forFeed feedId: UUID) async {
        articles = articleStore.getArticles(forFeed: feedId)
    }

    @objc func showAddFeed() {
        showAddFeedSheet = true
    }

    @objc func refreshSelectedFeed() {
        Task { await refreshFeed(id: selectedFeedId) }
    }

    @objc func refreshAllFeedsAction() {
        Task { await refreshAllFeeds() }
    }

    func refreshAllFeeds() async {
        isRefreshing = true
        for feed in feeds {
            await fetchAndSaveArticles(for: feed)
        }
        isRefreshing = false
        loadData()
    }

    func refreshFeed(id: UUID?) async {
        guard let id = id, let feed = feeds.first(where: { $0.id == id }) else { return }
        isRefreshing = true
        await fetchAndSaveArticles(for: feed)
        isRefreshing = false
        loadData()
    }

    private func fetchAndSaveArticles(for feed: Feed) async {
        do {
            let newArticles = try await feedService.fetchFeed(url: feed.url)
            for article in newArticles {
                articleStore.saveArticle(article)
            }
            feedStore.updateFeedLastFetched(feedId: feed.id)
        } catch {
            print("Failed to fetch feed \(feed.url): \(error)")
        }
    }

    func addFeed(url: URL, title: String?, categoryId: UUID?) async throws {
        let resolvedTitle = title ?? url.absoluteString
        let feed = Feed(
            id: UUID(),
            url: url,
            title: resolvedTitle,
            siteUrl: nil,
            iconUrl: nil,
            categoryId: categoryId,
            addedAt: Date(),
            lastFetchedAt: nil,
            errorMessage: nil
        )

        try feedStore.saveFeed(feed)

        // Fetch articles for the new feed
        await fetchAndSaveArticles(for: feed)
        loadData()
    }

    func deleteFeed(id: UUID) {
        feedStore.deleteFeed(id: id)
        articleStore.deleteArticles(forFeed: id)
        feeds.removeAll { $0.id == id }
        articles.removeAll { $0.feedId == id }
        if selectedFeedId == id {
            selectedFeedId = nil
        }
    }

    func addCategory(name: String, colorHex: String) {
        let category = Category(id: UUID(), name: name, sortOrder: categories.count, colorHex: colorHex)
        feedStore.saveCategory(category)
        categories = feedStore.getAllCategories()
    }

    func deleteCategory(id: UUID) {
        feedStore.deleteCategory(id: id)
        // Move feeds to uncategorized
        for i in feeds.indices {
            if feeds[i].categoryId == id {
                feeds[i].categoryId = nil
                feedStore.saveFeed(feeds[i])
            }
        }
        categories = feedStore.getAllCategories()
        loadData()
    }

    func markArticleRead(_ articleId: UUID) {
        articleStore.markRead(articleId: articleId)
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isRead = true
            articles[index].readAt = Date()
        }
    }

    func markArticleUnread(_ articleId: UUID) {
        articleStore.markUnread(articleId: articleId)
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isRead = false
            articles[index].readAt = nil
        }
    }

    @objc func markSelectedRead() {
        guard let id = selectedArticleId else { return }
        markArticleRead(id)
    }

    @objc func markSelectedUnread() {
        guard let id = selectedArticleId else { return }
        markArticleUnread(id)
    }

    @objc func nextArticle() {
        guard let current = selectedArticleId,
              let index = filteredArticles.firstIndex(where: { $0.id == current }),
              index + 1 < filteredArticles.count else { return }
        selectedArticleId = filteredArticles[index + 1].id
        markArticleRead(selectedArticleId!)
    }

    @objc func previousArticle() {
        guard let current = selectedArticleId,
              let index = filteredArticles.firstIndex(where: { $0.id == current }),
              index > 0 else { return }
        selectedArticleId = filteredArticles[index - 1].id
        markArticleRead(selectedArticleId!)
    }

    @objc func openSelectedInBrowser() {
        guard let id = selectedArticleId,
              let article = articles.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.open(article.url)
    }

    private func startBackgroundRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAllFeeds()
            }
        }
    }
}
