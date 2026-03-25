import SwiftUI

final class AccountsViewModel: ObservableObject {
    @Published var feedbinConnected: Bool
    @Published var feedlyConnected: Bool

    init() {
        feedbinConnected = FeedbinService.shared.isConnected
        feedlyConnected = FeedlyService.shared.isConnected
    }

    func disconnectFeedbin() {
        FeedbinService.shared.disconnect()
        feedbinConnected = false
    }

    func disconnectFeedly() {
        FeedlyService.shared.disconnect()
        feedlyConnected = false
    }

    func syncFeedbin() async {
        do {
            try await FeedbinService.shared.syncStarredArticles()
        } catch {
            print("Feedbin sync error: \(error)")
        }
    }

    func syncFeedly() async {
        do {
            try await FeedlyService.shared.syncCategories()
        } catch {
            print("Feedly sync error: \(error)")
        }
    }
}
