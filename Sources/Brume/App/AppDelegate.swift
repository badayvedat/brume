import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var terminationSignal: DispatchSourceSignal?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Toujours sombre : un terminal clair sous du verre se lit mal. Posé avant les fenêtres,
        // le moteur part directement en thème sombre.
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    /// `kill` et `scripts/build-app.sh` envoient SIGTERM, qui saute la fin normale de l'app : la
    /// session et les réglages s'enregistrent quand même, sans demander pour les commandes en
    /// cours. Sinon Brume rouvrirait la session du dernier ⌘Q.
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
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Comme Ghostty : ne pas bloquer un arrêt, un redémarrage ou une déconnexion du Mac.
        if let why = NSAppleEventManager.shared().currentAppleEvent?.attributeDescriptor(forKeyword: kAEQuitReason),
           [kAEShutDown, kAERestart, kAEReallyLogOut].contains(why.typeCodeValue) {
            return .terminateNow
        }
        guard TerminalWorkspace.needsConfirmQuit else { return .terminateNow }
        CloseConfirmation.quit.ask(in: NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible)) {
            sender.reply(toApplicationShouldTerminate: $0)
        }
        return .terminateLater
    }
}
