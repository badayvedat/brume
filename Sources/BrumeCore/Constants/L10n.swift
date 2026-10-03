import Foundation
import Observation

/// Langue de l'interface, choisie dans les réglages.
public enum Language: String, CaseIterable, Codable, Sendable {
    case french, english

    /// Pour écrire les nombres comme la langue choisie, pas comme le Mac.
    public var locale: Locale {
        Locale(identifier: self == .french ? "fr_FR" : "en_US")
    }

    /// Chaque langue s'écrit dans sa propre langue : on la reconnaît même sans lire l'autre.
    public var name: String {
        switch self {
        case .french: "Français"
        case .english: "English"
        }
    }
}

/// Textes de l'interface par clé. Un `switch` exhaustif par langue : une clé
/// sans traduction ne compile pas.
public enum TextKey: CaseIterable, Sendable {
    case closeTerminalTitle, closeTerminalMessage
    case closeTabTitle, closeTabMessage
    case closeWindowTitle, closeWindowMessage
    case quitTitle, quitMessage
    case close, closeWindow, quit, cancel
    case newTab, closeTab, previousTab, nextTab, tab, lastTab, terminal
    case renameTab, resetTabName
    case splitRight, splitDown, newWindow
    case focusPreviousSplit, focusNextSplit, focusSplitLeft, focusSplitRight, focusSplitUp, focusSplitDown
    case equalizeSplits, moveTabLeft, moveTabRight, moveTabUp, moveTabDown
    case find, findPlaceholder, findNext, findPrevious, findSelection, closeFind
    case increaseFontSize, decreaseFontSize, resetFontSize, resetAllSizes
    case moreOptions, showInFinder, openIn, copyPath, noFolderYet
    case closeTabsTitle, closeTabsMessage, closeOtherTabs, closeTabsToTheRight
    case resetTabs, tabColor, noColor, colorRed, colorOrange, colorYellow, colorGreen, colorBlue, colorPurple
    case settings, back, general, generalHint, appearance, appearanceHint
    case window, windowHint, glass, glassHint, opacity, opacityHint, blur, blurHint
    case colors, colorsHint, color, colorHint, colorDefault, colorBlack, colorPink, colorTeal, commandColors, commandColorsHint
    case tint, tintHint, strengthLow, strengthMedium, strengthHigh, showPreview, hidePreview, previewMessage, previewLink
    case text, font, fontHint, fontSize, fontSizeHint, smaller, larger, interface, language, languageHint
    case startup, restoreTabs, restoreTabsHint

    public func text(in language: Language) -> String {
        switch language {
        case .french: french
        case .english: english
        }
    }

    private var french: String {
        switch self {
        case .closeTerminalTitle: "Fermer le terminal ?"
        case .closeTerminalMessage: "Une commande tourne encore dans ce terminal. Le fermer l'arrêtera."
        case .closeTabTitle: "Fermer l'onglet ?"
        case .closeTabMessage: "Une commande tourne encore dans cet onglet. Le fermer l'arrêtera."
        case .closeWindowTitle: "Fermer la fenêtre ?"
        case .closeWindowMessage: "Une commande tourne encore dans un onglet de cette fenêtre. La fermer l'arrêtera."
        case .quitTitle: "Quitter Brume ?"
        case .quitMessage: "Une commande tourne encore dans un terminal. Quitter l'arrêtera."
        case .close: "Fermer"
        case .closeWindow: "Fermer la fenêtre"
        case .quit: "Quitter"
        case .cancel: "Annuler"
        case .newTab: "Nouvel onglet"
        case .closeTab: "Fermer l'onglet"
        case .previousTab: "Onglet précédent"
        case .nextTab: "Onglet suivant"
        case .tab: "Onglet"
        case .lastTab: "Dernier onglet"
        case .terminal: "Terminal"
        case .renameTab: "Renommer l'onglet"
        case .resetTabName: "Rendre le nom automatique"
        case .splitRight: "Diviser à droite"
        case .splitDown: "Diviser en dessous"
        case .newWindow: "Nouvelle fenêtre"
        case .focusPreviousSplit: "Split précédent"
        case .focusNextSplit: "Split suivant"
        case .focusSplitLeft: "Split à gauche"
        case .focusSplitRight: "Split à droite"
        case .focusSplitUp: "Split au-dessus"
        case .focusSplitDown: "Split en dessous"
        case .equalizeSplits: "Égaliser les splits"
        case .moveTabLeft: "Déplacer l'onglet à gauche"
        case .moveTabRight: "Déplacer l'onglet à droite"
        case .moveTabUp: "Déplacer l'onglet vers le haut"
        case .moveTabDown: "Déplacer l'onglet vers le bas"
        case .find: "Rechercher…"
        case .findPlaceholder: "Rechercher"
        case .findNext: "Résultat suivant"
        case .findPrevious: "Résultat précédent"
        case .findSelection: "Rechercher la sélection"
        case .closeFind: "Fermer la recherche"
        case .increaseFontSize: "Agrandir le texte"
        case .decreaseFontSize: "Réduire le texte"
        case .resetFontSize: "Taille réelle"
        case .resetAllSizes: "Réinitialiser les tailles"
        case .moreOptions: "Plus d'options"
        case .showInFinder: "Ouvrir dans le Finder"
        case .openIn: "Ouvrir dans"
        case .copyPath: "Copier le chemin"
        case .noFolderYet: "Dossier du terminal inconnu"
        case .closeTabsTitle: "Fermer les onglets ?"
        case .closeTabsMessage: "Une commande tourne encore dans un de ces onglets. Les fermer l'arrêtera."
        case .closeOtherTabs: "Fermer les autres onglets"
        case .closeTabsToTheRight: "Fermer les onglets à droite"
        case .resetTabs: "Réinitialiser les onglets"
        case .tabColor: "Couleur"
        case .noColor: "Sans couleur"
        case .colorRed: "Rouge"
        case .colorOrange: "Orange"
        case .colorYellow: "Jaune"
        case .colorGreen: "Vert"
        case .colorBlue: "Bleu"
        case .colorPurple: "Violet"
        case .settings: "Réglages"
        case .back: "Retour"
        case .general: "Général"
        case .generalHint: "Ce qui ne touche pas à l'apparence."
        case .appearance: "Apparence"
        case .appearanceHint: "L'allure des fenêtres et des terminaux, appliquée tout de suite : cette page change avec."
        case .window: "Fenêtre"
        case .windowHint: "Ce qu'on voit du bureau à travers la fenêtre."
        case .glass: "Verre"
        case .glassHint: "Le bureau flouté apparaît derrière les terminaux. Éteint, le fond est plein."
        case .opacity: "Opacité"
        case .opacityHint: "La part de la couleur du fond posée sur le bureau."
        case .blur: "Flou"
        case .blurHint: "Le flou du bureau derrière la fenêtre. Plus il est fort, plus il coûte à afficher."
        case .colors: "Couleurs"
        case .colorsHint: "Celles de l'interface et des terminaux, appliquées tout de suite."
        case .color: "Couleur"
        case .colorHint: "Le fond en prend la teinte, les onglets, le curseur et la sélection la couleur pleine."
        case .colorDefault: "Par défaut"
        case .colorBlack: "Noir"
        case .colorPink: "Rose"
        case .colorTeal: "Turquoise"
        case .tint: "Teinte du fond"
        case .tintHint: "La part de la couleur dans le fond. Sans effet avec le noir."
        case .strengthLow: "Faible"
        case .strengthMedium: "Moyenne"
        case .strengthHigh: "Forte"
        case .showPreview: "Voir l'aperçu"
        case .hidePreview: "Masquer l'aperçu"
        case .previewMessage: "premier jet"
        case .previewLink: "lien"
        case .commandColors: "Coloration des commandes"
        case .commandColorsHint: "Les couleurs des commandes, des fichiers et des erreurs dans le terminal."
        case .text: "Texte"
        case .font: "Police"
        case .fontHint: "Celle des terminaux."
        case .fontSize: "Taille du texte"
        case .fontSizeHint: "La taille de départ. Cmd+plus et Cmd+moins zooment par-dessus."
        case .smaller: "Plus petit"
        case .larger: "Plus grand"
        case .interface: "Interface"
        case .language: "Langue"
        case .languageHint: "Celle des menus et de toute l'interface."
        case .startup: "Démarrage"
        case .restoreTabs: "Rouvrir les onglets"
        case .restoreTabsHint: "Retrouver au lancement les fenêtres et les onglets laissés en quittant."
        }
    }

    private var english: String {
        switch self {
        case .closeTerminalTitle: "Close Terminal?"
        case .closeTerminalMessage: "The terminal still has a running process. If you close the terminal the process will be killed."
        case .closeTabTitle: "Close Tab?"
        case .closeTabMessage: "The terminal still has a running process. If you close the tab the process will be killed."
        case .closeWindowTitle: "Close Window?"
        case .closeWindowMessage: "All terminal sessions in this window will be terminated."
        case .quitTitle: "Quit Brume?"
        case .quitMessage: "The terminal still has a running process. If you quit, the process will be killed."
        case .close: "Close"
        case .closeWindow: "Close Window"
        case .quit: "Quit"
        case .cancel: "Cancel"
        case .newTab: "New Tab"
        case .closeTab: "Close Tab"
        case .previousTab: "Show Previous Tab"
        case .nextTab: "Show Next Tab"
        case .tab: "Tab"
        case .lastTab: "Last Tab"
        case .terminal: "Terminal"
        case .renameTab: "Rename Tab"
        case .resetTabName: "Reset Tab Name"
        case .splitRight: "Split Right"
        case .splitDown: "Split Down"
        case .newWindow: "New Window"
        case .focusPreviousSplit: "Select Previous Split"
        case .focusNextSplit: "Select Next Split"
        case .focusSplitLeft: "Select Split Left"
        case .focusSplitRight: "Select Split Right"
        case .focusSplitUp: "Select Split Above"
        case .focusSplitDown: "Select Split Below"
        case .equalizeSplits: "Equalize Splits"
        case .moveTabLeft: "Move Tab Left"
        case .moveTabRight: "Move Tab Right"
        case .moveTabUp: "Move Tab Up"
        case .moveTabDown: "Move Tab Down"
        case .find: "Find…"
        case .findPlaceholder: "Find"
        case .findNext: "Find Next"
        case .findPrevious: "Find Previous"
        case .findSelection: "Use Selection for Find"
        case .closeFind: "Close Find Bar"
        case .increaseFontSize: "Increase Font Size"
        case .decreaseFontSize: "Decrease Font Size"
        case .resetFontSize: "Reset Font Size"
        case .resetAllSizes: "Reset All Sizes"
        case .moreOptions: "More Options"
        case .showInFinder: "Show in Finder"
        case .openIn: "Open in"
        case .copyPath: "Copy Path"
        case .noFolderYet: "Terminal folder unknown"
        case .closeTabsTitle: "Close Tabs?"
        case .closeTabsMessage: "A terminal still has a running process. If you close these tabs the process will be killed."
        case .closeOtherTabs: "Close Other Tabs"
        case .closeTabsToTheRight: "Close Tabs to the Right"
        case .resetTabs: "Reset Tabs"
        case .tabColor: "Color"
        case .noColor: "No Color"
        case .colorRed: "Red"
        case .colorOrange: "Orange"
        case .colorYellow: "Yellow"
        case .colorGreen: "Green"
        case .colorBlue: "Blue"
        case .colorPurple: "Purple"
        case .settings: "Settings"
        case .back: "Back"
        case .general: "General"
        case .generalHint: "Everything that is not about looks."
        case .appearance: "Appearance"
        case .appearanceHint: "How windows and terminals look, applied right away: this page changes with it."
        case .window: "Window"
        case .windowHint: "How much of the desktop shows through the window."
        case .glass: "Glass"
        case .glassHint: "The blurred desktop shows behind the terminals. Off, the background is solid."
        case .opacity: "Opacity"
        case .opacityHint: "How much of the background color covers the desktop."
        case .blur: "Blur"
        case .blurHint: "The desktop blur behind the window. The higher, the more it costs to draw."
        case .colors: "Colors"
        case .colorsHint: "The interface's and the terminals', applied right away."
        case .color: "Color"
        case .colorHint: "The background takes its hue; tabs, cursor and selection take the full color."
        case .colorDefault: "Default"
        case .colorBlack: "Black"
        case .colorPink: "Pink"
        case .colorTeal: "Teal"
        case .tint: "Background Tint"
        case .tintHint: "How much of the color goes into the background. No effect with black."
        case .strengthLow: "Low"
        case .strengthMedium: "Medium"
        case .strengthHigh: "High"
        case .showPreview: "Show Preview"
        case .hidePreview: "Hide Preview"
        case .previewMessage: "first draft"
        case .previewLink: "link"
        case .commandColors: "Command Colors"
        case .commandColorsHint: "The colors of commands, files and errors in the terminal."
        case .text: "Text"
        case .font: "Font"
        case .fontHint: "The one used by terminals."
        case .fontSize: "Text Size"
        case .fontSizeHint: "The starting size. Cmd+plus and Cmd+minus zoom on top of it."
        case .smaller: "Smaller"
        case .larger: "Larger"
        case .interface: "Interface"
        case .language: "Language"
        case .languageHint: "Used by menus and the whole interface."
        case .startup: "Startup"
        case .restoreTabs: "Reopen Tabs"
        case .restoreTabsHint: "Bring back at launch the windows and tabs left when quitting."
        }
    }
}

@MainActor
public enum L10n {
    /// Observée : une vue qui affiche un texte se redessine quand la langue change.
    @Observable
    final class Current {
        var language = Language.french
    }

    private static let current = Current()

    public static var language: Language {
        get { current.language }
        set { current.language = newValue }
    }

    public static func text(_ key: TextKey) -> String {
        key.text(in: language)
    }
}
