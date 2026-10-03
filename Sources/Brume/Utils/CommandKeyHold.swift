import AppKit
import SwiftUI

/// Cmd tenu seul : de quoi montrer les numéros des onglets. Le délai évite qu'ils
/// clignotent à chaque Cmd+C ; une fois affichés, ils restent jusqu'au relâchement de Cmd,
/// même en enchaînant Cmd+1, Cmd+2...
@MainActor @Observable
final class CommandKeyHold {
    private(set) var isHeld = false
    @ObservationIgnored nonisolated(unsafe) private var monitor: Any?
    @ObservationIgnored nonisolated(unsafe) private var resignObserver: NSObjectProtocol?
    @ObservationIgnored private var pending: DispatchWorkItem?

    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                if event.type == .keyDown {
                    self.pending?.cancel()
                } else {
                    self.update(held: event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command)
                }
            }
            return event
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.update(held: false) }
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
    }

    private func update(held: Bool) {
        pending?.cancel()
        guard held else {
            isHeld = false
            return
        }
        let work = DispatchWorkItem { [weak self] in self?.isHeld = true }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }
}
