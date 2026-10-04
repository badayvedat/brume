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
            if (settings.welcome, settings.appearance.accent, settings.language) != (oldValue.welcome, oldValue.appearance.accent, oldValue.language) {
                applyWelcome()
            }
            if (settings.suggestsHistory, settings.completesCommands) != (oldValue.suggestsHistory, oldValue.completesCommands) {
                applyShellOptions()
            }
            scheduleSave()
        }
    }

    @ObservationIgnored private let file: SettingsFile
    @ObservationIgnored private let welcomeFiles: WelcomeFiles
    @ObservationIgnored private var welcomeConfigs: [URL] = []
    @ObservationIgnored private var pendingSave: DispatchWorkItem?
    @ObservationIgnored nonisolated(unsafe) private var terminateObserver: NSObjectProtocol?

    init(file: SettingsFile = .standard) {
        self.file = file
        welcomeFiles = WelcomeFiles(directory: file.url.deletingLastPathComponent())
        var loaded = file.load()
        // Une police désinstallée depuis : le moteur se rabattrait sans le dire, la liste resterait vide.
        if let family = loaded.font.family, !TerminalFonts.featured.contains(family) {
            loaded.font.family = nil
        }
        settings = loaded
        L10n.language = loaded.language
        applyWelcome()
        applyShellOptions()
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

    var suggestsHistory: Bool {
        get { settings.suggestsHistory }
        set { settings.suggestsHistory = newValue }
    }

    var completesCommands: Bool {
        get { settings.completesCommands }
        set { settings.completesCommands = newValue }
    }

    var welcome: Welcome {
        get { settings.welcome }
        set { settings.welcome = newValue }
    }

    var verticalTabs: VerticalTabs {
        get { settings.verticalTabs }
        set { settings.verticalTabs = newValue }
    }

    var showsFullPath: Bool {
        get { settings.showsFullPath }
        set { settings.showsFullPath = newValue }
    }

    var shortcuts: Shortcuts {
        get { settings.shortcuts }
        set { settings.shortcuts = newValue }
    }

    /// L'écran de démarrage tel que fastfetch le dessinera, aux tailles choisies, pour l'aperçu.
    func welcomePreview() async -> [[AnsiSpan]] {
        guard let config = welcomeConfigs.first, let output = await Fastfetch.output(config: config) else { return [] }
        return AnsiText.lines(output)
    }

    /// Le shell de chaque nouveau terminal hérite de ces variables : le patch zsh y lit les versions
    /// de l'écran de démarrage (`Patches/libghostty-spm-zsh-welcome.patch`).
    private func applyWelcome() {
        welcomeConfigs = (try? welcomeFiles.save(settings.welcome, accent: settings.appearance.accent, language: settings.language)) ?? []
        guard !welcomeConfigs.isEmpty, let fastfetch = Fastfetch.executable else {
            for name in ["BRUME_WELCOME_CONFIGS", "BRUME_WELCOME_ALIGN", "BRUME_FASTFETCH"] {
                unsetenv(name)
            }
            return
        }
        setenv("BRUME_WELCOME_CONFIGS", welcomeConfigs.map(\.path).joined(separator: ":"), 1)
        setenv("BRUME_WELCOME_ALIGN", settings.welcome.alignment.rawValue, 1)
        setenv("BRUME_FASTFETCH", fastfetch.path, 1)
    }

    /// Lues par le patch zsh (`Patches/libghostty-spm-zsh-plugins.patch`) : les terminaux déjà
    /// ouverts gardent ce qu'ils avaient.
    private func applyShellOptions() {
        setenv("BRUME_HISTORY_SUGGESTIONS", settings.suggestsHistory ? "1" : "0", 1)
        setenv("BRUME_COMPLETION", settings.completesCommands ? "1" : "0", 1)
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
