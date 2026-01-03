import Foundation
import XCTest

@testable import AuvasaKit

final class RealtimeServiceTests: XCTestCase {
    func testServiceInitialization() {
        let scheduleService = ScheduleService()
        let service = RealtimeService(scheduleService: scheduleService)
        XCTAssertNotNil(service)
    }

    // Note: Real endpoint tests are intentionally excluded from CI
    // These would require mocking the network layer for reliable, fast tests
    // Integration testing against real AUVASA endpoints should be done manually
}
