import Foundation
import AppKit

final class URLSchemeHandler {
    static let shared = URLSchemeHandler()

    func handle(url: URL) {
        guard let scheme = url.scheme, scheme == "foliords" else { return }

        let host = url.host ?? ""

        switch host {
        case "auth":
            handleAuthCallback(url: url)
        default:
            break
        }
    }

    private func handleAuthCallback(url: URL) {
        let path = url.path

        if path.starts(with: "/feedly") {
            Task {
                do {
                    try await FeedlyService.shared.handleOAuthCallback(url: url)
                } catch {
                    print("Feedly OAuth error: \(error)")
                }
            }
        }
    }
}
