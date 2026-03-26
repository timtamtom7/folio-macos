import SwiftUI
import WebKit

struct ReaderView: View {
    @EnvironmentObject var appState: FOLIOAppState
    @EnvironmentObject var articleListVM: ArticleListViewModel
    @StateObject private var readerVM = ReaderViewModel()
    @State private var article: Article?
    @State private var showReaderSettings = false
    @State private var showShareSheet = false

    private let contentExtractor = ContentExtractor()

    var body: some View {
        Group {
            if let article = articleListVM.selectedArticle {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    readerHeader(article)

                    Divider()

                    // Content
                    readerContent(article)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { markAsRead(article) }
                .onChange(of: articleListVM.selectedArticle) { newArticle in
                    if let newArticle = newArticle { markAsRead(newArticle) }
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

    @ViewBuilder
    private func readerHeader(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        if let author = article.author {
                            Text("By \(author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(article.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(contentExtractor.estimateReadTime(article))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { toggleFavorite(article) }) {
                        Image(systemName: article.isFavorite ? "star.fill" : "star")
                            .foregroundColor(article.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: { NSWorkspace.shared.open(article.url) }) {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: { copyLink(article) }) {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy link")

                    Button(action: { showReaderSettings.toggle() }) {
                        Image(systemName: "textformat.size")
                            .foregroundColor(showReaderSettings ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showReaderSettings, arrowEdge: .bottom) {
                        ReaderSettingsPopover()
                            .environmentObject(readerVM)
                    }
                    .help("Reader settings")
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func readerContent(_ article: Article) -> some View {
        GeometryReader { geometry in
            if let content = article.content, !content.isEmpty {
                let readTime = contentExtractor.estimateReadTime(article)
                ReaderWebView(
                    html: content,
                    viewModel: readerVM,
                    estimatedReadTime: readTime
                )
                .frame(width: min(geometry.size.width, readerVM.readerWidth.maxWidth))
            } else if let summary = article.summary {
                ScrollView {
                    Text(summary)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: readerVM.readerWidth.maxWidth)
                }
            } else {
                EmptyStateView(
                    title: "No Content",
                    systemImage: "doc.text",
                    description: "This article has no content"
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

    private func copyLink(_ article: Article) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(article.url.absoluteString, forType: .string)
    }
}

struct ReaderWebView: NSViewRepresentable {
    let html: String
    let viewModel: ReaderViewModel
    let estimatedReadTime: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        config.defaultWebpagePreferences = preferences
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let styledHTML = buildStyledHTML()
        nsView.loadHTMLString(styledHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    private func buildStyledHTML() -> String {
        let fontFamily = viewModel.readerFont.cssName
        let bg = viewModel.readerTheme.backgroundColor
        let fg = viewModel.readerTheme.textColor

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: \(fontFamily);
                    font-size: \(viewModel.readerFontSize)px;
                    line-height: 1.7;
                    padding: 24px 32px;
                    max-width: \(viewModel.readerWidth.maxWidth)px;
                    margin: 0 auto;
                    color: \(fg);
                    background-color: \(bg);
                }
                img { max-width: 100%; height: auto; display: block; margin: 16px 0; }
                a { color: #007AFF; text-decoration: none; }
                a:hover { text-decoration: underline; }
                blockquote {
                    border-left: 3px solid #888;
                    margin-left: 0;
                    padding-left: 16px;
                    color: #666;
                }
                pre, code {
                    font-family: Menlo, Courier New, monospace;
                    font-size: 0.9em;
                    background: rgba(128,128,128,0.1);
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                pre { padding: 16px; overflow-x: auto; }
                h1, h2, h3, h4, h5, h6 {
                    line-height: 1.3;
                    margin-top: 24px;
                    margin-bottom: 12px;
                }
                p { margin: 12px 0; }
                figure { margin: 16px 0; }
                figcaption { font-size: 0.85em; color: #888; text-align: center; }
                hr { border: none; border-top: 1px solid rgba(128,128,128,0.3); margin: 24px 0; }
                table { border-collapse: collapse; width: 100%; }
                td, th { border: 1px solid rgba(128,128,128,0.3); padding: 8px; }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }
}
