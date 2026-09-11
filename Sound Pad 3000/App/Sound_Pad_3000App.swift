import SwiftUI

@main
struct Sound_Pad_3000App: App {
    @State private var session = BoardSession(
        store: PadStore(
            root: PadStore.defaultRoot(),
            factorySamples: FactorySamples.bundled()
        ),
        audio: PadAudioEngine()
    )

    var body: some Scene {
        WindowGroup {
            BoardView(session: session)
        }
    }
}
