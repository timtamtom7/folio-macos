import SwiftUI

struct ReadingQueueView: View {
    @StateObject private var viewModel = ReadingQueueViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Reading Queue")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(viewModel.queuedArticles.count) articles")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            if viewModel.queuedArticles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Queue Empty")
                        .font(.title2)
                    Text("Add articles to your reading queue to save them for later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.queuedArticles) { article in
                        QueueArticleRow(article: article, viewModel: viewModel)
                    }
                    .onMove { source, destination in
                        viewModel.moveArticle(from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeFromQueue(viewModel.queuedArticles[index])
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear All") {
                    viewModel.clearQueue()
                }
            }
        }
    }
}

struct QueueArticleRow: View {
    let article: Article
    @ObservedObject var viewModel: ReadingQueueViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    if let author = article.author {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                    }
                    Text(article.publishedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.removeFromQueue(article)
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                viewModel.removeFromQueue(article)
            } label: {
                Label("Remove from Queue", systemImage: "tray.remove")
            }
            
            Button {
                viewModel.markAsRead(article)
            } label: {
                Label("Mark as Read", systemImage: "checkmark.circle")
            }
        }
    }
}

final class ReadingQueueViewModel: ObservableObject {
    @Published var queuedArticles: [Article] = []
    
    private let queueKey = "reading_queue"
    private let articleStore = SQLiteArticleStore()
    
    init() {
        loadQueue()
    }
    
    func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else {
            queuedArticles = []
            return
        }
        
        // Load articles in queue order
        let allArticles = articleStore.getArticles(feedId: nil, categoryId: nil, filter: .all)
        queuedArticles = ids.compactMap { id in
            allArticles.first { $0.id == id }
        }
    }
    
    func addToQueue(_ article: Article) {
        if !queuedArticles.contains(where: { $0.id == article.id }) {
            queuedArticles.append(article)
            saveQueue()
        }
    }
    
    func removeFromQueue(_ article: Article) {
        queuedArticles.removeAll { $0.id == article.id }
        saveQueue()
    }
    
    func moveArticle(from source: IndexSet, to destination: Int) {
        queuedArticles.move(fromOffsets: source, toOffset: destination)
        saveQueue()
    }
    
    func clearQueue() {
        queuedArticles.removeAll()
        saveQueue()
    }
    
    func markAsRead(_ article: Article) {
        articleStore.markRead(articleId: article.id)
        objectWillChange.send()
    }
    
    private func saveQueue() {
        let ids = queuedArticles.map { $0.id }
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}
