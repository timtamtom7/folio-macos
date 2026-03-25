import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        List {
            // Filter section
            Section("Library") {
                FilterRow(icon: "newspaper", title: "All Articles", count: appState.articles.count, isSelected: appState.selectedFeedId == nil && appState.articleFilter == .all) {
                    appState.selectedFeedId = nil
                    appState.articleFilter = .all
                }

                FilterRow(icon: "eye", title: "Unread", count: appState.articles.filter { !$0.isRead }.count, isSelected: appState.articleFilter == .unread) {
                    appState.articleFilter = .unread
                    appState.selectedFeedId = nil
                }

                FilterRow(icon: "star", title: "Favorites", count: appState.articles.filter { $0.isFavorite }.count, isSelected: appState.articleFilter == .favorites) {
                    appState.articleFilter = .favorites
                    appState.selectedFeedId = nil
                }
            }

            // Categories section
            Section("Categories") {
                ForEach(appState.categories) { category in
                    CategoryRow(category: category, feeds: feedsForCategory(category.id))
                        .contextMenu {
                            Button("Delete Category", role: .destructive) {
                                appState.deleteCategory(id: category.id)
                            }
                        }
                }

                Button {
                    appState.addCategory(name: "New Category", colorHex: "#4A90D9")
                } label: {
                    Label("Add Category", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            // Feeds section
            Section("Feeds") {
                ForEach(appState.feeds.filter { $0.categoryId == nil }) { feed in
                    FeedRow(feed: feed)
                        .contextMenu {
                            Button("Refresh") {
                                Task { await appState.refreshFeed(id: feed.id) }
                            }
                            Button("Delete", role: .destructive) {
                                appState.deleteFeed(id: feed.id)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.showAddFeedSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func feedsForCategory(_ categoryId: UUID) -> [Feed] {
        appState.feeds.filter { $0.categoryId == categoryId }
    }
}

struct FilterRow: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
    }
}

struct CategoryRow: View {
    let category: Category
    let feeds: [Feed]
    @EnvironmentObject var appState: FOLIOAppState
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(feeds) { feed in
                FeedRow(feed: feed)
                    .padding(.leading, 12)
                    .contextMenu {
                        Button("Remove from Category") {
                            var updatedFeed = feed
                            updatedFeed.categoryId = nil
                        }
                        Button("Delete", role: .destructive) {
                            appState.deleteFeed(id: feed.id)
                        }
                    }
            }
        } label: {
            HStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 8, height: 8)
                Text(category.name)
                Spacer()
                Text("\(feeds.count)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

struct FeedRow: View {
    let feed: Feed
    @EnvironmentObject var appState: FOLIOAppState

    var unreadCount: Int {
        appState.articles.filter { $0.feedId == feed.id && !$0.isRead }.count
    }

    var body: some View {
        Button {
            appState.selectedFeedId = feed.id
            appState.articleFilter = .all
        } label: {
            HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(Color(hex: "#4A90D9"))
                    .frame(width: 16)
                Text(feed.title)
                    .lineLimit(1)
                Spacer()
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
