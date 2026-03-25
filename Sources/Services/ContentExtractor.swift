import Foundation

final class ContentExtractor {
    func extractContent(from html: String) -> String {
        var cleaned = html

        let tagPatterns = [
            "<script[^>]*>.*?</script>",
            "<style[^>]*>.*?</style>",
            "<link[^>]*>",
            "<meta[^>]*>",
            "<noscript[^>]*>.*?</noscript>"
        ]
        for pattern in tagPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }

        cleaned = decodeHTMLEntities(cleaned)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractReadableContent(from html: String) -> (content: String, estimatedReadTime: Int) {
        let content = extractContent(from: html)
        let wordCount = content.split(separator: " ").count
        let readTimeMinutes = max(1, wordCount / 200)
        return (content, readTimeMinutes)
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string

        let replacements: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#39;", "'"),
            ("&mdash;", "\u{2014}"),
            ("&ndash;", "\u{2013}"),
            ("&hellip;", "\u{2026}"),
            ("&copy;", "\u{00A9}"),
            ("&reg;", "\u{00AE}"),
            ("&trade;", "\u{2122}"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}"),
            ("&bull;", "\u{2022}"),
            ("&middot;", "\u{00B7}")
        ]

        for (entity, char) in replacements {
            result = result.replacingOccurrences(of: entity, with: char)
        }

        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                if let range = Range(match.range, in: result),
                   let codeRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[codeRange]),
                   let scalar = Unicode.Scalar(code) {
                    result.replaceSubrange(range, with: String(Character(scalar)))
                }
            }
        }

        return result
    }

    func estimateReadTime(_ article: Article) -> String {
        let content = article.content ?? article.summary ?? ""
        let wordCount = content.split(separator: " ").count
        let minutes = max(1, wordCount / 200)
        return "\(minutes) min read"
    }
}
