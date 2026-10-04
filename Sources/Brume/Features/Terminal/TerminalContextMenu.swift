import AppKit
import BrumeCore
import GhosttyTerminal

/// Le clic droit dans un terminal, comme celui de Ghostty : copier, coller, diviser ; dans un
/// groupe, agrandir et en sortir ; fermer. Le terminal cliqué a déjà le clavier : les raccourcis
/// affichés agissent sur lui.
@MainActor
enum TerminalContextMenu {
    static func show(for pane: UUID, in workspace: TerminalWorkspace) {
        guard let state = workspace.states[pane] else { return }
        let label = { (action: ShortcutAction) in workspace.settings?.shortcutLabel(action) }
        var entries: [MenuEntry] = [
            .item(L10n.text(.copy), shortcut: "⌘C", enabled: state.surface?.hasSelection() == true) {
                _ = state.surface?.performBindingAction("copy_to_clipboard")
            },
            .item(L10n.text(.paste), shortcut: "⌘V") {
                _ = state.surface?.performBindingAction("paste_from_clipboard")
            },
            .separator,
            .item(L10n.text(.splitRight), shortcut: label(.splitRight)) { workspace.split(.horizontal, from: pane) },
            .item(L10n.text(.splitDown), shortcut: label(.splitDown)) { workspace.split(.vertical, from: pane) },
        ]
        if workspace.isSplit {
            entries.append(.item(L10n.text(.zoomSplit), shortcut: label(.zoomSplit), checked: workspace.zoomedPane == pane) { workspace.toggleZoom(pane) })
            entries.append(.item(L10n.text(.leaveGroup)) { workspace.detach(pane) })
        }
        entries.append(.separator)
        entries.append(.item(L10n.text(workspace.isSplit ? .closeTerminal : .closeTab), shortcut: label(.closeTerminal)) { workspace.closePane(pane) })
        PopupMenu.show(entries, at: NSEvent.mouseLocation)
    }
}
