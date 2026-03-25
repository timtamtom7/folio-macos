import SwiftUI

struct FOLIOApp: App {
    @StateObject private var appState = FOLIOAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Feed...") {
                    appState.showAddFeedSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Refresh All Feeds") {
                    Task { await appState.refreshAllFeeds() }
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarExtraView()
                .environmentObject(appState)
        } label: {
            Label("\(appState.unreadCount)", systemImage: "newspaper.fill")
        }
    }
}
