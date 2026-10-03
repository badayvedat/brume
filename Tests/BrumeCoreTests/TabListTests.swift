import BrumeCore
import Testing

struct TabListTests {
    // a, b, c, b affiché.
    var threeTabs: TabList<String> {
        TabList("a").inserting("c").selecting("a").inserting("b")
    }

    @Test func insertingPlacesAfterSelectedAndSelects() {
        #expect(threeTabs.tabs == ["a", "b", "c"])
        #expect(threeTabs.selected == "b")
    }

    @Test func selectingUnknownTabChangesNothing() {
        #expect(threeTabs.selecting("z") == threeTabs)
    }

    @Test func selectingByNumber() {
        #expect(threeTabs.selecting(number: 1).selected == "a")
        #expect(threeTabs.selecting(number: 4) == threeTabs)
    }

    @Test func numberNineIsAlwaysTheLast() {
        #expect(threeTabs.selecting(number: 9).selected == "c")
    }

    @Test func offsetWrapsAround() {
        #expect(threeTabs.selecting(number: 3).selecting(offset: 1).selected == "a")
        #expect(threeTabs.selecting(number: 1).selecting(offset: -1).selected == "c")
    }

    @Test func movingKeepsSelection() {
        let list = threeTabs.moving("a", to: 2)
        #expect(list.tabs == ["b", "c", "a"])
        #expect(list.selected == "b")
    }

    @Test func movingClampsTheDestination() {
        #expect(threeTabs.moving("c", to: -5).tabs == ["c", "a", "b"])
        #expect(threeTabs.moving("a", to: 99).tabs == ["b", "c", "a"])
    }

    @Test func removingSelectedShowsRightNeighbor() {
        let list = threeTabs.removing("b")
        #expect(list?.tabs == ["a", "c"])
        #expect(list?.selected == "c")
    }

    @Test func removingLastSelectedShowsLeftNeighbor() {
        #expect(threeTabs.selecting("c").removing("c")?.selected == "b")
    }

    @Test func removingHiddenTabKeepsSelection() {
        #expect(threeTabs.removing("a")?.selected == "b")
    }

    @Test func removingOnlyTabEmptiesTheList() {
        #expect(TabList("a").removing("a") == nil)
    }
}
