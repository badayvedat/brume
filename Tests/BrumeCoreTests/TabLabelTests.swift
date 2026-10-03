import BrumeCore
import CoreGraphics
import Testing

struct TabLabelTests {
    let vps = TabLabel(title: "vps", color: .red, icon: .server)
    let api = TabLabel(title: "api")

    // A (1) nommé vps, B (2).
    var twoTabs: WindowLayout<String, Int> {
        WindowLayout(tab: "A", pane: 1).addingTab("B", pane: 2).selecting("A")
    }

    @Test func splittingATabGivesItsNameToItsFirstPaneAndNumbersTheGroup() {
        let labels = WindowLabels<String, Int>(tabs: ["A": vps])
        let split = twoTabs.splitting(toward: .right, pane: 3)
        let result = labels.reconciled(from: twoTabs, to: split)
        #expect(result.tabs["A"] == nil)
        #expect(result.panes[1] == vps)
        #expect(result.panes[3] == nil)
        #expect(result.groupNumbers["A"] == 1)
    }

    @Test func aDetachedPaneTakesItsNameAsATab() {
        let split = twoTabs.splitting(toward: .right, pane: 3)
        let labels = WindowLabels<String, Int>(panes: [1: vps, 3: api], groupNumbers: ["A": 1])
        let result = labels.reconciled(from: split, to: split.detaching(3, into: "C"))
        #expect(result.tabs["C"] == api)
        #expect(result.tabs["A"] == vps)
        #expect(result.panes.isEmpty)
        #expect(result.groupNumbers.isEmpty)
    }

    @Test func aTabDroppedIntoAGroupKeepsItsNameAsAPane() {
        let split = twoTabs.splitting(toward: .right, pane: 3)
        let labels = WindowLabels<String, Int>(tabs: ["B": api], groupNumbers: ["A": 1])
        let drop = split.drop(of: .tab("B"), at: CGPoint(x: 10, y: 10), in: CGRect(x: 0, y: 0, width: 100, height: 100))!
        let result = labels.reconciled(from: split, to: split.dropping(drop))
        #expect(result.panes[2] == api)
        #expect(result.tabs["B"] == nil)
    }

    @Test func aRenamedGroupKeepsItsNameAndANewGroupTakesTheFreeNumber() {
        let split = twoTabs.splitting(toward: .right, pane: 3)
        let labels = WindowLabels<String, Int>(tabs: ["A": TabLabel(title: "backend")], panes: [1: vps], groupNumbers: ["A": 1])
        let both = split.selecting("B").splitting(toward: .down, pane: 4)
        let result = labels.reconciled(from: split, to: both)
        #expect(result.tabs["A"]?.title == "backend")
        #expect(result.groupNumbers == ["A": 1, "B": 2])
    }

    @Test func closingTheOtherSplitGivesThePaneNameBackToTheTab() {
        let split = twoTabs.splitting(toward: .right, pane: 3)
        let labels = WindowLabels<String, Int>(tabs: ["A": TabLabel(color: .blue)], panes: [1: vps], groupNumbers: ["A": 1])
        let result = labels.reconciled(from: split, to: split.removing(3)!)
        #expect(result.tabs["A"] == vps)
        #expect(result.groupNumbers.isEmpty)
    }
}
