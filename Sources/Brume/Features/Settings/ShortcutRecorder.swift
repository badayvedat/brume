import AppKit
import BrumeCore
import Observation

/// Le raccourci en train d'être tapé dans les réglages. Il prend les touches de leur fenêtre avant
/// les menus : ⌘T tapé ici ne doit pas ouvrir d'onglet. Celles des autres fenêtres passent, et la
/// fenêtre qui perd le clavier arrête l'enregistrement.
@MainActor @Observable
final class ShortcutRecorder {
    struct Attempt {
        let shortcut: Shortcut
        let issue: ShortcutIssue
    }

    /// L'action dont on tape le raccourci.
    private(set) var action: ShortcutAction?
    /// La dernière combinaison tapée, si elle pose problème : refusée, ou en attente d'une réponse.
    private(set) var attempt: Attempt?

    @ObservationIgnored private weak var settings: SettingsStore?
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var resignObserver: NSObjectProtocol?

    /// `window` : celle des réglages.
    init(window: NSWindow?) {
        self.window = window
    }

    func start(_ action: ShortcutAction, in settings: SettingsStore) {
        stop()
        guard let window else { return }
        self.action = action
        self.settings = settings
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let isTaken = MainActor.assumeIsolated {
                guard let self, event.window === self.window else { return false }
                self.handle(event)
                return true
            }
            return isTaken ? nil : event
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        monitor = nil
        resignObserver = nil
        action = nil
        attempt = nil
    }

    /// La combinaison en attente est gardée : reprise à l'autre action, ou touche du terminal.
    func confirm() {
        guard let action, let attempt, !attempt.issue.isBlocking else { return }
        if case let .taken(other) = attempt.issue {
            settings?.setShortcut(attempt.shortcut, for: action, replacing: other)
        } else {
            settings?.setShortcut(attempt.shortcut, for: action)
        }
        stop()
    }

    /// Le raccourci par défaut, s'il est libre ; sinon on demande, comme pour une combinaison tapée.
    func reset(_ action: ShortcutAction, in settings: SettingsStore) {
        start(action, in: settings)
        propose(action.defaultShortcut)
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
        switch (event.keyCode, flags.isEmpty) {
        case (53, true):
            stop()
        case (51, true), (117, true):
            if let action { settings?.setShortcut(nil, for: action) }
            stop()
        default:
            if let shortcut = KeyboardLayout.shortcut(from: event) { propose(shortcut) }
        }
    }

    private func propose(_ shortcut: Shortcut) {
        guard let action, let settings else { return }
        if let issue = settings.shortcutIssue(shortcut, for: action) {
            attempt = Attempt(shortcut: shortcut, issue: issue)
        } else {
            settings.setShortcut(shortcut, for: action)
            stop()
        }
    }
}
