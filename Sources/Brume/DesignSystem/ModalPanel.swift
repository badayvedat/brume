import BrumeCore
import SwiftUI

/// Un panneau par-dessus la page, du fond de la fenêtre, comme les modales de Monocode : il arrive
/// en fondu en remontant un peu, sans voile sur la page. Échap, la croix ou un clic à côté ferment.
struct ModalPanel<Content: View>: View {
    let title: String
    /// Le fond de la fenêtre, pour que le panneau soit du même thème que la page.
    let background: Color
    var maxWidth: CGFloat = 752
    let onClose: () -> Void
    @ViewBuilder let content: Content

    @State private var isShown = false

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: close)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Ink.text)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button(action: close) {
                        SystemSymbol.image("xmark", size: 9, weight: .bold)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel(L10n.text(.close))
                }
                content
            }
            .padding(16)
            .frame(maxWidth: maxWidth)
            .background {
                ZStack {
                    background
                    Ink.white(0.04)
                }
                .clipShape(.rect(cornerRadius: 14))
            }
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.border) }
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .padding(32)
            .scaleEffect(isShown ? 1 : 0.98)
            .offset(y: isShown ? 0 : 8)
            .opacity(isShown ? 1 : 0)
        }
        .onAppear { withAnimation(Ink.open) { isShown = true } }
    }

    private func close() {
        withAnimation(Ink.feedback) { isShown = false } completion: { onClose() }
    }
}
