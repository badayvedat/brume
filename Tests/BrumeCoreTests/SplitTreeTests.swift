import BrumeCore
import CoreGraphics
import Testing

struct SplitTreeTests {
    let unit = CGRect(x: 0, y: 0, width: 100, height: 100)

    // a | b, avec b coupé en b (haut) / c (bas).
    var threePanes: SplitTree<String> {
        SplitTree.pane("a")
            .inserting(.pane("b"), beside: "a", toward: .right)
            .inserting(.pane("c"), beside: "b", toward: .down)
    }

    @Test func splittingPlacesNewPaneAfterTarget() {
        #expect(threePanes.panes == ["a", "b", "c"])
    }

    @Test func splittingUnknownPaneChangesNothing() {
        let tree = SplitTree.pane("a")
        #expect(tree.inserting(.pane("b"), beside: "z", toward: .right) == tree)
    }

    @Test func removingCollapsesTheSplit() {
        #expect(threePanes.removing("b") == .split(.horizontal, ratio: 0.5, .pane("a"), .pane("c")))
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
        let dividers = threePanes.dividers(in: unit)
        #expect(dividers.map(\.line) == [
            CGRect(x: 50, y: 0, width: 0, height: 100),
            CGRect(x: 50, y: 50, width: 50, height: 0),
        ])
        #expect(dividers.map(\.path) == [[], [1]])
    }

    @Test func ratioMovesTheBoundary() {
        let tree = threePanes.settingRatio(0.25, at: [1])
        #expect(tree.frames(in: unit)["b"] == CGRect(x: 50, y: 0, width: 50, height: 25))
        #expect(tree.frames(in: unit)["c"] == CGRect(x: 50, y: 25, width: 50, height: 75))
        #expect(tree.frames(in: unit)["a"] == CGRect(x: 0, y: 0, width: 50, height: 100))
    }

    @Test func removingKeepsOtherRatios() {
        let tree = threePanes.settingRatio(0.7, at: []).removing("c")
        #expect(tree == .split(.horizontal, ratio: 0.7, .pane("a"), .pane("b")))
    }

    @Test func dragPositionBecomesAClampedRatio() {
        let divider = threePanes.dividers(in: unit)[1]
        #expect(divider.ratio(at: CGPoint(x: 70, y: 40)) == 0.4)
        #expect(divider.ratio(at: CGPoint(x: 70, y: 2)) == 0.15)
        #expect(divider.ratio(at: CGPoint(x: 70, y: 99)) == 0.85)
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

    @Test func equalizedSharesTheSameAxisByPaneCount() {
        // a | b | c : chacun un tiers.
        let tree = SplitTree.pane("a")
            .inserting(.pane("b"), beside: "a", toward: .right)
            .inserting(.pane("c"), beside: "b", toward: .right)
            .equalized()
        let frames = tree.frames(in: CGRect(x: 0, y: 0, width: 90, height: 10))
        #expect(frames["a"]?.width == 30)
        #expect(frames["b"]?.width == 30)
        #expect(frames["c"]?.width == 30)
    }

    @Test func equalizedCountsACrossSplitAsOne() {
        let tree = threePanes.settingRatio(0.8, at: []).settingRatio(0.2, at: [1]).equalized()
        #expect(tree == .split(.horizontal, ratio: 0.5, .pane("a"), .split(.vertical, ratio: 0.5, .pane("b"), .pane("c"))))
    }

    @Test func insertingPlacesSubtreeOnTheChosenSide() {
        let other = SplitTree.pane("x").inserting(.pane("y"), beside: "x", toward: .down)
        let left = SplitTree.pane("a").inserting(other, beside: "a", toward: .left)
        #expect(left == .split(.horizontal, ratio: 0.5, other, .pane("a")))
        let down = SplitTree.pane("a").inserting(other, beside: "a", toward: .down)
        #expect(down == .split(.vertical, ratio: 0.5, .pane("a"), other))
    }

    @Test func insertingBesideANestedPane() {
        #expect(threePanes.inserting(.pane("d"), beside: "c", toward: .right).panes == ["a", "b", "c", "d"])
    }

    @Test func nearestEdgeSplitsThePaneInFourTriangles() {
        #expect(SplitDirection.nearestEdge(to: CGPoint(x: 10, y: 50), in: unit) == .left)
        #expect(SplitDirection.nearestEdge(to: CGPoint(x: 90, y: 60), in: unit) == .right)
        #expect(SplitDirection.nearestEdge(to: CGPoint(x: 50, y: 5), in: unit) == .up)
        #expect(SplitDirection.nearestEdge(to: CGPoint(x: 60, y: 95), in: unit) == .down)
        // Près du coin bas droit, le bord le plus proche l'emporte.
        #expect(SplitDirection.nearestEdge(to: CGPoint(x: 97, y: 90), in: unit) == .right)
    }

    @Test func halfIsTheSideTheDropWillTake() {
        #expect(SplitDirection.right.half(of: unit) == CGRect(x: 50, y: 0, width: 50, height: 100))
        #expect(SplitDirection.up.half(of: unit) == CGRect(x: 0, y: 0, width: 100, height: 50))
    }
}
