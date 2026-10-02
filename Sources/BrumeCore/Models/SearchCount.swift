/// Résultats d'une recherche dans le terminal, tels que le moteur les compte.
public struct SearchCount: Equatable, Sendable {
    public let total: Int?
    /// À partir de 0.
    public let selected: Int?

    public init(total: Int?, selected: Int?) {
        self.total = total
        self.selected = selected
    }

    /// Comme Ghostty : « 2/12 », « -/12 » tant qu'aucun n'est sélectionné, rien sans compte.
    public var label: String? {
        switch (selected, total) {
        case let (selected?, total): "\(selected + 1)/\(total.map(String.init) ?? "?")"
        case let (nil, total?): "-/\(total)"
        case (nil, nil): nil
        }
    }

    /// Ghostty attend sur les recherches de moins de 3 caractères : elles trouvent
    /// des milliers de résultats et coûtent cher à chaque frappe.
    public static func delay(for needle: String) -> Duration {
        needle.isEmpty || needle.count >= 3 ? .zero : .milliseconds(300)
    }
}
