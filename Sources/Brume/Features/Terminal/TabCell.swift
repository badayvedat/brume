import BrumeCore
import GhosttyTerminal
import SwiftUI

struct TabCell: View {
    /// Le terminal de l'onglet, dont il affiche le titre.
    @ObservedObject var state: TerminalViewState
    let id: UUID
    let workspace: TerminalWorkspace
    let isDragging: Bool
    /// Le chiffre de son raccourci, montré tant que Cmd est tenu.
    let number: Int?

    @State private var isHovered = false
    @State private var draft = ""
    @Environment(\.accent) private var accent
    @FocusState private var isFieldFocused: Bool

    /// Affiché dans sa zone.
    private var isSelected: Bool {
        workspace.layout.isShown(id)
    }

    /// Le trait d'accent ne va qu'à l'onglet qui reçoit le clavier.
    private var isFocused: Bool {
        workspace.focusedID == id
    }

    private var isRenaming: Bool {
        workspace.renamingID == id
    }

    var body: some View {
        HStack(spacing: 4) {
            // Comme Muxy : l'icône terminal, et à sa place le numéro tant que Cmd est tenu.
            Group {
                if let number {
                    Text("\(number)")
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(accent.color, in: .rect(cornerRadius: 4))
                } else {
                    SystemSymbol.image("apple.terminal", size: 12)
                        .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
                }
            }
            .frame(width: 16, height: 16)
            .padding(.trailing, 4)
            .accessibilityHidden(true)
            Group {
                if isRenaming {
                    renameField
                } else {
                    Text(title)
                        .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
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
                if isFocused {
                    (workspace.color(of: id)?.color ?? accent.color).frame(height: 2)
                }
            }
            .clipShape(.rect(cornerRadius: 6))
        }
        .overlay {
            if isRenaming {
                RoundedRectangle(cornerRadius: 6).strokeBorder(accent.color, lineWidth: 1)
            }
        }
        .contentShape(.rect(cornerRadius: 6))
        .onTapGesture { workspace.focus(id) }
        // En plus du clic simple : le double-clic ne retarde pas la sélection.
        .simultaneousGesture(TapGesture(count: 2).onEnded(startRenaming))
        .onRightClick { PopupMenu.show(menu, at: $0) }
        .accessibilityAction(.default) { workspace.focus(id) }
        .accessibilityAction(named: L10n.text(.renameTab), startRenaming)
        // Le menu du clic droit est une fenêtre à part, hors de portée de VoiceOver.
        .accessibilityAction(named: L10n.text(.resetTabName)) { workspace.resetTitle(id) }
        .accessibilityAction(named: L10n.text(.closeOtherTabs)) { workspace.closeOthers(of: id) }
        .accessibilityAction(named: L10n.text(.closeTabsToTheRight)) { workspace.closeRight(of: id) }
        .accessibilityActions {
            ForEach(TabColor.allCases, id: \.self) { color in
                Button("\(L10n.text(.tabColor)) : \(color.name)") { workspace.setColor(color, of: id) }
            }
            Button(L10n.text(.noColor)) { workspace.setColor(nil, of: id) }
        }
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

    private var menu: [MenuEntry] {
        // Sans raccourcis affichés : ceux du menu agissent sur l'onglet actif, pas sur celui cliqué.
        var entries: [MenuEntry] = [.item(L10n.text(.renameTab), run: startRenaming)]
        if workspace.title(of: id) != nil {
            entries.append(.item(L10n.text(.resetTabName)) { workspace.resetTitle(id) })
        }
        let current = workspace.color(of: id)
        let colors: [MenuEntry] = TabColor.allCases.map { color in
            .item(color.name, swatch: color.color, checked: current == color) { workspace.setColor(color, of: id) }
        }
        entries.append(.submenu(L10n.text(.tabColor), colors + [.separator, .item(L10n.text(.noColor), checked: current == nil) {
            workspace.setColor(nil, of: id)
        }]))
        entries.append(.separator)
        entries.append(.item(L10n.text(.closeTab), run: close))
        entries.append(.item(L10n.text(.closeOtherTabs), enabled: !workspace.layout.tabs(besides: id).isEmpty) {
            workspace.closeOthers(of: id)
        })
        entries.append(.item(L10n.text(.closeTabsToTheRight), enabled: !workspace.layout.tabs(rightOf: id).isEmpty) {
            workspace.closeRight(of: id)
        })
        return entries
    }

    private var title: String {
        workspace.title(of: id) ?? (state.title.isEmpty ? L10n.text(.terminal) : state.title)
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
        workspace.startRenaming(id)
    }

    /// Nil : annulé.
    private func finishRenaming(_ input: String?) {
        workspace.finishRenaming(id, input: input, displayed: title)
    }

    private func close() {
        workspace.close(id)
    }

    /// Une couleur choisie teinte tout l'onglet, plus fort quand il est affiché.
    private var background: Color {
        if let color = workspace.color(of: id)?.color {
            return color.opacity(isSelected ? 0.28 : isHovered ? 0.18 : 0.12)
        }
        if isSelected { return Ink.selection }
        return isHovered ? Ink.hover : .clear
    }
}

private struct CloseButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("xmark", size: 9, weight: .bold)
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .frame(width: 18, height: 18)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.closeTab))
        .tooltip(L10n.text(.closeTab))
        .onHover { isHovered = $0 }
    }
}
