import GhosttyTerminal
import SwiftUI

struct TerminalScreen: View {
    @StateObject private var terminal = TerminalViewState()
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
