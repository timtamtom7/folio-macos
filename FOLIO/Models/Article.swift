import Foundation

struct Article: Identifiable, Codable, Hashable {
    let id: UUID
    let feedId: UUID
    var title: String
    var url: URL
    var author: String?
    var summary: String?
    var content: String?
    var imageUrl: URL?
    var publishedAt: Date
    var isRead: Bool
    var isFavorite: Bool
    var readAt: Date?
}
