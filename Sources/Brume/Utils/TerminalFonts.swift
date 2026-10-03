import AppKit
import BrumeCore

/// Les polices proposées, en plus de celle par défaut : celles de macOS et celles embarquées.
enum TerminalFonts {
    static let featured: [String] = {
        let installed = Set(NSFontManager.shared.availableFontFamilies)
        return TerminalFont.system.filter(installed.contains) + TerminalFont.bundled.filter(installed.contains)
    }()
}
