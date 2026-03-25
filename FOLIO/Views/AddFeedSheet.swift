import SwiftUI

struct AddFeedSheet: View {
    @EnvironmentObject var appState: FOLIOAppState
    @Environment(\.dismiss) var dismiss
    @State private var feedUrl = ""
    @State private var feedTitle = ""
    @State private var selectedCategoryId: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add Feed")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }

            Divider()

            // URL field
            VStack(alignment: .leading, spacing: 4) {
                Text("Feed URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("https://example.com/feed.xml", text: $feedUrl)
                    .textFieldStyle(.roundedBorder)
            }

            // Title field (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Title (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("My Feed", text: $feedTitle)
                    .textFieldStyle(.roundedBorder)
            }

            // Category picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Category (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Category", selection: $selectedCategoryId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(appState.categories) { category in
                        Text(category.name).tag(category.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Add button
            HStack {
                Spacer()
                Button("Add Feed") {
                    addFeed()
                }
                .disabled(feedUrl.isEmpty || isLoading)
            }
        }
        .padding(24)
        .frame(width: 400, height: 300)
    }

    private func addFeed() {
        guard var urlString = feedUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              !urlString.isEmpty else {
            errorMessage = "Please enter a valid URL"
            return
        }

        // Ensure URL has a scheme
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let title = feedTitle.isEmpty ? nil : feedTitle
                try await appState.addFeed(url: url, title: title, categoryId: selectedCategoryId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add feed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
