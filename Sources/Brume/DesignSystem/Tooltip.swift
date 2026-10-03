import AppKit
import SwiftUI

extension View {
    /// Infobulle maison sous la vue, avec le raccourci à droite. Dans sa propre petite fenêtre :
    /// une vue SwiftUI serait coupée par la barre qui défile et passerait sous le terminal.
    func tooltip(_ text: String, shortcut: String? = nil) -> some View {
        background(TooltipAnchor(text: text, shortcut: shortcut))
    }
}

private struct TooltipAnchor: NSViewRepresentable {
    let text: String
    let shortcut: String?

    func makeNSView(context: Context) -> AnchorView {
        AnchorView()
    }

    func updateNSView(_ view: AnchorView, context: Context) {
        view.text = text
        view.shortcut = shortcut
    }

    /// Le survol se suit par une zone de suivi : elle marche sous le bouton, qui garde les clics.
    final class AnchorView: NSView {
        var text = ""
        var shortcut: String?
        private var panel: NSPanel?
        private var pending: DispatchWorkItem?
        private var clickMonitor: Any?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }

        override func mouseEntered(with event: NSEvent) {
            let work = DispatchWorkItem { [weak self] in self?.show() }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
            // Un clic sur le bouton ne passe pas par cette vue : on le guette dès l'entrée, sinon un
            // clic rapide laisserait le délai courir et l'infobulle s'ouvrir sur le menu du bouton.
            clickMonitor = clickMonitor ?? NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
                self?.hide()
                return event
            }
        }

        override func mouseExited(with event: NSEvent) {
            hide()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window == nil { hide() }
        }

        private func show() {
            guard let window, panel == nil else { return }
            let host = NSHostingView(rootView: TooltipLabel(text: text, shortcut: shortcut))
            host.frame.size = host.fittingSize
            let panel = NSPanel(contentRect: host.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
            panel.contentView = host
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            let anchor = window.convertToScreen(convert(bounds, to: nil))
            var origin = CGPoint(x: anchor.midX - host.frame.width / 2, y: anchor.minY - host.frame.height - 6)
            if let screen = window.screen?.visibleFrame {
                origin.x = min(max(origin.x, screen.minX + 4), screen.maxX - host.frame.width - 4)
            }
            panel.setFrameOrigin(origin)
            window.addChildWindow(panel, ordered: .above)
            self.panel = panel
        }

        private func hide() {
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
    }
}

private struct TooltipLabel: View {
    let text: String
    let shortcut: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
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
