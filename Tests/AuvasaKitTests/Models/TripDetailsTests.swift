import Foundation
import XCTest

@testable import AuvasaKit

final class TripDetailsTests: XCTestCase {
    func testTripDetailsStopCount() {
        let tripDetails = createMockTripDetails(stopCount: 15)
        XCTAssertEqual(tripDetails.stopCount, 15)
    }

    func testTripDetailsNextStop() {
        let now = Date()
        let arrivals = [
            createMockArrival(stopId: "STOP1", scheduledTime: now.addingTimeInterval(-300)), // 5 min ago
            createMockArrival(stopId: "STOP2", scheduledTime: now.addingTimeInterval(120)), // 2 min
            createMockArrival(stopId: "STOP3", scheduledTime: now.addingTimeInterval(600)) // 10 min
        ]

        let tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: arrivals,
            vehiclePosition: nil,
            delay: nil,
            realtimeAvailable: false,
            progress: nil
        )

        XCTAssertEqual(tripDetails.nextStop?.stopId, "STOP2")
    }

    func testTripDetailsCurrentStop() {
        let now = Date()
        let arrivals = [
            createMockArrival(stopId: "STOP1", scheduledTime: now.addingTimeInterval(-600)), // 10 min ago
            createMockArrival(stopId: "STOP2", scheduledTime: now.addingTimeInterval(-120)), // 2 min ago
            createMockArrival(stopId: "STOP3", scheduledTime: now.addingTimeInterval(300)) // 5 min
        ]

        let tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: arrivals,
            vehiclePosition: nil,
            delay: nil,
            realtimeAvailable: false,
            progress: nil
        )

        XCTAssertEqual(tripDetails.currentStop?.stopId, "STOP2")
    }

    func testTripDetailsIsDelayed() {
        // Not delayed
        var tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: [],
            vehiclePosition: nil,
            delay: 120, // 2 minutes
            realtimeAvailable: true,
            progress: nil
        )
        XCTAssertFalse(tripDetails.isDelayed)

        // Delayed
        tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: [],
            vehiclePosition: nil,
            delay: 420, // 7 minutes
            realtimeAvailable: true,
            progress: nil
        )
        XCTAssertTrue(tripDetails.isDelayed)

        // No delay info
        tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: [],
            vehiclePosition: nil,
            delay: nil,
            realtimeAvailable: false,
            progress: nil
        )
        XCTAssertFalse(tripDetails.isDelayed)
    }

    func testTripDetailsDelayDescription() {
        var tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: [],
            vehiclePosition: nil,
            delay: 360, // 6 minutes late
            realtimeAvailable: true,
            progress: nil
        )
        XCTAssertEqual(tripDetails.delayDescription, "6 min late")

        tripDetails = TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: [],
            vehiclePosition: nil,
            delay: nil,
            realtimeAvailable: false,
            progress: nil
        )
        XCTAssertNil(tripDetails.delayDescription)
    }

    // MARK: - Helper Methods

    private func createMockTripDetails(stopCount: Int) -> TripDetails {
        var arrivals: [Arrival] = []
        let now = Date()

        for index in 0..<stopCount {
            arrivals.append(
                createMockArrival(
                    stopId: "STOP\(index)",
                    scheduledTime: now.addingTimeInterval(TimeInterval(index * 120))
                )
            )
        }

        return TripDetails(
            trip: createMockTrip(),
            route: createMockRoute(),
            stopArrivals: arrivals,
            vehiclePosition: nil,
            delay: nil,
            realtimeAvailable: false,
            progress: nil
        )
    }

    private func createMockArrival(stopId: String, scheduledTime: Date) -> Arrival {
        Arrival(
            stopId: stopId,
            route: createMockRoute(),
            trip: createMockTrip(),
            scheduledTime: scheduledTime,
            estimatedTime: nil,
            delay: nil,
            realtimeAvailable: false,
            stopSequence: 1
        )
    }

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
