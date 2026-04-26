import Foundation
import SwiftUI
import UIKit

@MainActor
final class CaptureViewModel: ObservableObject {
    enum CaptureState: Equatable {
        case idle
        case arming(source: CaptureLaunchSource)
        case listening(source: CaptureLaunchSource)
        case processing(message: String)
        case result(captureId: UUID)
        case error(message: String)
    }

    @Published var state: CaptureState = .idle
    @Published var lastCapture: Capture?
    @Published var feedbackMessage: String?
    @Published var showFeedbackBanner = false

    let speechService: SpeechService

    private let formatter = AppleIntelligenceFormatter()
    private let clipboardWriter = ClipboardWriter()
    private var autoFinishTask: Task<Void, Never>?

    init(speechService: SpeechService) {
        self.speechService = speechService
    }

    var isArming: Bool {
        if case .arming = state {
            return true
        }
        return false
    }

    var isListening: Bool {
        if case .listening = state {
            return true
        }
        return false
    }

    var isCaptureActive: Bool {
        isArming || isListening
    }

    var isProcessing: Bool {
        if case .processing = state {
            return true
        }
        return false
    }

    func prepare(settings: AppSettingsStore) async {
        _ = await speechService.ensureAuthorization()
        speechService.prewarmForQuickCapture()
        formatter.prewarmIfPossible(preferFormatting: settings.useAppleIntelligenceFormatting)
    }

    func prewarmForCurrentSettings(_ settings: AppSettingsStore) {
        speechService.prewarmForQuickCapture()
        formatter.prewarmIfPossible(preferFormatting: settings.useAppleIntelligenceFormatting)
    }

    func startCapture(source: CaptureLaunchSource = .manual) async {
        guard !isProcessing else { return }

        if speechService.isRecording {
            return
        }

        clearTransientState()
        state = .arming(source: source)

        let authorized = await speechService.ensureAuthorization()
        guard authorized else {
            state = .error(message: speechService.authorizationStatus.guidance)
            return
        }

        do {
            try speechService.startRecording()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            state = .listening(source: source)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    func stopCapture(store: CaptureStore, settings: AppSettingsStore) async {
        await finalizeCapture(store: store, settings: settings)
    }

    func handleTranscriptChanged(store: CaptureStore, settings: AppSettingsStore) {
        guard isListening else { return }

        autoFinishTask?.cancel()

        guard settings.automaticallyFinishAfterPause else {
            return
        }

        let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            return
        }

        let pauseDuration = settings.pauseDuration

        autoFinishTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.finalizeCapture(store: store, settings: settings)
        }
    }

    func reset() {
        autoFinishTask?.cancel()
        autoFinishTask = nil

        if speechService.isRecording {
            speechService.stopRecording()
        }

        clearTransientState()
        lastCapture = nil
        state = .idle
    }

    func retryCopy(capture: Capture, store: CaptureStore) {
        let success = clipboardWriter.write(capture.clipboardText)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)

        store.updateStatus(
            id: capture.id,
            status: success ? .saved : .failed,
            error: success ? nil : "Failed to copy to clipboard"
        )

        if lastCapture?.id == capture.id {
            lastCapture?.status = success ? .saved : .failed
            lastCapture?.errorMessage = success ? nil : "Failed to copy to clipboard"
        }

        showFeedback(success ? "Copied to clipboard again." : "Copy to clipboard failed.")
    }

    private func finalizeCapture(store: CaptureStore, settings: AppSettingsStore) async {
        guard speechService.isRecording || isListening else { return }

        autoFinishTask?.cancel()
        autoFinishTask = nil

        if speechService.isRecording {
            speechService.stopRecording()
        }

        let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            state = .error(message: "I didn’t catch anything. Try once more and speak after the pulse appears.")
            return
        }

        let processingMessage = settings.useAppleIntelligenceFormatting
            ? "Polishing your dictation..."
            : "Copying to clipboard..."
        state = .processing(message: processingMessage)

        let output = await formatter.prepareClipboardOutput(
            from: transcript,
            preferFormatting: settings.useAppleIntelligenceFormatting
        )

        let success = clipboardWriter.write(output.text)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)

        let capture = Capture(
            rawTranscript: transcript,
            clipboardText: output.text,
            outputStyle: output.style,
            status: success ? .saved : .failed,
            note: output.note,
            errorMessage: success ? nil : "Failed to copy to clipboard"
        )

        store.addCapture(capture)
        lastCapture = capture
        state = .result(captureId: capture.id)

        if success {
            showFeedback(output.note ?? "Copied to clipboard.")
        } else {
            showFeedback("Copy to clipboard failed.")
        }
    }

    private func clearTransientState() {
        feedbackMessage = nil
        showFeedbackBanner = false
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        showFeedbackBanner = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            self?.showFeedbackBanner = false
        }
    }
}
