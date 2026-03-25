import Foundation

struct SharedFeed: Identifiable, Codable {
    let id: UUID
    let feedId: UUID
    let shareCode: String
    var viewCount: Int
    var subscriberCount: Int
    let createdAt: Date
    
    init(id: UUID = UUID(), feedId: UUID, shareCode: String, viewCount: Int = 0, subscriberCount: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.feedId = feedId
        self.shareCode = shareCode
        self.viewCount = viewCount
        self.subscriberCount = subscriberCount
        self.createdAt = createdAt
    }
    
    var shareURL: URL? {
        URL(string: "foliords://shared-feed/\(shareCode)")
    }
    
    var webURL: URL? {
        URL(string: "https://folio.app/shared/\(shareCode)")
    }
}
