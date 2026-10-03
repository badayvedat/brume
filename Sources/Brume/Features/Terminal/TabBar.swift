import BrumeCore
import SwiftUI

/// La barre d'onglets du haut, aux mesures de Monocode : onglets arrondis, + et boutons de split.
/// Elle tient lieu de barre de titre.
struct TabBar: View {
    let workspace: TerminalWorkspace
    let width: CGFloat
    let height: CGFloat
    /// La place des boutons rouge, jaune, vert.
    let leadingInset: CGFloat
    let showsNumbers: Bool

    @State private var isDragging = false
    /// Le début de la rangée d'onglets dans l'espace de `TerminalScreen`, défilement compris.
    @State private var stripOriginX: CGFloat = 0
    /// Après une fermeture à la croix, la largeur des onglets reste la même tant que la souris
    /// est sur la barre, comme Chrome : le suivant vient sous elle, sa croix au même endroit.
    @State private var frozenWidth: CGFloat?

    private let spacing: CGFloat = 2
    private let tabWidth: ClosedRange<CGFloat> = 112 ... 224

    private var tabs: [UUID] {
        workspace.layout.tabs
    }

    var body: some View {
        let numbers = showsNumbers ? workspace.layout.shortcutNumbers : [:]
        HStack(spacing: 0) {
            GeometryReader { geometry in
                let width = frozenWidth ?? cellWidth(available: geometry.size.width)
                // Trop d'onglets pour la barre : la rangée défile, et le + reste fixé à droite.
                let overflows = CGFloat(tabs.count) * (width + spacing) + BarButton.size > geometry.size.width
                HStack(spacing: spacing) {
                    ScrollViewReader { scroller in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: spacing) {
                                ForEach(tabs, id: \.self) { tab in
                                    TabCell(tab: tab, workspace: workspace, isDragging: isDragging, number: numbers[tab]) {
                                        frozenWidth = width
                                        workspace.close(tab)
                                    }
                                    .frame(width: width)
                                    .opacity(workspace.drop?.dragged == .tab(tab) ? 0.5 : 1)
                                    // Pendant le renommage, glisser dans le champ sélectionne du texte.
                                    .gesture(drag(tab, step: width + spacing), including: workspace.renaming == .tab(tab) ? .subviews : .all)
                                    .transition(.collapse(.horizontal))
                                }
                                if !overflows {
                                    newTabButton
                                }
                            }
                            // Un onglet s'ouvre en accordéon, ses voisins et le + glissent avec lui.
                            .animation(Ink.slide, value: tabs)
                            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(TerminalScreen.space)).minX } action: {
                                stripOriginX = $0
                            }
                            .frame(maxHeight: .infinity)
                            .frame(minWidth: geometry.size.width, alignment: .leading)
                            .background { WindowDragArea() }
                        }
                        // ⌘T, ⌘9, ⇧⌘] : l'onglet affiché reste en vue quand la barre déborde.
                        .onChange(of: workspace.layout.selectedTab) { _, tab in
                            withAnimation(Ink.slide) { scroller.scrollTo(tab) }
                        }
                    }
                    if overflows {
                        newTabButton
                    }
                }
            }
            BarButtons(workspace: workspace)
                .padding(.leading, 12)
        }
        .padding(.leading, leadingInset)
        .padding(.trailing, 8)
        .frame(width: width, height: height)
        .background { WindowDragArea() }
        .overlay(alignment: .bottom) { Ink.rule.frame(height: 1).allowsHitTesting(false) }
        .onHover { hovering in
            if !hovering { withAnimation(Ink.slide) { frozenWidth = nil } }
        }
    }

    private var newTabButton: some View {
        BarButton(icon: "plus", label: L10n.text(.newTab), shortcut: "⌘T") {
            workspace.newTab(atEnd: true)
        }
    }

    /// Dans la barre, comme Muxy : l'onglet tenu prend la place de celui que survole la souris
    /// (toutes les cases ont la même largeur). Sur les terminaux, il rejoint l'onglet affiché.
    private func drag(_ tab: UUID, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(TerminalScreen.space))
            .onChanged { value in
                isDragging = true
                guard value.location.y < height else {
                    return workspace.hoverDrop(dragging: .tab(tab), at: value.location)
                }
                workspace.hoverDrop(dragging: .tab(tab), at: nil)
                let slot = Int((value.location.x - stripOriginX) / step)
                let target = min(max(slot, 0), tabs.count - 1)
                if tabs.firstIndex(of: tab) != target {
                    workspace.move(tab, to: target)
                }
            }
            .onEnded { _ in
                isDragging = false
                workspace.performDrop()
            }
    }

    /// Parts égales, sans dépasser `tabWidth` : au-delà, la barre défile.
    private func cellWidth(available: CGFloat) -> CGFloat {
        let count = CGFloat(max(tabs.count, 1))
        let free = available - BarButton.size - spacing * count
        return min(max(free / count, tabWidth.lowerBound), tabWidth.upperBound)
    }
}

/// Les boutons à droite de la barre : diviser le split actif, nouvelle fenêtre, et le menu
/// « ... » de son terminal.
struct BarButtons: View {
    let workspace: TerminalWorkspace

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 2) {
            // Seulement le temps de l'agrandissement : on voit où sont passés les autres splits.
            if workspace.zoomedPane != nil {
                BarButton(icon: "arrow.down.right.and.arrow.up.left", label: L10n.text(.zoomSplit), shortcut: "⇧⌘↩", isOn: true) {
                    workspace.toggleZoom()
                }
            }
            BarButton(icon: "square.split.2x1", label: L10n.text(.splitRight), shortcut: "⌘D") {
                workspace.split(.horizontal)
            }
            BarButton(icon: "square.split.1x2", label: L10n.text(.splitDown), shortcut: "⇧⌘D") {
                workspace.split(.vertical)
            }
            BarButton(icon: "macwindow.badge.plus", label: L10n.text(.newWindow), shortcut: "⌘N") {
                openWindow(id: BrumeApp.terminalWindowID)
            }
            MoreMenu(state: workspace.focused, workspace: workspace)
        }
    }
}

struct BarButton: View {
    static let size: CGFloat = 26

    let icon: String
    let label: String
    let shortcut: String
    /// Un mode en cours, que le bouton arrête : à la couleur d'accent.
    var isOn = false
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.accent) private var accent

    var body: some View {
        Button(action: action) {
            SystemSymbol.image(icon, size: 13, weight: .medium)
                .foregroundStyle(isOn ? accent.color : isHovered ? Ink.text : Ink.muted)
                .frame(width: Self.size, height: Self.size)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .tooltip(label, shortcut: shortcut)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }
}
