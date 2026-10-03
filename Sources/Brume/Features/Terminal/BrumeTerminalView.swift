import AppKit
import GhosttyTerminal

/// La vue d'un terminal, avec le menu maison au clic droit à la place du seul « Copy » du paquet,
/// en anglais. Un programme qui capte la souris (vim, htop) garde son clic droit.
final class BrumeTerminalView: TerminalView {
    var onContextMenu: (() -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        guard showsMenu else { return super.rightMouseDown(with: event) }
        window?.makeFirstResponder(self)
        onContextMenu?()
    }

    override func rightMouseUp(with event: NSEvent) {
        guard !showsMenu else { return }
        super.rightMouseUp(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard showsMenu else { return super.menu(for: event) }
        onContextMenu?()
        return nil
    }

    private var showsMenu: Bool {
        onContextMenu != nil && !isMouseCaptured
    }
}
