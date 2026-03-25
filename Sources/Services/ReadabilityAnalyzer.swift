import Foundation
import NaturalLanguage

final class ReadabilityAnalyzer {
    static let shared = ReadabilityAnalyzer()
    
    private init() {}
    
    struct ReadabilityResult {
        let fleschKincaidGrade: Double
        let fleschReadingEase: Double
        let estimatedReadingTime: TimeInterval
        let wordCount: Int
        let sentenceCount: Int
        let averageWordsPerSentence: Double
        
        var gradeLevel: String {
            switch fleschKincaidGrade {
            case 0..<6: return "Elementary"
            case 6..<9: return "Middle School"
            case 9..<13: return "High School"
            case 13..<17: return "College"
            default: return "Graduate"
            }
        }
    }
    
    func analyze(content: String) -> ReadabilityResult {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = content
        
        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.string = content
        
        var wordCount = 0
        var syllableCount = 0
        var sentenceCount = 0
        
        // Count words and syllables
        tokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { range, _ in
            let word = String(content[range])
            wordCount += 1
            syllableCount += countSyllables(in: word)
            return true
        }
        
        // Count sentences
        sentenceTokenizer.enumerateTokens(in: content.startIndex..<content.endIndex) { _, _ in
            sentenceCount += 1
            return true
        }
        
        guard sentenceCount > 0, wordCount > 0 else {
            return ReadabilityResult(
                fleschKincaidGrade: 0,
                fleschReadingEase: 100,
                estimatedReadingTime: 0,
                wordCount: 0,
                sentenceCount: 0,
                averageWordsPerSentence: 0
            )
        }
        
        let avgWordsPerSentence = Double(wordCount) / Double(sentenceCount)
        
        // Flesch-Kincaid Grade Level
        // FK = 0.39 * (words/sentences) + 11.8 * (syllables/words) - 15.59
        let fkGrade = 0.39 * Double(wordCount) / Double(sentenceCount) + 11.8 * Double(syllableCount) / Double(wordCount) - 15.59
        
        // Flesch Reading Ease
        // FRE = 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
        let freScore = 206.835 - 1.015 * avgWordsPerSentence - 84.6 * Double(syllableCount) / Double(wordCount)
        
        // Estimated reading time (assuming 200 words per minute)
        let readingTime = Double(wordCount) / 200.0 * 60.0
        
        return ReadabilityResult(
            fleschKincaidGrade: max(0, fkGrade),
            fleschReadingEase: max(0, min(100, freScore)),
            estimatedReadingTime: readingTime,
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            averageWordsPerSentence: avgWordsPerSentence
        )
    }
    
    private func countSyllables(in word: String) -> Int {
        let vowels: Set<Character> = ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]
        var count = 0
        var lastWasVowel = false
        
        for char in word {
            let isVowel = vowels.contains(char)
            if isVowel && !lastWasVowel {
                count += 1
            }
            lastWasVowel = isVowel
        }
        
        // Handle silent 'e' at end
        if word.lowercased().hasSuffix("e") && count > 1 {
            count -= 1
        }
        
        return max(1, count)
    }
    
    func estimateReadingTime(content: String) -> TimeInterval {
        let result = analyze(content: content)
        return result.estimatedReadingTime
    }
}
