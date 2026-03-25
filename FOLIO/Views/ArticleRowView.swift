import SwiftUI
import Kingfisher

struct ArticleRowView: View {
    let article: Article
    @EnvironmentObject var appState: FOLIOAppState

    private var feed: Feed? {
        appState.feeds.first { $0.id == article.feedId }
    }

    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: article.publishedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            Group {
                if let imageUrl = article.imageUrl {
                    KFImage(imageUrl)
                        .placeholder {
                            placeholderImage
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 60)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    placeholderImage
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                HStack(spacing: 6) {
                    if !article.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                    Text(article.title)
                        .font(.system(size: 14, weight: article.isRead ? .regular : .semibold))
                        .foregroundColor(article.isRead ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Feed name and date
                HStack(spacing: 8) {
                    if let feedName = feed?.title {
                        Text(feedName)
                            .font(.caption)
                            .foregroundColor(Color(hex: "#4A90D9"))
                    }
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let author = article.author {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Summary
                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            // Favorite indicator
            if article.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .keyboardShortcut(" ", modifiers: [])
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 80, height: 60)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
    }
}
