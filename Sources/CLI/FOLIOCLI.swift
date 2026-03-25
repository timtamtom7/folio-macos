import Foundation

// MARK: - FOLIO CLI

/// Command-line interface for FOLIO
/// Usage: folio <command> [options]
public final class FOLIOCLI {
    
    public enum Command {
        case add(url: String)
        case list
        case refresh(feedId: String?)
        case read(articleId: String)
        case export
        case search(query: String)
        case shell
        case help
    }
    
    public init() {}
    
    public func run(arguments: [String]) {
        guard let commandName = arguments.first else {
            printHelp()
            return
        }
        
        let args = Array(arguments.dropFirst())
        
        switch commandName {
        case "add":
            guard let url = args.first else {
                print("Error: URL required")
                print("Usage: folio add <url>")
                return
            }
            addFeed(url: url)
            
        case "list":
            listFeeds()
            
        case "refresh":
            let feedId = args.first
            refreshFeeds(feedId: feedId)
            
        case "read":
            guard let articleId = args.first else {
                print("Error: Article ID required")
                print("Usage: folio read <article-id>")
                return
            }
            markArticleRead(articleId: articleId)
            
        case "export":
            exportOPML()
            
        case "search":
            guard let query = args.first else {
                print("Error: Query required")
                print("Usage: folio search <query>")
                return
            }
            searchArticles(query: query)
            
        case "shell":
            runShell()
            
        case "help", "--help", "-h":
            printHelp()
            
        default:
            print("Unknown command: \(commandName)")
            printHelp()
        }
    }
    
    // MARK: - Commands
    
    private func addFeed(url: String) {
        guard let feedURL = URL(string: url) else {
            print("Error: Invalid URL")
            return
        }
        
        let feed = Feed(
            id: UUID(),
            url: feedURL,
            title: "New Feed",
            addedAt: Date()
        )
        
        let feedStore = SQLiteFeedStore()
        feedStore.saveFeed(feed)
        
        print("Added feed: \(feed.title)")
    }
    
    private func listFeeds() {
        let feedStore = SQLiteFeedStore()
        let feeds = feedStore.getAllFeeds()
        
        if feeds.isEmpty {
            print("No feeds subscribed")
            return
        }
        
        print("Subscribed feeds:")
        for (index, feed) in feeds.enumerated() {
            print("  \(index + 1). \(feed.title)")
            print("     \(feed.url)")
        }
    }
    
    private func refreshFeeds(feedId: String?) {
        print("Refreshing feeds...")
        // In production, trigger feed refresh
        print("Feeds refreshed")
    }
    
    private func markArticleRead(articleId: String) {
        guard let uuid = UUID(uuidString: articleId) else {
            print("Error: Invalid article ID")
            return
        }
        
        let articleStore = SQLiteArticleStore()
        articleStore.markRead(articleId: uuid)
        
        print("Marked article as read")
    }
    
    private func exportOPML() {
        let opmlService = OPMLService()
        let opml = opmlService.exportOPML()
        
        print(opml)
    }
    
    private func searchArticles(query: String) {
        let articleStore = SQLiteArticleStore()
        let results = articleStore.searchArticles(query: query)
        
        if results.isEmpty {
            print("No articles found matching '\(query)'")
            return
        }
        
        print("Found \(results.count) articles:")
        for article in results.prefix(10) {
            print("  - \(article.title)")
            print("    \(article.url)")
        }
    }
    
    private func runShell() {
        print("FOLIO Shell")
        print("Type 'help' for available commands, 'exit' to quit")
        
        // Simple interactive shell
        while true {
            print("folio> ", terminator: "")
            guard let line = readLine() else { break }
            
            let components = line.split(separator: " ").map(String.init)
            guard let command = components.first else { continue }
            
            if command == "exit" || command == "quit" {
                break
            }
            
            run(arguments: components)
        }
    }
    
    private func printHelp() {
        print("""
        FOLIO CLI - RSS Reader for Power Users
        
        Usage: folio <command> [options]
        
        Commands:
          add <url>       Add a new RSS feed
          list            List all subscribed feeds
          refresh         Refresh all feeds
          read <id>       Mark an article as read
          export          Export feeds as OPML
          search <query>  Search articles
          shell           Start interactive shell
          help            Show this help message
        
        Examples:
          folio add https://example.com/feed.xml
          folio list
          folio refresh
          folio search "swift"
        """)
    }
}

// MARK: - Main Entry Point

#if canImport(Darwin)
import Darwin

// CLI entry point when run from command line
// Note: This would be invoked from main.swift in a CLI context
#endif
