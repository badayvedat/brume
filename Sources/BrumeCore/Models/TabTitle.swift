import Foundation

/// Le nom choisi pour un onglet. Sans nom choisi, l'onglet affiche le titre du terminal
/// (son dossier, ou la commande en cours).
public enum TabTitle {
    /// Valider sans rien changer garde le titre automatique : le champ part prérempli avec lui.
    /// Un champ vidé rend le titre automatique.
    public static func renamed(input: String, displayed: String, current: String?) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed == displayed.trimmingCharacters(in: .whitespaces) { return current }
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Le dernier dossier d'un titre en chemin : coupé à droite, le chemin entier perdrait le plus
    /// parlant. Une commande en cours reste telle quelle.
    public static func short(_ title: String) -> String {
        guard title.hasPrefix("/") || title.hasPrefix("~/"), let last = title.split(separator: "/").last else { return title }
        return String(last)
    }

    /// Le dossier d'un terminal, le dossier personnel écrit `~` comme dans le shell.
    public static func folder(_ path: String, home: String) -> String {
        guard path == home || path.hasPrefix(home + "/") else { return path }
        return "~" + path.dropFirst(home.count)
    }
}
