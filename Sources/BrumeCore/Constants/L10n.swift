/// Langue de l'interface, à choisir plus tard dans les réglages.
public enum Language: CaseIterable, Sendable {
    case french, english
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
        }
    }
}

@MainActor
public enum L10n {
    public static var language: Language = .french

    public static func text(_ key: TextKey) -> String {
        key.text(in: language)
    }
}
