import AppKit
import BrumeCore

/// Les fenêtres de la dernière fois : chaque fenêtre qui s'ouvre en reprend une, et à la sortie
/// celles encore ouvertes sont enregistrées, comme `window-save-state` de Ghostty. Sauf si le
/// réglage est éteint : rien n'est relu ni gardé.
@MainActor @Observable
final class SessionStore {
    @ObservationIgnored private let file: SessionFile
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var pending: [SavedWindow]
    @ObservationIgnored private var windowsToOpen: Int
    @ObservationIgnored nonisolated(unsafe) private var terminateObserver: NSObjectProtocol?

    init(settings: SettingsStore, file: SessionFile = .standard) {
        self.file = file
        self.settings = settings
        pending = settings.settings.restoresSession ? file.load()?.windows ?? [] : []
        windowsToOpen = max(pending.count - 1, 0)
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.save() }
        }
    }

    deinit {
        if let terminateObserver { NotificationCenter.default.removeObserver(terminateObserver) }
    }

    /// La fenêtre suivante de la session, ou une neuve quand il n'en reste plus.
    func makeWorkspace() -> TerminalWorkspace {
        let workspace = TerminalWorkspace(restoring: pending.isEmpty ? nil : pending.removeFirst())
        workspace.settings = settings
        return workspace
    }

    /// Combien d'autres fenêtres la première doit ouvrir. Ne répond qu'une fois : les fenêtres
    /// ouvertes ainsi ne doivent pas en rouvrir à leur tour.
    func takeWindowsToOpen() -> Int {
        defer { windowsToOpen = 0 }
        return windowsToOpen
    }

    private func save() {
        guard settings.settings.restoresSession else { return file.delete() }
        let windows = TerminalWorkspace.all.map(\.snapshot)
        try? file.save(Session(windows: windows))
    }
}
