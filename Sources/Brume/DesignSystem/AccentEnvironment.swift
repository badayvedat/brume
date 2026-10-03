import BrumeCore
import SwiftUI

private struct AccentKey: EnvironmentKey {
    static let defaultValue = Accent.brume
}

extension EnvironmentValues {
    /// La couleur choisie dans les réglages. `Color.accentColor` reste celle du Mac, même sous `.tint`.
    var accent: Accent {
        get { self[AccentKey.self] }
        set { self[AccentKey.self] = newValue }
    }
}

extension Accent {
    var color: Color {
        Color(hex: hex)
    }
}
