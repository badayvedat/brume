import Foundation

/// Une combinaison de touches : une touche et ses touches de modification. La touche est le
/// caractère tel qu'il s'écrit sans modification sur le clavier (`d`, `[`, `1`), ou le nom d'une
/// touche spéciale (`return`, `left`, `f5`).
public struct Shortcut: Hashable, Sendable {
    public struct Modifiers: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let control = Modifiers(rawValue: 1)
        public static let option = Modifiers(rawValue: 2)
        public static let shift = Modifiers(rawValue: 4)
        public static let command = Modifiers(rawValue: 8)
    }

    public var key: String
    public var modifiers: Modifiers

    public init(_ key: String, _ modifiers: Modifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }

    public static let namedKeys = [
        "return", "tab", "space", "delete", "forwardDelete", "escape",
        "left", "right", "up", "down", "home", "end", "pageUp", "pageDown",
    ] + (1 ... 12).map { "f\($0)" }

    public var isDigit: Bool {
        key.count == 1 && key.first?.isWholeNumber == true
    }

    /// Seule, une touche part dans le terminal : il faut ⌘, ⌃ ou ⌥.
    public var hasModifier: Bool {
        !modifiers.isDisjoint(with: [.command, .control, .option])
    }

    /// Dans l'ordre des menus de macOS : ⌃⌥⇧⌘.
    public var modifiersLabel: String {
        [(Modifiers.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
            .filter { modifiers.contains($0.0) }
            .map(\.1)
            .joined()
    }

    @MainActor public var label: String {
        modifiersLabel + keyLabel
    }

    @MainActor public var keyLabel: String {
        switch key {
        case "return": "↩"
        case "tab": "⇥"
        case "space": L10n.text(.keySpace)
        case "delete": "⌫"
        case "forwardDelete": "⌦"
        case "escape": "⎋"
        case "left": "←"
        case "right": "→"
        case "up": "↑"
        case "down": "↓"
        case "home": "↖"
        case "end": "↘"
        case "pageUp": "⇞"
        case "pageDown": "⇟"
        case let name where name.count > 1: name.uppercased()
        default: key.uppercased()
        }
    }
}

/// Écrit `ctrl+cmd+s` dans le fichier des réglages, lisible et corrigeable à la main.
extension Shortcut: Codable, CustomStringConvertible {
    private static let modifierNames: [(Modifiers, String)] = [(.control, "ctrl"), (.option, "alt"), (.shift, "shift"), (.command, "cmd")]

    public var description: String {
        let names = Self.modifierNames.filter { modifiers.contains($0.0) }.map(\.1)
        return (names + [key == "+" ? "plus" : key]).joined(separator: "+")
    }

    public init?(parsing description: String) {
        var parts = description.split(separator: "+", omittingEmptySubsequences: false).map(String.init)
        guard let last = parts.popLast(), !last.isEmpty else { return nil }
        let key = last == "plus" ? "+" : last
        guard key.count == 1 || Self.namedKeys.contains(key) else { return nil }
        var modifiers: Modifiers = []
        for part in parts {
            guard let modifier = Self.modifierNames.first(where: { $0.1 == part })?.0 else { return nil }
            modifiers.insert(modifier)
        }
        self.init(key, modifiers)
    }

    public init(from decoder: Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let shortcut = Shortcut(parsing: text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Raccourci illisible : \(text)"))
        }
        self = shortcut
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
