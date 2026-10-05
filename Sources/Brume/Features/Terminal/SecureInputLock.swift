import BrumeCore
import SwiftUI

/// Dans le coin du terminal tant que macOS cache sa frappe aux autres apps.
struct SecureInputLock: View {
    var body: some View {
        SystemSymbol.image("lock.fill", size: 11)
            .foregroundStyle(Ink.muted)
            .frame(width: 22, height: 22)
            .contentShape(.rect)
            .tooltip(L10n.text(.secureInput))
            .accessibilityElement()
            .accessibilityLabel(L10n.text(.secureInput))
            .padding(6)
    }
}
