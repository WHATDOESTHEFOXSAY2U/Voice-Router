import AppIntents
import SwiftUI

@main
struct VoiceRouterApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var captureStore = CaptureStore()
    @StateObject private var launchCenter = CaptureLaunchCenter()
    @StateObject private var speechService = SpeechService()
    @StateObject private var settings = AppSettingsStore()

    init() {
        VoiceRouterAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(captureStore)
                .environmentObject(launchCenter)
                .environmentObject(speechService)
                .environmentObject(settings)
                .task {
                    launchCenter.loadPendingCaptureIfNeeded()
                }
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .active else { return }
                    launchCenter.loadPendingCaptureIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: .captureLaunchQueued)) { _ in
                    launchCenter.loadPendingCaptureIfNeeded()
                }
                .onOpenURL { url in
                    guard url.scheme == "voicerouter", url.host == "capture" else { return }
                    CaptureLaunchRequest.queue(source: .urlScheme)
                    DispatchQueue.main.async {
                        launchCenter.loadPendingCaptureIfNeeded()
                    }
                }
        }
    }
}
