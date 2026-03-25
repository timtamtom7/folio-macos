import SwiftUI

struct AddFeedSheet: View {
    @EnvironmentObject var appState: FOLIOAppState
    @Environment(\.dismiss) private var dismiss
    @State private var feedUrl = ""
    @State private var feedTitle = ""
    @State private var selectedCategory: Category?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Feed")
                .font(.headline)

            Form {
                TextField("Feed URL", text: $feedUrl)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                TextField("Title (optional)", text: $feedTitle)
                    .textFieldStyle(.roundedBorder)

                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as Category?)
                    ForEach(appState.categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .padding()

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: addFeed) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Add")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(feedUrl.isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 400, height: 280)
    }

    private func addFeed() {
        guard let url = URL(string: feedUrl) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.addFeed(url: url, title: feedTitle.isEmpty ? nil : feedTitle, categoryId: selectedCategory?.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
