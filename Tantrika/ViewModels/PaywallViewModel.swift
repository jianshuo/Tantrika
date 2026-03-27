import SwiftUI

@Observable
final class PaywallViewModel {

    var offerings: [SubscriptionOffering] = []
    var selectedOffering: SubscriptionOffering? = nil
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var purchaseSucceeded: Bool = false
    var errorMessage: String? = nil

    private let revenueCat: any RevenueCatServiceProtocol

    init(revenueCat: any RevenueCatServiceProtocol = RevenueCatService.shared) {
        self.revenueCat = revenueCat
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            offerings = try await revenueCat.fetchOfferings()
            // Default select the monthly offering
            selectedOffering = offerings.first(where: { $0.period == "monthly" }) ?? offerings.first
        } catch {
            errorMessage = "Couldn't load subscription options. Try again."
        }
    }

    func purchase() async {
        guard let offering = selectedOffering else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let success = try await revenueCat.purchase(offering: offering)
            purchaseSucceeded = success
            if !success {
                errorMessage = "Purchase could not be completed. Please try again."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let restored = try await revenueCat.restorePurchases()
            purchaseSucceeded = restored
            if !restored {
                errorMessage = "No previous purchases found for this Apple ID."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
