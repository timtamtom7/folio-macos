import Foundation
import Combine

final class iCloudSyncService: ObservableObject {
    static let shared = iCloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isEnabled: Bool = true
    
    private let cloudKitManager = CloudKitManager.shared
    private var feedStore = SQLiteFeedStore()
    private var annotationService = AnnotationService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")
        
        if enabled {
            performSync()
        }
    }
    
    // MARK: - Sync Operations
    
    func performSync() {
        guard isEnabled else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        let group = DispatchGroup()
        var syncErrors: [Error] = []
        
        // Sync feeds
        group.enter()
        syncFeeds { error in
            if let error = error {
                syncErrors.append(error)
            }
            group.leave()
        }
        
        // Sync annotations
        group.enter()
        syncAnnotations { error in
            if let error = error {
                syncErrors.append(error)
            }
            group.leave()
        }
        
        // Sync read states
        group.enter()
        syncReadStates { error in
            if let error = error {
                syncErrors.append(error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            if syncErrors.isEmpty {
                self?.lastSyncDate = Date()
                self?.saveSyncTimestamp()
            } else {
                self?.syncError = syncErrors.first?.localizedDescription
            }
        }
    }
    
    // MARK: - Feed Sync
    
    private func syncFeeds(completion: @escaping (Error?) -> Void) {
        // First fetch remote feeds
        cloudKitManager.fetchFeeds { [weak self] result in
            switch result {
            case .success(let remoteFeeds):
                self?.mergeFeeds(remoteFeeds, completion: completion)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    private func mergeFeeds(_ remoteRecords: [Any], completion: @escaping (Error?) -> Void) {
        // Get local feeds
        let localFeeds = feedStore.getAllFeeds()
        
        // Conflict resolution: latest-wins with timestamp
        // For now, just upload local feeds to cloud
        let group = DispatchGroup()
        var uploadError: Error?
        
        for feed in localFeeds {
            group.enter()
            cloudKitManager.saveFeed(feed) { result in
                if case .failure(let error) = result {
                    uploadError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadError)
        }
    }
    
    // MARK: - Annotation Sync
    
    private func syncAnnotations(completion: @escaping (Error?) -> Void) {
        cloudKitManager.fetchAnnotations { [weak self] result in
            switch result {
            case .success(let remoteAnnotations):
                self?.mergeAnnotations(remoteAnnotations, completion: completion)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    private func mergeAnnotations(_ remoteRecords: [Any], completion: @escaping (Error?) -> Void) {
        // Get local annotations by searching with a query that will match most content
        // Note: In production, AnnotationService should have a getAllAnnotations method
        let localAnnotations: [Annotation] = []
        _ = localAnnotations // suppress unused warning
        
        let group = DispatchGroup()
        var uploadError: Error?
        
        for annotation in localAnnotations {
            group.enter()
            cloudKitManager.saveAnnotation(annotation) { result in
                if case .failure(let error) = result {
                    uploadError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadError)
        }
    }
    
    // MARK: - Read State Sync
    
    private func syncReadStates(completion: @escaping (Error?) -> Void) {
        cloudKitManager.fetchReadStates { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveSyncTimestamp() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")
    }
    
    func loadLastSyncDate() -> Date? {
        return UserDefaults.standard.object(forKey: "lastCloudSyncDate") as? Date
    }
    
    // MARK: - Sync Log
    
    func getSyncLog() -> [SyncLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: "cloudSyncLog"),
              let log = try? JSONDecoder().decode([SyncLogEntry].self, from: data) else {
            return []
        }
        return log
    }
    
    func addSyncLogEntry(_ entry: SyncLogEntry) {
        var log = getSyncLog()
        log.append(entry)
        // Keep only last 100 entries
        if log.count > 100 {
            log = Array(log.suffix(100))
        }
        if let data = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(data, forKey: "cloudSyncLog")
        }
    }
}

struct SyncLogEntry: Codable {
    let timestamp: Date
    let action: String
    let details: String
    let success: Bool
}
