import SwiftData
import XCTest
@testable import SwiftGuardData

final class BookmarkRepositoryTests: XCTestCase {
    @MainActor
    func testAddIsIdempotent() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let repo = SwiftDataBookmarkRepository(modelContext: container.mainContext)
        try repo.add(code: "A01:2021")
        try repo.add(code: "A01:2021")
        XCTAssertEqual(try repo.list().count, 1)
    }

    @MainActor
    func testRemoveDeletesTheBookmark() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let repo = SwiftDataBookmarkRepository(modelContext: container.mainContext)
        try repo.add(code: "A01:2021")
        try repo.remove(code: "A01:2021")
        XCTAssertTrue(try repo.list().isEmpty)
    }

    @MainActor
    func testRemovingANonExistentBookmarkDoesNotThrow() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let repo = SwiftDataBookmarkRepository(modelContext: container.mainContext)
        XCTAssertNoThrow(try repo.remove(code: "DOES_NOT_EXIST"))
    }

    @MainActor
    func testListOrdersNewestFirst() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let repo = SwiftDataBookmarkRepository(modelContext: container.mainContext)
        try repo.add(code: "A01:2021")
        try repo.add(code: "A03:2021")
        let list = try repo.list()
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.first?.threatOrCardCode, "A03:2021") // added last, sorted newest-first
    }
}
