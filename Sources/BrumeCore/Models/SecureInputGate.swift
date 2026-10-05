/// Quand allumer la saisie sécurisée de macOS : Brume au premier plan, et un terminal qui attend
/// un mot de passe avec le clavier. `EnableSecureEventInput` compte ses appels pour tout le
/// système : un appel sans son inverse priverait les autres apps du clavier, d'où une bascule
/// seulement au changement, une fois dans chaque sens.
public struct SecureInputGate<ID: Hashable & Sendable>: Equatable, Sendable {
    public enum Switch: Sendable {
        case enable, disable
    }

    public private(set) var isEnabled = false
    private var isAppActive: Bool
    /// Les terminaux qui attendent un mot de passe et ont le clavier.
    private var asking: Set<ID> = []

    public init(isAppActive: Bool) {
        self.isAppActive = isAppActive
    }

    /// Ceux dont le cadenas s'affiche.
    public var secured: Set<ID> {
        isEnabled ? asking : []
    }

    public mutating func setAppActive(_ isActive: Bool) -> Switch? {
        isAppActive = isActive
        return settle()
    }

    /// `isAsking` : le terminal attend un mot de passe et a le clavier. Faux pour un terminal fermé.
    public mutating func set(_ id: ID, isAsking: Bool) -> Switch? {
        if isAsking {
            asking.insert(id)
        } else {
            asking.remove(id)
        }
        return settle()
    }

    /// En quittant.
    public mutating func removeAll() -> Switch? {
        asking.removeAll()
        return settle()
    }

    private mutating func settle() -> Switch? {
        let wanted = isAppActive && !asking.isEmpty
        guard wanted != isEnabled else { return nil }
        isEnabled = wanted
        return wanted ? .enable : .disable
    }
}
