import XCTest
@testable import File_Cloud

class UploadIconTests: XCTestCase {
    func testEachStateHasItsOwnSymbol() {
        let all: [UploadIcon] = [.idle, .dragging, .uploading, .success, .failure]
        let names = all.map(\.systemName)

        XCTAssertEqual(Set(names).count, all.count, "Two states share a symbol")
        XCTAssertFalse(names.contains(where: \.isEmpty))
    }

    func testOnlyResultsAreTemporary() {
        XCTAssertTrue(UploadIcon.success.isTemporary)
        XCTAssertTrue(UploadIcon.failure.isTemporary)
        XCTAssertFalse(UploadIcon.idle.isTemporary)
        XCTAssertFalse(UploadIcon.dragging.isTemporary)
        XCTAssertFalse(UploadIcon.uploading.isTemporary, "An upload can take longer than the delay")
    }

    func testTheSymbolsAreTheOnesTheAppShipped() {
        XCTAssertEqual(UploadIcon.idle.systemName, "cloud.fill")
        XCTAssertEqual(UploadIcon.dragging.systemName, "cloud")
        XCTAssertEqual(UploadIcon.uploading.systemName, "arrow.up")
        XCTAssertEqual(UploadIcon.success.systemName, "checkmark")
        XCTAssertEqual(UploadIcon.failure.systemName, "xmark")
    }
}
