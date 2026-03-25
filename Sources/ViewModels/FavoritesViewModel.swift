import Foundation
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Article] = []
    @Published var searchQuery = ""

    private let articleStore = SQLiteArticleStore()

    init() {
        loadFavorites()
    }

    func loadFavorites() {
        favorites = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .favorites)
    }

    func filteredFavorites() -> [Article] {
        if searchQuery.isEmpty {
            return favorites
        }
        return favorites.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.author?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    func removeFavorite(_ article: Article) {
        articleStore.toggleFavorite(articleId: article.id)
        favorites.removeAll { $0.id == article.id }
    }
}
