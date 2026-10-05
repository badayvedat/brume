import BrumeCore
import Foundation
import Testing

struct OpenedFoldersTests {
    let root = FileManager.default.temporaryDirectory.appending(path: "brume-\(UUID())")

    /// `projet/` et son fichier `projet/notes.txt`.
    private func makeProject() throws -> (folder: URL, file: URL) {
        let folder = root.appending(path: "projet")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "notes.txt")
        try Data().write(to: file)
        return (folder, file)
    }

    @Test func aFolderOpensItself() throws {
        let project = try makeProject()
        #expect(OpenedFolders.paths(for: [project.folder]) == [project.folder.path])
        try FileManager.default.removeItem(at: root)
    }

    @Test func aFileOpensItsFolder() throws {
        let project = try makeProject()
        #expect(OpenedFolders.paths(for: [project.file]) == [project.folder.path])
        try FileManager.default.removeItem(at: root)
    }

    @Test func eachFolderComesOnceInOrder() throws {
        let project = try makeProject()
        let other = root.appending(path: "autre")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        let withSlash = URL(fileURLWithPath: project.folder.path + "/")
        let opened = OpenedFolders.paths(for: [other, project.file, withSlash, project.folder, other])
        #expect(opened == [other.path, project.folder.path])
        try FileManager.default.removeItem(at: root)
    }

    @Test func missingPathsAndWebLinksAreLeftOut() throws {
        let project = try makeProject()
        let missing = root.appending(path: "parti")
        let web = try #require(URL(string: "https://brume.app"))
        #expect(OpenedFolders.paths(for: [missing, web, project.folder]) == [project.folder.path])
        try FileManager.default.removeItem(at: root)
    }

    @Test func dotsInThePathAreResolved() throws {
        let project = try makeProject()
        let dotted = root.appending(path: "projet/../projet/.")
        #expect(OpenedFolders.paths(for: [dotted]) == [project.folder.path])
        try FileManager.default.removeItem(at: root)
    }
}
