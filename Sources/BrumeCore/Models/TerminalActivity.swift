/// Ce qui arrive dans un terminal et que sa pastille ou une notification peut signaler.
public enum TerminalEvent: Equatable, Sendable {
    /// `exitCode` nil : le shell ne l'a pas donné.
    case commandFinished(exitCode: Int?, duration: Duration)
    /// Une notification demandée par le programme (OSC 9 ou 777) : Claude Code qui attend.
    case notification(title: String, body: String)
    case bell
    /// Une progression qui s'arrête : Claude Code a fini son tour.
    case progressEnded
}

/// Ce qui s'est passé dans un terminal depuis qu'on l'a regardé : la pastille de son onglet.
/// Rangée par gravité : un groupe prend celle du plus grave de ses terminaux.
public enum TerminalActivity: Comparable, Sendable {
    case new
    /// Sa dernière commande a échoué.
    case failed

    /// Une commande réussie rend sa couleur à une pastille rouge, le reste ne l'efface pas.
    public static func after(_ event: TerminalEvent, from current: TerminalActivity?) -> TerminalActivity {
        guard case let .commandFinished(exitCode?, _) = event else { return current ?? .new }
        return exitCode == 0 ? .new : .failed
    }
}

/// Le texte d'une notification de macOS pour un terminal, sous le nom de son onglet.
public struct TerminalNotice: Equatable, Sendable {
    public var subtitle = ""
    public var body: String

    /// Plus courte, une commande finit sous les yeux de celui qui l'a lancée.
    public static let minimumDuration = Duration.seconds(10)

    /// Nil : rien qui vaille une notification.
    @MainActor public init?(_ event: TerminalEvent) {
        switch event {
        case let .commandFinished(exitCode, duration):
            guard duration >= Self.minimumDuration else { return nil }
            if let exitCode, exitCode != 0 {
                body = L10n.text(.commandFailedWithCode, "\(exitCode)")
            } else {
                body = L10n.text(.commandFinished)
            }
        case let .notification(title, body):
            // OSC 9 n'a pas de titre : le texte seul.
            guard !title.isEmpty, !body.isEmpty else {
                guard !(title + body).isEmpty else { return nil }
                self.body = title + body
                return
            }
            subtitle = title
            self.body = body
        case .bell, .progressEnded:
            return nil
        }
    }
}
