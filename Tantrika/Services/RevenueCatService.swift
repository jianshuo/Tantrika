import Foundation
import RevenueCat

final class RevenueCatService: RevenueCatServiceProtocol, @unchecked Sendable {

    static let shared = RevenueCatService()
    private init() {}

    func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.logLevel = .warn
    }

    func hasActiveEntitlement() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return info.entitlements["pro"]?.isActive == true
    }

    func fetchOfferings() async throws -> [SubscriptionOffering] {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else { return [] }

        return current.availablePackages.map { pkg in
            SubscriptionOffering(
                id: pkg.identifier,
                title: pkg.storeProduct.localizedTitle,
                price: pkg.localizedPriceString,
                period: pkg.packageType == .monthly ? "monthly" : "annual",
                rawPackageIdentifier: pkg.identifier
            )
        }
    }

    func purchase(offering: SubscriptionOffering) async throws -> Bool {
        guard let offerings = try? await Purchases.shared.offerings(),
              let current = offerings.current,
              let pkg = current.availablePackages.first(where: {
                  $0.identifier == offering.rawPackageIdentifier
              }) else {
            throw ServiceError.unknown("Package not found")
        }
        let result = try await Purchases.shared.purchase(package: pkg)
        return result.customerInfo.entitlements["pro"]?.isActive == true
    }

    func restorePurchases() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements["pro"]?.isActive == true
    }
}
