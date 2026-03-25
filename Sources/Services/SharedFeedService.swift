import Foundation

final class SharedFeedService {
    static let shared = SharedFeedService()
    
    private let sharedFeedsKey = "shared_feeds"
    
    private init() {}
    
    // MARK: - Shared Feed Management
    
    func getAllSharedFeeds() -> [SharedFeed] {
        guard let data = UserDefaults.standard.data(forKey: sharedFeedsKey),
              let feeds = try? JSONDecoder().decode([SharedFeed].self, from: data) else {
            return []
        }
        return feeds
    }
    
    func getSharedFeed(forFeedId feedId: UUID) -> SharedFeed? {
        return getAllSharedFeeds().first { $0.feedId == feedId }
    }
    
    func createSharedFeed(forFeedId feedId: UUID) -> SharedFeed {
        // Generate a share code
        let shareCode = generateShareCode()
        
        let sharedFeed = SharedFeed(
            feedId: feedId,
            shareCode: shareCode
        )
        
        var feeds = getAllSharedFeeds()
        feeds.append(sharedFeed)
        saveSharedFeeds(feeds)
        
        return sharedFeed
    }
    
    func deleteSharedFeed(id: UUID) {
        var feeds = getAllSharedFeeds()
        feeds.removeAll { $0.id == id }
        saveSharedFeeds(feeds)
    }
    
    func incrementViewCount(forShareCode shareCode: String) {
        var feeds = getAllSharedFeeds()
        if let index = feeds.firstIndex(where: { $0.shareCode == shareCode }) {
            feeds[index].viewCount += 1
            saveSharedFeeds(feeds)
        }
    }
    
    private func saveSharedFeeds(_ feeds: [SharedFeed]) {
        if let data = try? JSONEncoder().encode(feeds) {
            UserDefaults.standard.set(data, forKey: sharedFeedsKey)
        }
    }
    
    // MARK: - Share Code Generation
    
    private func generateShareCode() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Deep Link Handling
    
    func handleSharedFeedDeepLink(_ url: URL) -> UUID? {
        // Expected format: foliords://shared-feed/{shareCode}
        guard url.scheme == "foliords",
              url.host == "shared-feed",
              let shareCode = url.pathComponents.last else {
            return nil
        }
        
        let feeds = getAllSharedFeeds()
        if let sharedFeed = feeds.first(where: { $0.shareCode == shareCode }) {
            return sharedFeed.feedId
        }
        
        return nil
    }
    
    // MARK: - Import Shared Feed
    
    func importSharedFeed(fromShareCode shareCode: String, completion: @escaping (Result<Feed, Error>) -> Void) {
        // In production, this would fetch the feed metadata from folio.app
        // For now, return an error
        completion(.failure(SharedFeedError.notImplemented))
    }
    
    enum SharedFeedError: Error {
        case notImplemented
        case feedNotFound
        case invalidShareCode
    }
}
