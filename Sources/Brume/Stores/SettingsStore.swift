import AppKit
import BrumeCore
import Observation

/// Les réglages de l'app : les vues les lisent et s'y adaptent en direct.
@MainActor @Observable
final class SettingsStore {
    private(set) var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            L10n.language = settings.language
            scheduleSave()
        }
    }

    @ObservationIgnored private let file: SettingsFile
    @ObservationIgnored private var pendingSave: DispatchWorkItem?
    @ObservationIgnored nonisolated(unsafe) private var terminateObserver: NSObjectProtocol?

    init(file: SettingsFile = .standard) {
        self.file = file
        var loaded = file.load()
        // Une police désinstallée depuis : le moteur se rabattrait sans le dire, la liste resterait vide.
        if let family = loaded.font.family, !TerminalFonts.featured.contains(family) {
            loaded.font.family = nil
        }
        settings = loaded
        L10n.language = loaded.language
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveNow() }
        }
    }

    deinit {
        if let terminateObserver { NotificationCenter.default.removeObserver(terminateObserver) }
    }

    var appearance: Appearance {
        get { settings.appearance }
        set { settings.appearance = newValue }
    }

    var font: TerminalFont {
        get { settings.font }
        set { settings.font = newValue }
    }

    var language: Language {
        get { settings.language }
        set { settings.language = newValue }
    }

    var restoresSession: Bool {
        get { settings.restoresSession }
        set { settings.restoresSession = newValue }
    }

    /// Un curseur qu'on glisse change la valeur à chaque image : on écrit une fois qu'il s'arrête.
    private func scheduleSave() {
        pendingSave?.cancel()
        let save = DispatchWorkItem { [weak self] in self?.saveNow() }
        pendingSave = save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: save)
    }

    private func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        try? file.save(settings)
    }
}
