import SwiftUI

struct AnnotationPanelView: View {
    let article: Article
    @StateObject private var annotationVM = AnnotationViewModel()
    @State private var newNoteText = ""
    @State private var selectedColor = "#FFE066"
    @State private var showExportMenu = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Annotations")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Export as Markdown") { exportAnnotations(.markdown) }
                    Button("Export as PDF") { exportAnnotations(.pdf) }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Annotation list
            if annotationVM.annotations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No annotations yet")
                        .foregroundColor(.secondary)
                    Text("Select text and click the note icon to add an annotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(annotationVM.annotations) { annotation in
                            AnnotationCard(annotation: annotation, onDelete: {
                                annotationVM.deleteAnnotation(annotation)
                            })
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Add note
            VStack(spacing: 8) {
                if let selectedText = annotationVM.selectedText {
                    Text("\"\(selectedText.prefix(100))...\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack {
                    TextField("Add a note...", text: $newNoteText)
                        .textFieldStyle(.roundedBorder)

                    ColorPicker("", selection: Binding(
                        get: { Color(hex: selectedColor) ?? .yellow },
                        set: { selectedColor = $0.toHex() ?? "#FFE066" }
                    ))
                    .labelsHidden()
                    .frame(width: 30)

                    Button(action: addNote) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(newNoteText.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 280)
        .onAppear {
            annotationVM.loadAnnotations(for: article)
        }
    }

    private func addNote() {
        annotationVM.addAnnotation(
            articleId: article.id,
            content: newNoteText,
            highlightColor: selectedColor
        )
        newNoteText = ""
    }

    private func exportAnnotations(_ format: ExportFormat) {
        switch format {
        case .markdown:
            var md = "# Annotations for: \(article.title)\n\n"
            for annotation in annotationVM.annotations {
                if let selectedText = annotation.selectedText {
                    md += "> \(selectedText)\n"
                }
                md += "\(annotation.content)\n\n---\n\n"
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(md, forType: .string)
        case .pdf:
            break
        }
    }

    enum ExportFormat {
        case markdown
        case pdf
    }
}

struct AnnotationCard: View {
    let annotation: Annotation
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let selectedText = annotation.selectedText {
                Text("\"\(selectedText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Text(annotation.content)
                .font(.body)

            HStack {
                Text(annotation.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: annotation.highlightColor ?? "#FFE066")?.opacity(0.3) ?? .clear, lineWidth: 1)
                )
        )
    }
}

extension Color {
    func toHex() -> String? {
        let nsColor = NSColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.usingColorSpace(.deviceRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red*255), Int(green*255), Int(blue*255))
    }
}
