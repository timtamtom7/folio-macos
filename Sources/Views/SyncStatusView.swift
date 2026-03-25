import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var feedbinService = FeedbinService.shared
    @ObservedObject var feedlyService = FeedlyService.shared

    var body: some View {
        HStack(spacing: 8) {
            if feedbinService.isConnected {
                HStack(spacing: 4) {
                    Circle()
                        .fill(syncColor)
                        .frame(width: 8, height: 8)
                    Text("Feedbin")
                        .font(.caption2)
                    if let lastSync = feedbinService.lastSyncedAt {
                        Text(lastSync, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if feedlyService.isConnected {
                HStack(spacing: 4) {
                    Circle()
                        .fill(syncColor)
                        .frame(width: 8, height: 8)
                    Text("Feedly")
                        .font(.caption2)
                    if let lastSync = feedlyService.lastSyncedAt {
                        Text(lastSync, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var syncColor: Color {
        if feedbinService.lastSyncedAt == nil && feedlyService.lastSyncedAt == nil {
            return .orange
        }
        return .green
    }
}
