import Foundation
import SQLite

struct Annotation: Identifiable, Codable {
    let id: UUID
    let articleId: UUID
    var content: String
    var highlightColor: String?
    var selectedText: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), articleId: UUID, content: String, highlightColor: String? = nil, selectedText: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.articleId = articleId
        self.content = content
        self.highlightColor = highlightColor
        self.selectedText = selectedText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ReadingSession: Identifiable, Codable {
    let id: UUID
    let articleId: UUID
    var startedAt: Date
    var durationSeconds: Int
    var completedReading: Bool

    init(id: UUID = UUID(), articleId: UUID, startedAt: Date = Date(), durationSeconds: Int = 0, completedReading: Bool = false) {
        self.id = id
        self.articleId = articleId
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.completedReading = completedReading
    }
}

struct ShareTarget: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: String
    var config: String?

    init(id: UUID = UUID(), name: String, type: String, config: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.config = config
    }
}
