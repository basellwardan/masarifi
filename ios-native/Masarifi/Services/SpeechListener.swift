import AVFoundation
import Foundation
import Observation
import Speech

/// Listens with Apple's speech recognizer and stops on its own after a short
/// silence (like the Android build), then hands back what was said.
@Observable
final class SpeechListener {
    enum Failure: Equatable { case denied, unavailable, failed }

    var transcript = ""
    var isListening = false
    var level: CGFloat = 0
    var failure: Failure?

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var capTimer: Timer?
    private var onFinish: ((String) -> Void)?
    private var finished = false

    private static let silence: TimeInterval = 1.8
    private static let noSpeech: TimeInterval = 7
    private static let maxListen: TimeInterval = 20

    func start(lang: Lang, onFinish: @escaping (String) -> Void) {
        guard !isListening else { return }
        failure = nil
        transcript = ""
        finished = false
        self.onFinish = onFinish
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { self.failure = .denied; return }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else { self.failure = .denied; return }
                        self.begin(lang: lang)
                    }
                }
            }
        }
    }

    private func begin(lang: Lang) {
        let locale = Locale(identifier: lang == .ar ? "ar-SA" : "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            failure = .unavailable
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = false }
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                self?.meter(buffer)
            }
            engine.prepare()
            try engine.start()

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        self.arm(Self.silence)
                        if result.isFinal { self.finish() }
                    } else if error != nil {
                        self.finish()
                    }
                }
            }
            isListening = true
            arm(Self.noSpeech)
            capTimer = Timer.scheduledTimer(withTimeInterval: Self.maxListen, repeats: false) { [weak self] _ in
                self?.stop()
            }
        } catch {
            failure = .failed
            teardown()
        }
    }

    private func meter(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in stride(from: 0, to: n, by: 8) { sum += abs(data[i]) }
        let avg = n > 0 ? sum / Float(n / 8 + 1) : 0
        DispatchQueue.main.async { self.level = min(1, CGFloat(avg) * 12) }
    }

    private func arm(_ seconds: TimeInterval) {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.stop()
        }
    }

    /// Stop listening; the result arrives through `onFinish`.
    func stop() {
        guard isListening else { return }
        request?.endAudio()
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.finish() }
    }

    func cancel() {
        onFinish = nil
        finished = true
        task?.cancel()
        teardown()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        task?.finish()
        teardown()
        let text = transcript
        onFinish?(text)
        onFinish = nil
    }

    private func teardown() {
        silenceTimer?.invalidate()
        capTimer?.invalidate()
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request = nil
        task = nil
        isListening = false
        level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
