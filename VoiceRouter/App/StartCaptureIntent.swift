import AppIntents

struct StartCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Voice Capture"
    static var description = IntentDescription("Open Voice Router and immediately start listening for a clipboard-ready transcription.")

    func perform() async throws -> some IntentResult {
        CaptureLaunchRequest.queue(source: .shortcut)
        return .result()
    }
}

@available(*, deprecated)
extension StartCaptureIntent {
    static var openAppWhenRun: Bool { true }
}

struct VoiceRouterAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: StartCaptureIntent(),
                phrases: [
                    "Start capture in \(.applicationName)",
                    "Record with \(.applicationName)",
                    "Transcribe to clipboard in \(.applicationName)"
                ],
                shortTitle: "Start Capture",
                systemImageName: "mic.badge.plus"
            )
        ]
    }
}
