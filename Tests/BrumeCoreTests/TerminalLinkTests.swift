import BrumeCore
import Testing

struct TerminalLinkTests {
    private func link(_ text: String, from directory: String? = "/Users/me/projet") -> TerminalLink? {
        TerminalLink(text, from: directory, home: "/Users/me")
    }

    @Test func lineAndColumnOfAnError() {
        #expect(link("src/App.vue:42:5") == .file(path: "/Users/me/projet/src/App.vue", line: 42, column: 5))
        #expect(link("src/App.vue:42") == .file(path: "/Users/me/projet/src/App.vue", line: 42, column: nil))
        #expect(link("src/App.vue:42:5:") == .file(path: "/Users/me/projet/src/App.vue", line: 42, column: 5))
        #expect(link("src/App.vue") == .file(path: "/Users/me/projet/src/App.vue", line: nil, column: nil))
    }

    @Test func relativePathsStartFromTheTerminalFolder() {
        #expect(link("./a.ts:3") == .file(path: "/Users/me/projet/a.ts", line: 3, column: nil))
        #expect(link("../autre/b.ts") == .file(path: "/Users/me/autre/b.ts", line: nil, column: nil))
        #expect(link("src/a.ts", from: nil) == nil)
    }

    @Test func absoluteAndHomePaths() {
        #expect(link("/etc/hosts:1", from: nil) == .file(path: "/etc/hosts", line: 1, column: nil))
        #expect(link("~/notes/a.md:7:2") == .file(path: "/Users/me/notes/a.md", line: 7, column: 2))
        #expect(link("~") == .file(path: "/Users/me", line: nil, column: nil))
        #expect(link("/Users/me/Mes documents/a b.txt") == .file(path: "/Users/me/Mes documents/a b.txt", line: nil, column: nil))
    }

    @Test func urlsAreNotPaths() {
        for url in ["https://brume.app/a:1", "http://localhost:3000/", "mailto:moi@brume.app", "file:///tmp/a.txt", "ssh://serveur"] {
            #expect(link(url) == .url)
        }
        #expect(link("Makefile:12") == .file(path: "/Users/me/projet/Makefile", line: 12, column: nil))
    }

    @Test func emptyTextIsNothing() {
        #expect(link("  ") == nil)
    }
}
