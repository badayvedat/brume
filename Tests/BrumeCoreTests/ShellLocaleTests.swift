import BrumeCore
import Testing

struct ShellLocaleTests {
    @Test func macRegionGivesItsUTF8Locale() {
        #expect(ShellLocale.lang(appleLocale: "fr_FR", isAvailable: { _ in true }) == "fr_FR.UTF-8")
    }

    @Test func modifiersAreDropped() {
        #expect(ShellLocale.lang(appleLocale: "en_FR@rg=frzzzz", isAvailable: { _ in true }) == "en_FR.UTF-8")
    }

    @Test func unknownOrMissingLocaleLeavesItToTheEngine() {
        #expect(ShellLocale.lang(appleLocale: "en_FR", isAvailable: { _ in false }) == nil)
        #expect(ShellLocale.lang(appleLocale: nil, isAvailable: { _ in true }) == nil)
        #expect(ShellLocale.lang(appleLocale: "", isAvailable: { _ in true }) == nil)
    }
}
