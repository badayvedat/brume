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

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropTarget(sender) == nil ? [] : .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let target = dropTarget(sender), let text = TerminalPasteboardContent.text(from: sender.draggingPasteboard) else {
            return false
        }
        NSApp.activate()
        target.window?.makeKeyAndOrderFront(nil)
        target.window?.makeFirstResponder(target)
        return target.paste(text: text)
    }

    /// Les terminaux des onglets cachés restent montés, transparents, et macOS peut leur proposer
    /// le dépôt : il va au terminal que le clic atteindrait, ni à un caché ni sous les réglages.
    private func dropTarget(_ sender: NSDraggingInfo) -> BrumeTerminalView? {
        guard let contentView = window?.contentView else { return nil }
        let point = contentView.superview?.convert(sender.draggingLocation, from: nil) ?? sender.draggingLocation
        var view = contentView.hitTest(point)
        while let current = view, !(current is BrumeTerminalView) { view = current.superview }
        return view as? BrumeTerminalView
    }

    private var showsMenu: Bool {
        onContextMenu != nil && !isMouseCaptured
    }
}
