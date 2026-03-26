import Foundation
import StoreKit

@available(macOS 13.0, *)
public final class FolioSubscriptionManager: ObservableObject {
    public static let shared = FolioSubscriptionManager()
    @Published public private(set) var subscription: FolioSubscription?
    @Published public private(set) var products: [Product] = []
    private init() {}
    public func loadProducts() async {
        do { products = try await Product.products(for: ["com.folio.macos.pro.monthly","com.folio.macos.pro.yearly","com.folio.macos.team.monthly","com.folio.macos.team.yearly"]) }
        catch { print("Failed to load products") }
    }
    public func canAccess(_ feature: FolioFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .teamSharing: return sub.tier == .team
        }
    }
    public func updateStatus() async {
        var found: FolioSubscription = FolioSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("team") { found = FolioSubscription(tier: .team, status: t.revocationDate == nil ? "active" : "expired") }
                else if t.productID.contains("pro") { found = FolioSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired") }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    public func restore() async throws { try await AppStore.sync(); await updateStatus() }
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T { switch r { case .unverified: throw NSError(domain: "Folio", code: -1); case .verified(let s): return s } }
}
public enum FolioFeature { case widgets, shortcuts, teamSharing }
