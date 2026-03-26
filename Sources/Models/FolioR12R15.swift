import Foundation

// MARK: - Folio R12-R15 Models

struct FeedTeam: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [FeedMember]
    var sharedFeeds: [SharedFeed]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        members: [FeedMember] = [],
        sharedFeeds: [SharedFeed] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.sharedFeeds = sharedFeeds
        self.createdAt = createdAt
    }
}

struct FeedMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var role: FeedRole

    enum FeedRole: String, Codable {
        case admin
        case editor
        case viewer
    }

    init(id: UUID = UUID(), name: String, email: String, role: FeedRole = .viewer) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }
}

struct SharedFeedConfig: Identifiable, Codable {
    let id: UUID
    var feedId: UUID
    var shareCode: String
    var expiresAt: Date?
    var accessCount: Int

    init(
        id: UUID = UUID(),
        feedId: UUID,
        shareCode: String = String(UUID().uuidString.prefix(8)).uppercased(),
        expiresAt: Date? = nil,
        accessCount: Int = 0
    ) {
        self.id = id
        self.feedId = feedId
        self.shareCode = shareCode
        self.expiresAt = expiresAt
        self.accessCount = accessCount
    }
}

struct FeedAnnotation: Identifiable, Codable {
    let id: UUID
    var articleId: UUID
    var highlight: String
    var note: String?
    var tags: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        articleId: UUID,
        highlight: String,
        note: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.articleId = articleId
        self.highlight = highlight
        self.note = note
        self.tags = tags
        self.createdAt = createdAt
    }
}

struct ReadngGoal: Identifiable, Codable {
    let id: UUID
    var name: String
    var targetArticles: Int
    var period: GoalPeriod
    var createdAt: Date

    enum GoalPeriod: String, Codable {
        case daily
        case weekly
        case monthly
    }

    init(
        id: UUID = UUID(),
        name: String,
        targetArticles: Int,
        period: GoalPeriod = .weekly,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetArticles = targetArticles
        self.period = period
        self.createdAt = createdAt
    }
}
