import AppKit
import SwiftUI

extension View {
    /// Le clic droit (ou Ctrl+clic), avec la place de la souris à l'écran : pour ouvrir un
    /// `PopupMenu` là où on a cliqué.
    /// Éteint, le clic droit revient à la vue dessous (Copier, Coller d'un champ).
    func onRightClick(isEnabled: Bool = true, _ action: @escaping (NSPoint) -> Void) -> some View {
        overlay {
            if isEnabled { RightClickCatcher(action: action) }
        }
    }
}

private struct RightClickCatcher: NSViewRepresentable {
    let action: (NSPoint) -> Void

    func makeNSView(context: Context) -> CatcherView {
        CatcherView()
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.action = action
    }

    /// Transparente aux autres clics : la vue SwiftUI dessous garde ses gestes.
    final class CatcherView: NSView {
        var action: ((NSPoint) -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            let isRightClick = event.type == .rightMouseDown
                || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            return isRightClick ? super.hitTest(point) : nil
        }

        override func rightMouseDown(with event: NSEvent) {
            action?(NSEvent.mouseLocation)
        }

        override func mouseDown(with event: NSEvent) {
            action?(NSEvent.mouseLocation)
        }
    }
}
