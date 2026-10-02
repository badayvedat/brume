import BrumeCore
import CoreGraphics
import Testing

struct SplitTreeTests {
    let unit = CGRect(x: 0, y: 0, width: 100, height: 100)

    // a | b, avec b coupé en b (haut) / c (bas).
    var threePanes: SplitTree<String> {
        SplitTree.pane("a")
            .splitting("a", axis: .horizontal, adding: "b")
            .splitting("b", axis: .vertical, adding: "c")
    }

    @Test func splittingPlacesNewPaneAfterTarget() {
        #expect(threePanes.panes == ["a", "b", "c"])
    }

    @Test func splittingUnknownPaneChangesNothing() {
        let tree = SplitTree.pane("a")
        #expect(tree.splitting("z", axis: .horizontal, adding: "b") == tree)
    }

    @Test func removingCollapsesTheSplit() {
        #expect(threePanes.removing("b") == .split(.horizontal, .pane("a"), .pane("c")))
    }

    @Test func removingLastPaneEmptiesTheTree() {
        #expect(SplitTree.pane("a").removing("a") == nil)
    }

    @Test func framesShareTheSpace() {
        let frames = threePanes.frames(in: unit)
        #expect(frames["a"] == CGRect(x: 0, y: 0, width: 50, height: 100))
        #expect(frames["b"] == CGRect(x: 50, y: 0, width: 50, height: 50))
        #expect(frames["c"] == CGRect(x: 50, y: 50, width: 50, height: 50))
    }

    @Test func dividersSitOnBoundaries() {
        #expect(threePanes.dividers(in: unit) == [
            CGRect(x: 50, y: 0, width: 0, height: 100),
            CGRect(x: 50, y: 50, width: 50, height: 0),
        ])
    }

    @Test func nextAndPreviousWrapAround() {
        #expect(threePanes.pane(after: "c") == "a")
        #expect(threePanes.pane(before: "a") == "c")
        #expect(threePanes.pane(after: "a") == "b")
    }

    @Test func neighborFollowsTheLayout() {
        let tree = threePanes
        #expect(tree.neighbor(of: "a", toward: .right) == "b")
        #expect(tree.neighbor(of: "c", toward: .left) == "a")
        #expect(tree.neighbor(of: "b", toward: .down) == "c")
        #expect(tree.neighbor(of: "c", toward: .up) == "b")
        #expect(tree.neighbor(of: "a", toward: .left) == nil)
    }
}
