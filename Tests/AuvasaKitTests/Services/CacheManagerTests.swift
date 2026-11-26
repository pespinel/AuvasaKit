import Foundation
import XCTest
@testable import AuvasaKit

final class CacheManagerTests: XCTestCase {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CacheManagerTests-\(UUID().uuidString)")

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testMemoryHit() async {
        let cache = CacheManager(enableDiskCache: false)
        await cache.set(key: "k", value: "v")

        let value: String? = await cache.get(key: "k", policy: .alert)

        XCTAssertEqual(value, "v")
    }

    func testExpiredValueReturnsNil() async {
        let cache = CacheManager(enableDiskCache: true, cacheDirectory: directory)
        await cache.set(key: "k", value: "v")

        let value: String? = await cache.get(key: "k", policy: CachePolicy(maxAge: -1, refreshInterval: 0))

        XCTAssertNil(value)
    }

    func testDiskHitIsReturnedWhenMemoryIsEmpty() async {
        let writer = CacheManager(enableDiskCache: true, cacheDirectory: directory)
        await writer.set(key: "k", value: "v")

        let reader = CacheManager(enableDiskCache: true, cacheDirectory: directory)
        let value: String? = await reader.get(key: "k", policy: .alert)

        XCTAssertEqual(value, "v")
    }

    func testMissReturnsNil() async {
        let cache = CacheManager(enableDiskCache: true, cacheDirectory: directory)

        let value: String? = await cache.get(key: "missing", policy: .alert)

        XCTAssertNil(value)
    }
}
