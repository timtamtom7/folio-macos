import SwiftUI
import UniformTypeIdentifiers

struct ImportOPMLSheet: View {
    @Binding var isPresented: Bool
    @State private var isImporting = false
    @State private var progressText = ""
    @State private var result: OPMLService.ImportResult?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Import OPML")
                .font(.headline)

            if let result = result {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(result.feedsImported) feeds imported", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    if result.categoriesImported > 0 {
                        Label("\(result.categoriesImported) categories imported", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    if !result.errors.isEmpty {
                        Text("Warnings:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ForEach(result.errors.prefix(5), id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if isImporting {
                ProgressView()
                    .padding()
                Text(progressText)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    Text("Select an OPML file to import your feeds and categories.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("Choose File...") {
                        importOPML()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }

            HStack {
                if result != nil || errorMessage != nil {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .frame(width: 400, height: result != nil ? 250 : 200)
    }

    private func importOPML() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "opml") ?? .xml, .xml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isImporting = true
        progressText = "Importing..."
        errorMessage = nil

        Task {
            do {
                let opml = OPMLService()
                let importResult = try await opml.importOPML(from: url)
                await MainActor.run {
                    result = importResult
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }
}
