import SwiftUI

struct HeaderBar: View {
    var onStopAll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Sound Pad 3000")
                    .font(.system(size: 40, weight: .semibold))
                    .tracking(-3.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Your custom sound board")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .tracking(-1.6)
            }
            .foregroundStyle(Theme.headerInk)
            Spacer(minLength: 8)
            Button(action: onStopAll) {
                SpeakerMark()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop all sounds")
        }
        .padding(Theme.headerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.header)
    }
}

struct SpeakerMark: View {
    private let columns = 15
    private let shortColumn = 9
    private let tallColumn = 11
    private let dot: CGFloat = 6
    private let gap: CGFloat = 2

    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            ForEach(0..<columns, id: \.self) { column in
                let count = (column == 0 || column == columns - 1) ? shortColumn : tallColumn
                VStack(spacing: gap) {
                    ForEach(0..<count, id: \.self) { row in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Theme.speakerDot)
                            .frame(width: dot, height: dot)
                            .shadow(color: .black.opacity(0.25), radius: 1, x: 1, y: 1)
                            .id("\(column)-\(row)")
                    }
                }
                .shadow(color: Theme.speakerGlow, radius: 0.5, x: 1, y: 1)
            }
        }
        .fixedSize()
    }
}

#if DEBUG
#Preview("Header") {
    HeaderBar(onStopAll: {})
}

#Preview("Speaker") {
    SpeakerMark()
        .padding()
        .background(Theme.header)
}
#endif
