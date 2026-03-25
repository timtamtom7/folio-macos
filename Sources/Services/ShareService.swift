import Foundation
import AppKit

final class ShareService {
    static let shared = ShareService()

    private let shareTargetsStore = ShareTargetsStore()

    func getShareTargets() -> [ShareTarget] {
        shareTargetsStore.getAllTargets()
    }

    func shareArticle(_ article: Article, target: ShareTarget) async throws {
        switch target.type {
        case "markdown":
            try shareAsMarkdown(article)
        case "obsidian":
            try await shareToObsidian(article, target: target)
        case "clipboard":
            shareToClipboard(article)
        default:
            throw ShareError.unknownTarget
        }
    }

    private func shareAsMarkdown(_ article: Article) throws {
        let markdown = "[\(article.title)](\(article.url.absoluteString))"
        shareToClipboardWithString(markdown)
    }

    private func shareToClipboardWithString(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private func shareToClipboard(_ article: Article) {
        shareToClipboardWithString(article.url.absoluteString)
    }

    private func shareToObsidian(_ article: Article, target: ShareTarget) async throws {
        guard let config = target.config,
              let data = config.data(using: .utf8),
              let configDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let folderPath = configDict["folder"] as? String else {
            throw ShareError.invalidConfig
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(dateFormatter.string(from: Date()))-\(article.title.prefix(50)).md"

        let sanitizedTitle = article.title.replacingOccurrences(of: "/", with: "-")
        let safeFilename = "\(dateFormatter.string(from: Date()))-\(sanitizedTitle.prefix(50)).md"

        let content = """
        # \(article.title)

        **Source:** [\(article.url.absoluteString)](\(article.url.absoluteString))

        **Author:** \(article.author ?? "Unknown")
        **Published:** \(article.publishedAt)

        ---

        \(article.summary ?? "")

        [Read article](\(article.url.absoluteString))
        """

        let filePath = (folderPath as NSString).appendingPathComponent(safeFilename)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    func showSharePicker(for article: Article, from view: NSView) {
        let picker = NSSharingServicePicker(items: [
            ShareItem(title: article.title, url: article.url)
        ])

        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    enum ShareError: LocalizedError {
        case unknownTarget
        case invalidConfig

        var errorDescription: String? {
            switch self {
            case .unknownTarget: return "Unknown share target"
            case .invalidConfig: return "Invalid share target configuration"
            }
        }
    }
}

struct ShareItem: URLPrintable {
    let title: String
    let url: URL
}

protocol URLPrintable {
    var title: String { get }
    var url: URL { get }
}

final class ShareTargetsStore {
    private let key = "shareTargets"

    func getAllTargets() -> [ShareTarget] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let targets = try? JSONDecoder().decode([ShareTarget].self, from: data) else {
            return defaultTargets()
        }
        return targets
    }

    func saveTarget(_ target: ShareTarget) {
        var targets = getAllTargets()
        targets.removeAll { $0.id == target.id }
        targets.append(target)
        saveTargets(targets)
    }

    func deleteTarget(id: UUID) {
        var targets = getAllTargets()
        targets.removeAll { $0.id == id }
        saveTargets(targets)
    }

    private func saveTargets(_ targets: [ShareTarget]) {
        if let data = try? JSONEncoder().encode(targets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func defaultTargets() -> [ShareTarget] {
        [
            ShareTarget(name: "Copy as Markdown", type: "markdown"),
            ShareTarget(name: "Copy Link", type: "clipboard")
        ]
    }
}
