import SwiftUI
import Kingfisher

struct ArticleRowView: View {
    let article: Article
    @EnvironmentObject var appState: FOLIOAppState
    @State private var isRead: Bool = false

    private let articleStore = SQLiteArticleStore()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let imageUrl = article.imageUrl {
                KFImage(imageUrl)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 60)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(article.isRead ? Color.clear : Color.accentColor)
                        .frame(width: 8, height: 8)

                    Text(article.title)
                        .font(.system(size: 14, weight: article.isRead ? .regular : .semibold))
                        .foregroundColor(article.isRead ? .secondary : .primary)
                        .lineLimit(2)

                    Spacer()

                    if article.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                HStack {
                    Text(article.author ?? "Unknown Feed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(article.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onAppear {
            isRead = article.isRead
        }
    }
}
