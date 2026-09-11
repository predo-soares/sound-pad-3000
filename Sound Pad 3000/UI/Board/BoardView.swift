import SwiftUI
import UIKit

struct BoardView: View {
    @Bindable var session: BoardSession
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [
        GridItem(.flexible(), spacing: Theme.gridGap),
        GridItem(.flexible(), spacing: Theme.gridGap)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(onStopAll: { session.stopAll() })

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: Theme.gridGap) {
                    ForEach(session.store.pads) { pad in
                        SoundPadView(
                            pad: pad,
                            litBars: session.litBars(for: pad.id),
                            isPlaying: session.playingPadIDs.contains(pad.id),
                            onTap: { session.tap(pad: pad.id) },
                            onLongPress: { session.beginEdit(pad: pad.id) }
                        )
                    }
                }
                .padding(.horizontal, Theme.gridPaddingHorizontal)
                .padding(.vertical, Theme.gridPaddingVertical)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.always)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(item: editingPad) { pad in
            PadEditSheet(
                pad: pad,
                existingAudioURL: session.store.fileURL(for: pad),
                onCancel: { session.cancelEdit() },
                onSave: { name, file, remove in
                    session.applyEdit(padID: pad.id, name: name, replacingFile: file, removeAudio: remove)
                },
                onMicrophoneDenied: { session.alert = .microphoneDenied }
            )
            .presentationDetents([.fraction(0.5)])
        }
        .alert(item: $session.alert) { alert in
            if alert == .microphoneDenied {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text("OK"))
                )
            }
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                session.sceneBecameInactive()
            }
        }
    }

    private var editingPad: Binding<Pad?> {
        Binding(
            get: {
                guard let id = session.editingPadID else { return nil }
                return session.store.pad(id: id)
            },
            set: { newValue in
                if newValue == nil {
                    session.cancelEdit()
                }
            }
        )
    }
}

#if DEBUG
#Preview("Board idle") {
    BoardPreviewHost(session: PreviewBoard.session())
}

#Preview("Board playing") {
    BoardPreviewHost(session: PreviewBoard.session(meters: [1: 0.9, 3: 0.45, 5: 0.2]))
}

private struct BoardPreviewHost: View {
    @State var session: BoardSession

    var body: some View {
        BoardView(session: session)
    }
}
#endif
