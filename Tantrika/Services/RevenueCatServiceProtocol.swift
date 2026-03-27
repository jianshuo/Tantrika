import Foundation

protocol RevenueCatServiceProtocol: Sendable {
    /// Configure RevenueCat with the given API key. Call once at app startup.
    func configure(apiKey: String)

    /// Returns true if the user currently has an active "pro" entitlement.
    /// Queries the RevenueCat SDK cache (fast) with a server refresh when stale.
    func hasActiveEntitlement() async -> Bool

    /// Fetch available subscription offerings.
    func fetchOfferings() async throws -> [SubscriptionOffering]

    /// Purchase the given offering package. Returns true on success.
    func purchase(offering: SubscriptionOffering) async throws -> Bool

    /// Restore previously purchased subscriptions.
    func restorePurchases() async throws -> Bool
}

struct SubscriptionOffering: Identifiable, Sendable {
    let id: String
    let title: String
    let price: String          // formatted, e.g. "$9.99/month"
    let period: String         // "monthly" | "annual"
    let rawPackageIdentifier: String
}
