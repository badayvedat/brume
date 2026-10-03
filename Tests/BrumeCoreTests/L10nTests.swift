import BrumeCore
import Testing

struct L10nTests {
    @Test func everyKeyHasATextInEveryLanguage() {
        for language in Language.allCases {
            for key in TextKey.allCases {
                #expect(!key.text(in: language).isEmpty)
            }
        }
    }

    @Test @MainActor func interfaceFollowsTheChosenLanguage() {
        #expect(L10n.text(.cancel) == "Annuler")
        L10n.language = .english
        defer { L10n.language = .french }
        #expect(L10n.text(.cancel) == "Cancel")
    }
}
