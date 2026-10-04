import AppKit
import BrumeCore
import Sparkle

/// Les fenêtres standard de Sparkle, sauf ses trois alertes : il les ouvre en `runModal`, qui
/// plante sur macOS 27 après le chargement du moteur (comme `CloseConfirmation`). Elles passent
/// ici en feuille sur la fenêtre de Brume.
final class UpdaterUserDriver: SPUStandardUserDriver {
    override func showUpdateNotFoundWithError(_ error: any Error, acknowledgement: @escaping () -> Void) {
        let error = error as NSError
        let reason = (error.userInfo[SPUNoUpdateFoundReasonKey] as? NSNumber).flatMap { SPUNoUpdateFoundReason(rawValue: $0.int32Value) }
        let isLatest = reason == .onLatestVersion || reason == .onNewerThanLatestVersion
        let message = isLatest ? L10n.text(.upToDateMessage) : error.localizedRecoverySuggestion ?? error.localizedDescription
        show(title: L10n.text(.upToDate), message: message, style: .informational, then: acknowledgement)
    }

    override func showUpdaterError(_ error: any Error, acknowledgement: @escaping () -> Void) {
        let error = error as NSError
        let message = [error.localizedDescription, error.localizedRecoverySuggestion].compactMap(\.self).joined(separator: "\n\n")
        show(title: L10n.text(.updateError), message: message, style: .warning, then: acknowledgement)
    }

    override func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        // Relancée, Sparkle n'affiche pas d'alerte.
        guard !relaunched else {
            return super.showUpdateInstalledAndRelaunched(relaunched, acknowledgement: acknowledgement)
        }
        show(title: L10n.text(.updateInstalled), message: nil, style: .informational, then: acknowledgement)
    }

    private func show(title: String, message: String?, style: NSAlert.Style, then acknowledgement: @escaping () -> Void) {
        // Ferme la fenêtre « Recherche des mises à jour… » : Sparkle la ferme d'ordinaire dans
        // l'alerte remplacée ici, sa méthode n'est pas accessible.
        dismissUpdateInstallation()
        guard let window = NSApp.mainWindow ?? NSApp.orderedWindows.first(where: { $0.isVisible && $0.canBecomeMain }),
              window.attachedSheet == nil else {
            return acknowledgement()
        }
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = message ?? ""
        alert.addButton(withTitle: L10n.text(.ok))
        alert.beginSheetModal(for: window) { _ in acknowledgement() }
    }
}
