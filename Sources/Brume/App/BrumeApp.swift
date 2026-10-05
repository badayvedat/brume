import SwiftUI

@main
struct BrumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var session: SessionStore
    @State private var settings: SettingsStore
    @State private var updater: UpdaterStore

    init() {
        let settings = SettingsStore()
        _settings = State(initialValue: settings)
        _session = State(initialValue: SessionStore(settings: settings))
        _updater = State(initialValue: UpdaterStore())
        SystemSymbol.preload()
        InstalledApps.preload()
        // Le shell hérite de cette variable : le patch zsh y trouve les greffons embarqués.
        if let resources = Bundle.main.resourcePath {
            setenv("BRUME_RESOURCES_DIR", resources, 1)
        }
    }

    static let terminalWindowID = "terminal"

    /// La barre latérale s'ajoute, le terminal garde sa largeur (sinon l'écran de démarrage
    /// retombe sur sa version étroite).
    @MainActor static func defaultWindowSize(_ settings: SettingsStore) -> CGSize {
        let sidebar = settings.verticalTabs.isOn ? settings.verticalTabs.width + 1 : 0
        return CGSize(width: 800 + sidebar, height: 500)
    }

    var body: some Scene {
        WindowGroup(id: Self.terminalWindowID) {
            TerminalScreen()
                .environment(session)
                .environment(settings)
                .environment(updater)
        }
        // Brume rouvre lui-même ses fenêtres (`SessionStore`) : macOS en rouvrirait en double.
        .restorationBehavior(.disabled)
        .windowStyle(.hiddenTitleBar)
        // Lu à chaque nouvelle fenêtre.
        .defaultWindowPlacement { _, _ in
            WindowPlacement(size: Self.defaultWindowSize(settings))
        }
        .commands {
            UpdateCommands(updater: updater)
            TabCommands(settings: settings)
            CloseCommands(settings: settings)
            SplitCommands(settings: settings)
            SearchCommands()
            FontSizeCommands()
            SettingsCommands()
            VerticalTabsCommands(settings: settings)
            HelpCommands()
        }
    }
}
