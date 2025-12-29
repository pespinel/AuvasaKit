import Foundation
import XCTest

@testable import AuvasaKit

final class CoordinateTests: XCTestCase {
    func testCoordinateInitialization() {
        let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)
        XCTAssertEqual(coordinate.latitude, 41.6523, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -4.7245, accuracy: 0.0001)
    }

    func testCoordinateEquality() {
        let coord1 = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let coord2 = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let coord3 = Coordinate(latitude: 41.6500, longitude: -4.7200)

        XCTAssertEqual(coord1, coord2)
        XCTAssertNotEqual(coord1, coord3)
    }

    func testCoordinateCodable() throws {
        let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)

        let encoder = JSONEncoder()
        let data = try encoder.encode(coordinate)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coordinate.self, from: data)

        XCTAssertEqual(coordinate.latitude, decoded.latitude, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, decoded.longitude, accuracy: 0.0001)
    }

    func testDistanceCalculation() {
        // Plaza Mayor, Valladolid
        let plazaMayor = Coordinate(latitude: 41.6523, longitude: -4.7245)

        // Campo Grande, Valladolid (approx 1.5 km away)
        let campoGrande = Coordinate(latitude: 41.6498, longitude: -4.7383)

        let distance = plazaMayor.distance(to: campoGrande)

        // Distance should be approximately 1200-1300 meters
        XCTAssertGreaterThan(distance, 1_100)
        XCTAssertLessThan(distance, 1_400)
    }

    func testDistanceSameLocation() {
        let coord = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let distance = coord.distance(to: coord)

        XCTAssertEqual(distance, 0, accuracy: 0.01)
    }

    func testDistanceVeryCloseLocations() {
        let coord1 = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let coord2 = Coordinate(latitude: 41.6524, longitude: -4.7246)

        let distance = coord1.distance(to: coord2)

        // Should be about 10-20 meters (very small coordinate difference)
        XCTAssertGreaterThan(distance, 5)
        XCTAssertLessThan(distance, 25)
    }

    func testDistanceLongDistance() {
        // Valladolid
        let valladolid = Coordinate(latitude: 41.6523, longitude: -4.7245)

        // Madrid (approx 162 km away)
        let madrid = Coordinate(latitude: 40.4168, longitude: -3.7038)

        let distance = valladolid.distance(to: madrid)

        // Distance should be approximately 160-165 km
        XCTAssertGreaterThan(distance, 160_000)
        XCTAssertLessThan(distance, 165_000)
    }

    func testCLLocationCoordinate2DConversion() {
        let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let clCoordinate = coordinate.clLocationCoordinate2D

        XCTAssertEqual(clCoordinate.latitude, 41.6523, accuracy: 0.0001)
        XCTAssertEqual(clCoordinate.longitude, -4.7245, accuracy: 0.0001)
    }

    func testCoordinateDescription() {
        let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let description = coordinate.description

        XCTAssertTrue(description.contains("41.6523"))
        XCTAssertTrue(description.contains("-4.7245"))
    }
}
