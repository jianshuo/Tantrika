import SwiftUI
import AuthenticationServices
import CryptoKit

@Observable
final class AuthViewModel {

    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let supabase: any SupabaseServiceProtocol
    private var currentNonce: String = ""

    init(supabase: any SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabase = supabase
    }

    // MARK: — Session restore

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }
        isAuthenticated = (try? await supabase.restoreSession()) ?? false
    }

    // MARK: — Sign in with Apple

    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        currentNonce = randomNonceString()
        request.requestedScopes = [.email]
        request.nonce = sha256(currentNonce)
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let idTokenData = credential.identityToken,
                let idToken = String(data: idTokenData, encoding: .utf8)
            else {
                errorMessage = "Sign in with Apple returned an unexpected credential."
                return
            }
            await performSignIn(idToken: idToken)
        }
    }

    private func performSignIn(idToken: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.signInWithApple(idToken: idToken, nonce: currentNonce)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await supabase.signOut()
        isAuthenticated = false
    }

    // MARK: — Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
