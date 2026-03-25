import Foundation
import Combine

@MainActor
class FeedListViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var categories: [Category] = []

    private let feedStore = SQLiteFeedStore()
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadFeeds()
        loadCategories()
    }

    func loadFeeds() {
        feeds = feedStore.getAllFeeds()
    }

    func loadCategories() {
        categories = feedStore.getAllCategories()
    }
}
