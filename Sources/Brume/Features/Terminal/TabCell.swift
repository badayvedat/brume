import BrumeCore
import GhosttyTerminal
import SwiftUI

struct TabCell: View {
    /// Le terminal actif de l'onglet, dont il affiche le titre.
    @ObservedObject var state: TerminalViewState
    let workspace: TerminalWorkspace
    let tabs: TerminalTabs
    let isDragging: Bool
    let showsNumber: Bool

    @State private var isHovered = false
    @State private var draft = ""
    @FocusState private var isFieldFocused: Bool

    private var isSelected: Bool {
        workspace === tabs.selected
    }

    private var isRenaming: Bool {
        tabs.renamingID == workspace.id
    }

    var body: some View {
        HStack(spacing: 4) {
            if showsNumber, let number = tabs.shortcutNumber(of: workspace.id) {
                Text("\(number)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(Color.accentColor, in: .rect(cornerRadius: 4))
                    .padding(.trailing, 3)
                    .accessibilityHidden(true)
            }
            Group {
                if isRenaming {
                    renameField
                } else {
                    Text(title)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            CloseButton(action: close)
                .opacity(isSelected || isHovered ? 1 : 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .frame(height: 26)
        // Le trait d'accent court sur toute la largeur et suit l'arrondi des coins.
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                background
                if isSelected {
                    Color.accentColor.frame(height: 2)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
        }
        .overlay {
            if isRenaming {
                RoundedRectangle(cornerRadius: 8).strokeBorder(Color.accentColor, lineWidth: 1)
            }
        }
        .contentShape(.rect(cornerRadius: 8))
        .onTapGesture { tabs.select(workspace.id) }
        // En plus du clic simple : le double-clic ne retarde pas la sélection.
        .simultaneousGesture(TapGesture(count: 2).onEnded(startRenaming))
        .contextMenu {
            Button(L10n.text(.renameTab), action: startRenaming)
            if workspace.customTitle != nil {
                Button(L10n.text(.resetTabName)) { tabs.resetTitle(workspace.id) }
            }
            Divider()
            Button(L10n.text(.closeTab), action: close)
        }
        .accessibilityAction(.default) { tabs.select(workspace.id) }
        .accessibilityAction(named: L10n.text(.renameTab), startRenaming)
        // Pendant un glisser, les onglets passent sous la souris en changeant de place :
        // sans ça, leur croix clignote au passage.
        .onHover { hovering in
            if !isDragging { isHovered = hovering }
        }
        .onChange(of: isDragging) { _, dragging in
            if dragging { isHovered = false }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: L10n.text(.closeTab), close)
    }

    private var title: String {
        workspace.customTitle ?? (state.title.isEmpty ? L10n.text(.terminal) : state.title)
    }

    private var renameField: some View {
        TextField(L10n.text(.renameTab), text: $draft)
            .textFieldStyle(.plain)
            .labelsHidden()
            .focused($isFieldFocused)
            .onSubmit { finishRenaming(draft) }
            .onExitCommand { finishRenaming(nil) }
            // Cliquer ailleurs valide, comme dans le Finder.
            .onChange(of: isFieldFocused) { _, focused in
                if !focused { finishRenaming(draft) }
            }
            .onAppear {
                draft = title
                // Le champ vient d'entrer dans la fenêtre : le focus ne prend qu'un tour plus tard.
                DispatchQueue.main.async { isFieldFocused = true }
            }
    }

    private func startRenaming() {
        tabs.startRenaming(workspace.id)
    }

    /// Nil : annulé.
    private func finishRenaming(_ input: String?) {
        tabs.finishRenaming(workspace.id, input: input, displayed: title)
    }

    private func close() {
        tabs.close(workspace.id)
    }

    private var background: Color {
        if isSelected { return .primary.opacity(0.12) }
        return isHovered ? .primary.opacity(0.06) : .clear
    }
}

private struct CloseButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("xmark", size: 9, weight: .bold)
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 18, height: 18)
                .background(isHovered ? Color.primary.opacity(0.12) : .clear, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.closeTab))
        .tooltip(L10n.text(.closeTab))
        .onHover { isHovered = $0 }
    }
}
