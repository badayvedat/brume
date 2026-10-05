import AppKit
import SwiftUI

extension View {
    /// Infobulle maison sous la vue, avec le raccourci à droite et au besoin une seconde ligne.
    /// Dans sa propre petite fenêtre : une vue SwiftUI serait coupée par la barre qui défile et
    /// passerait sous le terminal.
    func tooltip(_ text: String, detail: String? = nil, shortcut: String? = nil, isEnabled: Bool = true) -> some View {
        modifier(TooltipModifier(text: text, detail: detail, shortcut: shortcut, isEnabled: isEnabled))
    }
}

/// Le survol vient de SwiftUI et pas d'une zone de suivi AppKit : un bouton qui se redessine au
/// survol faisait perdre l'entrée de la souris, et une vue cachée sous les réglages (sans
/// `allowsHitTesting`) n'en reçoit pas.
private struct TooltipModifier: ViewModifier {
    let text: String
    let detail: String?
    let shortcut: String?
    let isEnabled: Bool

    @State private var tip = Tooltip()

    func body(content: Content) -> some View {
        content
            .background(TooltipAnchor(tip: tip))
            .onHover { hovering in
                if hovering && isEnabled { tip.schedule(text: text, detail: detail, shortcut: shortcut) } else { tip.hide() }
            }
            .onChange(of: isEnabled) { if !$1 { tip.hide() } }
            .onDisappear { tip.hide() }
    }
}

/// La vue AppKit sous laquelle l'infobulle se place.
private struct TooltipAnchor: NSViewRepresentable {
    let tip: Tooltip

    func makeNSView(context: Context) -> AnchorView {
        let view = AnchorView()
        tip.anchor = view
        return view
    }

    func updateNSView(_ view: AnchorView, context: Context) {}

    final class AnchorView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}

@MainActor
private final class Tooltip {
    weak var anchor: NSView?
    private var panel: NSPanel?
    private var pending: DispatchWorkItem?
    private var clickMonitor: Any?

    func schedule(text: String, detail: String?, shortcut: String?) {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.show(text: text, detail: detail, shortcut: shortcut) }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
        // Un clic laisserait le délai courir, et l'infobulle s'ouvrirait sur le menu du bouton.
        clickMonitor = clickMonitor ?? NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            self?.hide()
            return event
        }
    }

    func hide() {
        pending?.cancel()
        pending = nil
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        clickMonitor = nil
        if let panel {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }
        panel = nil
    }

    private func show(text: String, detail: String?, shortcut: String?) {
        guard let anchor, let window = anchor.window, panel == nil else { return }
        let host = NSHostingView(rootView: TooltipLabel(text: text, detail: detail, shortcut: shortcut))
        host.frame.size = host.fittingSize
        let panel = NSPanel(contentRect: host.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.contentView = host
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        let frame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        var origin = CGPoint(x: frame.midX - host.frame.width / 2, y: frame.minY - host.frame.height - 6)
        if let screen = window.screen?.visibleFrame {
            origin.x = min(max(origin.x, screen.minX + 4), screen.maxX - host.frame.width - 4)
        }
        panel.setFrameOrigin(origin)
        window.addChildWindow(panel, ordered: .above)
        self.panel = panel
    }
}

private struct TooltipLabel: View {
    let text: String
    let detail: String?
    let shortcut: String?

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                if let detail {
                    Text(detail).foregroundStyle(.secondary)
                }
            }
            if let shortcut {
                Text(shortcut).foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 11))
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: .rect(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.12)))
        .fixedSize()
    }
}
