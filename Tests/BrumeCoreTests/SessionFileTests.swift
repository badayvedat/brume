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

    @Test func deletedSessionIsGone() throws {
        try file.save(Session(windows: []))
        file.delete()
        #expect(file.load() == nil)
        try? FileManager.default.removeItem(at: file.url.deletingLastPathComponent())
    }
}
