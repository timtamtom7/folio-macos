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

    init(id: UUID = UUID(), feedId: UUID, title: String, url: URL, author: String? = nil, summary: String? = nil, content: String? = nil, imageUrl: URL? = nil, publishedAt: Date, isRead: Bool = false, isFavorite: Bool = false, readAt: Date? = nil) {
        self.id = id
        self.feedId = feedId
        self.title = title
        self.url = url
        self.author = author
        self.summary = summary
        self.content = content
        self.imageUrl = imageUrl
        self.publishedAt = publishedAt
        self.isRead = isRead
        self.isFavorite = isFavorite
        self.readAt = readAt
    }
}

extension Article {
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }

    var truncatedSummary: String {
        guard let summary = summary else { return "" }
        if summary.count <= 500 {
            return summary
        }
        return String(summary.prefix(500)) + "..."
    }
}
