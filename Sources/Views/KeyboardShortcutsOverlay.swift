import SwiftUI

struct KeyboardShortcutsOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 24) {
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(.title2.bold())
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .top, spacing: 40) {
                    shortcutColumn(title: "Navigation", shortcuts: [
                        ("j / ↓", "Next article"),
                        ("k / ↑", "Previous article"),
                        ("g", "First article"),
                        ("G", "Last article"),
                        ("/", "Focus search"),
                        ("o", "Open in reader"),
                        ("Enter", "Open in browser"),
                        ("Esc", "Close reader")
                    ])

                    shortcutColumn(title: "Article Actions", shortcuts: [
                        ("s", "Save to favorites"),
                        ("m", "Toggle read/unread"),
                        ("u", "Mark unread"),
                        ("r", "Refresh feed"),
                        ("?", "Show this overlay")
                    ])

                    shortcutColumn(title: "Reader", shortcuts: [
                        ("j / ↓", "Scroll down"),
                        ("k / ↑", "Scroll up"),
                        ("Space", "Page down"),
                        ("b", "Page up"),
                        ("Esc", "Close reader"),
                        ("+ / -", "Font size"),
                        ("t", "Toggle theme")
                    ])

                    shortcutColumn(title: "Global", shortcuts: [
                        ("⌘⇧F", "Activate & search"),
                        ("⌘⇧I", "Import OPML"),
                        ("⌘⇧E", "Export OPML"),
                        ("⌘⇧R", "Reader settings"),
                        ("⌘,", "Preferences")
                    ])
                }

                Text("Click anywhere or press Escape to close")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .frame(maxWidth: 800, maxHeight: 500)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
        .onReceive(NotificationCenter.default.publisher(for: .keyPressed)) { notification in
            if let key = notification.userInfo?["key"] as? String, key == "Escape" {
                isPresented = false
            }
        }
    }

    @ViewBuilder
    private func shortcutColumn(title: String, shortcuts: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(shortcuts, id: \.0) { shortcut in
                HStack {
                    Text(shortcut.0)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)

                    Text(shortcut.1)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

extension Notification.Name {
    static let keyPressed = Notification.Name("keyPressed")
}
