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
}
