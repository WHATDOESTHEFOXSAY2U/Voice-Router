import AVFoundation
import CoreGraphics
import Foundation
import Speech

@MainActor
final class SpeechService: ObservableObject {
    enum AuthorizationStatus: Equatable {
        case unknown
        case requesting
        case authorized
        case microphoneDenied
        case speechDenied
        case recognizerUnavailable
        case requestTimedOut

        var guidance: String {
            switch self {
            case .unknown:
                return "Voice Router needs microphone and speech access before it can listen."
            case .requesting:
                return "Requesting microphone and speech access."
            case .authorized:
                return "Ready to listen."
            case .microphoneDenied:
                return "Microphone access is off. Enable it in Settings to start capture."
            case .speechDenied:
                return "Speech recognition access is off. Enable it in Settings to transcribe."
            case .recognizerUnavailable:
                return "Speech recognition is not available for the current language right now."
            case .requestTimedOut:
                return "Permission request timed out. Reopen the app or grant Microphone and Speech Recognition access in Settings."
            }
        }
    }

    @Published var isRecording = false
    @Published var transcript = ""
    @Published var audioLevel: CGFloat = 0.08
    @Published var errorMessage: String?
    @Published private(set) var authorizationStatus: AuthorizationStatus = .unknown
    @Published private(set) var supportsOnDeviceRecognition = false

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasInstalledTap = false
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognizerLocaleIdentifier: String?

    func ensureAuthorization() async -> Bool {
        authorizationStatus = .requesting
        errorMessage = nil

        switch audioSession.recordPermission {
        case .granted:
            break
        case .denied:
            authorizationStatus = .microphoneDenied
            errorMessage = authorizationStatus.guidance
            return false
        case .undetermined:
            let microphoneResolution = await requestMicrophonePermission()

            switch microphoneResolution {
            case .granted:
                break
            case .denied:
                authorizationStatus = .microphoneDenied
                errorMessage = authorizationStatus.guidance
                return false
            case .timedOut:
                authorizationStatus = .requestTimedOut
                errorMessage = authorizationStatus.guidance
                return false
            }
        @unknown default:
            authorizationStatus = .microphoneDenied
            errorMessage = authorizationStatus.guidance
            return false
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            break
        case .denied, .restricted:
            authorizationStatus = .speechDenied
            errorMessage = authorizationStatus.guidance
            return false
        case .notDetermined:
            let speechResolution = await requestSpeechPermission()

            switch speechResolution {
            case .authorized:
                break
            case .denied:
                authorizationStatus = .speechDenied
                errorMessage = authorizationStatus.guidance
                return false
            case .timedOut:
                authorizationStatus = .requestTimedOut
                errorMessage = authorizationStatus.guidance
                return false
            }
        @unknown default:
            authorizationStatus = .speechDenied
            errorMessage = authorizationStatus.guidance
            return false
        }

        guard let recognizer = currentSpeechRecognizer() else {
            authorizationStatus = .recognizerUnavailable
            errorMessage = authorizationStatus.guidance
            return false
        }

        supportsOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        authorizationStatus = .authorized
        return true
    }

    func refreshAuthorizationState() {
        errorMessage = nil

        switch audioSession.recordPermission {
        case .denied:
            authorizationStatus = .microphoneDenied
            supportsOnDeviceRecognition = false
            return
        case .undetermined:
            authorizationStatus = .unknown
            supportsOnDeviceRecognition = false
            return
        case .granted:
            break
        @unknown default:
            authorizationStatus = .unknown
            supportsOnDeviceRecognition = false
            return
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            authorizationStatus = .authorized
        case .denied, .restricted:
            authorizationStatus = .speechDenied
            supportsOnDeviceRecognition = false
            return
        case .notDetermined:
            authorizationStatus = .unknown
            supportsOnDeviceRecognition = false
            return
        @unknown default:
            authorizationStatus = .unknown
            supportsOnDeviceRecognition = false
            return
        }
    }

    func startRecording() throws {
        guard isAuthorized else {
            throw SpeechError.notAuthorized
        }

        guard let recognizer = currentSpeechRecognizer() else {
            throw SpeechError.recognizerUnavailable
        }

        guard recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        supportsOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        if isRecording {
            stopRecording()
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        if #available(iOS 16, *) {
            request.addsPunctuation = true
        }

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)
            let level = Self.normalizedAudioLevel(from: buffer)

            Task { @MainActor in
                self?.audioLevel = level
            }
        }
        hasInstalledTap = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if let error {
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        return
                    }

                    self.errorMessage = error.localizedDescription
                    self.stopRecording()
                }
            }
        }

        transcript = ""
        audioLevel = 0.08
        errorMessage = nil

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        audioLevel = 0.08

        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestMicrophonePermission() async -> PermissionResolution {
        if audioSession.recordPermission == .granted {
            return .granted
        }

        if audioSession.recordPermission == .denied {
            return .denied
        }

        await withCheckedContinuation { continuation in
            var didResume = false

            func resume(_ result: PermissionResolution) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: result)
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                resume(.timedOut)
            }

            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    resume(granted ? .granted : .denied)
                }
            }
        }
    }

    private func requestSpeechPermission() async -> PermissionResolution {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            break
        @unknown default:
            return .denied
        }

        await withCheckedContinuation { continuation in
            var didResume = false

            func resume(_ result: PermissionResolution) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: result)
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                resume(.timedOut)
            }

            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        resume(.authorized)
                    case .denied, .restricted, .notDetermined:
                        resume(.denied)
                    @unknown default:
                        resume(.denied)
                    }
                }
            }
        }
    }

    private func currentSpeechRecognizer() -> SFSpeechRecognizer? {
        let localeIdentifier = Locale.autoupdatingCurrent.identifier

        if recognizerLocaleIdentifier != localeIdentifier || speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
            recognizerLocaleIdentifier = localeIdentifier
        }

        return speechRecognizer
    }

    private static func normalizedAudioLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0.08
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return 0.08
        }

        let sampleStride = max(frameLength / 32, 1)
        var total: Float = 0
        var samples = 0

        for index in stride(from: 0, to: frameLength, by: sampleStride) {
            let sample = channelData[index]
            total += sample * sample
            samples += 1
        }

        let rms = sqrt(total / Float(max(samples, 1)))
        return min(max(CGFloat(rms) * 16.0, 0.08), 1.0)
    }

    enum SpeechError: LocalizedError {
        case notAuthorized
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Microphone and speech access are required before capture can start."
            case .recognizerUnavailable:
                return "Speech recognition is unavailable for the current language."
            }
        }
    }

    private enum PermissionResolution {
        case granted
        case authorized
        case denied
        case timedOut
    }
}
