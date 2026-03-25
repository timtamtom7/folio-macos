import SwiftUI

struct SearchResultsView: View {
    let query: String
    let results: [Article]
    let onSelect: (Article) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Search: \"\(query)\"")
                    .font(.headline)
                Spacer()
                Text("\(results.count) results")
                    .foregroundColor(.secondary)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No articles found for \"\(query)\"")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { article in
                            SearchResultRow(article: article, query: query)
                                .onTapGesture {
                                    onSelect(article)
                                }
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SearchResultRow: View {
    let article: Article
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            highlightedTitleText

            if let summary = article.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(article.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if article.isRead {
                    Text("Read")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .contentShape(Rectangle())
    }

    private var highlightedTitleText: Text {
        var str = AttributedString(article.title)
        if let range = str.range(of: query, options: .caseInsensitive) {
            str[range].backgroundColor = .yellow
        }
        return Text(str)
            .font(.system(size: 14, weight: .medium))
    }
}
