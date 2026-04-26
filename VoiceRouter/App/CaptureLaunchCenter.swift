import Foundation

@MainActor
final class CaptureLaunchCenter: ObservableObject {
    @Published private(set) var pendingSource: CaptureLaunchSource?

    func loadPendingCaptureIfNeeded() {
        guard pendingSource == nil else { return }
        pendingSource = CaptureLaunchRequest.consumeIfNeeded()
    }

    func consumePendingCapture() -> CaptureLaunchSource? {
        let source = pendingSource
        pendingSource = nil
        return source
    }
}
