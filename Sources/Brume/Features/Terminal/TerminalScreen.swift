import GhosttyTerminal
import SwiftUI

// Un seul moteur pour tous les onglets et fenêtres, comme Ghostty.
@MainActor private let sharedController = TerminalController(
    terminalConfiguration: TerminalConfiguration {
        // Gérées par le patch zsh de Patches/ : le script du paquet les ignore.
        $0.withCustom("shell-integration-features", "ssh-env,ssh-terminfo")
        // Le moteur avale ces raccourcis pour des actions que le paquet ne transmet pas :
        // on les rend au menu de l'app.
        $0.withCustom("keybind", "super+t=unbind")
        $0.withCustom("keybind", "super+n=unbind")
    }
)

struct TerminalScreen: View {
    @StateObject private var terminal = TerminalViewState(controller: sharedController)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TerminalSurfaceView(context: terminal)
            .navigationTitle(terminal.title)
            // La barre de titre prend la couleur du terminal, comme dans Ghostty.
            .containerBackground(Color(terminal.backgroundColor), for: .window)
            .onAppear {
                terminal.onClose = { _ in dismiss() }
                terminal.requestFocus()
            }
    }
}
