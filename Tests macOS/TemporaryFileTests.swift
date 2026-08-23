import XCTest
@testable import File_Cloud

class TemporaryFileTests: XCTestCase {
    func testCopyKeepsTheNameAndTheContents() throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("photo.png")
        try Data("bytes".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        let copy = try TemporaryFile.copy(from: source)
        defer { TemporaryFile.remove(copy) }

        XCTAssertEqual(copy.lastPathComponent, "photo.png")
        XCTAssertEqual(try Data(contentsOf: copy), Data("bytes".utf8))
        XCTAssertNotEqual(copy, source)
    }

    func testTwoCopiesOfTheSameNameDoNotCollide() throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("IMG_0001.jpg")
        try Data("first".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        let first = try TemporaryFile.copy(from: source)
        defer { TemporaryFile.remove(first) }
        try Data("second".utf8).write(to: source)
        let second = try TemporaryFile.copy(from: source)
        defer { TemporaryFile.remove(second) }

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: first), Data("first".utf8))
        XCTAssertEqual(try Data(contentsOf: second), Data("second".utf8))
    }

    func testRemoveDeletesTheCopyAndItsDirectory() throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("doc.txt")
        try Data("bytes".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        let copy = try TemporaryFile.copy(from: source)
        let directory = copy.deletingLastPathComponent()

        TemporaryFile.remove(copy)

        XCTAssertFalse(FileManager.default.fileExists(atPath: copy.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path), "The source must stay")
    }

    func testCopyThrowsForAMissingSource() {
        XCTAssertThrowsError(try TemporaryFile.copy(from: URL(fileURLWithPath: "/nonexistent/file.txt")))
    }
}
