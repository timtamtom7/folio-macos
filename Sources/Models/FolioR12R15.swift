import Foundation

// MARK: - Folio R12: Collaboration & Document Sharing

/// Shared libraries, collaborative annotation, approval workflows, client sharing
final class FolioCollaborationService: ObservableObject {
    static let shared = FolioCollaborationService()

    @Published var sharedLibraries: [SharedLibrary] = []
    @Published var annotations: [DocAnnotation] = []
    @Published var approvalRequests: [ApprovalRequest] = []
    @Published var clientShares: [ClientShare] = []
    @Published var templates: [SharedDocTemplate] = []

    private init() { loadState() }

    func shareLibrary(_ libraryId: UUID, with member: LibraryMember) {
        let lib = SharedLibrary(id: UUID(), libraryId: libraryId, members: [member], createdAt: Date())
        sharedLibraries.append(lib); saveState()
    }

    func addAnnotation(documentId: UUID, author: String, highlight: String, note: String?) -> DocAnnotation {
        let ann = DocAnnotation(id: UUID(), documentId: documentId, author: author, highlight: highlight, note: note, status: .active, createdAt: Date())
        annotations.append(ann); saveState(); return ann
    }

    func submitForApproval(documentId: UUID, approver: String) -> ApprovalRequest {
        let req = ApprovalRequest(id: UUID(), documentId: documentId, approver: approver, status: .pending, submittedAt: Date())
        approvalRequests.append(req); saveState(); return req
    }

    func createClientShare(documentId: UUID, accessLevel: ClientAccessLevel, daysValid: Int) -> ClientShare {
        let share = ClientShare(id: UUID(), documentId: documentId, accessLevel: accessLevel, expiresAt: Calendar.current.date(byAdding: .day, value: daysValid, to: Date()), viewed: false, createdAt: Date())
        clientShares.append(share); saveState(); return share
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FOLIO/collaboration.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = FolioCollabState(sharedLibraries: sharedLibraries, annotations: annotations, approvalRequests: approvalRequests, clientShares: clientShares, templates: templates)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(FolioCollabState.self, from: data) else { return }
        sharedLibraries = state.sharedLibraries; annotations = state.annotations
        approvalRequests = state.approvalRequests; clientShares = state.clientShares
        templates = state.templates
    }
}

// MARK: - Models

struct SharedLibrary: Identifiable, Codable {
    let id: UUID; let libraryId: UUID; var members: [LibraryMember]; let createdAt: Date
}

struct LibraryMember: Identifiable, Codable {
    let id: UUID; var name: String; var email: String; var role: LibraryRole
}

enum LibraryRole: String, Codable { case admin, editor, viewer }

struct DocAnnotation: Identifiable, Codable {
    let id: UUID; let documentId: UUID; var author: String; var highlight: String
    var note: String?; var status: AnnotationStatus; let createdAt: Date
}

enum AnnotationStatus: String, Codable { case active, resolved, approved, rejected }

struct ApprovalRequest: Identifiable, Codable {
    let id: UUID; let documentId: UUID; let approver: String
    var status: ApprovalStatus; let submittedAt: Date
}

enum ApprovalStatus: String, Codable { case pending, approved, rejected, changesRequested }

struct ClientShare: Identifiable, Codable {
    let id: UUID; let documentId: UUID; var accessLevel: ClientAccessLevel
    var expiresAt: Date?; var viewed: Bool; let createdAt: Date
}

enum ClientAccessLevel: String, Codable { case readOnly, download }

struct SharedDocTemplate: Identifiable, Codable {
    let id: UUID; var name: String; var content: Data; var version: Int
    var createdAt: Date
}

struct FolioCollabState: Codable {
    var sharedLibraries: [SharedLibrary]; var annotations: [DocAnnotation]
    var approvalRequests: [ApprovalRequest]; var clientShares: [ClientShare]
    var templates: [SharedDocTemplate]
}
