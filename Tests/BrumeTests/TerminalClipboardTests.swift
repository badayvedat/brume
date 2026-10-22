import AppKit
import Testing
@testable import Brume

@MainActor
struct TerminalClipboardTests {
    private func withPasteboard(_ body: (NSPasteboard) -> Void) {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        body(pasteboard)
    }

    @Test func screenshotPasteUsesCLIClipboardHandler() {
        withPasteboard { pasteboard in
            let image = NSImage(size: NSSize(width: 1, height: 1))
            image.lockFocus()
            NSColor.red.setFill()
            NSRect(x: 0, y: 0, width: 1, height: 1).fill()
            image.unlockFocus()
            #expect(pasteboard.writeObjects([image]))
            #expect(TerminalClipboard.containsImage(in: pasteboard))
        }
    }

    @Test func imageWithTextStillUsesCLIClipboardHandler() {
        withPasteboard { pasteboard in
            pasteboard.setData(Data([0]), forType: .png)
            pasteboard.setString("Image description", forType: .string)
            #expect(TerminalClipboard.containsImage(in: pasteboard))
        }
    }

    @Test func copiedFileWithImagePreviewKeepsPathPaste() {
        withPasteboard { pasteboard in
            #expect(pasteboard.writeObjects([NSURL(fileURLWithPath: "/Users/example/Pictures/image.png")]))
            pasteboard.setData(Data([0]), forType: .tiff)
            #expect(!TerminalClipboard.containsImage(in: pasteboard))
        }
    }

    @Test func textAndEmptyClipboardKeepOrdinaryPaste() {
        withPasteboard { pasteboard in
            #expect(!TerminalClipboard.containsImage(in: pasteboard))
            pasteboard.setString("hello", forType: .string)
            #expect(!TerminalClipboard.containsImage(in: pasteboard))
        }
    }
}
