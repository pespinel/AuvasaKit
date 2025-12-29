import XCTest

@testable import AuvasaKit

/// Basic smoke tests for AuvasaKit
/// Detailed unit tests are in separate test files organized by component
final class AuvasaKitTests: XCTestCase {
    func testClientInitialization() {
        let client = AuvasaClient()
        XCTAssertNotNil(client)
    }
}
