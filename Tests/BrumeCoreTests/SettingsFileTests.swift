import BrumeCore
import Foundation
import Testing

struct SettingsFileTests {
    let file = SettingsFile(url: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())/settings.json"))

    @Test func noFileGivesDefaults() {
        #expect(file.load() == AppSettings())
    }

    @Test func savedSettingsAreReadBack() throws {
        var settings = AppSettings()
        settings.appearance.isGlass = false
        settings.appearance.commandColors = .nord
        settings.appearance.accent = .orange
        settings.font = TerminalFont(family: "Menlo", size: 15)
        settings.language = .english
        settings.restoresSession = false
        try file.save(settings)
        #expect(file.load() == settings)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func unreadableSettingKeepsItsDefaultAndTheOthersSurvive() {
        let settings = AppSettings.decoded(from: Data(#"{"appearance": {"commandColors": "nord", "isGlass": "plaid"}}"#.utf8))
        #expect(settings?.appearance.commandColors == .nord)
        #expect(settings?.appearance.isGlass == Appearance().isGlass)
    }

    @Test func valuesStayInRangeEvenFromAFileEditedByHand() {
        #expect(TerminalFont(family: nil, size: 200).size == TerminalFont.sizeRange.upperBound)
        let settings = AppSettings.decoded(from: Data(#"{"font": {"size": 200}, "appearance": {"glassOpacity": 0, "glassBlur": -5}}"#.utf8))
        #expect(settings?.font.size == TerminalFont.sizeRange.upperBound)
        #expect(settings?.appearance.glassOpacity == Appearance.glassOpacityRange.lowerBound)
        #expect(settings?.appearance.glassBlur == 0)
    }
}
