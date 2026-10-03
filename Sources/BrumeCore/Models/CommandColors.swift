/// La coloration des commandes : les 16 couleurs ANSI du terminal (commandes reconnues, fichiers,
/// erreurs, texte grisé de l'autocomplétion), reprises de thèmes connus. Le fond n'en dépend pas.
public enum CommandColors: String, CaseIterable, Codable, Sendable {
    case brume, catppuccin, tokyoNight, rosePine, nord, gruvbox, github, afterglow
    case dracula, oneDark, solarized, kanagawa, everforest, ayu, monokai, nightOwl

    public var name: String {
        switch self {
        case .brume: "Brume"
        case .catppuccin: "Catppuccin"
        case .tokyoNight: "Tokyo Night"
        case .rosePine: "Rosé Pine"
        case .nord: "Nord"
        case .gruvbox: "Gruvbox"
        case .github: "GitHub"
        case .afterglow: "Afterglow"
        case .dracula: "Dracula"
        case .oneDark: "One Dark"
        case .solarized: "Solarized"
        case .kanagawa: "Kanagawa"
        case .everforest: "Everforest"
        case .ayu: "Ayu"
        case .monokai: "Monokai"
        case .nightOwl: "Night Owl"
        }
    }

    /// Le thème de Ghostty d'où viennent les couleurs. Nil pour Brume, dont la palette est
    /// celle de Monocode (`ownPalette`).
    public var ghosttyName: String? {
        switch self {
        case .brume: nil
        case .catppuccin: "Catppuccin Mocha"
        case .tokyoNight: "TokyoNight Night"
        case .rosePine: "Rose Pine"
        case .nord: "Nord"
        case .gruvbox: "Gruvbox Dark"
        case .github: "GitHub Dark Default"
        case .afterglow: "Afterglow"
        case .dracula: "Dracula"
        case .oneDark: "Atom One Dark"
        case .solarized: "iTerm2 Solarized Dark"
        case .kanagawa: "Kanagawa Wave"
        case .everforest: "Everforest Dark Hard"
        case .ayu: "Ayu Mirage"
        case .monokai: "Monokai Pro"
        case .nightOwl: "Night Owl"
        }
    }

    public var ownPalette: [String]? {
        guard self == .brume else { return nil }
        return [
            "1f2a3f", "f87171", "4ade80", "fbbf24", "60a5fa", "c084fc", "22d3ee", "dce3ee",
            "64748b", "fca5a5", "86efac", "fde68a", "93c5fd", "d8b4fe", "67e8f9", "f8fafc",
        ]
    }
}
