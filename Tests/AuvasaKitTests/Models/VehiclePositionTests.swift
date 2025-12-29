import Foundation
import XCTest

@testable import AuvasaKit

final class VehiclePositionTests: XCTestCase {
    func testVehiclePositionInitialization() {
        let vehicle = Vehicle(
            id: "BUS123",
            label: "Bus 123",
            licensePlate: "ABC123"
        )

        let tripDescriptor = TripDescriptor(
            tripId: "TRIP001",
            routeId: "L1",
            directionId: 0,
            startDate: "20231201",
            scheduleRelationship: .scheduled
        )

        let position = VehiclePosition(
            id: "VP001",
            vehicle: vehicle,
            trip: tripDescriptor,
            position: Coordinate(latitude: 41.6523, longitude: -4.7245),
            bearing: 180.0,
            speed: 10.5,
            currentStopSequence: 5,
            currentStopId: "STOP123",
            occupancyStatus: .manySeatsAvailable,
            timestamp: Date()
        )

        XCTAssertEqual(position.id, "VP001")
        XCTAssertEqual(position.vehicle.id, "BUS123")
        XCTAssertEqual(position.vehicle.label, "Bus 123")
        XCTAssertEqual(position.trip?.tripId, "TRIP001")
        XCTAssertEqual(position.position.latitude, 41.6523, accuracy: 0.0001)
        XCTAssertEqual(position.position.longitude, -4.7245, accuracy: 0.0001)
        XCTAssertEqual(position.bearing, 180.0)
        XCTAssertEqual(position.speed, 10.5)
        XCTAssertEqual(position.currentStopSequence, 5)
        XCTAssertEqual(position.currentStopId, "STOP123")
        XCTAssertEqual(position.occupancyStatus, .manySeatsAvailable)
    }

    func testVehiclePositionEquality() {
        let vehicle = Vehicle(id: "BUS123", label: "123", licensePlate: nil)
        let position = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let timestamp = Date()

        let vp1 = VehiclePosition(
            id: "VP001",
            vehicle: vehicle,
            trip: nil,
            position: position,
            bearing: nil,
            speed: nil,
            currentStopSequence: nil,
            currentStopId: nil,
            occupancyStatus: nil,
            timestamp: timestamp
        )

        let vp2 = VehiclePosition(
            id: "VP001",
            vehicle: vehicle,
            trip: nil,
            position: position,
            bearing: nil,
            speed: nil,
            currentStopSequence: nil,
            currentStopId: nil,
            occupancyStatus: nil,
            timestamp: timestamp
        )

        XCTAssertEqual(vp1, vp2)
    }

    func testVehiclePositionCodable() throws {
        let position = VehiclePosition(
            id: "VP001",
            vehicle: Vehicle(id: "BUS123", label: "123", licensePlate: "ABC"),
            trip: nil,
            position: Coordinate(latitude: 41.6523, longitude: -4.7245),
            bearing: 90.0,
            speed: 15.5,
            currentStopSequence: 3,
            currentStopId: "STOP456",
            occupancyStatus: .standingRoomOnly,
            timestamp: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(position)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VehiclePosition.self, from: data)

        XCTAssertEqual(position.id, decoded.id)
        XCTAssertEqual(position.vehicle.id, decoded.vehicle.id)
        XCTAssertEqual(position.position.latitude, decoded.position.latitude, accuracy: 0.0001)
        XCTAssertEqual(position.bearing, decoded.bearing)
        XCTAssertEqual(position.speed, decoded.speed)
    }
}
