import Foundation
import Combine

@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var selectedArticle: Article?
    @Published var isLoading = false

    private let articleStore = SQLiteArticleStore()
    private let feedStore = SQLiteFeedStore()
    private var currentFeedId: UUID?
    private var currentCategoryId: UUID?
    private var currentFilter: FilterMode = .all

    enum FilterMode {
        case all, unread, favorites
    }

    func loadArticles(for feed: Feed?, filter: ArticleListView.FilterMode = .all) {
        currentFeedId = feed?.id
        currentCategoryId = nil
        currentFilter = mapFilter(filter)
        reloadArticles()
    }

    func loadArticles(forFeed feedId: UUID?, category: Category?, filter: ArticleListView.FilterMode = .all) {
        currentFeedId = feedId
        currentCategoryId = category?.id
        currentFilter = mapFilter(filter)
        reloadArticles()
    }

    private func mapFilter(_ filter: ArticleListView.FilterMode) -> FilterMode {
        switch filter {
        case .all: return .all
        case .unread: return .unread
        case .favorites: return .favorites
        }
    }

    private func reloadArticles() {
        articles = articleStore.getArticles(
            feedId: currentFeedId,
            categoryId: currentCategoryId,
            filter: currentFilter
        )
    }

    func markRead(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isRead = true
        }
    }

    func toggleRead(for article: Article) {
        let articleStore = SQLiteArticleStore()
        articleStore.toggleRead(articleId: article.id)
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isRead.toggle()
        }
    }

    func toggleFavorite(_ article: Article) {
        let articleStore = SQLiteArticleStore()
        articleStore.toggleFavorite(articleId: article.id)
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isFavorite.toggle()
        }
    }

    func searchArticles(query: String) {
        if query.isEmpty {
            reloadArticles()
        } else {
            articles = articleStore.searchArticles(query: query)
        }
    }
}
