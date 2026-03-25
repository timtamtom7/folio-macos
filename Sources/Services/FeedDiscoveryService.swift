import Foundation
import SwiftSoup

final class FeedDiscoveryService {
    static let shared = FeedDiscoveryService()
    
    private init() {}
    
    struct DiscoveredFeed: Identifiable {
        let id = UUID()
        let url: URL
        let title: String
        let description: String?
        let estimatedUpdateFrequency: UpdateFrequency?
        
        enum UpdateFrequency: String {
            case hourly = "Hourly"
            case daily = "Daily"
            case weekly = "Weekly"
            case unknown = "Unknown"
        }
    }
    
    func discoverFeeds(from websiteURL: URL) async throws -> [DiscoveredFeed] {
        var discoveredFeeds: [DiscoveredFeed] = []
        
        // First, try to fetch the main page and look for link tags
        let (data, _) = try await URLSession.shared.data(from: websiteURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw DiscoveryError.invalidResponse
        }
        
        // Parse HTML for RSS/Atom link tags
        let doc = try SwiftSoup.parse(html)
        
        // Look for <link rel="alternate"> tags
        let linkTags = try doc.select("link[rel=alternate]")
        for link in linkTags.array() {
            let type = try link.attr("type")
            let href = try link.attr("href")
            let title = try link.attr("title")
            
            if type.contains("rss") || type.contains("atom") {
                let feedURL = resolveURL(href, base: websiteURL)
                if let feedURL = feedURL {
                    discoveredFeeds.append(DiscoveredFeed(
                        url: feedURL,
                        title: title.isEmpty ? websiteURL.host ?? "Feed" : title,
                        description: nil,
                        estimatedUpdateFrequency: .unknown
                    ))
                }
            }
        }
        
        // Also check common paths
        let commonPaths = ["/rss", "/feed", "/atom.xml", "/feed.xml", "/rss.xml", "/feed/", "/rss/"]
        for path in commonPaths {
            if let url = URL(string: path, relativeTo: websiteURL) {
                if await isValidFeed(url) {
                    if !discoveredFeeds.contains(where: { $0.url == url }) {
                        discoveredFeeds.append(DiscoveredFeed(
                            url: url,
                            title: websiteURL.host ?? "Feed",
                            description: nil,
                            estimatedUpdateFrequency: .unknown
                        ))
                    }
                }
            }
        }
        
        return discoveredFeeds
    }
    
    private func resolveURL(_ href: String, base: URL) -> URL? {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return URL(string: href)
        } else if href.hasPrefix("/") {
            return URL(string: href, relativeTo: base)
        } else {
            return URL(string: href, relativeTo: base)
        }
    }
    
    private func isValidFeed(_ url: URL) async -> Bool {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let str = String(data: data, encoding: .utf8) ?? ""
            return str.contains("<rss") || str.contains("<feed") || str.contains("<atom")
        } catch {
            return false
        }
    }
    
    enum DiscoveryError: Error {
        case invalidResponse
        case noFeedsFound
    }
}
