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

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }

    @IBAction func newFeed(_ sender: Any?) {
        NotificationCenter.default.post(name: .showAddFeedSheet, object: nil)
    }

    @IBAction func refreshAllFeeds(_ sender: Any?) {
        NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
    }

    @IBAction func toggleSidebar(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }
}

extension Notification.Name {
    static let showAddFeedSheet = Notification.Name("showAddFeedSheet")
    static let refreshAllFeeds = Notification.Name("refreshAllFeeds")
    static let toggleSidebar = Notification.Name("toggleSidebar")
}
