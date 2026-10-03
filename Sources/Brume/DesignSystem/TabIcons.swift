import BrumeCore

extension TabIcon {
    /// Chacun préchargé par `SystemSymbol`, à la taille des onglets.
    var symbol: String {
        switch self {
        case .terminal: "apple.terminal"
        case .project: "folder"
        case .server: "server.rack"
        case .machine: "desktopcomputer"
        case .cloud: "cloud"
        case .web: "globe"
        case .database: "cylinder.split.1x2"
        case .container: "shippingbox"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .tools: "hammer"
        case .ai: "sparkles"
        case .production: "exclamationmark.triangle"
        }
    }

    @MainActor var name: String {
        let key: TextKey = switch self {
        case .terminal: .iconTerminal
        case .project: .iconProject
        case .server: .iconServer
        case .machine: .iconMachine
        case .cloud: .iconCloud
        case .web: .iconWeb
        case .database: .iconDatabase
        case .container: .iconContainer
        case .code: .iconCode
        case .tools: .iconTools
        case .ai: .iconAI
        case .production: .iconProduction
        }
        return L10n.text(key)
    }
}
