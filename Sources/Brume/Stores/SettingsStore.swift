import BrumeCore
import Observation

/// Les réglages de l'app : les vues les lisent et s'y adaptent en direct.
@MainActor @Observable
final class SettingsStore {
    private(set) var settings: Settings {
        didSet { try? file.save(settings) }
    }

    @ObservationIgnored private let file: SettingsFile

    init(file: SettingsFile = .standard) {
        self.file = file
        settings = file.load()
    }

    var translucency: Translucency {
        settings.translucency
    }

    func setTranslucency(_ translucency: Translucency) {
        settings.translucency = translucency
    }
}
