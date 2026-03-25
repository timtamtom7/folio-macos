import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DatabaseManager.shared.setup()
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {}

    @IBAction func newFeed(_ sender: Any?) {
        NotificationCenter.default.post(name: .showAddFeedSheet, object: nil)
    }

    @IBAction func refreshAllFeeds(_ sender: Any?) {
        NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
    }

    @IBAction func toggleSidebar(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    @IBAction func importOPML(_ sender: Any?) {
        NotificationCenter.default.post(name: .showImportOPMLSheet, object: nil)
    }

    @IBAction func exportOPML(_ sender: Any?) {
        exportOPMLFile()
    }

    @IBAction func importFromInstapaper(_ sender: Any?) {
        NotificationCenter.default.post(name: .showInstapaperImportSheet, object: nil)
    }

    @IBAction func showReaderSettings(_ sender: Any?) {
        NotificationCenter.default.post(name: .showReaderSettings, object: nil)
    }

    @IBAction func toggleReaderMode(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleReaderMode, object: nil)
    }

    @IBAction func copyArticleLink(_ sender: Any?) {
        NotificationCenter.default.post(name: .copyArticleLink, object: nil)
    }

    @IBAction func openArticleInBrowser(_ sender: Any?) {
        NotificationCenter.default.post(name: .openArticleInBrowser, object: nil)
    }

    @IBAction func markArticleRead(_ sender: Any?) {
        NotificationCenter.default.post(name: .markArticleRead, object: nil)
    }

    @IBAction func markArticleUnread(_ sender: Any?) {
        NotificationCenter.default.post(name: .markArticleUnread, object: nil)
    }

    @IBAction func saveToInstapaper(_ sender: Any?) {
        NotificationCenter.default.post(name: .saveToInstapaper, object: nil)
    }

    private func exportOPMLFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.xml]
        savePanel.nameFieldStringValue = "folio-export.opml"
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }

        let opml = OPMLService()
        let content = opml.exportOPML()

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
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
}
