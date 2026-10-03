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
    case tint, tintHint, strengthLow, strengthMedium, strengthHigh, blurMedium, blurHigh, showPreview, hidePreview, previewMessage, previewLink
    case text, font, fontHint, fontSize, fontSizeHint, smaller, larger, interface, language, languageHint
    case startup, restoreTabs, restoreTabsHint
    case welcome, welcomeHint, welcomePage, showWelcome, welcomePageHint, visual, visualHint, visualGhost
    case visualSaucer, visualApple, welcomeText, welcomeTextHint, information
    case informationHint, infoNone, infoEssential, infoCategories, position, positionHint, alignLeft, alignCenter, alignRight, preview
    case visualSlime, visualGem, visualMoon, visualMushroom
    case visualSaturn, visualCloud, content, contentHint, contentVisual, contentText, contentBoth, welcomeSize, welcomeSizeHint, sizeSmall, sizeMedium, sizeLarge, informationGroup, informationGroupHint, showContent, showContentHint, characters, welcomeTextPlaceholder
    case welcomeHardware, welcomeSoftware, welcomeSession, welcomeOS, welcomeHost, welcomeCPU, welcomeGPU, welcomeMemory, welcomeDisk, welcomePackages, welcomeShell, welcomeTerminal, welcomeUser, welcomeUptime, welcomeLocalIP

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
        case .generalHint: "Démarrage, langue et comportement de l'application."
        case .appearance: "Apparence"
        case .appearanceHint: "Style des fenêtres, couleurs et police des terminaux. Les changements s'appliquent immédiatement."
        case .window: "Fenêtre"
        case .windowHint: "Transparence et flou de l'arrière-plan."
        case .glass: "Effet verre"
        case .glassHint: "Affiche le bureau flouté derrière la fenêtre. Désactivé, le fond est opaque."
        case .opacity: "Opacité"
        case .opacityHint: "Opacité de la couleur de fond au-dessus du bureau."
        case .blur: "Flou"
        case .blurHint: "Intensité du flou appliqué au bureau. Un flou fort sollicite davantage la carte graphique."
        case .colors: "Couleurs"
        case .colorsHint: "Couleurs de l'interface et des terminaux."
        case .color: "Couleur d'accent"
        case .colorHint: "Utilisée pour le curseur, la sélection et les éléments actifs. Le fond en prend une teinte légère."
        case .colorDefault: "Par défaut"
        case .colorBlack: "Noir"
        case .colorPink: "Rose"
        case .colorTeal: "Turquoise"
        case .tint: "Teinte du fond"
        case .tintHint: "Intensité de la couleur d'accent dans le fond. Sans effet avec le noir."
        case .strengthLow: "Faible"
        case .strengthMedium: "Moyenne"
        case .strengthHigh: "Forte"
        case .blurMedium: "Moyen"
        case .blurHigh: "Fort"
        case .showPreview: "Afficher l'aperçu"
        case .hidePreview: "Masquer l'aperçu"
        case .previewMessage: "premier jet"
        case .previewLink: "lien"
        case .commandColors: "Coloration des commandes"
        case .commandColorsHint: "Couleurs appliquées aux commandes, aux fichiers et aux erreurs dans le terminal."
        case .text: "Texte"
        case .font: "Police"
        case .fontHint: "Police utilisée dans les terminaux."
        case .fontSize: "Taille du texte"
        case .fontSizeHint: "Taille par défaut des terminaux. ⌘+ et ⌘− l'ajustent ensuite terminal par terminal."
        case .smaller: "Plus petit"
        case .larger: "Plus grand"
        case .interface: "Interface"
        case .language: "Langue"
        case .languageHint: "Langue des menus et de l'interface."
        case .startup: "Session"
        case .restoreTabs: "Restaurer la session"
        case .restoreTabsHint: "Au démarrage, restaure les fenêtres et les onglets de la session précédente."
        case .welcome: "Démarrage"
        case .welcomeHint: "L'écran affiché à l'ouverture de chaque terminal : un visuel, un mot et les informations du Mac."
        case .welcomePage: "Affichage"
        case .showWelcome: "Afficher l'écran de démarrage"
        case .welcomePageHint: "À l'ouverture de chaque terminal, onglet ou split."
        case .visual: "Visuel"
        case .visualHint: "Pixel art teinté de la couleur d'accent."
        case .visualGhost: "Fantôme"
        case .visualSaucer: "Soucoupe"
        case .visualApple: "Apple"
        case .welcomeText: "Texte"
        case .welcomeTextHint: "Un mot en grandes lettres pixel : lettres, chiffres et ponctuation simple. Sa longueur maximale dépend de la taille."
        case .information: "Informations"
        case .informationHint: "Informations du Mac affichées à côté du visuel."
        case .infoNone: "Aucune"
        case .infoEssential: "Essentiel"
        case .infoCategories: "Par catégorie"
        case .position: "Position"
        case .positionHint: "Alignement de l'écran de démarrage dans la largeur du terminal."
        case .alignLeft: "Gauche"
        case .alignCenter: "Centre"
        case .alignRight: "Droite"
        case .preview: "Aperçu"
        case .visualSaturn: "Saturne"
        case .visualSlime: "Slime"
        case .visualGem: "Diamant"
        case .visualMoon: "Lune"
        case .visualMushroom: "Champignon"
        case .visualCloud: "Nuage"
        case .content: "Contenu"
        case .contentHint: "Un visuel, un mot, ou les deux."
        case .contentVisual: "Visuel"
        case .contentText: "Texte"
        case .contentBoth: "Visuel et texte"
        case .welcomeSize: "Taille"
        case .welcomeSizeHint: "Pour le visuel et le texte. Réduite si le terminal est trop petit."
        case .sizeSmall: "Compacte"
        case .sizeMedium: "Standard"
        case .informationGroup: "Informations"
        case .showContent: "En-tête"
        case .showContentHint: "Ce qui s'affiche en grand, au-dessus des informations."
        case .informationGroupHint: "Ce que l'écran de démarrage indique du Mac, et sa place dans le terminal."
        case .characters: "caractères"
        case .welcomeTextPlaceholder: "Votre mot"
        case .sizeLarge: "Grande"
        case .welcomeHardware: "Matériel"
        case .welcomeSoftware: "Logiciel"
        case .welcomeSession: "Session"
        case .welcomeOS: "Système"
        case .welcomeHost: "Machine"
        case .welcomeCPU: "Processeur"
        case .welcomeGPU: "Graphique"
        case .welcomeMemory: "Mémoire"
        case .welcomeDisk: "Disque"
        case .welcomePackages: "Paquets"
        case .welcomeShell: "Shell"
        case .welcomeTerminal: "Terminal"
        case .welcomeUser: "Utilisateur"
        case .welcomeUptime: "Allumé depuis"
        case .welcomeLocalIP: "IP locale"
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
        case .generalHint: "Startup, language and app behavior."
        case .appearance: "Appearance"
        case .appearanceHint: "Window style, colors and terminal font. Changes apply immediately."
        case .window: "Window"
        case .windowHint: "Background transparency and blur."
        case .glass: "Glass Effect"
        case .glassHint: "Shows the blurred desktop behind the window. When off, the background is opaque."
        case .opacity: "Opacity"
        case .opacityHint: "Opacity of the background color over the desktop."
        case .blur: "Blur"
        case .blurHint: "Strength of the desktop blur. A strong blur uses more graphics resources."
        case .colors: "Colors"
        case .colorsHint: "Interface and terminal colors."
        case .color: "Accent Color"
        case .colorHint: "Used for the cursor, selection and active elements. The background takes a light tint of it."
        case .colorDefault: "Default"
        case .colorBlack: "Black"
        case .colorPink: "Pink"
        case .colorTeal: "Teal"
        case .tint: "Background Tint"
        case .tintHint: "How strongly the accent color tints the background. No effect with black."
        case .strengthLow: "Low"
        case .strengthMedium: "Medium"
        case .strengthHigh: "High"
        case .blurMedium: "Medium"
        case .blurHigh: "High"
        case .showPreview: "Show Preview"
        case .hidePreview: "Hide Preview"
        case .previewMessage: "first draft"
        case .previewLink: "link"
        case .commandColors: "Command Colors"
        case .commandColorsHint: "Colors for commands, files and errors in the terminal."
        case .text: "Text"
        case .font: "Font"
        case .fontHint: "Font used in terminals."
        case .fontSize: "Text Size"
        case .fontSizeHint: "Default size for terminals. ⌘+ and ⌘− then adjust each terminal individually."
        case .smaller: "Smaller"
        case .larger: "Larger"
        case .interface: "Interface"
        case .language: "Language"
        case .languageHint: "Language of menus and the interface."
        case .startup: "Session"
        case .restoreTabs: "Restore Session"
        case .restoreTabsHint: "At startup, restores the windows and tabs from your previous session."
        case .welcome: "Startup"
        case .welcomeHint: "The screen shown when each terminal opens: a visual, a word and information about your Mac."
        case .welcomePage: "Display"
        case .showWelcome: "Show Startup Screen"
        case .welcomePageHint: "When each terminal, tab or split opens."
        case .visual: "Visual"
        case .visualHint: "Pixel art tinted with the accent color."
        case .visualGhost: "Ghost"
        case .visualSaucer: "Flying Saucer"
        case .visualApple: "Apple"
        case .welcomeText: "Text"
        case .welcomeTextHint: "A word in large pixel letters: letters, digits and simple punctuation. Its maximum length depends on the size."
        case .information: "Information"
        case .informationHint: "Mac information shown next to the visual."
        case .infoNone: "None"
        case .infoEssential: "Essentials"
        case .infoCategories: "By Category"
        case .position: "Position"
        case .positionHint: "Alignment of the startup screen across the terminal width."
        case .alignLeft: "Left"
        case .alignCenter: "Center"
        case .alignRight: "Right"
        case .preview: "Preview"
        case .visualSaturn: "Saturn"
        case .visualSlime: "Slime"
        case .visualGem: "Diamond"
        case .visualMoon: "Moon"
        case .visualMushroom: "Mushroom"
        case .visualCloud: "Cloud"
        case .content: "Content"
        case .contentHint: "A visual, a word, or both."
        case .contentVisual: "Visual"
        case .contentText: "Text"
        case .contentBoth: "Visual and Text"
        case .welcomeSize: "Size"
        case .welcomeSizeHint: "For the visual and the text. Reduced if the terminal is too small."
        case .sizeSmall: "Compact"
        case .sizeMedium: "Standard"
        case .informationGroup: "Information"
        case .showContent: "Header"
        case .showContentHint: "What appears large, above the information."
        case .informationGroupHint: "What the startup screen shows about your Mac, and where it sits in the terminal."
        case .characters: "characters"
        case .welcomeTextPlaceholder: "Your word"
        case .sizeLarge: "Large"
        case .welcomeHardware: "Hardware"
        case .welcomeSoftware: "Software"
        case .welcomeSession: "Session"
        case .welcomeOS: "OS"
        case .welcomeHost: "Machine"
        case .welcomeCPU: "CPU"
        case .welcomeGPU: "GPU"
        case .welcomeMemory: "Memory"
        case .welcomeDisk: "Disk"
        case .welcomePackages: "Packages"
        case .welcomeShell: "Shell"
        case .welcomeTerminal: "Terminal"
        case .welcomeUser: "User"
        case .welcomeUptime: "Uptime"
        case .welcomeLocalIP: "Local IP"
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
