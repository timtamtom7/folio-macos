import Foundation
import NaturalLanguage

final class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func detectLanguage(of text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
    
    func translate(text: String, from sourceLanguage: String?, to targetLanguage: String) async throws -> String {
        // Note: On-device Neural Machine Translation requires NMTTranslator (iOS 17+/macOS 14+)
        // For macOS 13, we detect the language and return a message that translation
        // requires a newer macOS version
        
        let detectedLang = sourceLanguage ?? detectLanguage(of: text)
        
        guard let source = detectedLang else {
            throw TranslationError.languageNotDetected
        }
        
        if source == targetLanguage {
            return text
        }
        
        // Return original text with a note
        // In a production app, you would integrate with a translation API here
        return "[Translation requires macOS 14+ or network-based translation API]\n\n" + text
    }
    
    enum TranslationError: Error, LocalizedError {
        case languageNotDetected
        case translationNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .languageNotDetected:
                return "Could not detect the language of the text"
            case .translationNotAvailable:
                return "Translation is not available on this macOS version"
            }
        }
    }
}
