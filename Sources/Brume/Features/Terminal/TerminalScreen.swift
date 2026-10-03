import SwiftUI

struct TerminalScreen: View {
    /// Commun à la barre d'onglets et aux terminaux : un onglet glissé passe de l'une aux autres.
    static let space = "terminal-screen"

    @State private var tabs = TerminalTabs()

    var body: some View {
        VStack(spacing: 0) {
            TabBar(tabs: tabs)
            TerminalSplitView(tabs: tabs)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: {
                    tabs.terminalArea = $0
                }
        }
        .coordinateSpace(.named(Self.space))
        .overlay(alignment: .topLeading) {
            if let drop = tabs.splitDrop {
                SplitDropHighlight(frame: drop.highlight)
            }
        }
        .animation(.easeOut(duration: 0.12), value: tabs.splitDrop)
        .ignoresSafeArea(.container, edges: .top)
        .modifier(TerminalWindowChrome(state: tabs.selected.focused, customTitle: tabs.selected.customTitle))
        .focusedSceneValue(\.terminalTabs, tabs)
        .focusedSceneValue(\.terminalWorkspace, tabs.selected)
        .background(WindowReader { tabs.attach(to: $0) })
        .onAppear { tabs.selected.focus(tabs.selected.focusedID) }
    }
}

/// Où ira l'onglet lâché : la moitié du terminal visé, en couleur d'accent.
private struct SplitDropHighlight: View {
    let frame: CGRect

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.accentColor.opacity(0.18))
            .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 2)
            .padding(4)
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
