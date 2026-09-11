import SwiftUI

struct SoundPadView: View {
    let pad: Pad
    let litBars: Int
    var isPlaying = false
    var onTap: () -> Void
    var onLongPress: () -> Void

    @State private var skipTap = false
    @GestureState private var isTouching = false

    private var isEmpty: Bool { !pad.hasAudio }
    private var isDown: Bool { isEmpty || isTouching || isPlaying }

    var body: some View {
        Button {
            if skipTap {
                skipTap = false
                return
            }
            onTap()
        } label: {
            PadFace(pad: pad, litBars: litBars, isEmpty: isEmpty, isDown: isDown)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isTouching) { _, state, _ in
                    state = pad.hasAudio
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    skipTap = true
                    onLongPress()
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        let name = pad.name.isEmpty ? "Pad \(pad.id)" : "Pad \(pad.id), \(pad.name)"
        let audio: String
        if !pad.hasAudio {
            audio = "empty"
        } else if isPlaying {
            audio = "playing"
        } else {
            audio = "has sound"
        }
        return "\(name), \(audio)"
    }
}

private struct PadFace: View {
    let pad: Pad
    let litBars: Int
    let isEmpty: Bool
    let isDown: Bool

    private var lipHeight: CGFloat {
        isDown ? Theme.padLipHeightPressed : Theme.padLipHeight
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.padCorner, style: .continuous)
        return ZStack {
            Theme.padBezel
            ZStack(alignment: .topLeading) {
                shape.fill(isEmpty ? Theme.padEmptyLip : Theme.padLip)
                shape
                    .fill(isEmpty ? Theme.padEmptyGradient : Theme.padGradient)
                    .padding(.bottom, lipHeight)

                HStack {
                    Spacer()
                    MeterBars(litCount: isEmpty ? 0 : litBars)
                }
                .opacity(isEmpty ? 0.35 : 1)
                .padding(Theme.padInnerPadding)
                .padding(.bottom, lipHeight)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(pad.id)")
                        .font(.custom(Theme.padNumberTypeface, size: 24))
                        .tracking(-0.4)
                        .foregroundStyle(isEmpty ? Theme.padEmptyNumber : Theme.padNumber)
                    Spacer()
                    if !pad.name.isEmpty {
                        Text(pad.name.uppercased())
                            .font(.system(size: 14, weight: .light, design: .monospaced))
                            .tracking(-0.4)
                            .foregroundStyle(Theme.padName.opacity(isEmpty ? 0.45 : 1))
                            .lineLimit(1)
                    }
                }
                .padding(Theme.padInnerPadding)
                .padding(.bottom, lipHeight)
            }
            .clipShape(shape)
            .padding(Theme.padBezelWidth)
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(
            color: Color.black.opacity(isDown ? 0.08 : 0.28),
            radius: isDown ? 0 : 2,
            x: 0,
            y: isDown ? 0 : 3
        )
        .animation(.easeOut(duration: 0.08), value: isDown)
    }
}

struct MeterBars: View {
    let litCount: Int

    var body: some View {
        VStack(spacing: Theme.meterGap) {
            ForEach((0..<MeterMapper.barCount).reversed(), id: \.self) { index in
                let lit = index < litCount
                RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                    .fill(lit ? Theme.barGlow : Theme.barDim)
                    .frame(width: Theme.meterWidth, height: Theme.meterHeight)
                    .shadow(color: lit ? Theme.barGlow : .clear, radius: lit ? 3 : 0)
            }
        }
    }
}

#if DEBUG
#Preview("Pad empty") {
    SoundPadView(
        pad: Pad(id: 8, name: "", filename: nil),
        litBars: 0,
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 180, height: 180)
    .padding()
    .background(Theme.canvas)
}

#Preview("Pad idle") {
    SoundPadView(
        pad: Pad(id: 1, name: "CLAP", filename: "clap.wav"),
        litBars: 0,
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 180, height: 180)
    .padding()
    .background(Theme.canvas)
}

#Preview("Pad playing") {
    SoundPadView(
        pad: Pad(id: 1, name: "CLAP", filename: "clap.wav"),
        litBars: 9,
        isPlaying: true,
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 180, height: 180)
    .padding()
    .background(Theme.canvas)
}

#Preview("Meter dim") {
    MeterBars(litCount: 0)
        .padding()
        .background(Theme.canvas)
}

#Preview("Meter lit") {
    MeterBars(litCount: 12)
        .padding()
        .background(Theme.canvas)
}
#endif
