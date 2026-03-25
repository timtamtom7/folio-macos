import SwiftUI

struct InstapaperImportSheet: View {
    @Binding var isPresented: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isVerifying = false
    @State private var importProgress = ""
    @State private var importedCount = 0
    @State private var importComplete = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Import from Instapaper")
                .font(.headline)

            if importComplete {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Imported \(importedCount) bookmarks!")
                        .font(.title3)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Username or Email")
                        .font(.subheadline)
                    TextField("username@email.com", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)

                    Text("Password")
                        .font(.subheadline)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                }
                .padding(.horizontal)

                if isLoading {
                    HStack {
                        ProgressView()
                        Text(importProgress)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isLoading)

                    Button(isVerifying ? "Verifying..." : "Import") {
                        importFromInstapaper()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                }
            }
        }
        .frame(width: 400, height: importComplete ? 220 : 320)
        .padding()
    }

    private func importFromInstapaper() {
        isLoading = true
        isVerifying = true
        errorMessage = nil

        Task {
            let service = InstapaperService()

            do {
                let valid = try await service.verifyCredentials(username: username, password: password)
                guard valid else {
                    await MainActor.run {
                        errorMessage = "Invalid credentials. Please check your username and password."
                        isLoading = false
                        isVerifying = false
                    }
                    return
                }

                await MainActor.run {
                    isVerifying = false
                    importProgress = "Fetching bookmarks..."
                }

                let bookmarks = try await service.importBookmarks(username: username, password: password)
                await MainActor.run {
                    importedCount = bookmarks.count
                    importProgress = "Imported \(bookmarks.count) bookmarks"
                    importComplete = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    isVerifying = false
                }
            }
        }
    }
}
