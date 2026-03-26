import Foundation
import Network

// MARK: - Folio R14: REST API (port 8777) & Webhooks

final class FolioAPIService: ObservableObject {
    static let shared = FolioAPIService()

    private var listener: NWListener?
    private let port: UInt16 = 8777
    @Published var isRunning = false

    private init() {}

    func start() {
        guard listener == nil else { return }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { self?.isRunning = state == .ready }
            }
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handle(conn)
            }
            listener?.start(queue: .global())
        } catch { print("FolioAPI error: \(error)") }
    }

    func stop() {
        listener?.cancel(); listener = nil
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data, let req = String(data: data, encoding: .utf8) else { conn.cancel(); return }
            let resp = self?.route(req) ?? FolioHTTPResp(code: 404, body: #"{"error":"Not found"}"#)
            let http = "HTTP/1.1 \(resp.code)\r\nContent-Type: application/json\r\nContent-Length: \(resp.body.count)\r\n\r\n\(resp.body)"
            conn.send(content: http.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    struct FolioHTTPResp { let code: Int; let body: String }

    private func route(_ req: String) -> FolioHTTPResp {
        let lines = req.split(separator: "\r\n")
        guard let rl = lines.first else { return FolioHTTPResp(code: 404, body: #"{"error":"Not found"}"#) }
        let parts = String(rl).split(separator: " ")
        guard parts.count >= 2 else { return FolioHTTPResp(code: 404, body: #"{"error":"Not found"}"#) }
        let path = String(parts[1])
        guard lines.contains(where: { $0.hasPrefix("X-API-Key:") }) else {
            return FolioHTTPResp(code: 401, body: #"{"error":"Unauthorized"}"#)
        }
        switch path {
        case "/documents": return FolioHTTPResp(code: 200, body: "[]")
        case "/search": return FolioHTTPResp(code: 200, body: #"{"results":[]}"#)
        case "/tags": return FolioHTTPResp(code: 200, body: "[]")
        case "/share": return FolioHTTPResp(code: 200, body: #"{"shareUrl":""}"#)
        case "/openapi.json": return FolioHTTPResp(code: 200, body: openAPISpec())
        default: return FolioHTTPResp(code: 404, body: #"{"error":"Not found"}"#)
        }
    }

    private func openAPISpec() -> String {
        return #"{"openapi":"3.0.0","info":{"title":"FOLIO API","version":"1.0"},"paths":{"/documents":{"get":{"summary":"List documents"}},"/search":{"get":{"summary":"Search documents"}},"/tags":{"get":{"summary":"List tags"}},"/share":{"post":{"summary":"Generate share link"}}}}"#
    }
}

// MARK: - Folio R15: iOS Companion Stub

final class FolioiOSService: ObservableObject {
    static let shared = FolioiOSService()
    @Published var recentDocuments: [iOSDocRef] = []
    @Published var widgetData: [String: Any] = [:]

    struct iOSDocRef: Identifiable {
        let id = UUID(); let title: String; let modifiedAt: Date
    }

    private init() {}
}
