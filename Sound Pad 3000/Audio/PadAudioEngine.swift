import AVFoundation
import Foundation

final class PadAudioEngine: NSObject, AudioPlaying, AVAudioPlayerDelegate {
    private var players: [Int: AVAudioPlayer] = [:]
    private(set) var playingPadIDs: Set<Int> = []
    private var interruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if type == AVAudioSession.InterruptionType.began.rawValue {
                self?.handleInterruption()
            }
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func play(pad id: Int, url: URL) {
        stopPlayer(id)
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        player.isMeteringEnabled = true
        player.prepareToPlay()
        players[id] = player
        playingPadIDs.insert(id)
        player.play()
    }

    func restart(pad id: Int) {
        guard let player = players[id] else { return }
        player.pause()
        player.currentTime = 0
        player.play()
        playingPadIDs.insert(id)
    }

    func stopAll() {
        for player in players.values {
            player.stop()
        }
        players.removeAll()
        playingPadIDs.removeAll()
    }

    func handleInterruption() {
        stopAll()
    }

    func meterLevel(for id: Int) -> Float {
        guard let player = players[id], player.isPlaying else { return 0 }
        player.updateMeters()
        let db = player.averagePower(forChannel: 0)
        let minDB: Float = -40
        let maxDB: Float = 0
        let clamped = min(max(db, minDB), maxDB)
        return (clamped - minDB) / (maxDB - minDB)
    }

    func snapshotMeters() -> [Int: Float] {
        var result: [Int: Float] = [:]
        for id in playingPadIDs {
            result[id] = meterLevel(for: id)
        }
        return result
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let id = players.first(where: { $0.value === player })?.key {
            playingPadIDs.remove(id)
            players[id] = nil
        }
    }

    private func stopPlayer(_ id: Int) {
        players[id]?.stop()
        players[id] = nil
        playingPadIDs.remove(id)
    }
}
