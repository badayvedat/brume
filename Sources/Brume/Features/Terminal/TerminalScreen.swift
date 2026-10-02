import GhosttyTerminal
import SwiftUI

struct TerminalScreen: View {
    // Gérées par le patch zsh de Patches/ : le script du paquet les ignore.
    @StateObject private var terminal = TerminalViewState(
        terminalConfiguration: TerminalConfiguration {
            $0.withCustom("shell-integration-features", "ssh-env,ssh-terminfo")
        }
    )
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
