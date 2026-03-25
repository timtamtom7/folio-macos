import Foundation

final class BackupService {
    static let shared = BackupService()
    
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        backupDirectory = appSupport.appendingPathComponent("FOLIO/backups", isDirectory: true)
        
        // Create backup directory if needed
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Export
    
    func createBackup(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let tempDir = self.fileManager.temporaryDirectory.appendingPathComponent("folio-backup-\(UUID().uuidString)")
                try self.fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // Export feeds
                let feedStore = SQLiteFeedStore()
                let feeds = feedStore.getAllFeeds()
                let feedsData = try JSONEncoder().encode(feeds)
                try feedsData.write(to: tempDir.appendingPathComponent("feeds.json"))
                
                // Export articles (metadata only) - search with empty query
                let articleStore = SQLiteArticleStore()
                let articles = articleStore.searchArticles(query: "")
                let articlesData = try JSONEncoder().encode(articles)
                try articlesData.write(to: tempDir.appendingPathComponent("articles.json"))
                
                // Export settings
                let settings = self.exportSettings()
                let settingsData = try JSONEncoder().encode(settings)
                try settingsData.write(to: tempDir.appendingPathComponent("settings.json"))
                
                // Export OPML
                let opmlService = OPMLService()
                let opml = opmlService.exportOPML()
                try opml.write(to: tempDir.appendingPathComponent("opml/export.opml"), atomically: true, encoding: .utf8)
                
                // Create ZIP
                let zipPath = self.backupDirectory.appendingPathComponent("folio-backup-\(self.formattedDate()).zip")
                try self.createZip(from: tempDir, to: zipPath)
                
                // Cleanup temp dir
                try? self.fileManager.removeItem(at: tempDir)
                
                // Rotate backups (keep last 5)
                self.rotateBackups()
                
                DispatchQueue.main.async {
                    completion(.success(zipPath))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createZip(from sourceDir: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        
        coordinator.coordinate(readingItemAt: sourceDir, options: .forUploading, error: &coordinatorError) { zipURL in
            do {
                try fileManager.copyItem(at: zipURL, to: destinationURL)
            } catch {
                print("Error copying zip: \(error)")
            }
        }
        
        if let error = coordinatorError {
            throw error
        }
    }
    
    private func rotateBackups() {
        let backupFiles = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "zip" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
        
        if let files = backupFiles, files.count > 5 {
            for file in files.suffix(from: 5) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Import
    
    func restoreFromBackup(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Extract ZIP
                let tempDir = self.fileManager.temporaryDirectory.appendingPathComponent("folio-restore-\(UUID().uuidString)")
                try self.fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // Import feeds
                if let feedsData = try? Data(contentsOf: tempDir.appendingPathComponent("feeds.json")) {
                    let feeds = try JSONDecoder().decode([Feed].self, from: feedsData)
                    self.importFeeds(feeds)
                }
                
                // Import settings
                if let settingsData = try? Data(contentsOf: tempDir.appendingPathComponent("settings.json")) {
                    let settings = try JSONDecoder().decode([String: String].self, from: settingsData)
                    self.importSettings(settings)
                }
                
                // Cleanup
                try? self.fileManager.removeItem(at: tempDir)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func importFeeds(_ feeds: [Feed]) {
        let feedStore = SQLiteFeedStore()
        for feed in feeds {
            feedStore.saveFeed(feed)
        }
    }
    
    private func importSettings(_ settings: [String: String]) {
        for (key, value) in settings {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
    
    private func exportSettings() -> [String: String] {
        let keys = [
            "iCloudSyncEnabled",
            "refreshInterval",
            "readerFontSize",
            "readerFontFamily",
            "readerTheme",
            "notificationsEnabled",
            "markAsReadOnScroll",
            "openArticlesInNewWindow"
        ]
        
        var settings: [String: String] = [:]
        for key in keys {
            if let value = UserDefaults.standard.string(forKey: key) {
                settings[key] = value
            }
        }
        return settings
    }
    
    // MARK: - Auto Backup
    
    func performAutoBackupIfNeeded() {
        let lastAutoBackup = UserDefaults.standard.object(forKey: "lastAutoBackupDate") as? Date ?? .distantPast
        let calendar = Calendar.current
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        if lastAutoBackup < dayAgo {
            createBackup { result in
                if case .success = result {
                    UserDefaults.standard.set(Date(), forKey: "lastAutoBackupDate")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
    
    func listBackups() -> [URL] {
        return (try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "zip" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }) ?? []
    }
}
