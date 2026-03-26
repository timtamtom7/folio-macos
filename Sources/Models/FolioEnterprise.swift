import Foundation
import Combine

// MARK: - Folio R13: Enterprise & Compliance Features

/// Retention policies, legal hold, compliance reporting, SSO
final class FolioEnterpriseService: ObservableObject {
    static let shared = FolioEnterpriseService()

    @Published var retentionPolicies: [RetentionPolicy] = []
    @Published var legalHolds: [LegalHold] = []
    @Published var auditLog: [FolioAuditEntry] = []
    @Published var complianceReports: [ComplianceReport] = []
    @Published var ssoConfig: FolioSSOConfig?

    struct RetentionPolicy: Identifiable, Codable {
        let id: UUID; var name: String; var documentType: String?
        var duration: RetentionDuration; var action: RetentionAction; var isEnabled: Bool
    }

    enum RetentionDuration: String, Codable {
        case days30 = "30 days", days90 = "90 days", oneYear = "1 year", sevenYears = "7 years", indefinite
    }

    enum RetentionAction: String, Codable { case archive, delete, review }

    struct LegalHold: Identifiable, Codable {
        let id: UUID; var documentIds: [UUID]; var reason: String
        var appliedBy: String; var appliedAt: Date
    }

    struct FolioAuditEntry: Identifiable, Codable {
        let id: UUID; let action: AuditAction; let user: String; let documentId: UUID?
        var detail: String; let timestamp: Date
    }

    enum AuditAction: String, Codable {
        case documentUploaded, documentViewed, documentDownloaded, documentShared, annotationAdded, holdApplied
    }

    struct ComplianceReport: Identifiable, Codable {
        let id: UUID; var title: String; var generatedAt: Date
        var documentCount: Int; var expiringCount: Int; var heldCount: Int
    }

    struct FolioSSOConfig: Codable {
        var provider: SSOProvider; var enabled: Bool
        enum SSOProvider: String, Codable { case okta, azureAD, googleWorkspace }
    }

    private init() { loadState() }

    func applyRetentionPolicy(_ policy: RetentionPolicy) {
        retentionPolicies.append(policy); saveState()
    }

    func placeHold(documentIds: [UUID], reason: String, by user: String) -> LegalHold {
        let hold = LegalHold(id: UUID(), documentIds: documentIds, reason: reason, appliedBy: user, appliedAt: Date())
        legalHolds.append(hold); saveState(); return hold
    }

    func generateComplianceReport() -> ComplianceReport {
        let report = ComplianceReport(id: UUID(), title: "Compliance Report", generatedAt: Date(), documentCount: 0, expiringCount: 0, heldCount: legalHolds.count)
        complianceReports.append(report); saveState(); return report
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FOLIO/enterprise.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = FolioEnterpriseState(retentionPolicies: retentionPolicies, legalHolds: legalHolds, auditLog: auditLog, complianceReports: complianceReports, ssoConfig: ssoConfig)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(FolioEnterpriseState.self, from: data) else { return }
        retentionPolicies = state.retentionPolicies; legalHolds = state.legalHolds
        auditLog = state.auditLog; complianceReports = state.complianceReports
        ssoConfig = state.ssoConfig
    }
}

struct FolioEnterpriseState: Codable {
    var retentionPolicies: [FolioEnterpriseService.RetentionPolicy]
    var legalHolds: [FolioEnterpriseService.LegalHold]
    var auditLog: [FolioEnterpriseService.FolioAuditEntry]
    var complianceReports: [FolioEnterpriseService.ComplianceReport]
    var ssoConfig: FolioEnterpriseService.FolioSSOConfig?
}
