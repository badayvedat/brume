/// Variables que Brume ne transmet pas à ses shells : lancé depuis Claude Code, il en hérite, et
/// chaque `claude` ouvert dans Brume se croirait alors une sous-session.
public enum InheritedEnvironment {
    static let excludedNames: Set<String> = ["CLAUDECODE"]
    static let excludedPrefixes = ["CLAUDE_CODE_"]

    public static func excluded(from names: some Sequence<String>) -> [String] {
        names.filter { name in
            excludedNames.contains(name) || excludedPrefixes.contains { name.hasPrefix($0) }
        }
    }
}
