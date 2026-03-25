import Foundation

final class RulesEngine {
    static let shared = RulesEngine()
    
    private init() {}
    
    // MARK: - Rule Storage
    
    private let rulesKey = "automation_rules"
    
    func getAllRules() -> [FilterRule] {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let rules = try? JSONDecoder().decode([FilterRule].self, from: data) else {
            return []
        }
        return rules
    }
    
    func saveRule(_ rule: FilterRule) {
        var rules = getAllRules()
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        saveRules(rules)
    }
    
    func deleteRule(id: UUID) {
        var rules = getAllRules()
        rules.removeAll { $0.id == id }
        saveRules(rules)
    }
    
    private func saveRules(_ rules: [FilterRule]) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: rulesKey)
        }
    }
    
    // MARK: - Rule Evaluation
    
    func evaluateArticle(_ article: Article, withRules rules: [FilterRule]) -> [RuleAction] {
        var triggeredActions: [RuleAction] = []
        
        for rule in rules where rule.isEnabled {
            if evaluateConditions(rule.conditions, for: article) {
                triggeredActions.append(contentsOf: rule.actions)
            }
        }
        
        return triggeredActions
    }
    
    private func evaluateConditions(_ conditions: [RuleCondition], for article: Article) -> Bool {
        for condition in conditions {
            if !evaluateCondition(condition, for: article) {
                return false
            }
        }
        return true
    }
    
    private func evaluateCondition(_ condition: RuleCondition, for article: Article) -> Bool {
        switch condition.type {
        case .feedIs:
            return article.feedId.uuidString == condition.value
        case .authorContains:
            return article.author?.lowercased().contains(condition.value.lowercased()) ?? false
        case .titleContains:
            return article.title.lowercased().contains(condition.value.lowercased())
        case .contentContains:
            return article.content?.lowercased().contains(condition.value.lowercased()) ?? false
        case .publishedAfter:
            if let date = ISO8601DateFormatter().date(from: condition.value) {
                return article.publishedAt > date
            }
            return false
        case .publishedBefore:
            if let date = ISO8601DateFormatter().date(from: condition.value) {
                return article.publishedAt < date
            }
            return false
        case .isOlderThan:
            if let hours = Int(condition.value) {
                let cutoff = Date().addingTimeInterval(-Double(hours * 3600))
                return article.publishedAt < cutoff
            }
            return false
        }
    }
    
    // MARK: - Apply Actions
    
    func applyActions(_ actions: [RuleAction], to article: Article) {
        let articleStore = SQLiteArticleStore()
        
        for action in actions {
            switch action.type {
            case .markAsRead:
                articleStore.markRead(articleId: article.id)
            case .addToFavorites:
                articleStore.toggleFavorite(articleId: article.id)
            default:
                break
            }
        }
    }
    
    // MARK: - Test Rules
    
    func testRule(_ rule: FilterRule, on articles: [Article]) -> [Article] {
        return articles.filter { evaluateConditions(rule.conditions, for: $0) }
    }
    
    func countArticlesAffected(by rule: FilterRule) -> Int {
        let articleStore = SQLiteArticleStore()
        let articles = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .all)
        return testRule(rule, on: articles).count
    }
}
