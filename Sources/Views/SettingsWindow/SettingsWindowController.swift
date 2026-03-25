import SwiftUI

struct SettingsWindow: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var accountsVM = AccountsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("General", systemImage: "gear") }

            AccountsSettingsView(viewModel: accountsVM)
                .tabItem { Label("Accounts", systemImage: "person.circle") }

            NotificationsSettingsView(viewModel: viewModel)
                .tabItem { Label("Notifications", systemImage: "bell") }

            ReaderSettingsView()
                .tabItem { Label("Reader", systemImage: "text.alignleft") }

            KeyboardSettingsView()
                .tabItem { Label("Keyboard", systemImage: "keyboard") }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Show reading statistics", isOn: $viewModel.showReadingStats)
            }

            Section {
                Button("Request Notification Permission") {
                    Task { await viewModel.requestNotificationPermission() }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AccountsSettingsView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @State private var showFeedbinConnect = false
    @State private var showFeedlyConnect = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Feedbin
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(viewModel.feedbinConnected ? .green : .gray)
                    .font(.caption)
                Text("Feedbin")
                    .font(.headline)
                Spacer()
                if viewModel.feedbinConnected {
                    Button("Disconnect") {
                        viewModel.disconnectFeedbin()
                    }
                    Button("Sync Now") {
                        Task { await viewModel.syncFeedbin() }
                    }
                } else {
                    Button("Connect...") {
                        showFeedbinConnect = true
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Feedly
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(viewModel.feedlyConnected ? .green : .gray)
                    .font(.caption)
                Text("Feedly")
                    .font(.headline)
                Spacer()
                if viewModel.feedlyConnected {
                    Button("Disconnect") {
                        viewModel.disconnectFeedly()
                    }
                    Button("Sync Now") {
                        Task { await viewModel.syncFeedly() }
                    }
                } else {
                    Button("Connect via OAuth...") {
                        FeedlyService.shared.startOAuth()
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showFeedbinConnect) {
            FeedbinConnectSheet()
        }
    }
}

struct FeedbinConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var apiKey = ""
    @State private var isConnecting = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Connect to Feedbin")
                .font(.headline)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                Button("Connect") {
                    isConnecting = true
                    Task {
                        do {
                            try await FeedbinService.shared.connect(email: email, apiKey: apiKey)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                            isConnecting = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || apiKey.isEmpty || isConnecting)
            }
        }
        .padding()
        .frame(width: 350)
    }
}

struct NotificationsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Enable notifications", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { _ in
                        if viewModel.notificationsEnabled {
                            Task { await viewModel.requestNotificationPermission() }
                        }
                    }

                if viewModel.notificationsEnabled {
                    Picker("Notification frequency", selection: $viewModel.notificationFrequency) {
                        ForEach(SettingsViewModel.NotificationFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    Toggle("Notify on new articles", isOn: $viewModel.notifyOnNewArticles)

                    if viewModel.notifyOnNewArticles {
                        Stepper("Min articles: \(viewModel.minArticlesForNotification)",
                                value: $viewModel.minArticlesForNotification, in: 1...50)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct KeyboardSettingsView: View {
    @State private var showShortcutsOverlay = false

    var body: some View {
        VStack(spacing: 16) {
            Text("All keyboard shortcuts are active in FOLIO.")
                .foregroundColor(.secondary)

            Button("Show All Shortcuts") {
                showShortcutsOverlay = true
            }

            Text("Global hotkey: ⌘⇧F activates FOLIO and focuses search from anywhere.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .sheet(isPresented: $showShortcutsOverlay) {
            KeyboardShortcutsOverlay(isPresented: $showShortcutsOverlay)
        }
    }
}

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "FOLIO Settings"
        window.contentView = NSHostingView(rootView: SettingsWindow())
        window.center()

        self.init(window: window)
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
