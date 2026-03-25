import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var feedbinEmail = ""
    @Published var feedbinApiKey = ""
    @Published var isConnectingFeedbin = false
    @Published var feedbinError: String?
    @Published var feedbinSuccess = false

    @Published var notificationsEnabled = false
    @Published var notificationFrequency: NotificationFrequency = .immediate
    @Published var notifyOnNewArticles = true
    @Published var minArticlesForNotification = 5

    @Published var showReadingStats = false
    @Published var defaultReaderWidth = ReaderViewModel.ReaderWidth.medium

    @Published var keyboardShortcutsEnabled = true

    private let notificationService = NotificationService.shared
    private let feedbinService = FeedbinService.shared

    init() {
        loadSettings()
    }

    func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if let freq = UserDefaults.standard.string(forKey: "notificationFrequency"),
           let f = NotificationFrequency(rawValue: freq) {
            notificationFrequency = f
        }
        showReadingStats = UserDefaults.standard.bool(forKey: "showReadingStats")
    }

    func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(notificationFrequency.rawValue, forKey: "notificationFrequency")
        UserDefaults.standard.set(showReadingStats, forKey: "showReadingStats")
    }

    func connectFeedbin() async {
        await MainActor.run { isConnectingFeedbin = true; feedbinError = nil }

        do {
            try await feedbinService.connect(email: feedbinEmail, apiKey: feedbinApiKey)
            await MainActor.run {
                feedbinSuccess = true
                isConnectingFeedbin = false
            }
        } catch {
            await MainActor.run {
                feedbinError = error.localizedDescription
                isConnectingFeedbin = false
            }
        }
    }

    func requestNotificationPermission() async {
        _ = await notificationService.requestAuthorization()
        await MainActor.run {
            notificationsEnabled = notificationService.isAuthorized
        }
    }

    enum NotificationFrequency: String, CaseIterable {
        case immediate = "Immediate"
        case hourly = "Hourly Digest"
        case daily = "Daily Digest"
    }
}
