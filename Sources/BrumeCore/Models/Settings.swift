import Foundation

/// Les réglages de l'app, enregistrés à chaque changement.
public struct Settings: Codable, Hashable, Sendable {
    public var translucency = TranslucencyPreset.glass.translucency

    public init() {}

    /// Un réglage absent ou illisible garde sa valeur par défaut : un fichier d'une version
    /// précédente, sans les réglages ajoutés depuis, ne fait pas tout perdre.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let translucency = try? container.decode(Translucency.self, forKey: .translucency) {
            self.translucency = translucency
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decoded(from data: Data) -> Settings? {
        try? JSONDecoder().decode(Settings.self, from: data)
    }
}
