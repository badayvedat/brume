import BrumeCore
import SwiftUI

struct TerminalScreen: View {
    /// Toute la fenêtre : barres d'onglets, terminaux et glissés partagent cet espace.
    static let space = "terminal-screen"

    @Environment(SessionStore.self) private var session
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openWindow) private var openWindow
    /// Créé à l'apparition et pas à l'init : SwiftUI peut refaire l'init, et chaque appel
    /// consommerait une fenêtre de la session.
    @State private var workspace: TerminalWorkspace?

    var body: some View {
        ZStack {
            if let workspace {
                TerminalWindow(workspace: workspace, translucency: settings.translucency)
            }
        }
        .onAppear {
            guard workspace == nil else { return }
            workspace = session.makeWorkspace()
            for _ in 0 ..< session.takeWindowsToOpen() {
                openWindow(id: BrumeApp.terminalWindowID)
            }
        }
    }
}

private struct TerminalWindow: View {
    let workspace: TerminalWorkspace

    @State private var titlebar = WindowTitlebar()
    @State private var commandKey = CommandKeyHold()
    @State private var translucency: TranslucencyTransition
    @Environment(SettingsStore.self) private var settings
    /// Cmd+chiffre n'agit que sur la fenêtre active : les autres ne montrent pas de numéros.
    @Environment(\.appearsActive) private var isActive

    init(workspace: TerminalWorkspace, translucency: Translucency) {
        self.workspace = workspace
        _translucency = State(initialValue: TranslucencyTransition(translucency))
    }

    var body: some View {
        TerminalSplitView(workspace: workspace, titlebar: titlebar, showsNumbers: commandKey.isHeld && isActive)
            .coordinateSpace(.named(TerminalScreen.space))
            .ignoresSafeArea(.container, edges: .top)
            .modifier(TerminalWindowChrome(
                state: workspace.focused,
                customTitle: workspace.title(of: workspace.focusedID),
                translucency: translucency.shown
            ))
            .focusedSceneValue(\.terminalWorkspace, workspace)
            .background(WindowReader {
                workspace.attach(to: $0)
                titlebar.attach(to: $0)
                translucency.attach(to: $0)
            })
            .onAppear { workspace.focus(workspace.focusedID) }
            .onChange(of: settings.translucency) { translucency.animate(to: $1) }
    }
}
