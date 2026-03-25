import SwiftUI

struct ICloudSyncSettingsView: View {
    @StateObject private var syncService = iCloudSyncService.shared
    @State private var showingBackup = false
    @State private var backupStatus: String = ""
    @State private var showingRestore = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable iCloud Sync", isOn: Binding(
                    get: { syncService.isEnabled },
                    set: { syncService.setEnabled($0) }
                ))
                
                if syncService.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .foregroundColor(.secondary)
                    }
                } else if let lastSync = syncService.lastSyncDate {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = syncService.syncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            } header: {
                Text("iCloud Sync")
            }
            
            Section {
                Button("Sync Now") {
                    syncService.performSync()
                }
                .disabled(syncService.isSyncing || !syncService.isEnabled)
            }
            
            Section {
                Button("Create Backup...") {
                    createBackup()
                }
                
                Button("Restore from Backup...") {
                    showingRestore = true
                }
                
                if !backupStatus.isEmpty {
                    Text(backupStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Backup")
            }
            
            Section {
                if !syncService.getSyncLog().isEmpty {
                    List(syncService.getSyncLog().reversed().prefix(10), id: \.timestamp) { entry in
                        HStack {
                            Image(systemName: entry.success ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(entry.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(entry.action)
                                    .font(.subheadline)
                                Text(entry.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Sync Log")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 400)
        .fileImporter(
            isPresented: $showingRestore,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    restoreBackup(at: url)
                }
            case .failure(let error):
                backupStatus = "Failed to select backup: \(error.localizedDescription)"
            }
        }
    }
    
    private func createBackup() {
        BackupService.shared.createBackup { result in
            switch result {
            case .success(let url):
                backupStatus = "Backup created: \(url.lastPathComponent)"
            case .failure(let error):
                backupStatus = "Backup failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func restoreBackup(at url: URL) {
        // Start accessing security scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            backupStatus = "Failed to access backup file"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        BackupService.shared.restoreFromBackup(at: url) { result in
            switch result {
            case .success:
                backupStatus = "Restore completed successfully"
            case .failure(let error):
                backupStatus = "Restore failed: \(error.localizedDescription)"
            }
        }
    }
}
