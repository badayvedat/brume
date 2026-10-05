import BrumeCore
import Testing

struct EditorsTests {
    @Test func eachEditorIsListedOnce() {
        #expect(Set(Editors.bundleIdentifiers).count == Editors.bundleIdentifiers.count)
    }

    @Test func editorOpensTheFileAtTheLine() {
        let vscode = Editors.url(opening: "/Users/me/src/App.vue", line: 42, column: 5, in: "com.microsoft.VSCode")
        #expect(vscode?.absoluteString == "vscode://file/Users/me/src/App.vue:42:5")
        let zed = Editors.url(opening: "/Users/me/Mes documents/é.ts", line: 3, column: nil, in: "dev.zed.Zed")
        #expect(zed?.absoluteString == "zed://file/Users/me/Mes%20documents/%C3%A9.ts:3")
    }

    @Test func editorWithoutSchemeGetsNoURL() {
        #expect(Editors.url(opening: "/a.swift", line: 1, column: 1, in: "com.apple.dt.Xcode") == nil)
    }
}
