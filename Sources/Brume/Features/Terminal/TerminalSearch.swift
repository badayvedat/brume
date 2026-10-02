import BrumeCore
import GhosttyTerminal
import Observation

/// La recherche ouverte dans un volet. Le moteur cherche et surligne lui-même :
/// on ne lui envoie que le texte et les déplacements.
@MainActor @Observable
final class TerminalSearch {
    var needle: String {
        didSet {
            if needle != oldValue { schedule() }
        }
    }

    /// Change à chaque demande de focus du champ, même s'il est déjà ouvert.
    private(set) var focusRequest = 0

    private let state: TerminalViewState
    private var pending: Task<Void, Never>?

    init(state: TerminalViewState, needle: String) {
        self.state = state
        self.needle = needle
        if !needle.isEmpty { send() }
    }

    func focusField() {
        focusRequest += 1
    }

    func next() {
        state.surface?.performBindingAction("navigate_search:next")
    }

    func previous() {
        state.surface?.performBindingAction("navigate_search:previous")
    }

    func end() {
        pending?.cancel()
        state.surface?.performBindingAction("end_search")
    }

    private func schedule() {
        pending?.cancel()
        let delay = SearchCount.delay(for: needle)
        guard delay > .zero else { return send() }
        pending = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.send()
        }
    }

    private func send() {
        state.surface?.performBindingAction("search:\(needle)")
    }
}
