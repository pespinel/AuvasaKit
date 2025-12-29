import Foundation
import XCTest

@testable import AuvasaKit

final class LocationUtilsTests: XCTestCase {
    func testBoundingBoxCalculation() {
        // Center: Plaza Mayor, Valladolid
        let center = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let radiusMeters: Double = 1_000 // 1 km

        let boundingBox = LocationUtils.boundingBox(
            center: center,
            radiusMeters: radiusMeters
        )

        // Verify the center is within the bounding box
        XCTAssertGreaterThan(center.latitude, boundingBox.minLatitude)
        XCTAssertLessThan(center.latitude, boundingBox.maxLatitude)
        XCTAssertGreaterThan(center.longitude, boundingBox.minLongitude)
        XCTAssertLessThan(center.longitude, boundingBox.maxLongitude)

        // Verify box is roughly symmetric around center
        let latDiff = boundingBox.maxLatitude - boundingBox.minLatitude
        let lonDiff = boundingBox.maxLongitude - boundingBox.minLongitude

        // Latitude difference should be roughly 2 * (radius / 111km) ≈ 0.018 degrees
        XCTAssertGreaterThan(latDiff, 0.015)
        XCTAssertLessThan(latDiff, 0.025)

        // Longitude difference should be larger at this latitude (cos factor)
        XCTAssertGreaterThan(lonDiff, latDiff)
    }

    func testIsCoordinateInBoundingBox() {
        let boundingBox = BoundingBox(
            minLatitude: 41.64,
            maxLatitude: 41.66,
            minLongitude: -4.74,
            maxLongitude: -4.71
        )

        // Inside
        let inside = Coordinate(latitude: 41.65, longitude: -4.72)
        XCTAssertTrue(LocationUtils.isWithinBounds(inside, boundingBox: boundingBox))

        // Outside (north)
        let outsideNorth = Coordinate(latitude: 41.67, longitude: -4.72)
        XCTAssertFalse(LocationUtils.isWithinBounds(outsideNorth, boundingBox: boundingBox))

        // Outside (west)
        let outsideWest = Coordinate(latitude: 41.65, longitude: -4.75)
        XCTAssertFalse(LocationUtils.isWithinBounds(outsideWest, boundingBox: boundingBox))

        // On edge (should be inside)
        let onEdge = Coordinate(latitude: 41.64, longitude: -4.72)
        XCTAssertTrue(LocationUtils.isWithinBounds(onEdge, boundingBox: boundingBox))
    }

    func testNearestCoordinate() {
        let target = Coordinate(latitude: 41.6523, longitude: -4.7245)

        let coordinates = [
            Coordinate(latitude: 41.6700, longitude: -4.7500), // FAR
            Coordinate(latitude: 41.6530, longitude: -4.7250), // NEAR
            Coordinate(latitude: 41.6600, longitude: -4.7300) // MID
        ]

        let result = LocationUtils.nearest(to: target, from: coordinates)

        XCTAssertNotNil(result)
        if let result {
            XCTAssertEqual(result.coordinate.latitude, 41.6530, accuracy: 0.0001)
            XCTAssertEqual(result.coordinate.longitude, -4.7250, accuracy: 0.0001)
            XCTAssertLessThan(result.distance, 200)
        }
    }

    func testNearestCoordinateEmptyList() {
        let target = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let result = LocationUtils.nearest(to: target, from: [])
        XCTAssertNil(result)
    }

    func testBearingCalculation() {
        let start = Coordinate(latitude: 41.6523, longitude: -4.7245)

        // North
        let north = Coordinate(latitude: 41.6623, longitude: -4.7245)
        let bearingNorth = LocationUtils.bearing(from: start, to: north)
        XCTAssertEqual(bearingNorth, 0, accuracy: 5)

        // South
        let south = Coordinate(latitude: 41.6423, longitude: -4.7245)
        let bearingSouth = LocationUtils.bearing(from: start, to: south)
        XCTAssertEqual(bearingSouth, 180, accuracy: 5)

        // East
        let east = Coordinate(latitude: 41.6523, longitude: -4.7145)
        let bearingEast = LocationUtils.bearing(from: start, to: east)
        XCTAssertEqual(bearingEast, 90, accuracy: 5)

        // West
        let west = Coordinate(latitude: 41.6523, longitude: -4.7345)
        let bearingWest = LocationUtils.bearing(from: start, to: west)
        XCTAssertEqual(bearingWest, 270, accuracy: 5)
    }

    func testFormatDistance() {
        XCTAssertEqual(LocationUtils.formatDistance(500), "500 m")
        XCTAssertEqual(LocationUtils.formatDistance(1_500), "1.5 km")
        XCTAssertEqual(LocationUtils.formatDistance(12_345), "12.3 km")
    }

    func testAreApproximatelyEqual() {
        let coord1 = Coordinate(latitude: 41.6523, longitude: -4.7245)
        let coord2 = Coordinate(latitude: 41.6523001, longitude: -4.7245001)
        let coord3 = Coordinate(latitude: 41.6530, longitude: -4.7250)

        XCTAssertTrue(LocationUtils.areApproximatelyEqual(coord1, coord2))
        XCTAssertFalse(LocationUtils.areApproximatelyEqual(coord1, coord3))
    }

    func testInterpolate() {
        let start = Coordinate(latitude: 0, longitude: 0)
        let end = Coordinate(latitude: 10, longitude: 10)

        let midpoint = LocationUtils.interpolate(from: start, to: end, fraction: 0.5)
        XCTAssertEqual(midpoint.latitude, 5, accuracy: 0.001)
        XCTAssertEqual(midpoint.longitude, 5, accuracy: 0.001)

        let quarterPoint = LocationUtils.interpolate(from: start, to: end, fraction: 0.25)
        XCTAssertEqual(quarterPoint.latitude, 2.5, accuracy: 0.001)
        XCTAssertEqual(quarterPoint.longitude, 2.5, accuracy: 0.001)
    }
}
