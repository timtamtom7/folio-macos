import Foundation
import SQLite

final class OPMLService {
    private let feedStore = SQLiteFeedStore()
    private let articleStore = SQLiteArticleStore()
    private var categorySortOrder = 0

    struct OPMLOutline {
        var text: String
        var xmlUrl: String?
        var htmlUrl: String?
        var children: [OPMLOutline]
    }

    struct ImportResult {
        var feedsImported: Int
        var categoriesImported: Int
        var errors: [String]
    }

    func exportOPML() -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
        <head>
            <title>FOLIO Export</title>
            <dateCreated>\(ISO8601DateFormatter().string(from: Date()))</dateCreated>
        </head>
        <body>

        """

        let categories = feedStore.getAllCategories()
        let allFeeds = feedStore.getAllFeeds()
        for category in categories {
            let feeds = allFeeds.filter { $0.categoryId == category.id }
            if feeds.isEmpty { continue }

            xml += "  <outline text=\"\(escapeXML(category.name))\" title=\"\(escapeXML(category.name))\">\n"
            for feed in feeds {
                xml += "    <outline text=\"\(escapeXML(feed.displayTitle))\" title=\"\(escapeXML(feed.displayTitle))\" xmlUrl=\"\(escapeXML(feed.url.absoluteString))\""
                if let siteUrl = feed.siteUrl {
                    xml += " htmlUrl=\"\(escapeXML(siteUrl.absoluteString))\""
                }
                xml += " />\n"
            }
            xml += "  </outline>\n"
        }

        // Uncategorized feeds
        let uncategorizedFeeds = allFeeds.filter { $0.categoryId == nil }
        for feed in uncategorizedFeeds {
            xml += "  <outline text=\"\(escapeXML(feed.displayTitle))\" title=\"\(escapeXML(feed.displayTitle))\" xmlUrl=\"\(escapeXML(feed.url.absoluteString))\""
            if let siteUrl = feed.siteUrl {
                xml += " htmlUrl=\"\(escapeXML(siteUrl.absoluteString))\""
            }
            xml += " />\n"
        }

        xml += """
        </body>
        </opml>
        """

        return xml
    }

    func importOPML(from url: URL) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw OPMLError.invalidEncoding
        }
        return try await importOPML(content: content)
    }

    func importOPML(content: String) async throws -> ImportResult {
        var result = ImportResult(feedsImported: 0, categoriesImported: 0, errors: [])
        var existingUrls = Set<String>()
        let existingFeeds = feedStore.getAllFeeds()
        for feed in existingFeeds {
            existingUrls.insert(feed.url.absoluteString)
        }

        let outlines = parseOPML(content)
        var importedCategoryIds: [String: UUID] = [:]

        for outline in outlines {
            if let xmlUrl = outline.xmlUrl, !xmlUrl.isEmpty {
                if existingUrls.contains(xmlUrl) {
                    result.errors.append("Skipped duplicate: \(outline.text)")
                    continue
                }
                existingUrls.insert(xmlUrl)
                await addFeed(from: outline, categoryId: nil)
                result.feedsImported += 1
            } else if !outline.children.isEmpty {
                // It's a category
                let category = Category(
                    id: UUID(),
                    name: outline.text,
                    sortOrder: categorySortOrder,
                    colorHex: "#007AFF"
                )
                categorySortOrder += 1
                feedStore.saveCategory(category)
                importedCategoryIds[outline.text] = category.id
                result.categoriesImported += 1

                for child in outline.children {
                    if let xmlUrl = child.xmlUrl, !xmlUrl.isEmpty {
                        if existingUrls.contains(xmlUrl) {
                            result.errors.append("Skipped duplicate: \(child.text)")
                            continue
                        }
                        existingUrls.insert(xmlUrl)
                        await addFeed(from: child, categoryId: category.id)
                        result.feedsImported += 1
                    }
                }
            }
        }

        return result
    }

    private func addFeed(from outline: OPMLOutline, categoryId: UUID?) async {
        guard let xmlUrlString = outline.xmlUrl, let xmlUrl = URL(string: xmlUrlString) else { return }
        let feed = Feed(
            id: UUID(),
            url: xmlUrl,
            title: outline.text,
            siteUrl: outline.htmlUrl.flatMap { URL(string: $0) },
            iconUrl: nil,
            categoryId: categoryId,
            addedAt: Date(),
            lastFetchedAt: nil,
            errorMessage: nil
        )
        feedStore.saveFeed(feed)
    }

    private func parseOPML(_ content: String) -> [OPMLOutline] {
        var outlines: [OPMLOutline] = []
        let regex = try? NSRegularExpression(pattern: "<outline([\\s\\S]*?)/>", options: [])
        guard let matches = regex?.matches(in: content, range: NSRange(content.startIndex..., in: content)) else {
            return outlines
        }

        for match in matches {
            guard let fullRange = Range(match.range, in: content),
                  let attrsRange = Range(match.range(at: 1), in: content) else { continue }
            let attrs = String(content[attrsRange])
            let outline = parseOutlineAttributes(attrs)
            outlines.append(outline)
        }

        return outlines
    }

    private func parseOutlineAttributes(_ attrs: String) -> OPMLOutline {
        var text = ""
        var xmlUrl: String?
        var htmlUrl: String?

        let textRegex = try? NSRegularExpression(pattern: "text=\"([^\"]*)\"")
        if let match = textRegex?.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
           let range = Range(match.range(at: 1), in: attrs) {
            text = String(attrs[range])
        }

        let xmlUrlRegex = try? NSRegularExpression(pattern: "xmlUrl=\"([^\"]*)\"")
        if let match = xmlUrlRegex?.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
           let range = Range(match.range(at: 1), in: attrs) {
            xmlUrl = String(attrs[range])
        }

        let htmlUrlRegex = try? NSRegularExpression(pattern: "htmlUrl=\"([^\"]*)\"")
        if let match = htmlUrlRegex?.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
           let range = Range(match.range(at: 1), in: attrs) {
            htmlUrl = String(attrs[range])
        }

        return OPMLOutline(text: text, xmlUrl: xmlUrl, htmlUrl: htmlUrl, children: [])
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    enum OPMLError: LocalizedError {
        case invalidEncoding
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidEncoding: return "Could not read OPML file as text"
            case .invalidFormat: return "Invalid OPML format"
            }
        }
    }
}
