import Foundation
import FeedKit

actor FeedService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func fetchFeed(url: URL) async throws -> [Article] {
        let (data, _) = try await session.data(from: url)
        return try parseFeed(data: data, feedUrl: url)
    }

    private func parseFeed(data: Data, feedUrl: URL) throws -> [Article] {
        let parser = FeedParser(data: data)
        let result = parser.parse()

        switch result {
        case .success(let feed):
            return convertFeed(feed, feedUrl: feedUrl)
        case .failure(let error):
            throw error
        }
    }

    private func convertFeed(_ feed: FeedKit.Feed, feedUrl: URL) -> [Article] {
        switch feed {
        case .rss(let rssFeed):
            return parseRSS(rssFeed, feedUrl: feedUrl)
        case .atom(let atomFeed):
            return parseAtom(atomFeed, feedUrl: feedUrl)
        case .json(let jsonFeed):
            return parseJSON(jsonFeed, feedUrl: feedUrl)
        }
    }

    private func parseRSS(_ feed: RSSFeed, feedUrl: URL) -> [Article] {
        guard let items = feed.items else { return [] }
        return items.compactMap { item -> Article? in
            guard let title = item.title,
                  let link = item.link,
                  let url = URL(string: link) else { return nil }

            let publishedAt = item.pubDate ?? Date()
            let content = item.content?.contentEncoded ?? item.description
            let summary = String((content ?? "").prefix(500))
            let imageUrl = item.enclosure?.attributes?.url.flatMap { URL(string: $0) }
                ?? extractImageUrl(from: content ?? item.description ?? "")

            return Article(
                id: UUID(),
                feedId: UUID(), // Will be set by caller
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url,
                author: item.author ?? item.dublinCore?.dcCreator,
                summary: summary.isEmpty ? nil : summary,
                content: content,
                imageUrl: imageUrl,
                publishedAt: publishedAt,
                isRead: false,
                isFavorite: false,
                readAt: nil
            )
        }
    }

    private func parseAtom(_ feed: AtomFeed, feedUrl: URL) -> [Article] {
        guard let entries = feed.entries else { return [] }
        return entries.compactMap { entry -> Article? in
            guard let title = entry.title,
                  let link = entry.links?.first?.attributes?.href,
                  let url = URL(string: link) else { return nil }

            let publishedAt = entry.published ?? entry.updated ?? Date()
            let content = entry.content?.value
            let summary = String((content ?? entry.summary?.value ?? "").prefix(500))
            let imageUrl = extractImageUrl(from: content ?? entry.summary?.value ?? "")

            return Article(
                id: UUID(),
                feedId: UUID(),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url,
                author: entry.authors?.first?.name,
                summary: summary.isEmpty ? nil : summary,
                content: content,
                imageUrl: imageUrl,
                publishedAt: publishedAt,
                isRead: false,
                isFavorite: false,
                readAt: nil
            )
        }
    }

    private func parseJSON(_ feed: JSONFeed, feedUrl: URL) -> [Article] {
        guard let items = feed.items else { return [] }
        return items.compactMap { item -> Article? in
            guard let title = item.title,
                  let urlStr = item.url ?? item.externalUrl,
                  let url = URL(string: urlStr) else { return nil }

            let publishedAt = item.datePublished ?? Date()
            let content = item.contentHtml ?? item.contentText
            let summary = String((content ?? "").prefix(500))
            let imageUrl = item.image.flatMap { URL(string: $0) }
                ?? item.bannerImage.flatMap { URL(string: $0) }

            return Article(
                id: UUID(),
                feedId: UUID(),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url,
                author: item.author?.name,
                summary: summary.isEmpty ? nil : summary,
                content: content,
                imageUrl: imageUrl,
                publishedAt: publishedAt,
                isRead: false,
                isFavorite: false,
                readAt: nil
            )
        }
    }

    private func extractImageUrl(from html: String) -> URL? {
        // Look for og:image meta tag first
        if let ogImage = extractMetaContent(from: html, property: "og:image") {
            return URL(string: ogImage)
        }
        // Fall back to first img tag
        let pattern = #"<img[^>]+src\s*=\s*[\"']([^\"']+)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return URL(string: String(html[range]))
    }

    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = #"<meta[^>]+property\s*=\s*[\"']" + NSRegularExpression.escapedPattern(for: property) + #"[\"'][^>]+content\s*=\s*[\"']([^\"']+)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }
}
