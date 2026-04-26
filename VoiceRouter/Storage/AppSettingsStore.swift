import Combine
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var useAppleIntelligenceFormatting: Bool {
        didSet { defaults.set(useAppleIntelligenceFormatting, forKey: Keys.useAppleIntelligenceFormatting) }
    }

    @Published var automaticallyFinishAfterPause: Bool {
        didSet { defaults.set(automaticallyFinishAfterPause, forKey: Keys.automaticallyFinishAfterPause) }
    }

    @Published var pauseDuration: Double {
        didSet { defaults.set(pauseDuration, forKey: Keys.pauseDuration) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.useAppleIntelligenceFormatting = defaults.object(forKey: Keys.useAppleIntelligenceFormatting) as? Bool ?? false
        self.automaticallyFinishAfterPause = defaults.object(forKey: Keys.automaticallyFinishAfterPause) as? Bool ?? true
        self.pauseDuration = defaults.object(forKey: Keys.pauseDuration) as? Double ?? 0.75
    }

    private enum Keys {
        static let useAppleIntelligenceFormatting = "settings.useAppleIntelligenceFormatting"
        static let automaticallyFinishAfterPause = "settings.automaticallyFinishAfterPause"
        static let pauseDuration = "settings.pauseDuration"
    }
}
