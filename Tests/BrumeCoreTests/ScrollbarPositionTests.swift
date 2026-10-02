import BrumeCore
import Testing

struct ScrollbarPositionTests {
    // 100 lignes dont 20 visibles, vue sur 200 points : 10 points par ligne.
    let atBottom = ScrollbarPosition(total: 100, offset: 80, visible: 20)

    @Test func screenWithoutHistoryIsNotScrollable() {
        #expect(!ScrollbarPosition(total: 20, offset: 0, visible: 20).isScrollable)
        #expect(atBottom.isScrollable)
    }

    @Test func documentMatchesTheWholeHistory() {
        #expect(atBottom.documentHeight(viewport: 200) == 1000)
    }

    @Test func originCountsFromTheBottom() {
        #expect(atBottom.scrollOrigin(viewport: 200) == 0)
        #expect(ScrollbarPosition(total: 100, offset: 0, visible: 20).scrollOrigin(viewport: 200) == 800)
    }

    @Test func draggedOriginGivesTheTopRow() {
        #expect(atBottom.row(atScrollOrigin: 0, viewport: 200) == 80)
        #expect(atBottom.row(atScrollOrigin: 800, viewport: 200) == 0)
        #expect(atBottom.row(atScrollOrigin: 304, viewport: 200) == 50)
    }

    @Test func draggedRowStaysInsideTheHistory() {
        #expect(atBottom.row(atScrollOrigin: -50, viewport: 200) == 80)
        #expect(atBottom.row(atScrollOrigin: 5000, viewport: 200) == 0)
    }

    @Test func outputAtTheBottomIsNotAScroll() {
        let more = ScrollbarPosition(total: 101, offset: 81, visible: 20)
        #expect(!more.hasScrolled(from: atBottom))
    }

    @Test func outputWhileScrolledUpIsNotAScroll() {
        let up = ScrollbarPosition(total: 100, offset: 40, visible: 20)
        #expect(!ScrollbarPosition(total: 101, offset: 40, visible: 20).hasScrolled(from: up))
    }

    @Test func movingInTheHistoryIsAScroll() {
        let up = ScrollbarPosition(total: 100, offset: 77, visible: 20)
        #expect(up.hasScrolled(from: atBottom))
        #expect(atBottom.hasScrolled(from: up))
        #expect(!atBottom.hasScrolled(from: nil))
    }
}
