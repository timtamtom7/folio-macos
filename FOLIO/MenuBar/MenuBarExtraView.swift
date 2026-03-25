import SwiftUI

struct MenuBarExtraView: View {
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("FOLIO")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await appState.refreshAllFeeds() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Unread count
            HStack {
                Text("Unread Articles")
                    .font(.subheadline)
                Spacer()
                Text("\(appState.unreadCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Recent articles
            let recentArticles = Array(appState.articles.prefix(5))
            if recentArticles.isEmpty {
                Text("No articles yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(recentArticles) { article in
                    MenuBarArticleRow(article: article)
                }
            }

            Divider()

            // Open app
            Button("Open FOLIO") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Quit
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
    }
}

struct MenuBarArticleRow: View {
    let article: Article
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        Button {
            NSWorkspace.shared.open(article.url)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(article.isRead ? Color.clear : Color.blue)
                    .frame(width: 6, height: 6)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    Text(article.publishedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
