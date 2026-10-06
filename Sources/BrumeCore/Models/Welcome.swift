/// L'écran de démarrage d'un nouveau terminal, affiché par fastfetch : un visuel, un mot en grosses
/// lettres, ou les deux, et les informations du Mac.
public struct Welcome: Codable, Hashable, Sendable {
    public var isEnabled = true
    public var content = WelcomeContent.visual
    public var visual = WelcomeVisual.breath
    public var text = ""
    public var size = WelcomeSize.medium
    public var info = WelcomeInfo.categories
    public var alignment = WelcomeAlignment.center

    public init() {}

    /// Un réglage absent ou illisible garde sa valeur par défaut.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ value: inout T) {
            if let decoded = try? container.decode(T.self, forKey: key) { value = decoded }
        }
        read(.isEnabled, &isEnabled)
        read(.content, &content)
        read(.visual, &visual)
        read(.text, &text)
        if container.contains(.size) {
            read(.size, &size)
        } else if let legacy = try? decoder.container(keyedBy: LegacyKeys.self),
                  let decoded = try? legacy.decode(WelcomeSize.self, forKey: .visualSize) {
            size = decoded
        }
        read(.info, &info)
        read(.alignment, &alignment)
    }

    /// Rien à afficher : seulement un texte sans caractère dessinable, et pas d'informations.
    public var isEmpty: Bool { !showsVisual && !showsText && info == .none }

    public var showsVisual: Bool { content != .text }
    /// Un texte sans caractère dessinable, ou fait d'espaces, ne compte pas.
    public var showsText: Bool { content != .visual && PixelFont.supported(text).contains { $0 != " " } }

    /// Le mot tel qu'il s'affiche à une taille : coupé à sa limite, le texte saisi reste entier.
    public func displayedText(at size: WelcomeSize) -> String {
        String(text.prefix(size.textLimit))
    }

    /// Avant la taille unique, le visuel et le texte avaient chacun la leur.
    private enum LegacyKeys: String, CodingKey {
        case visualSize
    }
}

public enum WelcomeContent: String, CaseIterable, Codable, Sendable {
    case visual, text, both
}

public enum WelcomeVisual: String, CaseIterable, Codable, Sendable {
    case apple, breath, prompt, ghost, saturn, cloud, saucer, slime, gem, moon, mushroom, turtle
}

public enum WelcomeSize: String, CaseIterable, Codable, Comparable, Sendable {
    case small, medium, large

    /// Pixels du terminal par pixel de la police.
    public var textScale: Int {
        switch self {
        case .small: 1
        case .medium: 2
        case .large: 3
        }
    }

    /// Ce qui tient sur une ligne de 100 colonnes, la largeur d'une fenêtre par défaut.
    public var textLimit: Int {
        switch self {
        case .small: 16
        case .medium: 8
        case .large: 5
        }
    }

    /// La taille d'en dessous, pour un terminal trop petit.
    public var smaller: WelcomeSize? {
        switch self {
        case .small: nil
        case .medium: .small
        case .large: .medium
        }
    }

    public static func < (lhs: WelcomeSize, rhs: WelcomeSize) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

public enum WelcomeInfo: String, CaseIterable, Codable, Sendable {
    case none, essential, categories
}

public enum WelcomeAlignment: String, CaseIterable, Codable, Sendable {
    case left, center, right
}

public extension WelcomeContent {
    var title: TextKey {
        switch self {
        case .visual: .contentVisual
        case .text: .contentText
        case .both: .contentBoth
        }
    }
}

public extension WelcomeVisual {
    var title: TextKey {
        switch self {
        case .ghost: .visualGhost
        case .saturn: .visualSaturn
        case .cloud: .visualCloud
        case .saucer: .visualSaucer
        case .slime: .visualSlime
        case .gem: .visualGem
        case .moon: .visualMoon
        case .mushroom: .visualMushroom
        case .turtle: .visualTurtle
        case .apple: .visualApple
        case .breath: .visualBreath
        case .prompt: .visualPrompt
        }
    }
}

public extension WelcomeSize {
    var title: TextKey {
        switch self {
        case .small: .sizeSmall
        case .medium: .sizeMedium
        case .large: .sizeLarge
        }
    }
}

public extension WelcomeInfo {
    var title: TextKey {
        switch self {
        case .none: .infoNone
        case .essential: .infoEssential
        case .categories: .infoCategories
        }
    }
}

public extension WelcomeAlignment {
    var title: TextKey {
        switch self {
        case .left: .alignLeft
        case .center: .alignCenter
        case .right: .alignRight
        }
    }
}
