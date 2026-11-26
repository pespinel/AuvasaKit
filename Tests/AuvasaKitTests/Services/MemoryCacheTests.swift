import Foundation
import XCTest
@testable import AuvasaKit

final class MemoryCacheTests: XCTestCase {
    func testEvictsOldestWhenAtCapacity() async throws {
        let cache = MemoryCache(maxItems: 2)
        await cache.set("first", value: 1)
        try await Task.sleep(nanoseconds: 10_000_000)
        await cache.set("second", value: 2)
        await cache.set("third", value: 3)

        let first: CachedValue<Int>? = await cache.get("first")
        let second: CachedValue<Int>? = await cache.get("second")
        let third: CachedValue<Int>? = await cache.get("third")
        let count = await cache.count

        XCTAssertNil(first)
        XCTAssertEqual(second?.value, 2)
        XCTAssertEqual(third?.value, 3)
        XCTAssertEqual(count, 2)
    }

    func testOverwritingExistingKeyDoesNotEvict() async {
        let cache = MemoryCache(maxItems: 2)
        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("a", value: 10)

        let first: CachedValue<Int>? = await cache.get("a")
        let second: CachedValue<Int>? = await cache.get("b")

        XCTAssertEqual(first?.value, 10)
        XCTAssertEqual(second?.value, 2)
    }
}
