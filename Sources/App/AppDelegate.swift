import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?
    var settingsWindowController: SettingsWindowController?
    var menuBarExtraController: FOLIOMenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DatabaseManager.shared.setup()
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)
        FolioAPIService.shared.start()

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        setupMenu()
        setupNotificationObservers()
        setupGlobalHotkeys()
        setupMenuBarExtra()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestatableState(_ app: NSApplication) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            URLSchemeHandler.shared.handle(url: url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        FolioAPIService.shared.stop()
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About FOLIO", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide FOLIO", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "")
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit FOLIO", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Add Feed...", action: #selector(newFeed(_:)), keyEquivalent: "n")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Import OPML...", action: #selector(importOPML(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Export OPML...", action: #selector(exportOPML(_:)), keyEquivalent: "")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Import from Instapaper...", action: #selector(importFromInstapaper(_:)), keyEquivalent: "")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Reader Settings...", action: #selector(showReaderSettings(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Toggle Reader Mode", action: #selector(toggleReaderMode(_:)), keyEquivalent: "")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Reading Width", action: nil, keyEquivalent: "")
        let narrowItem = NSMenuItem(title: "Narrow", action: #selector(setReaderWidth(_:)), keyEquivalent: "")
        narrowItem.tag = 0
        viewMenu.addItem(narrowItem)
        let mediumItem = NSMenuItem(title: "Medium", action: #selector(setReaderWidth(_:)), keyEquivalent: "")
        mediumItem.tag = 1
        viewMenu.addItem(mediumItem)
        let wideItem = NSMenuItem(title: "Wide", action: #selector(setReaderWidth(_:)), keyEquivalent: "")
        wideItem.tag = 2
        viewMenu.addItem(wideItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Article menu
        let articleMenuItem = NSMenuItem()
        let articleMenu = NSMenu(title: "Article")
        articleMenu.addItem(withTitle: "Mark as Read", action: #selector(markArticleRead(_:)), keyEquivalent: "")
        articleMenu.addItem(withTitle: "Mark as Unread", action: #selector(markArticleUnread(_:)), keyEquivalent: "")
        articleMenu.addItem(NSMenuItem.separator())
        articleMenu.addItem(withTitle: "Save to Instapaper", action: #selector(saveToInstapaper(_:)), keyEquivalent: "")
        articleMenu.addItem(NSMenuItem.separator())
        articleMenu.addItem(withTitle: "Copy Link", action: #selector(copyArticleLink(_:)), keyEquivalent: "l")
        articleMenu.addItem(withTitle: "Open in Browser", action: #selector(openArticleInBrowser(_:)), keyEquivalent: "")
        articleMenuItem.submenu = articleMenu
        mainMenu.addItem(articleMenuItem)

        // Accounts menu
        let accountsMenuItem = NSMenuItem()
        let accountsMenu = NSMenu(title: "Accounts")
        accountsMenu.addItem(withTitle: "Add Account", action: nil, keyEquivalent: "")
        accountsMenu.addItem(withTitle: "Feedbin...", action: #selector(addFeedbinAccount(_:)), keyEquivalent: "")
        accountsMenu.addItem(withTitle: "Feedly...", action: #selector(addFeedlyAccount(_:)), keyEquivalent: "")
        accountsMenu.addItem(NSMenuItem.separator())
        accountsMenu.addItem(withTitle: "Sync Now", action: #selector(syncAccounts(_:)), keyEquivalent: "")
        accountsMenuItem.submenu = accountsMenu
        mainMenu.addItem(accountsMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Toggle Sidebar", action: #selector(toggleSidebar(_:)), keyEquivalent: "s")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        // Help menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "Keyboard Shortcuts", action: #selector(showKeyboardShortcuts(_:)), keyEquivalent: "?")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .openArticleFromNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let articleIdString = notification.userInfo?["articleId"] as? String,
               let articleId = UUID(uuidString: articleIdString) {
                NotificationCenter.default.post(name: .openArticleById, object: nil, userInfo: ["articleId": articleId])
            }
        }
    }

    private func setupGlobalHotkeys() {
        let hotkeyService = GlobalHotkeyService.shared

        hotkeyService.register(hotkey: .init(
            id: "activate-search",
            keyCode: 3, // F
            modifiers: GlobalHotkeyService.MOD_CMD | GlobalHotkeyService.MOD_SHIFT
        )) { [weak self] in
            self?.mainWindowController?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .focusSearch, object: nil)
        }

        hotkeyService.start()
    }

    private func setupMenuBarExtra() {
        // Menu bar extra setup deferred to FOLIOAppState for main actor access
    }

    // MARK: - Actions

    @objc func newFeed(_ sender: Any?) {
        NotificationCenter.default.post(name: .showAddFeedSheet, object: nil)
    }

    @objc func refreshAllFeeds(_ sender: Any?) {
        NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
    }

    @objc func toggleSidebar(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    @objc func showSettings(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow()
    }

    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    @objc func importOPML(_ sender: Any?) {
        NotificationCenter.default.post(name: .showImportOPMLSheet, object: nil)
    }

    @objc func exportOPML(_ sender: Any?) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.xml]
        savePanel.nameFieldStringValue = "folio-export.opml"
        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }
        let content = OPMLService().exportOPML()
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    @objc func importFromInstapaper(_ sender: Any?) {
        NotificationCenter.default.post(name: .showInstapaperImportSheet, object: nil)
    }

    @objc func showReaderSettings(_ sender: Any?) {
        NotificationCenter.default.post(name: .showReaderSettings, object: nil)
    }

    @objc func toggleReaderMode(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleReaderMode, object: nil)
    }

    @objc func setReaderWidth(_ sender: NSMenuItem) {
        let widths: [ReaderViewModel.ReaderWidth] = [.narrow, .medium, .wide]
        let index = sender.tag
        guard index < widths.count else { return }
        NotificationCenter.default.post(name: .setReaderWidth, object: nil, userInfo: ["width": widths[index].rawValue])
    }

    @objc func copyArticleLink(_ sender: Any?) {
        NotificationCenter.default.post(name: .copyArticleLink, object: nil)
    }

    @objc func openArticleInBrowser(_ sender: Any?) {
        NotificationCenter.default.post(name: .openArticleInBrowser, object: nil)
    }

    @objc func markArticleRead(_ sender: Any?) {
        NotificationCenter.default.post(name: .markArticleRead, object: nil)
    }

    @objc func markArticleUnread(_ sender: Any?) {
        NotificationCenter.default.post(name: .markArticleUnread, object: nil)
    }

    @objc func saveToInstapaper(_ sender: Any?) {
        NotificationCenter.default.post(name: .saveToInstapaper, object: nil)
    }

    @objc func addFeedbinAccount(_ sender: Any?) {
        showSettings(sender)
    }

    @objc func addFeedlyAccount(_ sender: Any?) {
        FeedlyService.shared.startOAuth()
    }

    @objc func syncAccounts(_ sender: Any?) {
        Task {
            try? await FeedbinService.shared.syncStarredArticles()
            try? await FeedlyService.shared.syncCategories()
        }
    }

    @objc func showKeyboardShortcuts(_ sender: Any?) {
        NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil)
    }
}

extension Notification.Name {
    static let showAddFeedSheet = Notification.Name("showAddFeedSheet")
    static let refreshAllFeeds = Notification.Name("refreshAllFeeds")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let showImportOPMLSheet = Notification.Name("showImportOPMLSheet")
    static let showInstapaperImportSheet = Notification.Name("showInstapaperImportSheet")
    static let showReaderSettings = Notification.Name("showReaderSettings")
    static let toggleReaderMode = Notification.Name("toggleReaderMode")
    static let copyArticleLink = Notification.Name("copyArticleLink")
    static let openArticleInBrowser = Notification.Name("openArticleInBrowser")
    static let markArticleRead = Notification.Name("markArticleRead")
    static let markArticleUnread = Notification.Name("markArticleUnread")
    static let saveToInstapaper = Notification.Name("saveToInstapaper")
    static let openArticleById = Notification.Name("openArticleById")
    static let focusSearch = Notification.Name("focusSearch")
    static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
    static let setReaderWidth = Notification.Name("setReaderWidth")
}
