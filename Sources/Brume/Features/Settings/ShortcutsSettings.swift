import BrumeCore
import SwiftUI

struct ShortcutsSettings: View {
    @Environment(SettingsStore.self) private var settings
    @State private var recorder = ShortcutRecorder()

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(ShortcutCategory.allCases, id: \.self) { category in
                SettingsGroup(title: L10n.text(category.title)) {
                    ForEach(category.actions, id: \.self) { action in
                        ShortcutRow(action: action, recorder: recorder, isLast: action == category.actions.last)
                    }
                }
            }
            Button(L10n.text(.restoreAllShortcuts)) {
                recorder.stop()
                settings.shortcuts.resetAll()
            }
            .buttonStyle(.secondary)
            .disabled(!settings.shortcuts.hasCustom)
        }
        .onDisappear { recorder.stop() }
    }
}

/// Le nom de l'action, et à droite son raccourci : un clic, puis la nouvelle combinaison. Ce qui
/// coince s'affiche dessous.
private struct ShortcutRow: View {
    let action: ShortcutAction
    let recorder: ShortcutRecorder
    let isLast: Bool

    @Environment(SettingsStore.self) private var settings

    private var isRecording: Bool {
        recorder.action == action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text(action.title))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.text)
                    if let hint = action.hint {
                        Text(L10n.text(hint))
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.hint)
                    }
                }
                Spacer(minLength: 16)
                resetButton
                ShortcutField(text: fieldText, isPlaceholder: isPlaceholder, isRecording: isRecording, label: L10n.text(action.title)) {
                    recorder.start(action, in: settings)
                }
            }
            if isRecording, let attempt = recorder.attempt {
                ShortcutIssueView(text: message(attempt), action: confirmLabel(attempt.issue), onCancel: recorder.stop, onConfirm: recorder.confirm)
                    .transition(.accordion(.vertical))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .animation(Ink.slide, value: isRecording ? recorder.attempt?.shortcut : nil)
        .overlay(alignment: .bottom) {
            if !isLast { Ink.rowRule.frame(height: 1) }
        }
    }

    /// Toujours à sa place, effacé tant que le raccourci est celui par défaut : rien ne bouge.
    private var resetButton: some View {
        let isCustom = settings.shortcuts.isCustom(action)
        return ResetButton(label: L10n.text(.restoreDefault)) { recorder.reset(action, in: settings) }
            .opacity(isCustom && !isRecording ? 1 : 0)
            .disabled(!isCustom || isRecording)
            .accessibilityHidden(!isCustom)
            .animation(Ink.feedback, value: isCustom)
    }

    private var fieldText: String {
        guard isRecording else { return settings.shortcutLabel(action) ?? L10n.text(.noShortcut) }
        return recorder.attempt.map { label(of: $0.shortcut) } ?? L10n.text(.pressShortcut)
    }

    /// « Aucun », ou « Tapez le raccourci » tant que rien n'est tapé.
    private var isPlaceholder: Bool {
        isRecording ? recorder.attempt == nil : settings.shortcuts[action] == nil
    }

    private func label(of shortcut: Shortcut) -> String {
        action == .selectTab ? "\(shortcut.modifiersLabel)1–9" : KeyboardLayout.label(shortcut)
    }

    private func message(_ attempt: Attempt) -> String {
        let shortcut = label(of: attempt.shortcut)
        switch attempt.issue {
        case .needsModifier: return L10n.text(.shortcutNeedsModifier)
        case .needsDigit: return L10n.text(.shortcutNeedsDigit)
        case let .reserved(title): return L10n.text(.shortcutInUse, shortcut, L10n.text(title))
        case let .taken(other): return L10n.text(.shortcutInUse, shortcut, L10n.text(other.title))
        case let .terminal(title?): return L10n.text(.shortcutInTerminal, shortcut, L10n.text(title))
        case .terminal(nil): return L10n.text(.shortcutWithoutCommand, shortcut)
        }
    }

    private func confirmLabel(_ issue: ShortcutIssue) -> String? {
        switch issue {
        case .taken: L10n.text(.replace)
        case .terminal: L10n.text(.useAnyway)
        default: nil
        }
    }

    private typealias Attempt = ShortcutRecorder.Attempt
}

/// Le raccourci dans une case bordée, à l'accent pendant qu'on le tape.
private struct ShortcutField: View {
    let text: String
    let isPlaceholder: Bool
    let isRecording: Bool
    let label: String
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.accent) private var accent

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: isPlaceholder ? .regular : .medium))
                .foregroundStyle(isPlaceholder ? Ink.hint : isRecording ? Ink.text : Ink.white(0.8))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(minWidth: 120, minHeight: 28)
                .background(isRecording ? Ink.selection : Ink.hover, in: .rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isRecording ? accent.color : isHovered ? Ink.white(0.2) : Ink.border)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
        .animation(Ink.feedback, value: isRecording)
        .accessibilityLabel("\(L10n.text(.changeShortcut)), \(label)")
        .accessibilityValue(text)
    }
}

private struct ResetButton: View {
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("arrow.counterclockwise", size: 11, weight: .medium)
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .frame(width: 28, height: 28)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 6))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .tooltip(label)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }
}

/// Ce qui empêche la combinaison, ou ce qu'elle coûte, avec de quoi passer outre.
private struct ShortcutIssueView: View {
    let text: String
    let action: String?
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            SystemSymbol.image("exclamationmark.triangle.fill", size: 11)
                .foregroundStyle(Ink.warning)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            if let action {
                Button(L10n.text(.cancel), action: onCancel)
                    .buttonStyle(.secondary)
                Button(action, action: onConfirm)
                    .buttonStyle(.secondary)
            }
        }
        // Tapé au clavier, le message n'a pas le focus : VoiceOver le lit quand même.
        .onChange(of: text, initial: true) { AccessibilityNotification.Announcement(text).post() }
    }
}
