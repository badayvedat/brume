import AppKit
import BrumeCore
import SwiftUI

/// Les raccourcis changés dans les réglages, tels que les menus, les infobulles et les numéros des
/// onglets les montrent.
extension SettingsStore {
    func keyboardShortcut(_ action: ShortcutAction) -> KeyboardShortcut? {
        shortcuts[action].map { KeyboardLayout.keyboardShortcut($0, isCustom: shortcuts.isCustom(action)) }
    }

    /// ⌘1 à ⌘8, et ⌘9 pour le dernier onglet, avec les touches de modification choisies.
    func tabShortcut(_ number: Int) -> KeyboardShortcut? {
        shortcuts[.selectTab].map { KeyboardLayout.keyboardShortcut(Shortcut("\(number)", $0.modifiers), isCustom: false) }
    }

    /// Les touches qui, tenues seules, montrent les numéros des onglets.
    var tabNumberModifiers: NSEvent.ModifierFlags? {
        shortcuts[.selectTab].map { KeyboardLayout.modifierFlags($0.modifiers) }
    }

    func shortcutLabel(_ action: ShortcutAction) -> String? {
        guard let shortcut = shortcuts[action] else { return nil }
        return action == .selectTab ? "\(shortcut.modifiersLabel)1–9" : KeyboardLayout.label(shortcut)
    }

    func shortcutIssue(_ shortcut: Shortcut, for action: ShortcutAction) -> ShortcutIssue? {
        shortcuts.issue(assigning: shortcut, to: action, normalize: KeyboardLayout.normalized)
    }

    /// `replacing` : l'action qui avait déjà la combinaison la perd.
    func setShortcut(_ shortcut: Shortcut?, for action: ShortcutAction, replacing other: ShortcutAction? = nil) {
        var shortcuts = shortcuts
        if let other { shortcuts.set(nil, for: other) }
        shortcuts.set(shortcut, for: action, normalize: KeyboardLayout.normalized)
        self.shortcuts = shortcuts
    }
}
