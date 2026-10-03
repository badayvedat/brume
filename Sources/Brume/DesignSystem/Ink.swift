import AppKit
import BrumeCore
import SwiftUI

/// La teinte unique de Brume, reprise de Monocode : un blanc cassé posé à différentes opacités sur
/// le fond du thème. Pas de `.secondary` ni d'accent pour hiérarchiser, l'opacité suffit.
enum Ink {
    static func white(_ opacity: Double) -> Color {
        Color(hex: "EBEBEB").opacity(opacity)
    }

    static let text = white(1)
    static let muted = white(0.5)
    static let hint = white(0.45)
    static let meta = white(0.4)
    static let disabled = white(0.3)
    /// La seule couleur hors du blanc : une limite dépassée.
    static let warning = Color(hex: "f87171")

    static let hover = white(0.05)
    static let selection = white(0.1)
    static let border = white(0.1)
    static let card = white(0.03)
    /// Les traits entre les barres et le contenu, et entre les lignes d'une carte.
    static let rule = white(0.07)
    static let rowRule = white(0.05)

    /// La courbe des retours visuels de Monocode (survol, choix), et celle des ouvertures.
    static var feedback: Animation? { motion(.timingCurve(0.22, 1, 0.36, 1, duration: 0.12)) }
    static var open: Animation? { motion(.timingCurve(0.16, 1, 0.3, 1, duration: 0.17)) }
    /// Un choix qui passe d'un endroit à l'autre (pastille d'un sélecteur), et un contenu qui change.
    static var slide: Animation? { motion(.timingCurve(0.22, 1, 0.36, 1, duration: 0.22)) }

    /// Avec « Réduire les animations » (Accessibilité de macOS), tout change d'un coup.
    static func motion(_ animation: Animation) -> Animation? {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : animation
    }
}

extension Color {
    /// `RRGGBB`, avec ou sans `#`.
    init(hex: String) {
        let channels = Hex.channels(hex).map { Double($0) / 255 }
        self.init(red: channels[0], green: channels[1], blue: channels[2])
    }
}
