import BrumeCore
import SwiftUI

/// Une confirmation posée sur la fenêtre, à la place d'une alerte macOS : les coins et le fondu des
/// menus maison, sur le fond du thème (le verre des menus laisserait voir le bureau derrière la
/// fenêtre). Entrée confirme, Échap ou un clic à côté annule.
struct ConfirmationCard: View {
    let title: String
    let message: String
    /// Le fond de la fenêtre, pour que la carte soit du même thème que la page.
    let background: Color
    /// Une conséquence à ne pas manquer, à la couleur des limites dépassées.
    var warning: String?
    let confirmLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var isShown = false
    /// Entrée puis Échap pendant le fondu : seul le premier compte.
    @State private var isClosing = false

    var body: some View {
        ZStack {
            Color.black.opacity(isShown ? 0.25 : 0)
                .contentShape(.rect)
                .onTapGesture { close(then: onCancel) }
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Ink.text)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .foregroundStyle(Ink.white(0.7))
                if let warning {
                    Text(warning).foregroundStyle(Ink.warning)
                }
                HStack(spacing: 8) {
                    Spacer()
                    Button(L10n.text(.cancel)) { close(then: onCancel) }
                        .buttonStyle(.secondary)
                        .keyboardShortcut(.cancelAction)
                    Button(confirmLabel) { close(then: onConfirm) }
                        .buttonStyle(.primary)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 8)
            }
            .font(.system(size: 12))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(width: 380)
            .background {
                ZStack {
                    background
                    Ink.white(0.04)
                }
            }
            .clipShape(.rect(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.border) }
            .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .scaleEffect(isShown ? 1 : 0.96)
            .opacity(isShown ? 1 : 0)
        }
        .ignoresSafeArea()
        .onAppear { withAnimation(Ink.open) { isShown = true } }
    }

    private func close(then action: @escaping () -> Void) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(Ink.feedback) { isShown = false } completion: { action() }
    }
}
