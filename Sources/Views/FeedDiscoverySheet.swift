import SwiftUI

struct FeedDiscoverySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FeedDiscoveryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Discover Feeds")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            
            Divider()
            
            // URL Input
            HStack {
                TextField("Enter website URL", text: $viewModel.websiteURL)
                    .textFieldStyle(.roundedBorder)
                Button("Discover") {
                    viewModel.discoverFeeds()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDiscovering || viewModel.websiteURL.isEmpty)
            }
            .padding()
            
            if viewModel.isDiscovering {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Discovering feeds...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.discoveredFeeds.isEmpty && !viewModel.websiteURL.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No feeds found")
                        .font(.title2)
                    Text("Try a different website")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.discoveredFeeds) { feed in
                        DiscoveredFeedRow(feed: feed, viewModel: viewModel)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct DiscoveredFeedRow: View {
    let feed: FeedDiscoveryService.DiscoveredFeed
    @ObservedObject var viewModel: FeedDiscoveryViewModel
    
    var isSelected: Bool {
        viewModel.selectedFeedIds.contains(feed.id)
    }
    
    var body: some View {
        HStack {
            Button {
                viewModel.toggleSelection(feed.id)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title)
                    .font(.headline)
                Text(feed.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let frequency = feed.estimatedUpdateFrequency {
                Text(frequency.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

final class FeedDiscoveryViewModel: ObservableObject {
    @Published var websiteURL: String = ""
    @Published var isDiscovering: Bool = false
    @Published var discoveredFeeds: [FeedDiscoveryService.DiscoveredFeed] = []
    @Published var selectedFeedIds: Set<UUID> = []
    @Published var errorMessage: String?
    
    private let discoveryService = FeedDiscoveryService.shared
    private let feedStore = SQLiteFeedStore()
    
    func discoverFeeds() {
        guard let url = URL(string: websiteURL) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isDiscovering = true
        errorMessage = nil
        
        Task {
            do {
                let feeds = try await discoveryService.discoverFeeds(from: url)
                await MainActor.run {
                    discoveredFeeds = feeds
                    isDiscovering = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isDiscovering = false
                }
            }
        }
    }
    
    func toggleSelection(_ id: UUID) {
        if selectedFeedIds.contains(id) {
            selectedFeedIds.remove(id)
        } else {
            selectedFeedIds.insert(id)
        }
    }
    
    func subscribeToSelectedFeeds() {
        for feed in discoveredFeeds where selectedFeedIds.contains(feed.id) {
            let newFeed = Feed(
                id: UUID(),
                url: feed.url,
                title: feed.title,
                addedAt: Date()
            )
            feedStore.saveFeed(newFeed)
        }
    }
}
