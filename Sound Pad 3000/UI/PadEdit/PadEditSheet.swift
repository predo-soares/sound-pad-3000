import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct PadEditSheet: View {
    let pad: Pad
    var existingAudioURL: URL?
    var onCancel: () -> Void
    var onSave: (_ name: String, _ file: URL?, _ removeAudio: Bool) -> Void
    var onMicrophoneDenied: () -> Void

    @State private var name: String
    @State private var pendingFile: URL?
    @State private var removeAudio = false
    @State private var isImporterPresented = false
    @State private var isRecording = false
    @State private var recordingSeconds: TimeInterval = 0
    @State private var recorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordTask: Task<Void, Never>?
    @State private var previewPlayer = PreviewPlayer()
    @State private var waveform: [Float] = []
    @State private var waveformTask: Task<Void, Never>?

    init(
        pad: Pad,
        existingAudioURL: URL? = nil,
        onCancel: @escaping () -> Void,
        onSave: @escaping (_ name: String, _ file: URL?, _ removeAudio: Bool) -> Void,
        onMicrophoneDenied: @escaping () -> Void
    ) {
        self.pad = pad
        self.existingAudioURL = existingAudioURL
        self.onCancel = onCancel
        self.onSave = onSave
        self.onMicrophoneDenied = onMicrophoneDenied
        _name = State(initialValue: pad.name)
    }

    private var previewURL: URL? {
        if removeAudio { return nil }
        return pendingFile ?? existingAudioURL
    }

    var body: some View {
        NavigationStack {
            Form {
                if previewURL != nil {
                    Section {
                        SoundPreviewView(samples: waveform, player: previewPlayer)
                    }
                }
                Section("Sound") {
                    Button(isRecording ? "Stop (\(Int(recordingSeconds))s)" : "Record") {
                        Task { await toggleRecord() }
                    }
                    Button("Choose File") {
                        isImporterPresented = true
                    }
                    if pad.hasAudio || pendingFile != nil {
                        Button("Remove Sound", role: .destructive) {
                            pendingFile = nil
                            removeAudio = true
                        }
                    }
                    if pendingFile != nil {
                        Text("New sound ready to save")
                            .foregroundStyle(.secondary)
                    } else if removeAudio {
                        Text("Sound will be removed")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear { reloadPreview() }
            .onChange(of: pendingFile) { _, _ in reloadPreview() }
            .onChange(of: removeAudio) { _, _ in reloadPreview() }
            .onDisappear {
                waveformTask?.cancel()
                previewPlayer.stop()
                previewPlayer.load(nil)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TextField("Pad \(pad.id)", text: $name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Pad name")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopRecordingIfNeeded()
                        previewPlayer.stop()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        stopRecordingIfNeeded()
                        previewPlayer.stop()
                        onSave(name, pendingFile, removeAudio)
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: Self.audioTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingFile = url
                    removeAudio = false
                }
            }
        }
    }

    private static let audioTypes: [UTType] = {
        var types: [UTType] = [.audio, .mp3, .wav, .mpeg4Audio]
        if let aac = UTType(filenameExtension: "aac") { types.append(aac) }
        if let caf = UTType(filenameExtension: "caf") { types.append(caf) }
        if let m4a = UTType(filenameExtension: "m4a") { types.append(m4a) }
        return types
    }()

    private func reloadPreview() {
        waveformTask?.cancel()
        previewPlayer.load(previewURL)
        guard let url = previewURL else {
            waveform = []
            return
        }
        waveformTask = Task { @MainActor in
            let samples = await Task.detached(priority: .userInitiated) {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                return WaveformSampler.samples(from: url)
            }.value
            guard !Task.isCancelled else { return }
            waveform = samples
        }
    }

    @MainActor
    private func toggleRecord() async {
        if isRecording {
            stopRecordingIfNeeded()
            return
        }
        let permitted = await requestMic()
        guard permitted else {
            onMicrophoneDenied()
            return
        }
        previewPlayer.stop()
        startRecording()
    }

    private func requestMic() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func startRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        recordingURL = url
        isRecording = true
        recordingSeconds = 0
        recordTask = Task { @MainActor in
            while !Task.isCancelled && recordingSeconds < 15 {
                try? await Task.sleep(for: .milliseconds(200))
                if Task.isCancelled { return }
                recordingSeconds += 0.2
            }
            if recordingSeconds >= 15 {
                stopRecordingIfNeeded()
            }
        }
    }

    private func stopRecordingIfNeeded() {
        recordTask?.cancel()
        recordTask = nil
        recorder?.stop()
        recorder = nil
        if isRecording, let recordingURL {
            pendingFile = recordingURL
            removeAudio = false
        }
        isRecording = false
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

#if DEBUG
#Preview("Edit empty pad") {
    PadEditSheet(
        pad: Pad(id: 4, name: "", filename: nil),
        onCancel: {},
        onSave: { _, _, _ in },
        onMicrophoneDenied: {}
    )
}

#Preview("Edit named pad") {
    PadEditSheet(
        pad: Pad(id: 1, name: "CLAP", filename: "clap.wav"),
        onCancel: {},
        onSave: { _, _, _ in },
        onMicrophoneDenied: {}
    )
}
#endif
