import BrumeCore
import SwiftUI

/// Le champ qui remplace le nom d'un onglet le temps de le renommer, prérempli avec lui.
struct TabRenameField: View {
    let title: String
    /// Nil : renommage annulé.
    let onFinish: (String?) -> Void

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(L10n.text(.renameTab), text: $draft)
            .textFieldStyle(.plain)
            .labelsHidden()
            .focused($isFocused)
            .onSubmit { onFinish(draft) }
            .onExitCommand { onFinish(nil) }
            // Cliquer ailleurs valide, comme dans le Finder.
            .onChange(of: isFocused) { _, focused in
                if !focused { onFinish(draft) }
            }
            .onAppear {
                draft = title
                // Le champ vient d'entrer dans la fenêtre : le focus ne prend qu'un tour plus tard.
                DispatchQueue.main.async { isFocused = true }
            }
    }
}
