import BrumeCore
import CoreGraphics
import Testing

struct WindowLayoutTests {
    // Zone A (onglets 1, 2) | zone B (onglet 3), le focus dans B.
    var twoAreas: WindowLayout<String, Int> {
        WindowLayout(area: "A", tab: 1).addingTab(2).splitting(toward: .right, area: "B", tab: 3)
    }

    @Test func splittingOpensAFocusedAreaWithOneTab() {
        #expect(twoAreas.tree.panes == ["A", "B"])
        #expect(twoAreas.focusedArea == "B")
        #expect(twoAreas.focusedTab == 3)
    }

    @Test func newTabGoesToTheFocusedArea() {
        let layout = twoAreas.addingTab(4)
        #expect(layout.areas["B"]?.tabs == [3, 4])
        #expect(layout.focusedTab == 4)
    }

    @Test func tabsAreInReadingOrder() {
        #expect(twoAreas.tabs == [1, 2, 3])
        #expect(twoAreas.shortcutNumber(of: 3) == 3)
    }

    @Test func numberNineIsAlwaysTheLastTab() {
        let ten = (2 ... 10).reduce(WindowLayout(area: "A", tab: 1)) { $0.addingTab($1) }
        #expect(ten.shortcutNumber(of: 9) == nil)
        #expect(ten.shortcutNumber(of: 10) == 9)
        #expect(ten.selecting(number: 9).focusedTab == 10)
    }

    @Test func numberSelectsAcrossAreas() {
        let layout = twoAreas.selecting(number: 1)
        #expect(layout.focusedArea == "A")
        #expect(layout.focusedTab == 1)
    }

    @Test func onlyTheSelectedTabOfEachAreaIsShown() {
        #expect(twoAreas.isShown(2))
        #expect(!twoAreas.isShown(1))
        #expect(twoAreas.isShown(3))
    }

    @Test func removingTheLastTabOfAnAreaRemovesTheArea() {
        let layout = twoAreas.removing(3)
        #expect(layout?.tree == .pane("A"))
        #expect(layout?.areas["B"] == nil)
        #expect(layout?.focusedArea == "A")
    }

    @Test func removingTheLastTabEmptiesTheWindow() {
        #expect(WindowLayout(area: "A", tab: 1).removing(1) == nil)
    }

    @Test func movingIntoAnotherAreaJoinsItsBar() {
        let layout = twoAreas.moving(1, into: "B")
        #expect(layout.areas["A"]?.tabs == [2])
        #expect(layout.areas["B"]?.tabs == [3, 1])
        #expect(layout.focusedTab == 1)
    }

    @Test func movingTheOnlyTabIntoAnotherAreaClosesItsArea() {
        let layout = twoAreas.moving(3, into: "A")
        #expect(layout.tree == .pane("A"))
        #expect(layout.areas["A"]?.tabs == [1, 2, 3])
    }

    @Test func movingBesideOpensANewArea() {
        let layout = twoAreas.moving(1, beside: "B", toward: .down, area: "C")
        #expect(layout.tree.panes == ["A", "B", "C"])
        #expect(layout.areas["C"]?.tabs == [1])
        #expect(layout.focusedArea == "C")
    }

    @Test func aLoneTabCannotMoveBesideItself() {
        #expect(!twoAreas.canMove(3, beside: "B"))
        #expect(twoAreas.moving(3, beside: "B", toward: .left, area: "C") == twoAreas)
        #expect(twoAreas.canMove(1, beside: "A"))
    }

    // A à gauche, B à droite, chacune 100 de large avec une barre de 10.
    let window = CGRect(x: 0, y: 0, width: 200, height: 110)

    @Test func centreOfAnotherAreaJoinsIt() {
        let drop = twoAreas.drop(of: 1, at: CGPoint(x: 150, y: 60), in: window, barHeight: 10)
        #expect(drop?.target == .area("B"))
        #expect(drop?.highlight == CGRect(x: 100, y: 10, width: 100, height: 100))
    }

    @Test func edgeOfAnotherAreaSplitsIt() {
        let drop = twoAreas.drop(of: 1, at: CGPoint(x: 195, y: 60), in: window, barHeight: 10)
        #expect(drop?.target == .split("B", .right))
        #expect(drop?.highlight == CGRect(x: 150, y: 10, width: 50, height: 100))
    }

    @Test func anywhereInItsOwnAreaSplitsIt() {
        #expect(twoAreas.drop(of: 1, at: CGPoint(x: 55, y: 60), in: window, barHeight: 10)?.target == .split("A", .right))
    }

    @Test func aLoneTabOverItsOwnAreaProposesNothing() {
        #expect(twoAreas.drop(of: 3, at: CGPoint(x: 150, y: 60), in: window, barHeight: 10) == nil)
    }

    @Test func droppingOnAnEdgeOpensTheNewArea() {
        let drop = twoAreas.drop(of: 1, at: CGPoint(x: 150, y: 105), in: window, barHeight: 10)!
        let layout = twoAreas.dropping(drop, newArea: "C")
        #expect(layout.tree.panes == ["A", "B", "C"])
        #expect(layout.areas["C"]?.tabs == [1])
    }

    @Test func movingTowardANeighbourJoinsIt() {
        let layout = twoAreas.selecting(1).movingFocusedTab(toward: .right, newArea: "C")
        #expect(layout.areas["B"]?.tabs == [3, 1])
        #expect(layout.focusedTab == 1)
    }

    @Test func movingTowardNothingOpensAnArea() {
        let layout = twoAreas.selecting(1).movingFocusedTab(toward: .down, newArea: "C")
        #expect(layout.areas["C"]?.tabs == [1])
        #expect(layout.tree.panes == ["A", "C", "B"])
    }

    @Test func aLoneTabWithNoNeighbourStays() {
        #expect(twoAreas.movingFocusedTab(toward: .right, newArea: "C") == twoAreas)
    }
}
