import Foundation

/// fastfetch, embarqué dans `Contents/MacOS` (`build-app.sh`) : l'écran de démarrage des terminaux et
/// son aperçu dans les réglages.
enum Fastfetch {
    static let executable = Bundle.main.url(forAuxiliaryExecutable: "fastfetch")

    /// La sortie colorée, comme dans un terminal. Nil sans fastfetch, s'il échoue ou s'il dépasse
    /// trois secondes.
    static func output(config: URL) async -> String? {
        guard let executable else { return nil }
        // Sur une file à part : la lecture bloque son fil jusqu'à la fin de fastfetch.
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                // Lancé par zsh comme dans un terminal : lancé par l'app, fastfetch prendrait Brume
                // pour le shell. Une commande après lui empêche zsh de se remplacer par fastfetch.
                process.executableURL = URL(filePath: "/bin/zsh")
                process.arguments = ["-fc", "\"$0\" --config \"$1\" --pipe false; exit $?", executable.path, config.path]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                guard (try? process.run()) != nil else { return continuation.resume(returning: nil) }
                let pid = process.processIdentifier
                let timeout = DispatchWorkItem { kill(pid, SIGTERM) }
                DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: timeout)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                timeout.cancel()
                continuation.resume(returning: process.terminationStatus == 0 ? String(decoding: data, as: UTF8.self) : nil)
            }
        }
    }
}
