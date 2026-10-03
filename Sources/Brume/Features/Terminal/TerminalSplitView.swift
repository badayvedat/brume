import BrumeCore
import GhosttyTerminal
import SwiftUI

/// Les zones de la fenêtre : la barre d'onglets en haut de chacune, son terminal affiché dessous.
struct TerminalSplitView: View {
    let workspace: TerminalWorkspace
    let titlebar: WindowTitlebar
    let showsNumbers: Bool

    var body: some View {
        GeometryReader { geometry in
            let bounds = CGRect(origin: .zero, size: geometry.size)
            let layout = workspace.layout
            let areas = layout.tree.frames(in: bounds)
            let barHeight = titlebar.buttonsCenterY * 2
            let areaOfTab = layout.areaOfTab
            let numbers = showsNumbers ? layout.shortcutNumbers : [:]
            // Les terminaux de toutes les zones au même niveau, rangés par identifiant : changer
            // d'onglet, diviser ou déplacer un onglet garde chaque vue. Une vue recréée tuerait
            // le shell qu'elle porte. Les onglets cachés restent montés, transparents.
            ZStack(alignment: .topLeading) {
                ForEach(layout.tabs, id: \.self) { id in
                    if let state = workspace.states[id], let area = areaOfTab[id], let frame = areas[area] {
                        let content = frame.divided(atDistance: barHeight, from: .minYEdge).remainder
                        let isShown = layout.areas[area]?.selected == id
                        TerminalPane(
                            state: state,
                            search: workspace.searches[id],
                            dimmed: workspace.isSplit && id != workspace.focusedID,
                            onFocus: { workspace.didFocus(id) },
                            onLeaveSearch: { workspace.focus(id) },
                            onCloseSearch: { workspace.endSearch(in: id) }
                        )
                        .frame(width: content.width, height: content.height)
                        .offset(x: content.minX, y: content.minY)
                        .opacity(isShown ? 1 : 0)
                        .allowsHitTesting(isShown)
                        .accessibilityHidden(!isShown)
                    }
                }
                ForEach(layout.tree.panes, id: \.self) { area in
                    if let frame = areas[area] {
                        let isTopLeft = frame.minX == 0 && frame.minY == 0
                        TabBar(
                            workspace: workspace,
                            area: area,
                            frame: frame,
                            height: barHeight,
                            leadingInset: isTopLeft && !titlebar.isFullScreen ? titlebar.buttonsWidth + 14 : 8,
                            showsNewWindow: frame.minY == 0 && frame.maxX == bounds.maxX,
                            numbers: numbers
                        )
                        .offset(x: frame.minX, y: frame.minY)
                    }
                }
                // Identifiées par leur place dans l'arbre : stable pendant un glissé.
                ForEach(layout.tree.dividers(in: bounds), id: \.path) { divider in
                    SplitHandle(divider: divider) { workspace.setRatio($0, at: divider.path) }
                }
                if let drop = workspace.drop {
                    DropHighlight(frame: drop.highlight)
                }
            }
            .animation(.easeOut(duration: 0.12), value: workspace.drop)
            .onChange(of: bounds, initial: true) { workspace.bounds = bounds }
            .onChange(of: barHeight, initial: true) { workspace.barHeight = barHeight }
        }
    }
}

/// Où ira l'onglet lâché, en couleur d'accent.
private struct DropHighlight: View {
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

/// Le trait entre deux zones. Il passe à la couleur d'accent au survol : on voit qu'il se glisse.
private struct SplitHandle: View {
    let divider: SplitDivider
    let onDrag: (CGFloat) -> Void

    @State private var isActive = false

    /// Plus large que le trait d'un point, pour l'attraper sans viser.
    private let grip: CGFloat = 6

    var body: some View {
        let line = divider.line
        let isVertical = divider.axis == .horizontal
        let thickness: CGFloat = isActive ? 2 : 1
        ZStack {
            Rectangle()
                .fill(isActive ? Color.accentColor : Color(nsColor: .separatorColor))
                .frame(width: isVertical ? thickness : nil, height: isVertical ? nil : thickness)
        }
        .frame(width: isVertical ? grip : line.width, height: isVertical ? line.height : grip)
        .contentShape(Rectangle())
        .pointerStyle(isVertical ? .columnResize : .rowResize)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isActive = hovering }
        }
        .offset(x: isVertical ? line.minX - grip / 2 : line.minX, y: isVertical ? line.minY : line.minY - grip / 2)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(TerminalScreen.space))
                .onChanged { onDrag(divider.ratio(at: $0.location)) }
        )
    }
}

private struct TerminalPane: View {
    @ObservedObject var state: TerminalViewState
    let search: TerminalSearch?
    let dimmed: Bool
    let onFocus: () -> Void
    let onLeaveSearch: () -> Void
    let onCloseSearch: () -> Void

    var body: some View {
        TerminalSurfaceView(context: state)
            // Comme Ghostty : le volet inactif est légèrement assombri.
            .overlay {
                if dimmed {
                    Color.black.opacity(0.3).allowsHitTesting(false)
                }
            }
            .overlay {
                ScrollbarOverlay(
                    position: state.scrollbar.map {
                        ScrollbarPosition(total: Int($0.total), offset: Int($0.offset), visible: Int($0.len))
                    },
                    isDark: state.backgroundColor.isDark,
                    onScroll: { state.attachedPlatformView?.scrollWheel(with: $0) },
                    onScrollToRow: { state.surface?.scrollToRow(UInt($0)) }
                )
            }
            .overlay(alignment: .topTrailing) {
                if let search {
                    TerminalSearchBar(
                        search: search,
                        count: SearchCount(total: state.searchTotal, selected: state.searchSelected),
                        onLeave: onLeaveSearch,
                        onClose: onCloseSearch
                    )
                }
            }
            .onChange(of: state.isFocused) { _, isFocused in
                if isFocused { onFocus() }
            }
    }
}

/// Titre et couleur de la fenêtre, pris sur le terminal qui a le focus, sauf nom choisi pour l'onglet.
struct TerminalWindowChrome: ViewModifier {
    @ObservedObject var state: TerminalViewState
    let customTitle: String?
    let translucency: Translucency

    func body(content: Content) -> some View {
        content
            .navigationTitle(customTitle ?? state.title)
            // La barre de titre prend la couleur du terminal, comme dans Ghostty. En verre, cette
            // couleur fait le voile de toute la fenêtre, terminaux compris.
            .containerBackground(Color(state.backgroundColor).opacity(translucency.opacity), for: .window)
    }
}

private extension TerminalColor {
    var isDark: Bool {
        0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue) < 128
    }
}
