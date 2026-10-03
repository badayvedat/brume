import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Toujours sombre : un terminal clair sous du verre se lit mal. Posé avant les fenêtres,
        // le moteur part directement en thème sombre.
        NSApp.appearance = NSAppearance(named: .darkAqua)
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
