import BrumeCore
import SwiftUI

/// La barre d'onglets d'une zone : onglets arrondis, + et boutons de split, aux mesures de Monocode.
/// Celles du haut de la fenêtre tiennent lieu de barre de titre.
struct TabBar: View {
    let workspace: TerminalWorkspace
    let area: UUID
    /// La zone dans l'espace de `TerminalScreen` : la barre en occupe le haut.
    let frame: CGRect
    let height: CGFloat
    /// La place des boutons rouge, jaune, vert pour la barre du coin haut gauche.
    let leadingInset: CGFloat
    let showsNewWindow: Bool
    /// Vide quand Cmd n'est pas tenu.
    let numbers: [UUID: Int]

    @State private var isDragging = false
    /// Le début de la rangée d'onglets dans l'espace de `TerminalScreen`, défilement compris.
    @State private var stripOriginX: CGFloat = 0
    @Environment(\.openWindow) private var openWindow

    private let spacing: CGFloat = 2
    private let tabWidth: ClosedRange<CGFloat> = 112 ... 224

    private var tabs: [UUID] {
        workspace.layout.areas[area]?.tabs ?? []
    }

    private var isAtTop: Bool {
        frame.minY == 0
    }

    var body: some View {
        HStack(spacing: 0) {
            GeometryReader { geometry in
                let width = cellWidth(available: geometry.size.width)
                // Trop d'onglets pour la zone : la rangée défile, et le + reste fixé à droite.
                let overflows = CGFloat(tabs.count) * (width + spacing) + BarButton.size > geometry.size.width
                HStack(spacing: spacing) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(tabs, id: \.self) { id in
                                if let state = workspace.states[id] {
                                    TabCell(
                                        state: state,
                                        id: id,
                                        workspace: workspace,
                                        isDragging: isDragging,
                                        number: numbers[id]
                                    )
                                    .frame(width: width)
                                    .opacity(workspace.drop?.tab == id ? 0.5 : 1)
                                    // Pendant le renommage, glisser dans le champ sélectionne du texte.
                                    .gesture(drag(id, step: width + spacing), including: workspace.renamingID == id ? .subviews : .all)
                                }
                            }
                            if !overflows {
                                newTabButton
                            }
                        }
                        .animation(Ink.motion(.easeInOut(duration: 0.15)), value: tabs)
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(TerminalScreen.space)).minX } action: {
                            stripOriginX = $0
                        }
                        .frame(maxHeight: .infinity)
                        .frame(minWidth: geometry.size.width, alignment: .leading)
                        .background { if isAtTop { WindowDragArea() } }
                    }
                    if overflows {
                        newTabButton
                    }
                }
            }
            HStack(spacing: 2) {
                BarButton(icon: "square.split.2x1", label: L10n.text(.splitRight), shortcut: "⌘D") {
                    workspace.split(.horizontal, from: area)
                }
                BarButton(icon: "square.split.1x2", label: L10n.text(.splitDown), shortcut: "⇧⌘D") {
                    workspace.split(.vertical, from: area)
                }
                if showsNewWindow {
                    BarButton(icon: "macwindow.badge.plus", label: L10n.text(.newWindow), shortcut: "⌘N") {
                        openWindow(id: BrumeApp.terminalWindowID)
                    }
                }
                if let shown = workspace.layout.areas[area]?.selected, let state = workspace.states[shown] {
                    MoreMenu(state: state, workspace: workspace)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.leading, leadingInset)
        .padding(.trailing, 8)
        .frame(width: frame.width, height: height)
        .background { if isAtTop { WindowDragArea() } }
        .overlay(alignment: .bottom) { Ink.rule.frame(height: 1).allowsHitTesting(false) }
    }

    private var newTabButton: some View {
        BarButton(icon: "plus", label: L10n.text(.newTab), shortcut: "⌘T") {
            workspace.newTab(in: area)
        }
    }

    /// Dans sa barre, comme Muxy : l'onglet tenu prend la place de celui que survole la souris
    /// (toutes les cases ont la même largeur). Ailleurs, il rejoint une autre zone ou en ouvre une.
    private func drag(_ id: UUID, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(TerminalScreen.space))
            .onChanged { value in
                isDragging = true
                let bar = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: height)
                guard bar.contains(value.location) else {
                    return workspace.hoverDrop(dragging: id, at: value.location)
                }
                workspace.hoverDrop(dragging: id, at: nil)
                let slot = Int((value.location.x - stripOriginX) / step)
                let target = min(max(slot, 0), tabs.count - 1)
                if tabs.firstIndex(of: id) != target {
                    workspace.move(id, to: target)
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

struct BarButton: View {
    static let size: CGFloat = 26

    let icon: String
    let label: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image(icon, size: 13, weight: .medium)
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
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
