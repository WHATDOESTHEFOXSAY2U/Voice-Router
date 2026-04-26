import Foundation

enum CaptureLaunchSource: String {
    case manual
    case shortcut
    case urlScheme
}

enum CaptureLaunchRequest {
    private static let timestampKey = "captureLaunch.timestamp"
    private static let sourceKey = "captureLaunch.source"

    static func queue(source: CaptureLaunchSource) {
        let defaults = UserDefaults.standard
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        defaults.set(source.rawValue, forKey: sourceKey)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .captureLaunchQueued, object: source)
        }
    }

    static func consumeIfNeeded(maxAge: TimeInterval = 10) -> CaptureLaunchSource? {
        let defaults = UserDefaults.standard
        let timestamp = defaults.double(forKey: timestampKey)

        guard timestamp > 0 else {
            return nil
        }

        defaults.removeObject(forKey: timestampKey)

        let source = CaptureLaunchSource(rawValue: defaults.string(forKey: sourceKey) ?? "") ?? .manual
        defaults.removeObject(forKey: sourceKey)

        let age = Date().timeIntervalSince1970 - timestamp
        return age <= maxAge ? source : nil
    }
}

extension Notification.Name {
    static let captureLaunchQueued = Notification.Name("voicerouter.captureLaunchQueued")
    static let startCapture = Notification.Name("voicerouter.startCapture")
}
