import BrumeCore
import SwiftUI

/// Barre d'onglets maison, à la place de la barre de titre, comme Muxy : onglets
/// arrondis à côté des boutons de la fenêtre, splits et nouvelle fenêtre à droite.
struct TabBar: View {
    let tabs: TerminalTabs

    @State private var titlebar = WindowTitlebar()
    @State private var isDragging = false
    @State private var commandKey = CommandKeyHold()
    @Environment(\.openWindow) private var openWindow

    private let spacing: CGFloat = 4
    private let tabWidth: ClosedRange<CGFloat> = 110 ... 220
    /// Le début de la rangée d'onglets dans l'espace de `TerminalScreen`, défilement compris.
    @State private var stripOriginX: CGFloat = 0

    private var height: CGFloat {
        titlebar.buttonsCenterY * 2
    }

    var body: some View {
        HStack(spacing: 0) {
            GeometryReader { geometry in
                let width = cellWidth(available: geometry.size.width)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(tabs.tabs) { workspace in
                            TabCell(
                                state: workspace.focused,
                                workspace: workspace,
                                tabs: tabs,
                                isDragging: isDragging,
                                showsNumber: commandKey.isHeld
                            )
                            .frame(width: width)
                            .opacity(tabs.splitDrop?.tab == workspace.id ? 0.5 : 1)
                            // Pendant le renommage, glisser dans le champ sélectionne du texte.
                            .gesture(
                                drag(workspace.id, step: width + spacing),
                                including: tabs.renamingID == workspace.id ? .subviews : .all
                            )
                        }
                        BarButton(icon: "plus", label: L10n.text(.newTab), shortcut: "⌘T", action: tabs.newTab)
                    }
                    .animation(.easeInOut(duration: 0.15), value: tabs.tabs.map(\.id))
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(TerminalScreen.space)).minX } action: {
                        stripOriginX = $0
                    }
                    .frame(maxHeight: .infinity)
                    .frame(minWidth: geometry.size.width, alignment: .leading)
                    .background(WindowDragArea())
                }
            }
            HStack(spacing: 2) {
                BarButton(icon: "square.split.2x1", label: L10n.text(.splitRight), shortcut: "⌘D") {
                    tabs.selected.split(.horizontal)
                }
                BarButton(icon: "square.split.1x2", label: L10n.text(.splitDown), shortcut: "⇧⌘D") {
                    tabs.selected.split(.vertical)
                }
                BarButton(icon: "macwindow.badge.plus", label: L10n.text(.newWindow), shortcut: "⌘N") {
                    openWindow(id: BrumeApp.terminalWindowID)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.leading, titlebar.isFullScreen ? 8 : titlebar.buttonsWidth + 14)
        .padding(.trailing, 8)
        .frame(height: height)
        .background(WindowDragArea())
        .background(WindowReader { titlebar.attach(to: $0) })
    }

    /// Dans la barre, comme Muxy : l'onglet tenu prend la place de celui que survole la souris
    /// (toutes les cases ont la même largeur). Sur un terminal, il y deviendra un split.
    private func drag(_ id: UUID, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(TerminalScreen.space))
            .onChanged { value in
                isDragging = true
                guard value.location.y <= height else {
                    return tabs.hoverSplit(dragging: id, at: value.location)
                }
                tabs.hoverSplit(dragging: id, at: nil)
                let slot = Int((value.location.x - stripOriginX) / step)
                let target = min(max(slot, 0), tabs.tabs.count - 1)
                if tabs.tabs.firstIndex(where: { $0.id == id }) != target {
                    tabs.move(id, to: target)
                }
            }
            .onEnded { _ in
                isDragging = false
                tabs.dropSplit()
            }
    }

    /// Parts égales, sans dépasser `tabWidth` : au-delà, la barre défile.
    private func cellWidth(available: CGFloat) -> CGFloat {
        let count = CGFloat(tabs.tabs.count)
        let free = available - BarButton.size - spacing * count
        return min(max(free / count, tabWidth.lowerBound), tabWidth.upperBound)
    }
}

private struct BarButton: View {
    static let size: CGFloat = 26

    let icon: String
    let label: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image(icon, size: 13, weight: .medium)
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: Self.size, height: Self.size)
                .background(isHovered ? Color.primary.opacity(0.1) : .clear, in: .rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .tooltip(label, shortcut: shortcut)
        .onHover { isHovered = $0 }
    }
}
