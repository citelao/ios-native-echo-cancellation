import AVFAudio
import Combine

@MainActor
final class EchoAudioEngine: ObservableObject {
    @Published var isRunning = false
    @Published var isAECEnabled = false
    @Published var delaySeconds: Double = 0.3 {
        didSet { delayNode.delayTime = delaySeconds }
    }
    @Published var level: Float = 0
    @Published var errorMessage: String?

    private let engine = AVAudioEngine()
    private let delayNode = AVAudioUnitDelay()

    init() {
        delayNode.delayTime = delaySeconds
        delayNode.wetDryMix = 100
        delayNode.feedback = 0
    }

    func start() {
        guard !isRunning else { return }
        requestMicPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.errorMessage = "Microphone access denied. Enable it in Settings > EchoTest > Microphone."
                    return
                }
                self.buildGraphAndStart()
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engine.disconnectNodeInput(delayNode)
        engine.disconnectNodeOutput(delayNode)
        engine.detach(delayNode)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
        level = 0
    }

    /// Toggling voice processing requires the audio unit to be reconfigured,
    /// so we tear down and rebuild the graph rather than flipping it live.
    func setAECEnabled(_ enabled: Bool) {
        isAECEnabled = enabled
        guard isRunning else { return }
        stop()
        start()
    }

    private func requestMicPermission(_ completion: @escaping @Sendable (Bool) -> Void) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            completion(true)
        case .undetermined:
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        default:
            completion(false)
        }
    }

    private func buildGraphAndStart() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }

        let input = engine.inputNode
        do {
            try input.setVoiceProcessingEnabled(isAECEnabled)
        } catch {
            errorMessage = "Failed to set voice processing: \(error.localizedDescription)"
        }

        let format = input.outputFormat(forBus: 0)

        engine.attach(delayNode)
        engine.connect(input, to: delayNode, format: format)
        engine.connect(delayNode, to: engine.mainMixerNode, format: format)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let level = Self.rmsLevel(of: buffer)
            Task { @MainActor in
                self?.level = level
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isRunning = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start engine: \(error.localizedDescription)"
        }
    }

    nonisolated private static func rmsLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        let samples = channelData[0]
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += samples[i] * samples[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        return min(rms * 6, 1.0)
    }
}
