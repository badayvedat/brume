import BrumeCore
import Testing

struct SearchCountTests {
    @Test func selectedIsShownFromOne() {
        #expect(SearchCount(total: 12, selected: 1).label == "2/12")
    }

    @Test func missingPartsAreMarked() {
        #expect(SearchCount(total: 12, selected: nil).label == "-/12")
        #expect(SearchCount(total: nil, selected: 0).label == "1/?")
        #expect(SearchCount(total: nil, selected: nil).label == nil)
    }

    @Test func nothingFoundNeedsANeedleAndAZeroTotal() {
        #expect(SearchCount(total: 0, selected: nil).findsNothing(for: "xyz"))
        #expect(!SearchCount(total: 0, selected: nil).findsNothing(for: ""))
        #expect(!SearchCount(total: 3, selected: nil).findsNothing(for: "xyz"))
        #expect(!SearchCount(total: nil, selected: nil).findsNothing(for: "xyz"))
    }

    @Test func shortNeedlesWait() {
        #expect(SearchCount.delay(for: "ab") == .milliseconds(300))
        #expect(SearchCount.delay(for: "abc") == .zero)
        #expect(SearchCount.delay(for: "") == .zero)
    }
}
