import Foundation

/// Ce qu'on ouvre dans Brume (glissé sur l'icône du Dock, `open -a Brume`, service du Finder),
/// réduit aux dossiers où ouvrir un onglet.
public enum OpenedFolders {
    /// Un fichier donne son dossier. Ce qui n'est pas sur le disque est écarté, et un dossier ne
    /// vient qu'une fois, dans l'ordre reçu.
    public static func paths(for urls: [URL]) -> [String] {
        var seen: Set<String> = []
        return urls.compactMap { url in
            guard url.isFileURL else { return nil }
            let path = url.standardizedFileURL.path
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }
            let folder = isDirectory.boolValue ? path : (path as NSString).deletingLastPathComponent
            return seen.insert(folder).inserted ? folder : nil
        }
    }
}
