import AppKit
import BrumeCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var terminationSignal: DispatchSourceSignal?
    private var isConfirmingQuit = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Toujours sombre : un terminal clair sous du verre se lit mal. Posé avant les fenêtres,
        // le moteur part directement en thème sombre.
        NSApp.appearance = NSAppearance(named: .darkAqua)
        // Brume a ses propres onglets : sans ça, macOS ajoute ses articles d'onglets (« Fusionner
        // toutes les fenêtres »...) aux menus Présentation et Fenêtre.
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    /// `kill` et `scripts/build-app.sh` envoient SIGTERM, qui saute la fin normale de l'app : la
    /// session et les réglages s'enregistrent quand même, sans demander pour les commandes en
    /// cours. Sinon les tout derniers changements seraient perdus.
    func applicationDidFinishLaunching(_ notification: Notification) {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler {
            MainActor.assumeIsolated {
                NotificationCenter.default.post(name: NSApplication.willTerminateNotification, object: NSApp)
            }
            exit(0)
        }
        source.resume()
        terminationSignal = source
        NSApp.servicesProvider = FolderService()
        NSUpdateDynamicServices()
    }

    /// Un dossier glissé sur l'icône du Dock, ou `open -a Brume <dossier>`. Lancé ainsi, Brume
    /// n'ouvre aucune fenêtre de lui-même : `openTabs` s'en charge.
    func application(_ application: NSApplication, open urls: [URL]) {
        TerminalWorkspace.openTabs(in: OpenedFolders.paths(for: urls))
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Comme Ghostty : ne pas bloquer un arrêt, un redémarrage ou une déconnexion du Mac.
        if let why = NSAppleEventManager.shared().currentAppleEvent?.attributeDescriptor(forKeyword: kAEQuitReason),
           [kAEShutDown, kAERestart, kAEReallyLogOut].contains(why.typeCodeValue) {
            return .terminateNow
        }
        guard TerminalWorkspace.needsConfirmQuit else { return .terminateNow }
        // Un second ⌘Q pendant la question : sa réponse annulerait celle qu'on attend.
        guard !isConfirmingQuit else { return .terminateCancel }
        guard let window = TerminalWorkspace.front()?.window else { return .terminateNow }
        isConfirmingQuit = true
        CloseConfirmation.quit.ask(in: window) { quits in
            // Jamais avant le `.terminateLater` rendu plus bas : la réponse serait perdue et Brume
            // ne quitterait plus. Une feuille déjà ouverte répond non tout de suite.
            DispatchQueue.main.async { [weak self] in
                self?.isConfirmingQuit = false
                sender.reply(toApplicationShouldTerminate: quits)
            }
        }
        return .terminateLater
    }
}
