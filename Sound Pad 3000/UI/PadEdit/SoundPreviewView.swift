import SwiftUI

struct SoundPreviewView: View {
    var samples: [Float]
    @Bindable var player: PreviewPlayer

    var body: some View {
        HStack(spacing: 10) {
            Button {
                player.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.header)
                    .frame(width: 32, height: 32)
                    .background(Theme.padFill)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

            WaveformView(samples: samples, progress: player.progress) { fraction in
                player.seek(to: fraction)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)

            Text(format(player.duration))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.padName)
                .frame(minWidth: 36, alignment: .trailing)
                .accessibilityLabel("Duration")
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct WaveformView: View {
    let samples: [Float]
    var progress: Double
    var onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let count = max(samples.isEmpty ? 48 : samples.count, 1)
            let gap: CGFloat = 2
            let barWidth = max(1.5, (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count))
            HStack(alignment: .center, spacing: gap) {
                ForEach(0..<count, id: \.self) { index in
                    let value = samples.indices.contains(index) ? samples[index] : 0.08
                    let played = Double(index) / Double(count) <= progress
                    Capsule(style: .continuous)
                        .fill(played ? Theme.barGlow : Color(hex: 0x3A3A3A))
                        .frame(
                            width: barWidth,
                            height: max(4, geo.size.height * CGFloat(max(value, 0.08)))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = min(max(value.location.x / max(geo.size.width, 1), 0), 1)
                        onSeek(fraction)
                    }
            )
        }
        .accessibilityLabel("Waveform")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

#Preview {
    SoundPreviewView(
        samples: (0..<48).map { i in abs(sin(Float(i) / 4)) },
        player: PreviewPlayer()
    )
    .padding()
    .background(Theme.canvas)
}
