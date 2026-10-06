import BrumeCore
import Testing

struct RecentFoldersTests {
    @Test func mostRecentFirstWithoutDuplicates() {
        var folders = RecentFolders()
        for folder in ["/a", "/b", "/a", "/c"] { folders.visit(folder) }
        #expect(folders.all == ["/c", "/a", "/b"])
    }

    @Test func keepsTheTwentyLast() {
        var folders = RecentFolders()
        for index in 0..<25 { folders.visit("/\(index)") }
        #expect(folders.all.count == 20)
        #expect(folders.all.first == "/24")
        #expect(folders.all.last == "/5")
    }
}
