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
        let settings = AppSettings.decoded(from: Data(#"{"font": {"size": 200}}"#.utf8))
        #expect(settings?.font.size == TerminalFont.sizeRange.upperBound)
    }

    @Test func oldGlassNumbersBecomeTheClosestStep() {
        let settings = AppSettings.decoded(from: Data(#"{"appearance": {"glassOpacity": 0.62, "glassBlur": 100}}"#.utf8))
        #expect(settings?.appearance.glassOpacity == .low)
        #expect(settings?.appearance.glassBlur == .high)
        let steps = AppSettings.decoded(from: Data(#"{"appearance": {"glassOpacity": "high", "glassBlur": "low"}}"#.utf8))
        #expect(steps?.appearance.glassOpacity == .high)
        #expect(steps?.appearance.glassBlur == .low)
    }
}
