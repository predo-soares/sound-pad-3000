import AVFoundation
import Foundation
import Observation

@Observable
final class PadStore {
    static let maxImportBytes = 25 * 1024 * 1024
    static let allowedExtensions: Set<String> = ["m4a", "mp3", "wav", "aac", "caf"]

    static func defaultRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("SoundPad3000", isDirectory: true)
    }

    private(set) var pads: [Pad]
    private let root: URL
    private let fileManager: FileManager
    private let stateURL: URL
    private let audioDirectory: URL
    private let playability: (URL) -> Bool

    init(
        root: URL,
        fileManager: FileManager = .default,
        playability: @escaping (URL) -> Bool = { url in
            (try? AVAudioPlayer(contentsOf: url)) != nil
        },
        factorySamples: [FactorySample] = []
    ) {
        self.root = root
        self.fileManager = fileManager
        self.playability = playability
        self.stateURL = root.appendingPathComponent("pads.json")
        self.audioDirectory = root.appendingPathComponent("audio", isDirectory: true)
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        if let loaded = Self.load(from: stateURL, fileManager: fileManager) {
            pads = loaded
        } else {
            pads = (1...8).map { Pad(id: $0, name: "", filename: nil) }
            seedFactory(factorySamples)
            persist()
        }
    }

    func pad(id: Int) -> Pad? {
        pads.first { $0.id == id }
    }

    func fileURL(for pad: Pad) -> URL? {
        guard let filename = pad.filename else { return nil }
        return audioDirectory.appendingPathComponent(filename)
    }

    func setName(_ name: String, forPad id: Int) {
        update(id) { $0.name = name }
        persist()
    }

    func importFile(from url: URL, forPad id: Int) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let ext = url.pathExtension.lowercased()
        guard Self.allowedExtensions.contains(ext) else {
            throw PadStoreError.unsupportedType
        }

        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
        if size > Self.maxImportBytes {
            throw PadStoreError.fileTooLarge
        }

        let destName = "pad-\(id).\(ext)"
        let dest = audioDirectory.appendingPathComponent(destName)

        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }

        do {
            try fileManager.copyItem(at: url, to: dest)
        } catch {
            throw PadStoreError.copyFailed
        }

        if !playability(dest) {
            try? fileManager.removeItem(at: dest)
            throw PadStoreError.unplayable
        }

        if let existing = pad(id: id), let old = existing.filename, old != destName {
            let oldURL = audioDirectory.appendingPathComponent(old)
            try? fileManager.removeItem(at: oldURL)
        }

        update(id) { $0.filename = destName }
        persist()
    }

    func clearPad(id: Int) {
        if let current = pad(id: id), let filename = current.filename {
            let url = audioDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: url)
        }
        update(id) {
            $0.name = ""
            $0.filename = nil
        }
        persist()
    }

    func clearAudio(id: Int) {
        if let current = pad(id: id), let filename = current.filename {
            let url = audioDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: url)
        }
        update(id) { $0.filename = nil }
        persist()
    }

    func applyEdit(padID: Int, name: String, replacingFile url: URL?, removeAudio: Bool) throws {
        if removeAudio, url == nil {
            clearAudio(id: padID)
        }
        if let url {
            try importFile(from: url, forPad: padID)
        }
        setName(name, forPad: padID)
    }

    private func seedFactory(_ samples: [FactorySample]) {
        for sample in samples {
            try? importFile(from: sample.url, forPad: sample.padID)
            update(sample.padID) { $0.name = sample.name }
        }
    }

    private func update(_ id: Int, _ body: (inout Pad) -> Void) {
        guard let index = pads.firstIndex(where: { $0.id == id }) else { return }
        body(&pads[index])
    }

    private func persist() {
        let data = try? JSONEncoder().encode(pads)
        try? data?.write(to: stateURL, options: .atomic)
    }

    private static func load(from url: URL, fileManager: FileManager) -> [Pad]? {
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let pads = try? JSONDecoder().decode([Pad].self, from: data),
              pads.count == 8
        else { return nil }
        return pads
    }
}
