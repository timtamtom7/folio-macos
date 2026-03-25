import SwiftUI
import WebKit

struct ReaderView: View {
    @EnvironmentObject var appState: FOLIOAppState
    @EnvironmentObject var articleListVM: ArticleListViewModel
    @State private var article: Article?

    var body: some View {
        Group {
            if let article = articleListVM.selectedArticle {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            if let author = article.author {
                                Text("By \(author)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text(article.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: { toggleFavorite(article) }) {
                                Image(systemName: article.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(article.isFavorite ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)

                            Button(action: { openInBrowser(article) }) {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()

                    Divider()

                    // Content
                    if let content = article.content, !content.isEmpty {
                        ReaderWebView(html: content)
                    } else if let summary = article.summary {
                        ScrollView {
                            Text(summary)
                                .font(.body)
                                .padding()
                        }
                    } else {
                        EmptyStateView(
                            title: "No Content",
                            systemImage: "doc.text",
                            description: "This article has no content"
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    markAsRead(article)
                }
                .onChange(of: articleListVM.selectedArticle) { newArticle in
                    if let newArticle = newArticle {
                        markAsRead(newArticle)
                    }
                }
            } else {
                EmptyStateView(
                    title: "Select an Article",
                    systemImage: "doc.text.magnifyingglass",
                    description: "Choose an article from the list to read"
                )
            }
        }
    }

    private func markAsRead(_ article: Article) {
        guard !article.isRead else { return }
        let articleStore = SQLiteArticleStore()
        articleStore.markRead(articleId: article.id)
        articleListVM.markRead(article)
        appState.updateUnreadCount()
    }

    private func toggleFavorite(_ article: Article) {
        let articleStore = SQLiteArticleStore()
        articleStore.toggleFavorite(articleId: article.id)
        articleListVM.toggleFavorite(article)
    }

    private func openInBrowser(_ article: Article) {
        NSWorkspace.shared.open(article.url)
    }
}

struct ReaderWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    padding: 20px;
                    max-width: 800px;
                    margin: 0 auto;
                    color: #333;
                }
                img { max-width: 100%; height: auto; }
                a { color: #007AFF; }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
        nsView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
