import AppKit
import BrumeCore

/// Les fenêtres de la dernière fois : chaque fenêtre qui s'ouvre en reprend une, et celles
/// ouvertes sont enregistrées après chaque changement et à la sortie, comme `window-save-state` de
/// Ghostty. Sauf si le réglage est éteint : rien n'est relu ni gardé.
@MainActor @Observable
final class SessionStore {
    @ObservationIgnored private let file: SessionFile
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var pending: [SavedWindow]
    @ObservationIgnored private var windowsToOpen: Int
    /// Ce qui est sur le disque : une session identique n'est pas réécrite.
    @ObservationIgnored private var written: Session?
    @ObservationIgnored private var isSaveScheduled = false
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
        workspace.onSnapshotChange = { [weak self] in self?.scheduleSave() }
        scheduleSave()
        return workspace
    }

    /// Combien d'autres fenêtres la première doit ouvrir. Ne répond qu'une fois : les fenêtres
    /// ouvertes ainsi ne doivent pas en rouvrir à leur tour.
    func takeWindowsToOpen() -> Int {
        defer { windowsToOpen = 0 }
        return windowsToOpen
    }

    /// Un plantage ou une coupure de courant ne perd que les deux dernières secondes. Les
    /// changements qui suivent (un séparateur qu'on glisse, des `cd`) attendent ce même passage.
    private func scheduleSave() {
        guard !isSaveScheduled else { return }
        isSaveScheduled = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.isSaveScheduled = false
            self?.save()
        }
    }

    /// Les fenêtres pas encore rouvertes restent dans la session.
    private func save() {
        guard settings.settings.restoresSession else {
            written = nil
            return file.delete()
        }
        let session = Session(windows: TerminalWorkspace.all.map(\.snapshot) + pending)
        guard session != written, (try? file.save(session)) != nil else { return }
        written = session
    }
}
