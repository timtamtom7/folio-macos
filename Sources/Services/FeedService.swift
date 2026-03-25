import Foundation

actor FeedService {
    static let shared = FeedService()

    func fetchFeed(url: URL) async throws -> [Article] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseFeed(data: data, feedUrl: url)
    }

    private func parseFeed(data: Data, feedUrl: URL) throws -> [Article] {
        let parser = FeedParser(data: data, feedUrl: feedUrl)
        return parser.parse()
    }

    func discoverFeedUrl(from websiteUrl: URL) async throws -> URL? {
        let (data, _) = try await URLSession.shared.data(from: websiteUrl)
        guard let html = String(data: data, encoding: .utf8) else { return nil }

        let patterns = [
            "<link[^>]+type=\"application/rss\\+xml\"[^>]+href=\"([^\"]+)\"",
            "<link[^>]+href=\"([^\"]+)\"[^>]+type=\"application/rss\\+xml\""
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let href = String(html[range])
                if href.hasPrefix("http") {
                    return URL(string: href)
                } else if href.hasPrefix("/") {
                    return URL(string: href, relativeTo: websiteUrl)
                }
            }
        }

        return nil
    }
}

class FeedParser: NSObject, XMLParserDelegate {
    private let data: Data
    private let feedUrl: URL
    private var articles: [Article] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentAuthor = ""
    private var currentImageUrl = ""
    private var isInItem = false
    private var isInEntry = false
    private var isAtom = false

    init(data: Data, feedUrl: URL) {
        self.data = data
        self.feedUrl = feedUrl
    }

    func parse() -> [Article] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            isInItem = true
            resetCurrentValues()
        } else if elementName == "entry" {
            isInEntry = true
            isAtom = true
            resetCurrentValues()
        } else if elementName == "link" {
            if isAtom, let href = attributeDict["href"] {
                currentLink = href
            }
            if let rel = attributeDict["rel"], rel == "alternate", let href = attributeDict["href"] {
                currentLink = href
            }
        } else if elementName == "enclosure" || elementName == "media:content" || elementName == "media:thumbnail" {
            if let url = attributeDict["url"] {
                currentImageUrl = url
            }
        }

        if let src = attributeDict["url"], (elementName == "img" || elementName == "image") && !isInItem && !isInEntry {
            currentImageUrl = src
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "link":
            if !isAtom {
                currentLink += trimmed
            }
        case "description", "summary", "content":
            currentDescription += trimmed
        case "pubDate", "published", "updated":
            currentPubDate += trimmed
        case "author", "dc:creator":
            currentAuthor += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            finishItem()
            isInItem = false
        } else if elementName == "entry" {
            finishItem()
            isInEntry = false
        }
    }

    private func finishItem() {
        guard !currentTitle.isEmpty, !currentLink.isEmpty else { return }

        var articleUrl = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)) ?? feedUrl
        if articleUrl.scheme == nil {
            articleUrl = URL(string: currentLink, relativeTo: feedUrl) ?? feedUrl
        }

        let publishedDate = parseDate(currentPubDate) ?? Date()
        let summary = stripHTML(from: currentDescription)
        let imageUrl = extractImageUrl(from: currentDescription) ?? (currentImageUrl.isEmpty ? nil : URL(string: currentImageUrl))

        let article = Article(
            id: UUID(),
            feedId: UUID(),
            title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            url: articleUrl,
            author: currentAuthor.isEmpty ? nil : currentAuthor.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary,
            content: currentDescription.isEmpty ? nil : currentDescription,
            imageUrl: imageUrl,
            publishedAt: publishedDate,
            isRead: false,
            isFavorite: false,
            readAt: nil
        )

        articles.append(article)
    }

    private func resetCurrentValues() {
        currentTitle = ""
        currentLink = ""
        currentDescription = ""
        currentPubDate = ""
        currentAuthor = ""
        currentImageUrl = ""
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }

        let iso = ISO8601DateFormatter()
        return iso.date(from: string.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func stripHTML(from string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func extractImageUrl(from html: String) -> URL? {
        let pattern = "<img[^>]+src=\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return URL(string: String(html[range]))
        }
        return nil
    }
}
