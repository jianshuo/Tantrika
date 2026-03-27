import SwiftUI

@main
struct TantrikaApp: App {

    @State private var authViewModel = AuthViewModel()

    init() {
        configureRevenueCat()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    LibraryView()
                } else {
                    AuthView()
                }
            }
            .animation(.easeOut(duration: 0.25), value: authViewModel.isAuthenticated)
            .task {
                await authViewModel.restoreSession()
            }
        }
    }

    private func configureRevenueCat() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !apiKey.isEmpty else {
            return
        }
        RevenueCatService.shared.configure(apiKey: apiKey)
    }
}
