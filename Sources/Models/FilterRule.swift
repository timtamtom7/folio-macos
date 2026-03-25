import Foundation

struct FilterRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var conditions: [RuleCondition]
    var actions: [RuleAction]
    var isEnabled: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, conditions: [RuleCondition], actions: [RuleAction], isEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.conditions = conditions
        self.actions = actions
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

struct RuleCondition: Codable, Equatable {
    var type: ConditionType
    var value: String
    var operator_: ConditionOperator
    
    enum ConditionType: String, Codable, CaseIterable {
        case feedIs = "Feed is"
        case authorContains = "Author contains"
        case titleContains = "Title contains"
        case contentContains = "Content contains"
        case publishedAfter = "Published after"
        case publishedBefore = "Published before"
        case isOlderThan = "Is older than"
    }
    
    enum ConditionOperator: String, Codable {
        case contains
        case matches
        case equals
        case before
        case after
    }
}

struct RuleAction: Codable, Equatable {
    var type: ActionType
    var value: String?
    
    enum ActionType: String, Codable, CaseIterable {
        case markAsRead = "Mark as read"
        case addToCategory = "Add to category"
        case addTag = "Add tag"
        case addToFavorites = "Add to favorites"
        case sendNotification = "Send notification"
        case applyLabelColor = "Apply label color"
    }
}
