import BrumeCore
import Foundation
import Testing

struct SessionFileTests {
    let file = SessionFile(url: FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())/session.json"))

    @Test func noFileGivesNoSession() {
        #expect(file.load() == nil)
    }

    @Test func savedSessionIsReadBack() throws {
        let session = Session(windows: [SavedWindow(layout: WindowLayout(tab: UUID(), pane: UUID()), tabs: [:], panes: [:], frame: nil)])
        try file.save(session)
        #expect(file.load() == session)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func aRefusedFileIsKeptAside() throws {
        let data = Data(#"{"version": 99, "windows": []}"#.utf8)
        try FileManager.default.createDirectory(at: file.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: file.url)
        #expect(file.load() == nil)
        #expect(try Data(contentsOf: file.backupURL) == data)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func aDroppedWindowKeepsTheFileAside() throws {
        let good = SavedWindow(layout: WindowLayout(tab: UUID(), pane: UUID()), tabs: [:], panes: [:], frame: nil)
        let json = #"{"tabList": {"tabs": ["\#(UUID())"], "selected": "\#(UUID())"}, "splits": []}"#
        let broken = try JSONDecoder().decode(WindowLayout<UUID, UUID>.self, from: Data(json.utf8))
        try file.save(Session(windows: [good, SavedWindow(layout: broken, tabs: [:], panes: [:], frame: nil)]))
        let saved = try Data(contentsOf: file.url)
        #expect(file.load() == Session(windows: [good]))
        #expect(try Data(contentsOf: file.backupURL) == saved)
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func aReadableFileIsNotCopied() throws {
        try file.save(Session(windows: []))
        #expect(file.load() == Session(windows: []))
        #expect(!FileManager.default.fileExists(atPath: file.backupURL.path))
        try FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }

    @Test func deletedSessionIsGone() throws {
        try file.save(Session(windows: []))
        file.delete()
        #expect(file.load() == nil)
        try? FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }
}
