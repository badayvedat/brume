import AppKit
import SwiftUI

/// Symboles système chargés au lancement, avant le moteur : demandés plus tard,
/// certains sortent vides (taille nulle), différents à chaque lancement (macOS 27).
/// Une image AppKit ignore `.font` : chaque taille utilisée est chargée ici.
enum SystemSymbol {
    private struct Variant: Hashable {
        let name: String
        var size: CGFloat?
        var weight: NSFont.Weight = .regular
    }

    private static let variants = [
        Variant(name: "chevron.up"),
        Variant(name: "chevron.down"),
        Variant(name: "xmark"),
        Variant(name: "xmark", size: 9, weight: .bold),
        Variant(name: "plus", size: 13, weight: .medium),
        Variant(name: "apple.terminal", size: 12),
        Variant(name: "square.split.2x1", size: 13, weight: .medium),
        Variant(name: "square.split.1x2", size: 13, weight: .medium),
        Variant(name: "macwindow.badge.plus", size: 13, weight: .medium),
        Variant(name: "ellipsis", size: 13, weight: .medium),
        Variant(name: "checkmark", size: 11, weight: .semibold),
        Variant(name: "chevron.down", size: 10, weight: .semibold),
        Variant(name: "chevron.right", size: 10, weight: .semibold),
        Variant(name: "eye", size: 12),
        Variant(name: "eye.slash", size: 12),
        Variant(name: "gearshape", size: 14),
        Variant(name: "paintpalette", size: 14),
        Variant(name: "text.below.photo", size: 14),
        Variant(name: "apple.logo", size: 32),
        Variant(name: "chevron.left", size: 14),
        // Les glyphes des raccourcis dans les menus de macOS : chargés après le moteur, ils
        // sortent vides et les menus n'affichent que la touche, sans ⌘.
        Variant(name: "command"),
        Variant(name: "shift"),
        Variant(name: "option"),
        Variant(name: "control"),
    ]

    private static let images: [Variant: NSImage] = Dictionary(uniqueKeysWithValues: variants.compactMap { variant in
        var image = NSImage(systemSymbolName: variant.name, accessibilityDescription: nil)
        if let size = variant.size {
            image = image?.withSymbolConfiguration(.init(pointSize: size, weight: variant.weight))
        }
        return image.map { (variant, $0) }
    })

    static func preload() {
        _ = images
    }

    static func image(_ name: String, size: CGFloat? = nil, weight: NSFont.Weight = .regular) -> Image {
        guard let image = images[Variant(name: name, size: size, weight: weight)] else {
            assertionFailure("Symbole \(name) absent de SystemSymbol.variants")
            return Image(systemName: name)
        }
        return Image(nsImage: image).renderingMode(.template)
    }
}
