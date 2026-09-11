import Foundation

enum MeterMapper {
    static let barCount = 15

    static func litBars(powerDecibels: Float) -> Int {
        let minDB: Float = -40
        let maxDB: Float = 0
        let clamped = min(max(powerDecibels, minDB), maxDB)
        let normalized = (clamped - minDB) / (maxDB - minDB)
        if normalized <= 0 { return 0 }
        return min(barCount, Int(ceil(Double(normalized) * Double(barCount))))
    }

    static func litBars(level: Float) -> Int {
        let clamped = min(max(level, 0), 1)
        if clamped <= 0 { return 0 }
        return min(barCount, Int(ceil(Double(clamped) * Double(barCount))))
    }
}
