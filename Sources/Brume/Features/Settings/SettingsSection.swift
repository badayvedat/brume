import BrumeCore

/// Les pages des réglages, dans l'ordre de la barre latérale.
enum SettingsSection: String, CaseIterable {
    case general, appearance, welcome, shortcuts

    var title: TextKey {
        switch self {
        case .general: .general
        case .appearance: .appearance
        case .welcome: .welcome
        case .shortcuts: .shortcuts
        }
    }

    var hint: TextKey {
        switch self {
        case .general: .generalHint
        case .appearance: .appearanceHint
        case .welcome: .welcomeHint
        case .shortcuts: .shortcutsHint
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .welcome: "text.below.photo"
        case .shortcuts: "keyboard"
        }
    }
}
