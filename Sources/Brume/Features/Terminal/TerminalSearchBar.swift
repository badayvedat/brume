import BrumeCore
import SwiftUI

/// Barre de recherche d'un volet, calquée sur celle de Ghostty.
struct TerminalSearchBar: View {
    @Bindable var search: TerminalSearch
    let count: SearchCount
    let onLeave: () -> Void
    let onClose: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField(L10n.text(.findPlaceholder), text: $search.needle)
                .textFieldStyle(.plain)
                .frame(width: 180)
                .padding(.leading, 8)
                .padding(.trailing, 50)
                .padding(.vertical, 6)
                .background(Ink.selection, in: .rect(cornerRadius: 6))
                .overlay(alignment: .trailing) {
                    if let label = count.label {
                        Text(label)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Ink.muted)
                            .padding(.trailing, 8)
                    }
                }
                .accessibilityValue(count.label ?? "")
                .focused($isFieldFocused)
                .onSubmit { search.next() }
                .onKeyPress(.return, phases: .down) { press in
                    guard press.modifiers.contains(.shift) else { return .ignored }
                    search.previous()
                    return .handled
                }
                // Comme Ghostty : Échap rend la main au terminal, puis ferme si le champ est vide.
                .onExitCommand {
                    search.needle.isEmpty ? onClose() : onLeave()
                }

            SearchButton(icon: "chevron.up", label: L10n.text(.findNext), action: search.next)
            SearchButton(icon: "chevron.down", label: L10n.text(.findPrevious), action: search.previous)
            SearchButton(icon: "xmark", label: L10n.text(.closeFind), action: onClose)
        }
        .padding(8)
        .background(.background, in: .rect(cornerRadius: 8))
        .shadow(radius: 4)
        .padding(8)
        // Comme Ghostty : le champ vient d'entrer dans la fenêtre, le focus ne prend qu'un tour plus tard.
        .onAppear { focusField() }
        .onChange(of: search.focusRequest) { focusField() }
    }

    private func focusField() {
        DispatchQueue.main.async { isFieldFocused = true }
    }
}

private struct SearchButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image(icon)
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .padding(.horizontal, 2)
                .frame(height: 26)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
        .onHover { isHovered = $0 }
    }
}
