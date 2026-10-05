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
        settings.suggestsHistory = false
        settings.completesCommands = false
        settings.verticalTabs = VerticalTabs(isOn: true, width: 260)
        try file.save(settings)
        #expect(file.load() == settings)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func settingsFromBeforeTheShellOptionsKeepThemOn() {
        let settings = AppSettings.decoded(from: Data(#"{"restoresSession": false}"#.utf8))
        #expect(settings?.suggestsHistory == true)
        #expect(settings?.completesCommands == true)
    }

    @Test func savedLanguageIsKeptAndAMissingOneFollowsTheMac() {
        #expect(AppSettings.decoded(from: Data(#"{"language": "english"}"#.utf8))?.language == .english)
        #expect(AppSettings.decoded(from: Data(#"{"language": "french"}"#.utf8))?.language == .french)
        let mac = Language.preferred(in: Locale.preferredLanguages)
        #expect(AppSettings.decoded(from: Data(#"{"restoresSession": false}"#.utf8))?.language == mac)
        #expect(AppSettings().language == mac)
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
        let tabs = AppSettings.decoded(from: Data(#"{"verticalTabs": {"isOn": true, "width": 9000}}"#.utf8))
        #expect(tabs?.verticalTabs == VerticalTabs(isOn: true, width: VerticalTabs.widthRange.upperBound))
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
