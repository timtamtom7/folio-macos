import Foundation
import AppKit

// MARK: - Plugin Manifest

public struct FOLIOPluginManifest: Codable {
    public let name: String
    public let version: String
    public let author: String
    public let description: String
    public let permissions: [String]
    public let actions: [String]
    
    public init(name: String, version: String, author: String, description: String, permissions: [String], actions: [String]) {
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.permissions = permissions
        self.actions = actions
    }
}

// MARK: - Plugin Action

public struct PluginAction {
    public let title: String
    public let icon: String?
    public let identifier: String
    
    public init(title: String, icon: String?, identifier: String) {
        self.title = title
        self.icon = icon
        self.identifier = identifier
    }
}

// MARK: - Plugin Article

public struct PluginArticle {
    public let id: String
    public let title: String
    public let url: String
    public let content: String
    public let author: String?
    
    public init(id: String, title: String, url: String, content: String, author: String?) {
        self.id = id
        self.title = title
        self.url = url
        self.content = content
        self.author = author
    }
}

// MARK: - Plugin Protocol

public protocol FOLIOPlugin {
    var manifest: FOLIOPluginManifest { get }
    func process(content: String, for article: PluginArticle) -> String
    func toolbarAction(for article: PluginArticle) -> PluginAction?
}

// MARK: - Plugin Manager

final class PluginManager {
    static let shared = PluginManager()
    
    @Published var loadedPlugins: [LoadedPlugin] = []
    
    private init() {
        loadPlugins()
    }
    
    struct LoadedPlugin {
        let id: UUID
        let manifest: FOLIOPluginManifest
        let bundle: Bundle
        let instance: FOLIOPlugin?
    }
    
    func loadPlugins() {
        // Look for plugins in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pluginsDir = appSupport.appendingPathComponent("FOLIO/Plugins", isDirectory: true)
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        for item in contents where item.pathExtension == "folioplugin" {
            loadPlugin(at: item)
        }
    }
    
    private func loadPlugin(at url: URL) {
        guard let bundle = Bundle(url: url),
              let manifest = loadManifest(from: bundle) else {
            return
        }
        
        // Try to instantiate the principal class as a FOLIOPlugin
        var instance: FOLIOPlugin? = nil
        // Note: Plugin instantiation would require more complex reflection
        // For now, plugins are registered via manual calls
        
        let plugin = LoadedPlugin(
            id: UUID(),
            manifest: manifest,
            bundle: bundle,
            instance: instance
        )
        
        loadedPlugins.append(plugin)
    }
    
    private func loadManifest(from bundle: Bundle) -> FOLIOPluginManifest? {
        guard let manifestURL = bundle.url(forResource: "plugin", withExtension: "json"),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(FOLIOPluginManifest.self, from: data) else {
            return nil
        }
        return manifest
    }
    
    // MARK: - Content Processing
    
    func processContent(_ content: String, for article: Article) -> String {
        var processedContent = content
        
        for plugin in loadedPlugins {
            if let instance = plugin.instance,
               plugin.manifest.actions.contains("contentProcessor") {
                let pluginArticle = PluginArticle(
                    id: article.id.uuidString,
                    title: article.title,
                    url: article.url.absoluteString,
                    content: article.content ?? "",
                    author: article.author
                )
                processedContent = instance.process(content: processedContent, for: pluginArticle)
            }
        }
        
        return processedContent
    }
    
    // MARK: - Plugin Management
    
    func installPlugin(from url: URL) throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pluginsDir = appSupport.appendingPathComponent("FOLIO/Plugins", isDirectory: true)
        
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
        
        let destination = pluginsDir.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
        
        loadPlugins()
    }
    
    func uninstallPlugin(id: UUID) {
        if let plugin = loadedPlugins.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: plugin.bundle.bundleURL)
            loadedPlugins.removeAll { $0.id == id }
        }
    }
}
