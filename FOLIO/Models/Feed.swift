import Foundation

struct Feed: Identifiable, Codable, Hashable {
    let id: UUID
    var url: URL
    var title: String
    var siteUrl: URL?
    var iconUrl: URL?
    var categoryId: UUID?
    var addedAt: Date
    var lastFetchedAt: Date?
    var errorMessage: String?
}
