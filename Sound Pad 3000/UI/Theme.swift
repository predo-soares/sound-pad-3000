import SwiftUI

enum Theme {
    static let canvas = Color(hex: 0x161718)
    static let header = Color(hex: 0xF3431B)
    static let headerInk = Color.black.opacity(110.0 / 255.0)
    static let speakerDot = Color(hex: 0x862009)
    static let speakerGlow = Color(hex: 0xF25D3B)
    static let padBezel = Color.black
    static let padFill = Color(hex: 0x2F3336)
    static let padFillTop = Color(hex: 0x373737)
    static let padFillBottom = Color(hex: 0x1E1E1E)
    static let padGradient = LinearGradient(
        colors: [padFillTop, padFillBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let padEmptyFillTop = Color(hex: 0x232323)
    static let padEmptyFillBottom = Color(hex: 0x191919)
    static let padEmptyGradient = LinearGradient(
        colors: [padEmptyFillTop, padEmptyFillBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let padEmptyNumber = Color(hex: 0x4A4A4A)
    static let padEmptyLip = Color(hex: 0x101010)
    static let padInset = Color(hex: 0x161718)
    static let padNumber = Color(hex: 0xB5B5B5)
    static let padName = Color(hex: 0x7D7979)
    static let padNumberTypeface = "MediumRegular"
    static let barDim = Color(hex: 0x111111)
    static let barLit = Color(hex: 0x1E1E1E)
    static let barGlow = Color(hex: 0xDF472B).opacity(0.74)

    static let headerPadding: CGFloat = 16
    static let titleBlockPadding: CGFloat = 24
    static let gridPaddingVertical: CGFloat = 8
    static let gridPaddingHorizontal: CGFloat = 8
    static let gridGap: CGFloat = 8
    static let padBezelWidth: CGFloat = 2
    static let padCorner: CGFloat = 4
    static let padInnerPadding: CGFloat = 12
    static let padLip = Color(hex: 0x0C0C0C)
    static let padLipHeight: CGFloat = 5
    static let padLipHeightPressed: CGFloat = 1
    static let meterWidth: CGFloat = 39
    static let meterHeight: CGFloat = 6
    static let meterGap: CGFloat = 6
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
