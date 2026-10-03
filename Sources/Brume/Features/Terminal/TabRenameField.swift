import BrumeCore
import SwiftUI

/// Le champ qui remplace le nom d'un onglet le temps de le renommer, prérempli avec lui.
struct TabRenameField: View {
    let title: String
    /// Ce qu'on a tapé (nil : renommage annulé), et le titre du départ : celui d'un terminal peut
    /// changer pendant qu'on renomme.
    let onFinish: (_ input: String?, _ initial: String) -> Void

    @State private var draft = ""
    @State private var initial = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(L10n.text(.renameTab), text: $draft)
            .textFieldStyle(.plain)
            .labelsHidden()
            .focused($isFocused)
            .onSubmit { onFinish(draft, initial) }
            .onExitCommand { onFinish(nil, initial) }
            // Cliquer ailleurs valide, comme dans le Finder.
            .onChange(of: isFocused) { _, focused in
                if !focused { onFinish(draft, initial) }
            }
            .onAppear {
                draft = title
                initial = title
                // Le champ vient d'entrer dans la fenêtre : le focus ne prend qu'un tour plus tard.
                DispatchQueue.main.async { isFocused = true }
            }
    }
}
