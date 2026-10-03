import BrumeCore
import CoreGraphics
import Foundation
import Testing

struct SessionTests {
    @Test func aSessionSurvivesTheRoundTrip() throws {
        let (a, b, p1, p2, p3) = (UUID(), UUID(), UUID(), UUID(), UUID())
        let layout = WindowLayout(tab: a, pane: p1).splitting(toward: .down, pane: p2).settingRatio(0.3, at: []).addingTab(b, pane: p3)
        let window = SavedWindow(
            layout: layout,
            tabs: [a: SavedTab(customTitle: "serveur", color: .red, icon: .server, isCollapsed: true)],
            panes: [p1: SavedPane(workingDirectory: "/tmp")],
            frame: CGRect(x: 10, y: 20, width: 800, height: 500)
        )
        let session = Session(windows: [window])
        #expect(Session.decoded(from: try session.encoded()) == session)
    }

    // Une zone (onglets t1, t2, t2 affiché) à gauche d'une autre (t3), comme l'écrivait la version 1.
    @Test func aVersionOneSessionBecomesOneTabPerTerminal() throws {
        let (left, right, t1, t2, t3) = (UUID(), UUID(), UUID(), UUID(), UUID())
        let json = """
        {"version": 1, "windows": [{
          "layout": {
            "tree": {"split": {"_0": {"horizontal": {}}, "ratio": 0.5, "_2": {"pane": {"_0": "\(left)"}}, "_3": {"pane": {"_0": "\(right)"}}}},
            "areas": ["\(left)", {"tabs": ["\(t1)", "\(t2)"], "selected": "\(t2)"}, "\(right)", {"tabs": ["\(t3)"], "selected": "\(t3)"}],
            "focusedArea": "\(left)"
          },
          "tabs": ["\(t1)", {"workingDirectory": "/tmp", "customTitle": "vps", "color": "blue", "icon": "server"}],
          "frame": [[10, 20], [800, 500]]
        }]}
        """
        let window = try #require(Session.decoded(from: Data(json.utf8))?.windows.first)
        #expect(window.layout.tabs == [t1, t2, t3])
        #expect(window.layout.selectedTab == t2)
        #expect(window.layout.panes == [t1, t2, t3])
        #expect(window.tabs[t1] == SavedTab(customTitle: "vps", color: .blue, icon: .server, isCollapsed: false))
        #expect(window.panes[t1] == SavedPane(workingDirectory: "/tmp"))
        #expect(window.frame == CGRect(x: 10, y: 20, width: 800, height: 500))
    }

    @Test func unreadableDataGivesNoSession() {
        #expect(Session.decoded(from: Data("pas du json".utf8)) == nil)
    }

    @Test func anotherFormatIsIgnored() {
        #expect(Session.decoded(from: Data(#"{"version": 99, "windows": []}"#.utf8)) == nil)
    }

    @Test func anInconsistentWindowIsDropped() throws {
        let good = SavedWindow(layout: WindowLayout(tab: UUID(), pane: UUID()), tabs: [:], panes: [:], frame: nil)
        // Un onglet listé sans splits : le restaurer planterait.
        let json = #"{"tabList": {"tabs": ["\#(UUID())"], "selected": "\#(UUID())"}, "splits": []}"#
        let broken = try JSONDecoder().decode(WindowLayout<UUID, UUID>.self, from: Data(json.utf8))
        let session = Session(windows: [good, SavedWindow(layout: broken, tabs: [:], panes: [:], frame: nil)])
        #expect(Session.decoded(from: try session.encoded())?.windows == [good])
    }
}
