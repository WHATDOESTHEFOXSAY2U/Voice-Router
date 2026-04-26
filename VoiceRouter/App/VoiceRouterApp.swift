import AppIntents
import SwiftUI

@main
struct VoiceRouterApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var captureStore = CaptureStore()
    @StateObject private var speechService = SpeechService()
    @StateObject private var settings = AppSettingsStore()

    init() {
        VoiceRouterAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(captureStore)
                .environmentObject(speechService)
                .environmentObject(settings)
                .task {
                    schedulePendingCaptureDispatch()
                }
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .active else { return }
                    schedulePendingCaptureDispatch()
                }
                .onReceive(NotificationCenter.default.publisher(for: .captureLaunchQueued)) { _ in
                    schedulePendingCaptureDispatch()
                }
                .onOpenURL { url in
                    guard url.scheme == "voicerouter", url.host == "capture" else { return }
                    CaptureLaunchRequest.queue(source: .urlScheme)
                    DispatchQueue.main.async {
                        schedulePendingCaptureDispatch()
                    }
                }
        }
    }

    private func schedulePendingCaptureDispatch() {
        dispatchPendingCaptureIfNeeded()

        let retryDelays: [TimeInterval] = [0.18, 0.55, 1.1]
        for delay in retryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                dispatchPendingCaptureIfNeeded()
            }
        }
    }

    private func dispatchPendingCaptureIfNeeded() {
        guard let source = CaptureLaunchRequest.consumeIfNeeded() else { return }
        NotificationCenter.default.post(name: .startCapture, object: source)
    }
}
