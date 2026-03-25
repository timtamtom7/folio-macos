import Foundation
import UserNotifications

final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(title: String, body: String, articleId: UUID) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["articleId": articleId.uuidString]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func scheduleNewArticlesNotification(feedTitle: String, articleCount: Int, articleTitles: [String]) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(feedTitle)"
        content.body = "\(articleCount) new article\(articleCount == 1 ? "" : "s")"
        if let firstTitle = articleTitles.first {
            content.subtitle = firstTitle
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "folionewarticles-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func handleNotificationTap(articleId: UUID) {
        NotificationCenter.default.post(
            name: .openArticleFromNotification,
            object: nil,
            userInfo: ["articleId": articleId.uuidString]
        )
    }
}

extension Notification.Name {
    static let openArticleFromNotification = Notification.Name("openArticleFromNotification")
}
