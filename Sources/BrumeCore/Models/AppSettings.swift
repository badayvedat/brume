import Foundation

/// Les réglages de l'app, enregistrés à chaque changement.
public struct AppSettings: Codable, Hashable, Sendable {
    public var appearance = Appearance()
    public var font = TerminalFont.standard
    public var language = Language.french
    /// Rouvrir au lancement les fenêtres et les onglets de la dernière fois.
    public var restoresSession = true
    /// La commande déjà tapée proposée en gris (zsh-autosuggestions).
    public var suggestsHistory = true
    /// Le menu de complétion de zsh, ouvert par Tab.
    public var completesCommands = true
    public var welcome = Welcome()
    public var verticalTabs = VerticalTabs()
    public var shortcuts = Shortcuts()

    public init() {}

    /// Un réglage absent ou illisible garde sa valeur par défaut : un fichier d'une version
    /// précédente, sans les réglages ajoutés depuis, ne fait pas tout perdre.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(Appearance.self, forKey: .appearance) { appearance = value }
        if let value = try? container.decode(TerminalFont.self, forKey: .font) { font = value }
        if let value = try? container.decode(Language.self, forKey: .language) { language = value }
        if let value = try? container.decode(Bool.self, forKey: .restoresSession) { restoresSession = value }
        if let value = try? container.decode(Bool.self, forKey: .suggestsHistory) { suggestsHistory = value }
        if let value = try? container.decode(Bool.self, forKey: .completesCommands) { completesCommands = value }
        if let value = try? container.decode(Welcome.self, forKey: .welcome) { welcome = value }
        if let value = try? container.decode(VerticalTabs.self, forKey: .verticalTabs) { verticalTabs = value }
        if let value = try? container.decode(Shortcuts.self, forKey: .shortcuts) { shortcuts = value }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decoded(from data: Data) -> AppSettings? {
        try? JSONDecoder().decode(AppSettings.self, from: data)
    }
}
