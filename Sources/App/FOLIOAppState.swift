import Foundation
import Combine

@MainActor
class FOLIOAppState: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var selectedFeed: Feed?
    @Published var showAddFeedSheet = false
    @Published var isRefreshing = false
    @Published var unreadCount: Int = 0

    private let feedStore = SQLiteFeedStore()
    private let articleStore = SQLiteArticleStore()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    deinit {
        refreshTimer?.invalidate()
    }

    init() {
        loadData()
        setupNotifications()
        startBackgroundRefresh()
    }

    private func loadData() {
        feeds = feedStore.getAllFeeds()
        categories = feedStore.getAllCategories()
        updateUnreadCount()
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .showAddFeedSheet)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showAddFeedSheet = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .refreshAllFeeds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAllFeeds()
            }
            .store(in: &cancellables)
    }

    private func startBackgroundRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAllFeeds()
            }
        }
    }

    func refreshAllFeeds() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task {
            for feed in feeds {
                await refreshFeed(feed)
            }
            await MainActor.run {
                self.loadData()
                self.isRefreshing = false
            }
        }
    }

    func refreshFeed(_ feed: Feed) async {
        do {
            let articles = try await FeedService.shared.fetchFeed(url: feed.url)
            for article in articles {
                articleStore.saveArticle(article, feedId: feed.id)
            }
            var updatedFeed = feed
            updatedFeed.lastFetchedAt = Date()
            updatedFeed.errorMessage = nil
            feedStore.updateFeed(updatedFeed)
        } catch {
            var updatedFeed = feed
            updatedFeed.errorMessage = error.localizedDescription
            feedStore.updateFeed(updatedFeed)
        }
    }

    func addFeed(url: URL, title: String?, categoryId: UUID?) async throws {
        var feed = Feed(
            id: UUID(),
            url: url,
            title: title ?? url.host ?? "Unknown Feed",
            siteUrl: nil,
            iconUrl: nil,
            categoryId: categoryId,
            addedAt: Date(),
            lastFetchedAt: nil,
            errorMessage: nil
        )

        do {
            let fetchedArticles = try await FeedService.shared.fetchFeed(url: url)
            feed.title = title ?? fetchedArticles.first?.title ?? url.host ?? "Unknown Feed"

            if let firstArticle = fetchedArticles.first {
                feed.siteUrl = firstArticle.url
            }

            feedStore.saveFeed(feed)
            for article in fetchedArticles {
                articleStore.saveArticle(article, feedId: feed.id)
            }

            loadData()
        } catch {
            feedStore.saveFeed(feed)
            loadData()
            throw error
        }
    }

    func deleteFeed(_ feed: Feed) {
        feedStore.deleteFeed(feed.id)
        articleStore.deleteArticles(forFeed: feed.id)
        if selectedFeed?.id == feed.id {
            selectedFeed = nil
        }
        loadData()
    }

    func addCategory(name: String, colorHex: String) {
        let category = Category(
            id: UUID(),
            name: name,
            sortOrder: categories.count,
            colorHex: colorHex
        )
        feedStore.saveCategory(category)
        loadData()
    }

    func deleteCategory(_ category: Category) {
        feedStore.deleteCategory(category.id)
        feedStore.moveFeedsToUncategorized(categoryId: category.id)
        if selectedCategory?.id == category.id {
            selectedCategory = nil
        }
        loadData()
    }

    func updateUnreadCount() {
        unreadCount = articleStore.getUnreadCount()
    }
}
