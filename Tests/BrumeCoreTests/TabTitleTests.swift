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

    @Test func homeFolderIsWrittenWithATilde() {
        #expect(TabTitle.folder("/Users/alice", home: "/Users/alice") == "~")
        #expect(TabTitle.folder("/Users/alice/code", home: "/Users/alice") == "~/code")
        #expect(TabTitle.folder("/Users/alice2/code", home: "/Users/alice") == "/Users/alice2/code")
    }

    @Test func shortTitleKeepsTheLastFolder() {
        #expect(TabTitle.short("~/Documents/code/brume") == "brume")
        #expect(TabTitle.short("/tmp") == "tmp")
        #expect(TabTitle.short("~") == "~")
        #expect(TabTitle.short("/") == "/")
        #expect(TabTitle.short("npm run dev") == "npm run dev")
    }
}
