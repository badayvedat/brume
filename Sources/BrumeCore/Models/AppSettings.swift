import Foundation

/// Les réglages de l'app, enregistrés à chaque changement.
public struct AppSettings: Codable, Hashable, Sendable {
    public var appearance = Appearance()
    public var font = TerminalFont.standard
    public var language = Language.french
    /// Rouvrir au lancement les fenêtres et les onglets de la dernière fois.
    public var restoresSession = true

    public init() {}

    /// Un réglage absent ou illisible garde sa valeur par défaut : un fichier d'une version
    /// précédente, sans les réglages ajoutés depuis, ne fait pas tout perdre.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(Appearance.self, forKey: .appearance) { appearance = value }
        if let value = try? container.decode(TerminalFont.self, forKey: .font) { font = value }
        if let value = try? container.decode(Language.self, forKey: .language) { language = value }
        if let value = try? container.decode(Bool.self, forKey: .restoresSession) { restoresSession = value }
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
