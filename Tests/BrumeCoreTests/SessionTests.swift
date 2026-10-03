import BrumeCore
import CoreGraphics
import Foundation
import Testing

struct SessionTests {
    @Test func aSessionSurvivesTheRoundTrip() throws {
        let (a, b, t1, t2, t3) = (UUID(), UUID(), UUID(), UUID(), UUID())
        let layout = WindowLayout(area: a, tab: t1).addingTab(t2).splitting(toward: .down, area: b, tab: t3)
            .settingRatio(0.3, at: [])
        let window = SavedWindow(
            layout: layout,
            tabs: [t1: SavedTab(workingDirectory: "/tmp", customTitle: "serveur", color: .red)],
            frame: CGRect(x: 10, y: 20, width: 800, height: 500)
        )
        let session = Session(windows: [window])
        #expect(Session.decoded(from: try session.encoded()) == session)
    }

    @Test func unreadableDataGivesNoSession() {
        #expect(Session.decoded(from: Data("pas du json".utf8)) == nil)
    }

    @Test func anotherFormatIsIgnored() {
        #expect(Session.decoded(from: Data(#"{"version": 99, "windows": []}"#.utf8)) == nil)
    }

    @Test func anInconsistentWindowIsDropped() throws {
        let good = SavedWindow(layout: WindowLayout(area: UUID(), tab: UUID()), tabs: [:], frame: nil)
        // Une zone active absente des barres : la restaurer planterait.
        let json = #"{"tree":{"pane":{"_0":"\#(UUID())"}},"areas":[],"focusedArea":"\#(UUID())"}"#
        let broken = try JSONDecoder().decode(WindowLayout<UUID, UUID>.self, from: Data(json.utf8))
        let session = Session(windows: [good, SavedWindow(layout: broken, tabs: [:], frame: nil)])
        #expect(Session.decoded(from: try session.encoded())?.windows == [good])
    }
}
