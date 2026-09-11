import Foundation
import Testing
@testable import Sound_Pad_3000

@MainActor
final class FakeAudioEngine: AudioPlaying {
    enum Call: Equatable {
        case play(Int)
        case restart(Int)
        case stopAll
    }

    var calls: [Call] = []
    var playingPadIDs: Set<Int> = []
    var cannedLevel: Float = 0.4

    func play(pad id: Int, url: URL) {
        calls.append(.play(id))
        playingPadIDs.insert(id)
    }

    func restart(pad id: Int) {
        calls.append(.restart(id))
        playingPadIDs.insert(id)
    }

    func stopAll() {
        calls.append(.stopAll)
        playingPadIDs.removeAll()
    }

    func handleInterruption() {
        stopAll()
    }

    func meterLevel(for id: Int) -> Float {
        playingPadIDs.contains(id) ? cannedLevel : 0
    }

    func snapshotMeters() -> [Int: Float] {
        Dictionary(uniqueKeysWithValues: playingPadIDs.map { ($0, cannedLevel) })
    }
}

@MainActor
struct AudioEngineTests {
    @Test func tapPlaysWhenIdle() throws {
        let (session, fake, _) = try makeSession()
        session.tap(pad: 1)
        #expect(fake.calls == [.play(1)])
    }

    @Test func secondTapRestarts() throws {
        let (session, fake, _) = try makeSession()
        session.tap(pad: 1)
        session.tap(pad: 1)
        #expect(fake.calls == [.play(1), .restart(1)])
    }

    @Test func headerStopCallsStopAll() throws {
        let (session, fake, _) = try makeSession()
        session.tap(pad: 1)
        session.stopAll()
        #expect(fake.calls.last == .stopAll)
        #expect(fake.playingPadIDs.isEmpty)
    }

    @Test func openingSheetStopsAll() throws {
        let (session, fake, _) = try makeSession()
        session.tap(pad: 1)
        session.beginEdit(pad: 1)
        #expect(fake.calls.last == .stopAll)
        #expect(session.editingPadID == 1)
    }

    @Test func interruptionStopsAndDoesNotResume() throws {
        let (session, fake, _) = try makeSession()
        session.tap(pad: 1)
        session.handleInterruption()
        #expect(fake.playingPadIDs.isEmpty)
        #expect(fake.calls.last == .stopAll)
    }

    @Test func meterMapperLightsBottomBars() {
        #expect(MeterMapper.litBars(level: 0) == 0)
        #expect(MeterMapper.litBars(level: 1) == MeterMapper.barCount)
        let half = MeterMapper.litBars(level: 0.5)
        #expect(half > 0)
        #expect(half <= MeterMapper.barCount)
        #expect(MeterMapper.litBars(powerDecibels: -80) == 0)
        #expect(MeterMapper.litBars(powerDecibels: 0) == MeterMapper.barCount)
    }

    @Test func emptyPadDoesNotPlay() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let store = PadStore(root: root, playability: { _ in true })
        let fake = FakeAudioEngine()
        let session = BoardSession(store: store, audio: fake)
        session.tap(pad: 2)
        #expect(fake.calls.isEmpty)
    }

    private func makeSession() throws -> (BoardSession, FakeAudioEngine, PadStore) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let store = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("a.wav")
        try Data("audio".utf8).write(to: source)
        try store.importFile(from: source, forPad: 1)
        let fake = FakeAudioEngine()
        return (BoardSession(store: store, audio: fake), fake, store)
    }
}
