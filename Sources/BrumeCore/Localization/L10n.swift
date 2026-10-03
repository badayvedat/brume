/// Langue de l'interface, à choisir plus tard dans les réglages.
public enum Language: CaseIterable, Sendable {
    case french, english
}

/// Textes de l'interface par clé. Un `switch` exhaustif par langue : une clé
/// sans traduction ne compile pas.
public enum TextKey: CaseIterable, Sendable {
    case closeTerminalTitle, closeTerminalMessage
    case closeTabTitle, closeTabMessage
    case quitTitle, quitMessage
    case close, closeWindow, quit, cancel

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
        case .quitTitle: "Quitter Brume ?"
        case .quitMessage: "Une commande tourne encore dans un terminal. Quitter l'arrêtera."
        case .close: "Fermer"
        case .closeWindow: "Fermer la fenêtre"
        case .quit: "Quitter"
        case .cancel: "Annuler"
        }
    }

    private var english: String {
        switch self {
        case .closeTerminalTitle: "Close Terminal?"
        case .closeTerminalMessage: "The terminal still has a running process. If you close the terminal the process will be killed."
        case .closeTabTitle: "Close Tab?"
        case .closeTabMessage: "The terminal still has a running process. If you close the tab the process will be killed."
        case .quitTitle: "Quit Brume?"
        case .quitMessage: "The terminal still has a running process. If you quit, the process will be killed."
        case .close: "Close"
        case .closeWindow: "Close Window"
        case .quit: "Quit"
        case .cancel: "Cancel"
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
