import SwiftUI

struct CategoryEditorSheet: View {
    @EnvironmentObject var appState: FOLIOAppState
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var selectedColor = "#4A90D9"

    private let colorOptions = [
        "#4A90D9", "#50C878", "#E74C3C", "#9B59B6",
        "#F39C12", "#1ABC9C", "#34495E", "#E91E63"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("New Category")
                .font(.headline)

            Form {
                TextField("Category Name", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach(colorOptions, id: \.self) { colorHex in
                        Circle()
                            .fill(Color(hex: colorHex) ?? .blue)
                            .frame(width: 28, height: 28)
                            .overlay {
                                if selectedColor == colorHex {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            .onTapGesture {
                                selectedColor = colorHex
                            }
                    }
                }
            }
            .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: saveCategory) {
                    Text("Save")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(categoryName.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 350, height: 280)
    }

    private func saveCategory() {
        appState.addCategory(name: categoryName, colorHex: selectedColor)
        dismiss()
    }
}
