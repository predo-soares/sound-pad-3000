import Foundation
import Observation
import UIKit

enum BoardAlert: Equatable, Identifiable {
    case fileTooLarge
    case unsupportedType
    case unplayable
    case copyFailed
    case microphoneDenied

    var id: String {
        switch self {
        case .fileTooLarge: "fileTooLarge"
        case .unsupportedType: "unsupportedType"
        case .unplayable: "unplayable"
        case .copyFailed: "copyFailed"
        case .microphoneDenied: "microphoneDenied"
        }
    }

    var title: String {
        switch self {
        case .fileTooLarge: "File too large"
        case .unsupportedType: "Unsupported file"
        case .unplayable: "Can't play this file"
        case .copyFailed: "Couldn't copy file"
        case .microphoneDenied: "Microphone access needed"
        }
    }

    var message: String {
        switch self {
        case .fileTooLarge: "Choose a file under 25 MB."
        case .unsupportedType: "Use m4a, mp3, wav, aac, or caf."
        case .unplayable: "The pad was left unchanged."
        case .copyFailed: "The pad was left unchanged."
        case .microphoneDenied: "Enable the microphone in Settings to record, or pick a file instead."
        }
    }
}

@Observable
final class BoardSession {
    let store: PadStore
    let audio: any AudioPlaying
    var meters: [Int: Float] = [:]
    var playingPadIDs: Set<Int> = []
    var editingPadID: Int?
    var alert: BoardAlert?

    private var meterTimer: Timer?

    deinit {
        meterTimer?.invalidate()
    }

    init(store: PadStore, audio: any AudioPlaying) {
        self.store = store
        self.audio = audio
        startMetering()
    }

    func tap(pad id: Int) {
        guard let pad = store.pad(id: id), pad.hasAudio, let url = store.fileURL(for: pad) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if audio.playingPadIDs.contains(id) {
            audio.restart(pad: id)
        } else {
            audio.play(pad: id, url: url)
        }
        refreshMeters()
    }

    func beginEdit(pad id: Int) {
        audio.stopAll()
        refreshMeters()
        editingPadID = id
    }

    func stopAll() {
        audio.stopAll()
        refreshMeters()
    }

    func handleInterruption() {
        audio.handleInterruption()
        refreshMeters()
    }

    func sceneBecameInactive() {
        stopAll()
    }

    func applyEdit(padID: Int, name: String, replacingFile: URL?, removeAudio: Bool) {
        do {
            try store.applyEdit(padID: padID, name: name, replacingFile: replacingFile, removeAudio: removeAudio)
            editingPadID = nil
        } catch let error as PadStoreError {
            alert = Self.alert(for: error)
        } catch {
            alert = .copyFailed
        }
    }

    func cancelEdit() {
        editingPadID = nil
    }

    func litBars(for id: Int) -> Int {
        MeterMapper.litBars(level: meters[id] ?? 0)
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.refreshMeters()
        }
        meterTimer?.tolerance = 0.02
    }

    private func refreshMeters() {
        meters = audio.snapshotMeters()
        playingPadIDs = audio.playingPadIDs
    }

    private static func alert(for error: PadStoreError) -> BoardAlert {
        switch error {
        case .fileTooLarge: .fileTooLarge
        case .unsupportedType: .unsupportedType
        case .unplayable: .unplayable
        case .copyFailed: .copyFailed
        }
    }
}
