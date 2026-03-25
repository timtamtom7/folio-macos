import Foundation
import NaturalLanguage

final class SummarizationService {
    static let shared = SummarizationService()
    
    private init() {}
    
    enum SummaryLength {
        case short  // 1 sentence
        case medium // 3 sentences
        case long   // 1 paragraph
        
        var sentenceCount: Int {
            switch self {
            case .short: return 1
            case .medium: return 3
            case .long: return 5
            }
        }
    }
    
    func summarize(_ text: String, length: SummaryLength) -> String {
        // Simple extractive summarization - take first N sentences
        // In production, this would use a more sophisticated approach
        
        let sentences = splitIntoSentences(text)
        
        guard !sentences.isEmpty else { return "" }
        
        switch length {
        case .short:
            return sentences[0]
        case .medium:
            return sentences.prefix(3).joined(separator: " ")
        case .long:
            return sentences.prefix(5).joined(separator: " ")
        }
    }
    
    func calculateImportance(of article: Article) -> Double {
        // Simple importance scoring based on:
        // - Has content
        // - Has author
        // - Recent publication
        // - From known feeds
        
        var score = 5.0 // Base score
        
        if article.content != nil && !article.content!.isEmpty {
            score += 2.0
        }
        
        if article.author != nil {
            score += 1.0
        }
        
        let ageInHours = Date().timeIntervalSince(article.publishedAt) / 3600
        if ageInHours < 24 {
            score += 1.5
        } else if ageInHours < 72 {
            score += 0.5
        }
        
        return min(10.0, score)
    }
    
    func estimateReadingTime(_ text: String) -> TimeInterval {
        // Assume 200 words per minute, average word is 5 chars
        let wordCount = text.split(separator: " ").count
        return Double(wordCount) / 200.0 * 60.0 // seconds
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            if char == "." || char == "!" || char == "?" {
                let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                currentSentence = ""
            }
        }
        
        // Handle any remaining text
        let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sentences.append(trimmed)
        }
        
        return sentences
    }
}

// MARK: - Article Summary Model

struct ArticleSummary: Codable {
    let articleId: UUID
    var summaryShort: String?
    var summaryMedium: String?
    var summaryLong: String?
    var importanceScore: Double?
    var languageCode: String?
    let generatedAt: Date
    
    init(articleId: UUID) {
        self.articleId = articleId
        self.generatedAt = Date()
    }
}

// MARK: - Summarization Cache

final class SummarizationCache {
    static let shared = SummarizationCache()
    
    private let summariesKey = "article_summaries"
    
    private init() {}
    
    func getSummary(for articleId: UUID) -> ArticleSummary? {
        guard let data = UserDefaults.standard.data(forKey: summariesKey),
              let summaries = try? JSONDecoder().decode([UUID: ArticleSummary].self, from: data),
              let summary = summaries[articleId] else {
            return nil
        }
        return summary
    }
    
    func saveSummary(_ summary: ArticleSummary) {
        var summaries = getAllSummaries()
        summaries[summary.articleId] = summary
        saveSummaries(summaries)
    }
    
    func getAllSummaries() -> [UUID: ArticleSummary] {
        guard let data = UserDefaults.standard.data(forKey: summariesKey),
              let summaries = try? JSONDecoder().decode([UUID: ArticleSummary].self, from: data) else {
            return [:]
        }
        return summaries
    }
    
    private func saveSummaries(_ summaries: [UUID: ArticleSummary]) {
        if let data = try? JSONEncoder().encode(summaries) {
            UserDefaults.standard.set(data, forKey: summariesKey)
        }
    }
}
