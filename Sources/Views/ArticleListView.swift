import SwiftUI
import Kingfisher

struct ArticleListView: View {
    @EnvironmentObject var appState: FOLIOAppState
    @EnvironmentObject var articleListVM: ArticleListViewModel
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case favorites = "Favorites"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                Picker("Filter", selection: $filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                if appState.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Article list
            List(articleListVM.articles) { article in
                ArticleRowView(article: article)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        articleListVM.selectedArticle = article
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .onReceive(NotificationCenter.default.publisher(for: .toggleRead)) { notification in
                        if let articleId = notification.object as? UUID, articleId == article.id {
                            articleListVM.toggleRead(for: article)
                        }
                    }
            }
            .listStyle(.plain)
            .overlay {
                if articleListVM.articles.isEmpty {
                    EmptyStateView(
                        title: "No Articles",
                        systemImage: "newspaper",
                        description: "Add a feed to get started"
                    )
                }
            }
        }
        .frame(minWidth: 350)
        .searchable(text: $searchText, prompt: "Search articles")
        .onChange(of: appState.selectedFeed) { newFeed in
            articleListVM.loadArticles(for: newFeed, filter: filterMode)
        }
        .onChange(of: appState.selectedCategory) { newCategory in
            articleListVM.loadArticles(forFeed: nil, category: newCategory, filter: filterMode)
        }
        .onChange(of: filterMode) { newMode in
            if let feed = appState.selectedFeed {
                articleListVM.loadArticles(for: feed, filter: newMode)
            } else {
                articleListVM.loadArticles(forFeed: nil, category: appState.selectedCategory, filter: filterMode)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllFeeds)) { _ in
            if let feed = appState.selectedFeed {
                articleListVM.loadArticles(for: feed, filter: filterMode)
            }
        }
        .onAppear {
            if let feed = appState.selectedFeed {
                articleListVM.loadArticles(for: feed, filter: filterMode)
            } else {
                articleListVM.loadArticles(forFeed: nil, category: appState.selectedCategory, filter: filterMode)
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

extension Notification.Name {
    static let toggleRead = Notification.Name("toggleRead")
}
