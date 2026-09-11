import AVFoundation
import Foundation

enum WaveformSampler {
    static func samples(from url: URL, barCount: Int = 48) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }
        let format = file.processingFormat
        let totalFrames = file.length
        guard totalFrames > 0, barCount > 0 else { return [] }

        let framesPerBar = max(1, Int(totalFrames) / barCount)
        var bars = [Float](repeating: 0, count: barCount)

        for index in 0..<barCount {
            let start = AVAudioFramePosition(index * framesPerBar)
            let remaining = Int(totalFrames - start)
            let length = min(framesPerBar, remaining)
            guard length > 0 else { break }
            file.framePosition = start
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(length)
            ) else { continue }
            try? file.read(into: buffer, frameCount: AVAudioFrameCount(length))
            bars[index] = peak(in: buffer)
        }

        let maxPeak = bars.max() ?? 0
        guard maxPeak > 0 else { return bars }
        return bars.map { $0 / maxPeak }
    }

    private static func peak(in buffer: AVAudioPCMBuffer) -> Float {
        let count = Int(buffer.frameLength)
        guard count > 0, let data = buffer.floatChannelData?[0] else { return 0 }
        var peak: Float = 0
        for i in 0..<count {
            peak = max(peak, abs(data[i]))
        }
        return peak
    }
}
