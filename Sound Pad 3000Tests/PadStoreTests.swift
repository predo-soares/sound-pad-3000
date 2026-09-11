import Foundation
import Testing
@testable import Sound_Pad_3000

@MainActor
struct PadStoreTests {
    @Test func freshStoreHasEightEmptyPads() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in true })
        #expect(store.pads.count == 8)
        #expect(store.pads.allSatisfy { $0.name.isEmpty && $0.filename == nil })
    }

    @Test func importCopiesAndAttachesFile() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("clap.wav")
        try Data("audio".utf8).write(to: source)
        try store.importFile(from: source, forPad: 1)
        let pad = try #require(store.pad(id: 1))
        #expect(pad.filename == "pad-1.wav")
        let dest = try #require(store.fileURL(for: pad))
        #expect(FileManager.default.fileExists(atPath: dest.path))
    }

    @Test func importOver25MBFails() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("huge.wav")
        FileManager.default.createFile(atPath: source.path, contents: nil)
        let handle = try FileHandle(forWritingTo: source)
        try handle.truncate(atOffset: UInt64(PadStore.maxImportBytes + 1))
        try handle.close()
        #expect(throws: PadStoreError.fileTooLarge) {
            try store.importFile(from: source, forPad: 2)
        }
        #expect(store.pad(id: 2)?.filename == nil)
    }

    @Test func unsupportedTypeFails() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("notes.txt")
        try Data("nope".utf8).write(to: source)
        #expect(throws: PadStoreError.unsupportedType) {
            try store.importFile(from: source, forPad: 3)
        }
    }

    @Test func unplayableFileDoesNotAttach() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in false })
        let source = root.appendingPathComponent("bad.wav")
        try Data("x".utf8).write(to: source)
        #expect(throws: PadStoreError.unplayable) {
            try store.importFile(from: source, forPad: 1)
        }
        #expect(store.pad(id: 1)?.filename == nil)
    }

    @Test func clearRemovesFileAndName() throws {
        let root = try makeRoot()
        let store = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("clap.wav")
        try Data("audio".utf8).write(to: source)
        try store.importFile(from: source, forPad: 4)
        store.setName("CLAP", forPad: 4)
        let url = try #require(store.fileURL(for: store.pad(id: 4)!))
        store.clearPad(id: 4)
        #expect(store.pad(id: 4)?.name == "")
        #expect(store.pad(id: 4)?.filename == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func firstLaunchSeedsFactorySamples() throws {
        let root = try makeRoot()
        let horn = root.appendingPathComponent("horn.wav")
        let boom = root.appendingPathComponent("boom.wav")
        try Data("horn".utf8).write(to: horn)
        try Data("boom".utf8).write(to: boom)
        let store = PadStore(
            root: root,
            playability: { _ in true },
            factorySamples: [
                FactorySample(padID: 1, name: "HORN", url: horn),
                FactorySample(padID: 8, name: "BOOM", url: boom),
            ]
        )
        #expect(store.pad(id: 1)?.name == "HORN")
        #expect(store.pad(id: 1)?.filename == "pad-1.wav")
        #expect(store.pad(id: 8)?.name == "BOOM")
        #expect(store.pad(id: 2)?.filename == nil)
        #expect(FileManager.default.fileExists(atPath: store.fileURL(for: store.pad(id: 1)!)!.path))
    }

    @Test func existingStateIsNotReseeded() throws {
        let root = try makeRoot()
        let first = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("later.wav")
        try Data("later".utf8).write(to: source)
        let second = PadStore(
            root: root,
            playability: { _ in true },
            factorySamples: [FactorySample(padID: 1, name: "HORN", url: source)]
        )
        #expect(second.pad(id: 1)?.filename == nil)
        #expect(second.pad(id: 1)?.name == "")
    }

    @Test func reloadRestoresPads() throws {
        let root = try makeRoot()
        let first = PadStore(root: root, playability: { _ in true })
        let source = root.appendingPathComponent("a.mp3")
        try Data("audio".utf8).write(to: source)
        try first.importFile(from: source, forPad: 8)
        first.setName("ANGRY", forPad: 8)
        let second = PadStore(root: root, playability: { _ in true })
        #expect(second.pad(id: 8)?.name == "ANGRY")
        #expect(second.pad(id: 8)?.filename == "pad-8.mp3")
        #expect(second.fileURL(for: second.pad(id: 8)!) != nil)
    }

    private func makeRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
