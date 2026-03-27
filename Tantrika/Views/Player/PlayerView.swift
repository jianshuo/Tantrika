import SwiftUI
import AVKit

struct PlayerView: View {

    let lesson: Lesson

    @State private var viewModel = PlayerViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: TantrikaSpacing.md) {
                    Text(error)
                        .font(.tantrikaBody)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        Task { await viewModel.prepareVideo(lesson: lesson) }
                    }
                    .font(.tantrikaButton)
                    .foregroundStyle(Color.tantrikaAccent)
                }
                .padding(TantrikaSpacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(lesson.title)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.prepareVideo(lesson: lesson) }
        .onChange(of: viewModel.showPaywall) { _, show in
            if show { showPaywall = true }
        }
        .onDisappear { viewModel.cleanup() }
        .sheet(isPresented: $showPaywall, onDismiss: {
            viewModel.showPaywall = false
        }) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        PlayerView(lesson: Lesson.mockData(courseId: UUID())[0])
    }
}
