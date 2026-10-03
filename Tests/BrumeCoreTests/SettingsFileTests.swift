import BrumeCore
import Foundation
import Testing

struct SettingsFileTests {
    let file = SettingsFile(url: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())/settings.json"))

    @Test func noFileGivesDefaults() {
        #expect(file.load() == Settings())
    }

    @Test func savedSettingsAreReadBack() throws {
        var settings = Settings()
        settings.translucency = TranslucencyPreset.normal.translucency
        try file.save(settings)
        #expect(file.load() == settings)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func missingSettingKeepsItsDefault() {
        #expect(Settings.decoded(from: Data("{}".utf8)) == Settings())
    }
}
