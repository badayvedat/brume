import Foundation
import Observation
import Sparkle

/// Les mises à jour, par Sparkle. Il garde lui-même ses deux préférences dans les défauts de
/// l'app : les interrupteurs les lisent et les écrivent chez lui, pas dans `settings.json`.
@MainActor @Observable
final class UpdaterStore {
    private(set) var canCheck = false
    /// Faux tant que la recherche automatique est coupée : l'installation en dépend.
    private(set) var allowsAutomaticInstall = false

    var checksAutomatically = false {
        didSet { if updater.automaticallyChecksForUpdates != checksAutomatically { updater.automaticallyChecksForUpdates = checksAutomatically } }
    }

    var installsAutomatically = false {
        didSet { if updater.automaticallyDownloadsUpdates != installsAutomatically { updater.automaticallyDownloadsUpdates = installsAutomatically } }
    }

    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"

    // Pas de `SPUStandardUpdaterController` : il impose les alertes en `runModal` de Sparkle.
    @ObservationIgnored private let updater = SPUUpdater(
        hostBundle: .main,
        applicationBundle: .main,
        userDriver: UpdaterUserDriver(hostBundle: .main, delegate: nil),
        delegate: nil
    )
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []

    init() {
        // Hors de Brume.app (sans flux ni clé dans l'Info.plist), Sparkle refuse de démarrer :
        // pas de mises à jour, le bouton reste grisé.
        do {
            try updater.start()
        } catch {
            NSLog("Sparkle n'a pas démarré : \(error.localizedDescription)")
        }
        // Sparkle change aussi ces valeurs de son côté (case de sa fenêtre de mise à jour) :
        // les interrupteurs suivent.
        observations = [
            updater.observe(\.canCheckForUpdates, options: [.initial]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.canCheck = updater.canCheckForUpdates }
            },
            updater.observe(\.automaticallyChecksForUpdates, options: [.initial]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.checksAutomatically = updater.automaticallyChecksForUpdates }
            },
            updater.observe(\.automaticallyDownloadsUpdates, options: [.initial]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.installsAutomatically = updater.automaticallyDownloadsUpdates }
            },
            updater.observe(\.allowsAutomaticUpdates, options: [.initial]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.allowsAutomaticInstall = updater.allowsAutomaticUpdates }
            },
        ]
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
