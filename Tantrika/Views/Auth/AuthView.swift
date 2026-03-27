import SwiftUI
import AuthenticationServices

struct AuthView: View {

    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.tantrikaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(alignment: .center, spacing: TantrikaSpacing.sm) {
                    Text("Tantrika")
                        .font(.tantrikaDisplay)
                        .foregroundStyle(Color.tantrikaText)
                        .multilineTextAlignment(.center)

                    Text("with Astiko")
                        .font(.tantrikaHeadingItalic)
                        .foregroundStyle(Color.tantrikaTextMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, TantrikaSpacing.lg)

                Spacer()

                // CTA section
                VStack(spacing: TantrikaSpacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        viewModel.prepareSignInRequest(request)
                    } onCompletion: { result in
                        Task { await viewModel.handleSignInResult(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(TantrikaRadius.md)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.tantrikaCaption)
                            .foregroundStyle(Color.tantrikaAccent)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, TantrikaSpacing.lg)
                .padding(.bottom, TantrikaSpacing.xxl)
            }

            if viewModel.isLoading {
                Color.tantrikaBackground.opacity(0.6).ignoresSafeArea()
                ProgressView()
                    .tint(Color.tantrikaAccent)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.isLoading)
    }
}

#Preview {
    AuthView()
}
