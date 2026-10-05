import AppKit
import BrumeCore
import Carbon
import Combine

/// La saisie sécurisée de macOS pendant qu'un terminal demande un mot de passe (sudo, ssh), comme
/// Terminal et Ghostty : les autres apps ne voient plus la frappe. Le moteur signale l'invite.
@MainActor @Observable
final class SecureInput {
    private var gate = SecureInputGate<UUID>(isAppActive: NSApp.isActive)
    @ObservationIgnored private var watchers: [AnyCancellable] = []

    init() {
        let center = NotificationCenter.default
        watchers = [
            center.publisher(for: NSApplication.didBecomeActiveNotification).sink { [weak self] _ in
                self?.apply { $0.setAppActive(true) }
            },
            center.publisher(for: NSApplication.didResignActiveNotification).sink { [weak self] _ in
                self?.apply { $0.setAppActive(false) }
            },
            center.publisher(for: NSApplication.willTerminateNotification).sink { [weak self] _ in
                self?.apply { $0.removeAll() }
            },
        ]
    }

    func isSecured(_ pane: UUID) -> Bool {
        gate.secured.contains(pane)
    }

    /// `isAsking` : le terminal attend un mot de passe et a le clavier. Faux pour un terminal fermé.
    func set(_ pane: UUID, isAsking: Bool) {
        apply { $0.set(pane, isAsking: isAsking) }
    }

    private func apply(_ change: (inout SecureInputGate<UUID>) -> SecureInputGate<UUID>.Switch?) {
        var next = gate
        let flip = change(&next)
        // Même identique, une écriture redessine les terminaux qui lisent `isSecured`.
        if next != gate { gate = next }
        switch flip {
        case .enable: EnableSecureEventInput()
        case .disable: DisableSecureEventInput()
        case nil: break
        }
    }
}
