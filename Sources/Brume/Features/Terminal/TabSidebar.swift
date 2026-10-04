import BrumeCore
import SwiftUI

/// Les onglets verticaux : ceux de la fenêtre listés à gauche, sur le modèle de la barre latérale
/// des réglages. Un onglet divisé y est un groupe qui se déplie sur ses splits. Les boutons rouge,
/// jaune, vert en occupent le haut.
struct TabSidebar: View {
    let workspace: TerminalWorkspace
    let width: CGFloat
    /// La hauteur de la barre de titre, où se tiennent les boutons de la fenêtre.
    let topInset: CGFloat
    let showsNumbers: Bool
    let onResize: (CGFloat) -> Void
    let onResizeEnd: () -> Void

    @State private var isDragging = false
    /// La place de chaque onglet, groupe déplié compris, dans l'espace de `TerminalScreen`.
    @State private var frames: [UUID: CGRect] = [:]
    @State private var paneFrames: [UUID: CGRect] = [:]
    /// Le dernier onglet ou split survolé au glisser : un groupe plus haut que l'onglet tenu ne
    /// le renvoie pas aussitôt d'où il vient.
    @State private var lastTarget: UUID?
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let layout = workspace.layout
        let numbers = showsNumbers ? layout.shortcutNumbers : [:]
        GeometryReader { geometry in
            ScrollViewReader { scroller in
                ScrollView(.vertical) {
                    VStack(spacing: 2) {
                        ForEach(layout.tabs, id: \.self) { tab in
                            VStack(spacing: 2) {
                                TabSidebarRow(tab: tab, workspace: workspace, isDragging: isDragging, number: numbers[tab])
                                    .opacity(workspace.drop?.dragged == .tab(tab) ? 0.5 : 1)
                                    // Pendant le renommage, glisser dans le champ sélectionne du texte.
                                    .gesture(drag(tab), including: workspace.renaming == .tab(tab) ? .subviews : .all)
                                if layout.isSplit(tab) && !workspace.collapsed.contains(tab) {
                                    ForEach(layout.panes(of: tab), id: \.self) { pane in
                                        TabSidebarPane(pane: pane, tab: tab, workspace: workspace, isDragging: isDragging)
                                            .opacity(workspace.drop?.dragged == .pane(pane) ? 0.5 : 1)
                                            .gesture(drag(pane, in: tab), including: workspace.renaming == .pane(pane) ? .subviews : .all)
                                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(TerminalScreen.space)) } action: {
                                                paneFrames[pane] = $0
                                            }
                                            .transition(.accordion(.vertical))
                                    }
                                }
                            }
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(TerminalScreen.space)) } action: {
                                frames[tab] = $0
                            }
                            .transition(.accordion(.vertical))
                        }
                        NewTabRow(shortcut: settings.shortcutLabel(.newTab)) { workspace.newTab(atEnd: true) }
                    }
                    // Un onglet ou un split s'ouvre en accordéon, ses voisins et « Nouvel onglet »
                    // glissent avec lui.
                    .animation(Ink.slide, value: layout.panes)
                    .animation(Ink.slide, value: layout.tabs)
                    .animation(Ink.slide, value: workspace.collapsed)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    // Le vide sous la liste déplace la fenêtre ; double-cliqué, il ouvre un onglet,
                    // comme sous les onglets de Safari.
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .background { WindowDragArea { workspace.newTab(atEnd: true) } }
                }
                .scrollIndicators(.never)
                .onChange(of: layout.selectedTab) { _, tab in
                    withAnimation(Ink.slide) { scroller.scrollTo(tab) }
                }
            }
        }
        .padding(.top, topInset + 8)
        .frame(width: width)
        .background(Color.black.opacity(0.12))
        .background { WindowDragArea() }
        .overlay(alignment: .trailing) {
            TabSidebarEdge(width: width, onResize: onResize, onResizeEnd: onResizeEnd)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(.tabs))
    }

    /// Dans la liste, l'onglet tenu prend la place de celui que survole la souris. Sur les
    /// terminaux, il rejoint l'onglet affiché, comme depuis la barre du haut.
    private func drag(_ tab: UUID) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(TerminalScreen.space))
            .onChanged { value in
                isDragging = true
                guard value.location.x < width else {
                    return workspace.hoverDrop(dragging: .tab(tab), at: value.location)
                }
                workspace.hoverDrop(dragging: .tab(tab), at: nil)
                let tabs = workspace.layout.tabs
                let hovered = tabs.first { frames[$0].map { ($0.minY ... $0.maxY).contains(value.location.y) } ?? false }
                guard let target = hovered, target != tab else { return lastTarget = nil }
                guard target != lastTarget, let index = tabs.firstIndex(of: target) else { return }
                lastTarget = target
                workspace.move(tab, to: index)
            }
            .onEnded { _ in
                isDragging = false
                lastTarget = nil
                workspace.performDrop()
            }
    }

    /// Sur un autre split du groupe, il prend sa place. Sur les terminaux, il se pose à côté du
    /// split visé, avec le même repère qu'un onglet.
    private func drag(_ pane: UUID, in tab: UUID) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(TerminalScreen.space))
            .onChanged { value in
                isDragging = true
                guard value.location.x < width else {
                    return workspace.hoverDrop(dragging: .pane(pane), at: value.location)
                }
                workspace.hoverDrop(dragging: .pane(pane), at: nil)
                let hovered = workspace.layout.panes(of: tab).first {
                    paneFrames[$0].map { ($0.minY ... $0.maxY).contains(value.location.y) } ?? false
                }
                guard let target = hovered, target != pane else { return lastTarget = nil }
                guard target != lastTarget else { return }
                lastTarget = target
                workspace.swap(pane, target)
            }
            .onEnded { _ in
                isDragging = false
                lastTarget = nil
                workspace.performDrop()
            }
    }
}

/// Au bout de la liste, comme le + au bout de la barre du haut.
private struct NewTabRow: View {
    let shortcut: String?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SystemSymbol.image("plus", size: 12)
                    .frame(width: 16, height: 16)
                Text(L10n.text(.newTab))
                    .font(.system(size: 13))
                Spacer(minLength: 0)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 11))
                        .foregroundStyle(Ink.meta)
                        .opacity(isHovered ? 1 : 0)
                }
            }
            .foregroundStyle(isHovered ? Ink.text : Ink.muted)
            .padding(.horizontal, 8)
            .frame(height: TabSidebarRow.height)
            .background(isHovered ? Ink.hover : .clear, in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }
}
