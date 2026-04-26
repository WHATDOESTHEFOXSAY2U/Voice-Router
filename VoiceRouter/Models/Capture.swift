import Foundation
import SwiftUI

enum CaptureOutputStyle: String, Codable, CaseIterable {
    case transcript
    case appleIntelligence = "apple_intelligence"
    case fallbackTranscript = "fallback_transcript"
    case legacySmartFormat = "legacy_smart_format"

    var displayName: String {
        switch self {
        case .transcript:
            return "Transcript"
        case .appleIntelligence:
            return "Apple Intelligence"
        case .fallbackTranscript:
            return "Transcript Fallback"
        case .legacySmartFormat:
            return "Legacy Format"
        }
    }

    var icon: String {
        switch self {
        case .transcript:
            return "waveform"
        case .appleIntelligence:
            return "sparkles"
        case .fallbackTranscript:
            return "exclamationmark.circle"
        case .legacySmartFormat:
            return "archivebox"
        }
    }

    var color: Color {
        switch self {
        case .transcript:
            return Color(red: 0.36, green: 0.82, blue: 0.92)
        case .appleIntelligence:
            return Color(red: 0.99, green: 0.75, blue: 0.33)
        case .fallbackTranscript:
            return Color(red: 0.98, green: 0.56, blue: 0.28)
        case .legacySmartFormat:
            return Color(red: 0.63, green: 0.64, blue: 0.71)
        }
    }
}

enum CaptureStatus: String, Codable {
    case pending
    case saved
    case failed
}

struct Capture: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let rawTranscript: String
    let clipboardText: String
    let outputStyle: CaptureOutputStyle
    var status: CaptureStatus
    var note: String?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawTranscript: String,
        clipboardText: String,
        outputStyle: CaptureOutputStyle,
        status: CaptureStatus = .saved,
        note: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawTranscript = rawTranscript
        self.clipboardText = clipboardText
        self.outputStyle = outputStyle
        self.status = status
        self.note = note
        self.errorMessage = errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case rawTranscript
        case clipboardText
        case outputStyle
        case status
        case note
        case errorMessage
        case formattedOutput
        case intent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        rawTranscript = try container.decodeIfPresent(String.self, forKey: .rawTranscript) ?? ""
        clipboardText = try container.decodeIfPresent(String.self, forKey: .clipboardText)
            ?? container.decodeIfPresent(String.self, forKey: .formattedOutput)
            ?? rawTranscript
        outputStyle = try container.decodeIfPresent(CaptureOutputStyle.self, forKey: .outputStyle)
            ?? Self.legacyOutputStyle(from: try container.decodeIfPresent(String.self, forKey: .intent))
        status = try container.decodeIfPresent(CaptureStatus.self, forKey: .status) ?? .saved
        note = try container.decodeIfPresent(String.self, forKey: .note)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(rawTranscript, forKey: .rawTranscript)
        try container.encode(clipboardText, forKey: .clipboardText)
        try container.encode(outputStyle, forKey: .outputStyle)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }

    private static func legacyOutputStyle(from intentValue: String?) -> CaptureOutputStyle {
        guard let intentValue else {
            return .legacySmartFormat
        }

        return intentValue == "clipboard" ? .transcript : .legacySmartFormat
    }
}
