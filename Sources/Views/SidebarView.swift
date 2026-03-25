import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: FOLIOAppState
    @EnvironmentObject var feedListVM: FeedListViewModel
    @State private var showCategoryEditor = false
    @State private var selectedFeed: Feed?

    var body: some View {
        List(selection: $appState.selectedFeed) {
            Section("Categories") {
                Button(action: { appState.selectedCategory = nil }) {
                    Label("All Articles", systemImage: "tray.full")
                }
                .buttonStyle(.plain)
                .foregroundColor(appState.selectedCategory == nil ? .accentColor : .primary)

                ForEach(appState.categories) { category in
                    Button(action: { appState.selectedCategory = category }) {
                        Label(category.name, systemImage: "folder")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(appState.selectedCategory?.id == category.id ? .accentColor : .primary)
                    .contextMenu {
                        Button("Delete Category") {
                            appState.deleteCategory(category)
                        }
                    }
                }

                Button(action: { showCategoryEditor = true }) {
                    Label("Add Category", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            Section("Feeds") {
                ForEach(appState.feeds) { feed in
                    FeedRowView(feed: feed)
                        .tag(feed)
                        .contextMenu {
                            Button("Delete Feed") {
                                appState.deleteFeed(feed)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.showAddFeedSheet = true }) {
                    Image(systemName: "plus")
                }
                .help("Add Feed")
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { appState.refreshAllFeeds() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(appState.isRefreshing)
                .help("Refresh All Feeds")
            }
        }
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorSheet()
                .environmentObject(appState)
        }
        .onReceive(feedListVM.$feeds) { feeds in
            // Sync if needed
        }
    }
}

struct FeedRowView: View {
    let feed: Feed
    @EnvironmentObject var appState: FOLIOAppState
    @State private var unreadCount: Int = 0

    private let articleStore = SQLiteArticleStore()

    var body: some View {
        HStack {
            Image(systemName: "newspaper")
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(feed.displayTitle)
                    .font(.system(size: 13))
                    .lineLimit(1)

                if let error = feed.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            unreadCount = articleStore.getUnreadCount(forFeed: feed.id)
        }
    }
}
