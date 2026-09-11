import Foundation

protocol AudioPlaying: AnyObject {
    var playingPadIDs: Set<Int> { get }
    func play(pad id: Int, url: URL)
    func restart(pad id: Int)
    func stopAll()
    func handleInterruption()
    func meterLevel(for id: Int) -> Float
    func snapshotMeters() -> [Int: Float]
}
