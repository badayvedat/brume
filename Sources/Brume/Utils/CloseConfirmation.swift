import AppKit
import BrumeCore

/// Alerte avant de tuer une commande en cours, reprise de Ghostty.
@MainActor
enum CloseConfirmation {
    case terminal, tab, tabs, window, quit

    /// En feuille, une seule à la fois comme Ghostty. Pas de `runModal` : sur macOS 27,
    /// l'alerte modale plante en dessinant un symbole système après le chargement du moteur.
    func ask(in window: NSWindow?, then confirm: @escaping () -> Void) {
        ask(in: window) { if $0 { confirm() } }
    }

    /// Sans fenêtre où demander, ou avec une feuille déjà ouverte (une demande en double), la
    /// réponse est non : rien ne se ferme sans qu'on l'ait vu.
    func ask(in window: NSWindow?, answer: @escaping (Bool) -> Void) {
        guard let window, window.attachedSheet == nil else { return answer(false) }
        makeAlert().beginSheetModal(for: window) { answer($0 == .alertFirstButtonReturn) }
    }

    private func makeAlert() -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        let (title, message): (TextKey, TextKey) = switch self {
        case .terminal: (.closeTerminalTitle, .closeTerminalMessage)
        case .tab: (.closeTabTitle, .closeTabMessage)
        case .tabs: (.closeTabsTitle, .closeTabsMessage)
        case .window: (.closeWindowTitle, .closeWindowMessage)
        case .quit: (.quitTitle, .quitMessage)
        }
        alert.messageText = L10n.text(title)
        alert.informativeText = L10n.text(message)
        alert.addButton(withTitle: L10n.text(self == .quit ? .quit : .close))
        alert.addButton(withTitle: L10n.text(.cancel))
        return alert
    }
}
