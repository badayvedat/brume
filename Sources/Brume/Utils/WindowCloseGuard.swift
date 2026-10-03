import AppKit

/// SwiftUI ne donne pas `windowShouldClose` (bouton rouge, croix d'onglet, menu Fermer) :
/// on s'intercale devant son délégué, à qui on renvoie tout le reste.
final class WindowCloseGuard: NSObject, NSWindowDelegate {
    private nonisolated(unsafe) weak var original: NSWindowDelegate?
    private let shouldClose: @MainActor (NSWindow) -> Bool

    @MainActor
    init(on window: NSWindow, shouldClose: @escaping @MainActor (NSWindow) -> Bool) {
        original = window.delegate
        self.shouldClose = shouldClose
        super.init()
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        shouldClose(sender) && original?.windowShouldClose?(sender) ?? true
    }

    override nonisolated func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || original?.responds(to: selector) == true
    }

    override nonisolated func forwardingTarget(for selector: Selector!) -> Any? {
        original?.responds(to: selector) == true ? original : nil
    }
}
