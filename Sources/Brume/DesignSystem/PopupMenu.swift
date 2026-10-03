import AppKit
import SwiftUI

/// Une ligne cliquable de `PopupMenu`.
struct MenuAction {
    var title: String
    var shortcut: String?
    var icon: NSImage?
    /// Une pastille de couleur à la place de l'icône.
    var swatch: Color?
    var isChecked = false
    var isEnabled = true
    /// Un sous-menu, ouvert à droite au survol : la ligne n'a alors pas d'action à elle.
    var submenu: [MenuEntry]?
    var run: () -> Void = {}
}

enum MenuEntry {
    case action(MenuAction)
    case separator

    static func item(
        _ title: String, shortcut: String? = nil, icon: NSImage? = nil, swatch: Color? = nil, checked: Bool = false,
        enabled: Bool = true, run: @escaping () -> Void
    ) -> MenuEntry {
        .action(MenuAction(
            title: title, shortcut: shortcut, icon: icon, swatch: swatch, isChecked: checked,
            isEnabled: enabled, run: run
        ))
    }

    static func submenu(_ title: String, _ entries: [MenuEntry]) -> MenuEntry {
        .action(MenuAction(title: title, submenu: entries))
    }
}

/// Menu maison aux mesures de Monocode, à la place de `NSMenu` : verre presque transparent,
/// surlignage neutre plutôt que l'accent du Mac, raccourcis écrits en entier (les glyphes ⌘
/// de macOS sortent vides une fois le moteur chargé). Un sous-menu s'ouvre dans son propre
/// panneau, empilé sur le premier : le clavier agit sur celui du dessus.
@MainActor
enum PopupMenu {
    static let width: CGFloat = 228
    fileprivate static var stack: [MenuPanel] = []
    private static var monitors: [Any] = []
    private static var resignObserver: NSObjectProtocol?
    /// Le bouton du menu ouvert, et celui du dernier fermé : un clic sur le bouton ferme le menu
    /// en appuyant, puis le rouvrirait en relâchant.
    private static weak var openAnchor: NSView?
    private static weak var closedAnchor: NSView?
    private static var closedAt = Date.distantPast

    /// `point` en coordonnées de l'écran : le coin haut gauche du menu, ou haut droit.
    static func show(_ entries: [MenuEntry], at point: NSPoint, alignsRight: Bool = false, width: CGFloat = width) {
        close()
        open(entries, at: point, alignsRight: alignsRight, width: width)
        installMonitors()
    }

    /// Sous un bouton, calé sur son bord droit, à 6 points.
    static func show(_ entries: [MenuEntry], below view: NSView, width: CGFloat = width) {
        guard let window = view.window, !(closedAnchor === view && Date().timeIntervalSince(closedAt) < 0.4) else { return }
        let frame = window.convertToScreen(view.convert(view.bounds, to: nil))
        show(entries, at: NSPoint(x: frame.maxX, y: frame.minY - 6), alignsRight: true, width: width)
        openAnchor = view
    }

    static func close() {
        if !stack.isEmpty {
            closedAnchor = openAnchor
            closedAt = Date()
        }
        openAnchor = nil
        stack.reversed().forEach { $0.orderOut(nil) }
        stack = []
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        resignObserver = nil
    }

    @discardableResult
    fileprivate static func open(_ entries: [MenuEntry], at point: NSPoint, alignsRight: Bool, width: CGFloat) -> MenuPanel {
        let panel = MenuPanel(entries: entries, width: width)
        let size = panel.contentView?.fittingSize ?? .zero
        let screen = NSScreen.screens.first { $0.frame.contains(point) }?.visibleFrame ?? .zero
        var origin = NSPoint(x: alignsRight ? point.x - size.width : point.x, y: point.y - size.height)
        origin.x = min(max(origin.x, screen.minX + 8), screen.maxX - size.width - 8)
        if origin.y < screen.minY + 8 { origin.y = point.y }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFront(nil)
        panel.makeKey()
        stack.append(panel)
        return panel
    }

    /// Ferme les sous-menus ouverts au-dessus de `panel`.
    fileprivate static func closeAbove(_ panel: MenuPanel) {
        while let top = stack.last, top !== panel {
            top.orderOut(nil)
            stack.removeLast()
        }
        panel.makeKey()
    }

    private static func installMonitors() {
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { event in
            if !(event.window is MenuPanel) { close() }
            return event
        } as Any)
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            MainActor.assumeIsolated { close() }
        } as Any)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            stack.last?.handle(event) == true ? nil : event
        } as Any)
        resignObserver = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { close() }
        }
    }
}

/// La vue AppKit sous un bouton SwiftUI, d'où son menu s'ouvre.
final class MenuAnchor {
    weak var view: NSView?
}

extension View {
    func menuAnchor(_ anchor: MenuAnchor) -> some View {
        background(MenuAnchorView(anchor: anchor))
    }
}

private struct MenuAnchorView: NSViewRepresentable {
    let anchor: MenuAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

@MainActor @Observable
final class MenuModel {
    var highlighted: Int?
    /// La place de chaque ligne dans le panneau, depuis son coin haut gauche : un sous-menu
    /// s'ouvre à sa hauteur.
    @ObservationIgnored var rowFrames: [Int: CGRect] = [:]
}

private final class MenuPanel: NSPanel {
    private let model = MenuModel()
    private let entries: [MenuEntry]
    private let width: CGFloat

    init(entries: [MenuEntry], width: CGFloat) {
        self.entries = entries
        self.width = width
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        // Comme Monocode : une ligne est déjà active, Entrée la lance. Celle cochée d'abord : dans
        // une liste de choix, Entrée garde la valeur.
        model.highlighted = actionable.first { action(at: $0)?.isChecked == true } ?? actionable.first
        let view = NSHostingView(rootView: PopupMenuView(entries: entries, model: model, width: width) { [weak self] index, clicked in
            self?.highlight(index, run: clicked)
        })
        view.sizingOptions = [.intrinsicContentSize]
        contentView = view
    }

    override var canBecomeKey: Bool {
        true
    }

    private var actionable: [Int] {
        entries.indices.filter { action(at: $0)?.isEnabled == true }
    }

    private func action(at index: Int) -> MenuAction? {
        if case let .action(action) = entries[index] { return action }
        return nil
    }

    func handle(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 53: PopupMenu.close()
        case 123:
            if PopupMenu.stack.count > 1, let parent = PopupMenu.stack.dropLast().last { PopupMenu.closeAbove(parent) }
        case 124:
            if let index = model.highlighted, action(at: index)?.submenu != nil { highlight(index, run: true) }
        case 125, 126:
            let items = actionable
            guard !items.isEmpty else { return true }
            let position = model.highlighted.flatMap(items.firstIndex(of:))
            let step = event.keyCode == 125 ? 1 : -1
            let next = position.map { ($0 + step + items.count) % items.count } ?? (step == 1 ? 0 : items.count - 1)
            highlight(items[next], run: false, opensSubmenu: false)
        case 36, 76:
            if let index = model.highlighted { highlight(index, run: true) }
        default: return false
        }
        return true
    }

    /// Survoler une ligne la rend active et ouvre son sous-menu ; cliquer la lance. Au clavier, les
    /// flèches ne font que passer : le sous-menu s'ouvre avec → ou Entrée, sinon il prendrait le
    /// clavier à chaque passage.
    private func highlight(_ index: Int, run: Bool, opensSubmenu: Bool = true) {
        guard let action = action(at: index), action.isEnabled else { return }
        let changed = model.highlighted != index
        model.highlighted = index
        if let submenu = action.submenu {
            guard opensSubmenu || run else {
                if changed { PopupMenu.closeAbove(self) }
                return
            }
            guard changed || run || PopupMenu.stack.last === self, let row = model.rowFrames[index] else { return }
            PopupMenu.closeAbove(self)
            PopupMenu.open(submenu, at: NSPoint(x: frame.maxX + 4, y: frame.maxY - row.minY + 4), alignsRight: false, width: 200)
        } else {
            if changed { PopupMenu.closeAbove(self) }
            if run {
                PopupMenu.close()
                action.run()
            }
        }
    }
}
