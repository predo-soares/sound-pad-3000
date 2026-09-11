import Foundation
import Testing
@testable import Sound_Pad_3000

struct WaveformSamplerTests {
    @Test func invalidFileReturnsEmpty() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("not-audio.txt")
        try? Data("nope".utf8).write(to: url)
        #expect(WaveformSampler.samples(from: url, barCount: 16).isEmpty)
    }

    @Test func sineWavProducesNormalizedBars() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sine-\(UUID().uuidString).wav")
        try writeSineWAV(to: url, frames: 4410)
        let bars = WaveformSampler.samples(from: url, barCount: 16)
        #expect(bars.count == 16)
        #expect((bars.max() ?? 0) > 0.9)
        #expect(bars.allSatisfy { $0 >= 0 && $0 <= 1.001 })
    }
}

private func writeSineWAV(to url: URL, frames: Int) throws {
    let sampleRate: UInt32 = 44100
    var pcm = Data()
    pcm.reserveCapacity(frames * 2)
    for i in 0..<frames {
        let sample = sin(2.0 * Double.pi * 440.0 * Double(i) / Double(sampleRate))
        var value = Int16((sample * Double(Int16.max / 2)).rounded())
        withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
    }
    var data = Data()
    func append(_ string: String) { data.append(contentsOf: string.utf8) }
    func appendU32(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    func appendU16(_ value: UInt16) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    let dataSize = UInt32(pcm.count)
    append("RIFF")
    appendU32(36 + dataSize)
    append("WAVE")
    append("fmt ")
    appendU32(16)
    appendU16(1)
    appendU16(1)
    appendU32(sampleRate)
    appendU32(sampleRate * 2)
    appendU16(2)
    appendU16(16)
    append("data")
    appendU32(dataSize)
    data.append(pcm)
    try data.write(to: url)
}
