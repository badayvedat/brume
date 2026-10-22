import AppKit
import GhosttyTerminal
import UniformTypeIdentifiers

@MainActor
enum TerminalClipboard {
    static func containsImage(in pasteboard: NSPasteboard = .general) -> Bool {
        guard !pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else {
            return false
        }
        return pasteboard.types?.contains { UTType($0.rawValue)?.conforms(to: .image) == true } == true
    }

    static func paste(to surface: TerminalSurface?) {
        if containsImage() {
            // Local CLI editors read the native clipboard on Ctrl+V. Send a key,
            // not bracketed-paste text, and leave the image on the clipboard.
            surface?.sendKey(.v, modifiers: .ctrl)
        } else {
            _ = surface?.performBindingAction("paste_from_clipboard")
        }
    }
}
