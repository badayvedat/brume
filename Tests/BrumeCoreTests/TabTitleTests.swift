import BrumeCore
import Testing

struct TabTitleTests {
    @Test func newNameIsTrimmed() {
        #expect(TabTitle.renamed(input: "  serveur ", displayed: "~", current: nil) == "serveur")
    }

    @Test func unchangedFieldKeepsTheAutomaticTitle() {
        #expect(TabTitle.renamed(input: "~/Documents", displayed: "~/Documents", current: nil) == nil)
    }

    @Test func unchangedFieldKeepsTheChosenName() {
        #expect(TabTitle.renamed(input: "serveur", displayed: "serveur", current: "serveur") == "serveur")
    }

    @Test func emptyFieldGoesBackToTheAutomaticTitle() {
        #expect(TabTitle.renamed(input: "  ", displayed: "serveur", current: "serveur") == nil)
    }
}
