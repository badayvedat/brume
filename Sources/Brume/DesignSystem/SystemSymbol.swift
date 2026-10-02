import AppKit
import SwiftUI

/// Symboles système chargés au lancement, avant le moteur : demandés plus tard,
/// certains sortent vides (taille nulle), différents à chaque lancement (macOS 27).
enum SystemSymbol {
    private static let names = ["chevron.up", "chevron.down", "xmark"]

    private static let images: [String: NSImage] = Dictionary(uniqueKeysWithValues: names.compactMap { name in
        NSImage(systemSymbolName: name, accessibilityDescription: nil).map { (name, $0) }
    })

    static func preload() {
        _ = images
    }

    static func image(_ name: String) -> Image {
        guard let image = images[name] else {
            assertionFailure("Symbole \(name) absent de SystemSymbol.names")
            return Image(systemName: name)
        }
        return Image(nsImage: image).renderingMode(.template)
    }
}
