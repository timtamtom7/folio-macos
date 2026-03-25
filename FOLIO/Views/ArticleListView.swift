import SwiftUI

struct ArticleListView: View {
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filter
            HStack {
                Picker("Filter", selection: $appState.articleFilter) {
                    ForEach(FOLIOAppState.ArticleFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                if appState.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Refreshing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Button {
                        Task { await appState.refreshAllFeeds() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search articles...", text: $appState.searchText)
                    .textFieldStyle(.plain)
                if !appState.searchText.isEmpty {
                    Button {
                        appState.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Article list
            if appState.filteredArticles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No articles")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a feed to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Add Feed") {
                        appState.showAddFeedSheet = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appState.filteredArticles, selection: $appState.selectedArticleId) { article in
                    ArticleRowView(article: article)
                        .tag(article.id)
                        .contextMenu {
                            Button("Mark as Read") {
                                appState.markArticleRead(article.id)
                            }
                            Button("Mark as Unread") {
                                appState.markArticleUnread(article.id)
                            }
                            Divider()
                            Button("Open in Browser") {
                                NSWorkspace.shared.open(article.url)
                            }
                        }
                        .onChange(of: appState.selectedArticleId) { _, newId in
                            if newId == article.id {
                                appState.markArticleRead(article.id)
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.articleListBackground)
    }
}
