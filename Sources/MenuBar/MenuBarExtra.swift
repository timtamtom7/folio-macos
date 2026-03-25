import SwiftUI
import AppKit

final class FOLIOMenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    @Published var appState: FOLIOAppState?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "newspaper.fill", accessibilityDescription: "FOLIO")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 480)
        popover?.behavior = .transient
        popover?.animates = true
    }

    func setAppState(_ state: FOLIOAppState) {
        self.appState = state
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    if let appState = appState {
                        let contentView = MenuBarExtraView(appState: appState)
                        popover.contentViewController = NSHostingController(rootView: contentView)
                    }
                    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open FOLIO", action: #selector(openFOLIO), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit FOLIO", action: #selector(quitFOLIO), keyEquivalent: "")
        menu.delegate = self
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openFOLIO() {
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitFOLIO() {
        NSApp.terminate(nil)
    }

    func updateBadge() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let appState = self.appState else { return }
            let count = appState.unreadCount
            if count > 0 {
                self.statusItem?.button?.title = "\(count)"
            } else {
                self.statusItem?.button?.title = ""
            }
        }
    }
}

struct MenuBarExtraView: View {
    @ObservedObject var appState: FOLIOAppState
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var searchQuery = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(.accentColor)
                Text("FOLIO")
                    .font(.headline)
                Spacer()
                Button(action: { NotificationCenter.default.post(name: Notification.Name("showSettings"), object: nil) }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(unreadArticles.prefix(10)) { article in
                        MenuBarArticleRow(article: article)
                            .onTapGesture {
                                NotificationCenter.default.post(name: .openArticleById, object: nil, userInfo: ["articleId": article.id])
                            }
                        Divider()
                    }

                    if !favoritesVM.favorites.isEmpty {
                        Divider()
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Favorites")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))

                        ForEach(favoritesVM.favorites.prefix(5)) { article in
                            MenuBarArticleRow(article: article)
                                .onTapGesture {
                                    NotificationCenter.default.post(name: .openArticleById, object: nil, userInfo: ["articleId": article.id])
                                }
                            Divider()
                        }
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button(action: openFOLIO) {
                    Text("Open FOLIO")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(8)
        }
        .frame(width: 360, height: 480)
        .onAppear {
            favoritesVM.loadFavorites()
        }
    }

    private var unreadArticles: [Article] {
        let articleStore = SQLiteArticleStore()
        return articleStore.getArticles(feedId: nil, categoryId: nil, filter: .unread)
    }

    private func openFOLIO() {
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MenuBarArticleRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(article.isRead ? Color.clear : Color.accentColor)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.system(size: 13))
                    .lineLimit(2)

                Text(article.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
