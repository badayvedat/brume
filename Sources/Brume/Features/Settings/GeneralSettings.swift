import BrumeCore
import SwiftUI

struct GeneralSettings: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: 32) {
            SettingsGroup(title: L10n.text(.startup)) {
                SettingsRow(title: L10n.text(.restoreTabs), hint: L10n.text(.restoreTabsHint), isLast: true) {
                    Switch(label: L10n.text(.restoreTabs), isOn: $settings.restoresSession)
                }
            }
            SettingsGroup(title: L10n.text(.interface)) {
                SettingsRow(title: L10n.text(.language), hint: L10n.text(.languageHint), isLast: true) {
                    Segmented(options: Language.allCases.map { ($0, $0.name) }, selection: $settings.language)
                }
            }
        }
    }
}
