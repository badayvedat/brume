/// L'icône d'un onglet, pour reconnaître d'un coup d'œil un projet, un serveur ou une machine.
/// Peu de choix et nets entre eux, comme `TabColor`.
public enum TabIcon: String, CaseIterable, Codable, Sendable {
    case terminal, project, server, machine, cloud, web, database, container, code, tools, ai, production
}
