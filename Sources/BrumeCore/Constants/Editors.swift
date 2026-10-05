import Foundation

/// Les éditeurs que « Ouvrir avec » reconnaît, par identifiant d'app, dans l'ordre du menu.
/// Le nom et l'icône se lisent dans l'app installée : seuls les identifiants vivent ici.
public enum Editors {
    public static let bundleIdentifiers = [
        "dev.zed.Zed",
        "dev.zed.Zed-Preview",
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.todesktop.230313mzl4w4u92",
        "com.exafunction.windsurf",
        "com.vscodium",
        "com.sublimetext.4",
        "com.panic.Nova",
        "com.barebones.bbedit",
        "com.jetbrains.PhpStorm",
        "com.jetbrains.WebStorm",
        "com.jetbrains.intellij",
        "com.jetbrains.intellij.ce",
        "com.jetbrains.pycharm",
        "com.jetbrains.goland",
        "com.jetbrains.rustrover",
        "com.apple.dt.Xcode",
    ]

    /// Ceux qui ouvrent un fichier à la ligne par `<schéma>://file<chemin>:<ligne>:<colonne>`,
    /// d'après leur documentation ou leur code. Les autres reçoivent le fichier, sans la ligne.
    static let lineSchemes = [
        "dev.zed.Zed": "zed",
        "dev.zed.Zed-Preview": "zed",
        "com.microsoft.VSCode": "vscode",
        "com.microsoft.VSCodeInsiders": "vscode-insiders",
        "com.todesktop.230313mzl4w4u92": "cursor",
        "com.exafunction.windsurf": "windsurf",
        "com.vscodium": "vscodium",
    ]

    /// Nil : l'éditeur n'a pas de schéma connu.
    public static func url(opening path: String, line: Int, column: Int?, in bundleIdentifier: String) -> URL? {
        guard let scheme = lineSchemes[bundleIdentifier],
              let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        let position = column.map { ":\(line):\($0)" } ?? ":\(line)"
        return URL(string: "\(scheme)://file\(encoded)\(position)")
    }
}
