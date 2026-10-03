import BrumeCore
import Testing

struct EditorsTests {
    @Test func eachEditorIsListedOnce() {
        #expect(Set(Editors.bundleIdentifiers).count == Editors.bundleIdentifiers.count)
    }
}
