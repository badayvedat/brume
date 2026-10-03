import BrumeCore

/// Les pages des réglages, dans l'ordre de la barre latérale.
enum SettingsSection: CaseIterable {
    case general, appearance

    var title: TextKey {
        switch self {
        case .general: .general
        case .appearance: .appearance
        }
    }

    var hint: TextKey {
        switch self {
        case .general: .generalHint
        case .appearance: .appearanceHint
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        }
    }
}
