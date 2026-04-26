import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ClipboardOutput {
    let text: String
    let style: CaptureOutputStyle
    let note: String?
}

struct AppleIntelligenceAvailabilityStatus {
    let isReady: Bool
    let title: String
    let message: String
}

final class AppleIntelligenceFormatter {
    func availabilityStatus() -> AppleIntelligenceAvailabilityStatus {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default

            guard model.supportsLocale(Locale.autoupdatingCurrent) else {
                return AppleIntelligenceAvailabilityStatus(
                    isReady: false,
                    title: "Current language not supported",
                    message: "The on-device model does not support your current locale yet, so the app will keep the raw transcript."
                )
            }

            switch model.availability {
            case .available:
                return AppleIntelligenceAvailabilityStatus(
                    isReady: true,
                    title: "Ready",
                    message: "Apple Intelligence formatting is available on this device."
                )
            case .unavailable(.deviceNotEligible):
                return AppleIntelligenceAvailabilityStatus(
                    isReady: false,
                    title: "Device not eligible",
                    message: "This device does not support Apple Intelligence."
                )
            case .unavailable(.appleIntelligenceNotEnabled):
                return AppleIntelligenceAvailabilityStatus(
                    isReady: false,
                    title: "Turn on Apple Intelligence",
                    message: "Enable Apple Intelligence in Settings to clean up transcripts on device."
                )
            case .unavailable(.modelNotReady):
                return AppleIntelligenceAvailabilityStatus(
                    isReady: false,
                    title: "Model still preparing",
                    message: "Apple Intelligence is still downloading or warming up, so raw transcript fallback will be used for now."
                )
            case .unavailable(let other):
                return AppleIntelligenceAvailabilityStatus(
                    isReady: false,
                    title: "Temporarily unavailable",
                    message: "Apple Intelligence is unavailable right now (\(String(describing: other))). Raw transcript fallback will be used."
                )
            }
        }
#endif

        return AppleIntelligenceAvailabilityStatus(
            isReady: false,
            title: "Unavailable in this build",
            message: "Build with an iOS 26 SDK to enable Apple Intelligence formatting. The app will still copy the raw transcript."
        )
    }

    func prepareClipboardOutput(from transcript: String, preferFormatting: Bool) async -> ClipboardOutput {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        guard preferFormatting else {
            return ClipboardOutput(text: trimmed, style: .transcript, note: nil)
        }

#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = availabilityStatus()

            guard availability.isReady else {
                return ClipboardOutput(
                    text: trimmed,
                    style: .fallbackTranscript,
                    note: availability.message
                )
            }

            do {
                let session = LanguageModelSession(instructions: """
                    You clean up dictation for clipboard use.
                    Preserve the original meaning and language.
                    Remove filler words, false starts, and repeated fragments.
                    Fix punctuation, capitalization, and obvious speech artifacts.
                    Keep the result natural and concise.
                    Return only the rewritten text.
                    """
                )

                let prompt = """
                    Clean up this dictated text so it is ready to paste into another app:

                    \(trimmed)
                    """

                let response = try await session.respond(to: prompt)
                let polished = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !polished.isEmpty else {
                    throw FormatterError.emptyResponse
                }

                return ClipboardOutput(
                    text: polished,
                    style: .appleIntelligence,
                    note: "Polished with Apple Intelligence before copying."
                )
            } catch {
                return ClipboardOutput(
                    text: trimmed,
                    style: .fallbackTranscript,
                    note: "Apple Intelligence formatting failed, so the raw transcript was copied instead."
                )
            }
        }
#endif

        return ClipboardOutput(
            text: trimmed,
            style: .fallbackTranscript,
            note: "Apple Intelligence formatting is not available in this build, so the raw transcript was copied."
        )
    }

    private enum FormatterError: Error {
        case emptyResponse
    }
}
