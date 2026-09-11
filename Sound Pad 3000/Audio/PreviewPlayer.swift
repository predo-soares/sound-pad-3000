import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class PreviewPlayer {
    var isPlaying = false
    var progress: Double = 0
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var scopedURL: URL?

    func load(_ url: URL?) {
        stop()
        releaseScope()
        player = nil
        progress = 0
        currentTime = 0
        duration = 0
        isPlaying = false
        guard let url else { return }
        if url.startAccessingSecurityScopedResource() {
            scopedURL = url
        }
        let loaded = try? AVAudioPlayer(contentsOf: url)
        loaded?.prepareToPlay()
        player = loaded
        duration = loaded?.duration ?? 0
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            if player.currentTime >= player.duration - 0.02 {
                player.currentTime = 0
            }
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to fraction: Double) {
        guard let player, player.duration > 0 else { return }
        let clamped = min(max(fraction, 0), 1)
        player.currentTime = player.duration * clamped
        duration = player.duration
        currentTime = player.currentTime
        progress = clamped
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        currentTime = 0
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sync()
            }
        }
        timer?.tolerance = 0.02
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func sync() {
        guard let player else { return }
        duration = player.duration
        currentTime = player.currentTime
        if duration > 0 {
            progress = currentTime / duration
        }
        if !player.isPlaying {
            isPlaying = false
            if currentTime >= duration - 0.05 {
                progress = 0
                currentTime = 0
                player.currentTime = 0
            }
            stopTimer()
        }
    }

    private func releaseScope() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }
}
