import BrumeCore
import SwiftUI

struct GeneralSettings: View {
    let workspace: TerminalWorkspace

    @Environment(SettingsStore.self) private var settings
    @Environment(UpdaterStore.self) private var updater

    var body: some View {
        @Bindable var settings = settings
        @Bindable var updater = updater
        VStack(alignment: .leading, spacing: 32) {
            SettingsGroup(title: L10n.text(.startup)) {
                SettingsRow(title: L10n.text(.restoreTabs), hint: L10n.text(.restoreTabsHint)) {
                    Switch(label: L10n.text(.restoreTabs), isOn: $settings.restoresSession)
                }
                SettingsRow(title: L10n.text(.resetWindow), hint: hint(.resetWindowHint, shortcut: .resetWindow), isLast: true) {
                    Button("\(L10n.text(.reset))…", action: workspace.askReset)
                        .buttonStyle(.secondary)
                }
            }
            SettingsGroup(title: L10n.text(.input)) {
                SettingsRow(title: L10n.text(.historySuggestions), hint: L10n.text(.historySuggestionsHint)) {
                    Switch(label: L10n.text(.historySuggestions), isOn: $settings.suggestsHistory)
                }
                SettingsRow(title: L10n.text(.completion), hint: L10n.text(.completionHint), isLast: true) {
                    Switch(label: L10n.text(.completion), isOn: $settings.completesCommands)
                }
            }
            SettingsGroup(title: L10n.text(.interface)) {
                SettingsRow(title: L10n.text(.verticalTabs), hint: hint(.verticalTabsHint, shortcut: .verticalTabs)) {
                    Switch(label: L10n.text(.verticalTabs), isOn: $settings.verticalTabs.isOn)
                }
                SettingsRow(title: L10n.text(.language), hint: L10n.text(.languageHint), isLast: true) {
                    Segmented(label: L10n.text(.language), options: Language.allCases.map { ($0, $0.name) }, selection: $settings.language)
                }
            }
            SettingsGroup(title: L10n.text(.updates)) {
                SettingsRow(title: L10n.text(.currentVersion), hint: "Brume \(updater.version)") {
                    Button(L10n.text(.checkForUpdates), action: updater.checkForUpdates)
                        .buttonStyle(.secondary)
                        .disabled(!updater.canCheck)
                }
                SettingsRow(title: L10n.text(.checkAutomatically), hint: L10n.text(.checkAutomaticallyHint)) {
                    Switch(label: L10n.text(.checkAutomatically), isOn: $updater.checksAutomatically)
                }
                SettingsRow(title: L10n.text(.installAutomatically), hint: L10n.text(.installAutomaticallyHint), isLast: true) {
                    Switch(label: L10n.text(.installAutomatically), isOn: $updater.installsAutomatically)
                }
                .disabled(!updater.allowsAutomaticInstall)
                .opacity(updater.allowsAutomaticInstall ? 1 : 0.4)
                .animation(Ink.feedback, value: updater.allowsAutomaticInstall)
            }
        }
    }

    private func hint(_ key: TextKey, shortcut action: ShortcutAction) -> String {
        let hint = L10n.text(key)
        guard let shortcut = settings.shortcutLabel(action) else { return hint }
        return "\(hint) \(L10n.text(.shortcutHint, shortcut))"
    }
}
