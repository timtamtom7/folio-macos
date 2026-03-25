import Foundation
import StoreKit

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var isPro = false
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    enum SubscriptionStatus {
        case notSubscribed
        case pro
        case expired(Date)
    }
    
    private init() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func checkSubscriptionStatus() async {
        // In production, this would use StoreKit 2 to check actual subscription status
        // For now, check local UserDefaults
        
        let isProUser = UserDefaults.standard.bool(forKey: "folio_is_pro")
        let expiryDate = UserDefaults.standard.object(forKey: "folio_pro_expiry") as? Date
        
        if isProUser {
            if let expiry = expiryDate, expiry < Date() {
                subscriptionStatus = .expired(expiry)
                isPro = false
            } else {
                subscriptionStatus = .pro
                isPro = true
            }
        } else {
            subscriptionStatus = .notSubscribed
            isPro = false
        }
    }
    
    func purchasePro() async throws {
        // In production, this would initiate StoreKit purchase flow
        // For now, simulate a successful purchase
        let expiry = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        UserDefaults.standard.set(true, forKey: "folio_is_pro")
        UserDefaults.standard.set(expiry, forKey: "folio_pro_expiry")
        subscriptionStatus = .pro
        isPro = true
    }
    
    func restorePurchases() async throws {
        // In production, this would restore from StoreKit
        await checkSubscriptionStatus()
    }
    
    var proFeatures: [String] {
        [
            "AI Summaries",
            "Predictive Fetching",
            "Team Workspaces",
            "ActivityPub Federation",
            "Plugin System",
            "iCloud Sync",
            "Cloud Backup",
            "Multiple Accounts",
            "Custom Shortcuts"
        ]
    }
}
