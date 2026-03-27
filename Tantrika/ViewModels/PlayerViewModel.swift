import SwiftUI
import AVKit
import Combine

@Observable
final class PlayerViewModel {

    var player: AVPlayer? = nil
    var isLoading: Bool = false
    var showPaywall: Bool = false
    var errorMessage: String? = nil

    private let supabase: any SupabaseServiceProtocol
    private let edgeFunction: any EdgeFunctionServiceProtocol
    private let revenueCat: any RevenueCatServiceProtocol

    private var progressObserver: Any? = nil
    private var lesson: Lesson? = nil

    init(
        supabase: any SupabaseServiceProtocol = SupabaseService.shared,
        edgeFunction: any EdgeFunctionServiceProtocol = EdgeFunctionService.shared,
        revenueCat: any RevenueCatServiceProtocol = RevenueCatService.shared
    ) {
        self.supabase = supabase
        self.edgeFunction = edgeFunction
        self.revenueCat = revenueCat
    }

    // MARK: — Prepare video

    func prepareVideo(lesson: Lesson) async {
        self.lesson = lesson
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Gate: free preview passes; paid requires active entitlement
        if !lesson.isFreePreview {
            let hasAccess = await revenueCat.hasActiveEntitlement()
            guard hasAccess else {
                showPaywall = true
                return
            }
        }

        do {
            let url = try await edgeFunction.signedVideoURL(lessonId: lesson.id)
            await setupPlayer(url: url, lessonId: lesson.id, durationSeconds: lesson.durationSeconds)
        } catch ServiceError.videoAccessDenied {
            showPaywall = true
        } catch {
            errorMessage = "Couldn't load the video. Please try again."
        }
    }

    private func setupPlayer(url: URL, lessonId: UUID, durationSeconds: Int) async {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        // Restore prior position
        if let progress = try? await supabase.fetchProgress(lessonId: lessonId),
           progress.watchedSeconds > 0,
           !progress.isCompleted {
            let time = CMTime(seconds: Double(progress.watchedSeconds), preferredTimescale: 1)
            await avPlayer.seek(to: time)
        }

        startProgressTracking(player: avPlayer, lessonId: lessonId, durationSeconds: durationSeconds)
        avPlayer.play()
    }

    // MARK: — Progress tracking

    private func startProgressTracking(player: AVPlayer, lessonId: UUID, durationSeconds: Int) {
        let interval = CMTime(seconds: 10, preferredTimescale: 1)
        progressObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let watched = Int(time.seconds)
            let isCompleted = durationSeconds > 0 &&
                Double(watched) / Double(durationSeconds) >= UserProgress.completionThreshold
            Task {
                try? await self.supabase.upsertProgress(
                    lessonId: lessonId,
                    watchedSeconds: watched,
                    isCompleted: isCompleted
                )
            }
        }
    }

    func cleanup() {
        if let observer = progressObserver, let player {
            player.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
        progressObserver = nil
    }
}
