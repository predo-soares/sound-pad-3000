#if DEBUG
import Foundation

@MainActor
enum PreviewBoard {
    static func session(meters: [Int: Float] = [:]) -> BoardSession {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sound-pad-preview-\(UUID().uuidString)", isDirectory: true)
        let store = PadStore(root: root, playability: { _ in true })
        store.setName("CLAP", forPad: 1)
        store.setName("KICK", forPad: 2)
        store.setName("HAT", forPad: 3)
        store.setName("VOX", forPad: 5)
        return BoardSession(store: store, audio: PreviewAudio(meters: meters))
    }
}

final class PreviewAudio: AudioPlaying {
    var playingPadIDs: Set<Int>
    private let meters: [Int: Float]

    init(meters: [Int: Float] = [:]) {
        self.meters = meters
        self.playingPadIDs = Set(meters.keys)
    }

    func play(pad id: Int, url: URL) {}
    func restart(pad id: Int) {}
    func stopAll() {}
    func handleInterruption() {}
    func meterLevel(for id: Int) -> Float { meters[id] ?? 0 }
    func snapshotMeters() -> [Int: Float] { meters }
}
#endif
