import Foundation
import XCTest

@testable import AuvasaKit

final class ArrivalTests: XCTestCase {
    func testArrivalBestTime() {
        let scheduled = Date()
        let estimated = scheduled.addingTimeInterval(300) // 5 minutes later

        let arrival = Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: estimated,
            delay: 300,
            realtimeAvailable: true,
            stopSequence: 1
        )

        XCTAssertEqual(arrival.bestTime, estimated)
        XCTAssertEqual(arrival.delay, 300)
        XCTAssertTrue(arrival.realtimeAvailable)
    }

    func testArrivalBestTimeWithoutRealtime() {
        let scheduled = Date()

        let arrival = Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: nil,
            delay: nil,
            realtimeAvailable: false,
            stopSequence: 1
        )

        XCTAssertEqual(arrival.bestTime, scheduled)
        XCTAssertNil(arrival.delay)
        XCTAssertFalse(arrival.realtimeAvailable)
    }

    func testArrivalDelayDescription() {
        let scheduled = Date()

        // Test on time
        var arrival = createArrival(scheduled: scheduled, delay: 0)
        XCTAssertEqual(arrival.delayDescription, "On time")

        // Test late (6 minutes)
        arrival = createArrival(scheduled: scheduled, delay: 360)
        XCTAssertEqual(arrival.delayDescription, "6 min late")

        // Test early (3 minutes)
        arrival = createArrival(scheduled: scheduled, delay: -180)
        XCTAssertEqual(arrival.delayDescription, "3 min early")

        // Test late (45 seconds)
        arrival = createArrival(scheduled: scheduled, delay: 45)
        XCTAssertEqual(arrival.delayDescription, "45 sec late")

        // Test no delay info
        arrival = createArrival(scheduled: scheduled, delay: nil)
        XCTAssertNil(arrival.delayDescription)
    }

    private func createArrival(scheduled: Date, delay: Int?) -> Arrival {
        Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: delay.map { scheduled.addingTimeInterval(TimeInterval($0)) },
            delay: delay,
            realtimeAvailable: delay != nil,
            stopSequence: 1
        )
    }

    func testArrivalIsDelayed() {
        let scheduled = Date()

        // Not delayed (< 5 minutes)
        var arrival = Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: scheduled.addingTimeInterval(240), // 4 minutes
            delay: 240,
            realtimeAvailable: true,
            stopSequence: 1
        )
        XCTAssertFalse(arrival.isDelayed)

        // Delayed (> 5 minutes)
        arrival = Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: scheduled.addingTimeInterval(360), // 6 minutes
            delay: 360,
            realtimeAvailable: true,
            stopSequence: 1
        )
        XCTAssertTrue(arrival.isDelayed)

        // No delay info
        arrival = Arrival(
            stopId: "STOP001",
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduled,
            estimatedTime: nil,
            delay: nil,
            realtimeAvailable: false,
            stopSequence: 1
        )
        XCTAssertFalse(arrival.isDelayed)
    }

    // MARK: - Helper Methods

    private func createMockRoute() -> Route {
        Route(
            id: "L1",
            shortName: "1",
            longName: "Universidad - Circular",
            type: .bus,
            color: "FF0000",
            textColor: "FFFFFF"
        )
    }

    private func createMockTrip() -> Trip {
        Trip(
            id: "TRIP001",
            routeId: "L1",
            serviceId: "WEEKDAY",
            headsign: "Universidad",
            directionId: 0,
            shapeId: "SHAPE001"
        )
    }
}
