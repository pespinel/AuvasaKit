import XCTest

@testable import AuvasaKit

/// Integration tests for AuvasaKit
/// Unit tests are in separate test files organized by component
final class AuvasaKitIntegrationTests: XCTestCase {
    var client: AuvasaClient?

    override func setUp() async throws {
        client = AuvasaClient()
    }

    override func tearDown() async throws {
        client = nil
    }

    private var testClient: AuvasaClient {
        guard let client else {
            fatalError("Client not initialized")
        }
        return client
    }

    // MARK: - Real-Time Integration Tests

    func testFetchVehiclePositionsIntegration() async throws {
        let positions = try await testClient.fetchVehiclePositions()

        XCTAssertGreaterThan(positions.count, 0, "Should fetch at least some vehicles")

        // Verify first vehicle has required fields
        if let firstVehicle = positions.first {
            XCTAssertFalse(firstVehicle.id.isEmpty)
            XCTAssertFalse(firstVehicle.vehicle.id.isEmpty)
            XCTAssertNotNil(firstVehicle.position)
            XCTAssertNotNil(firstVehicle.timestamp)
        }
    }

    func testFetchTripUpdatesIntegration() async throws {
        let tripUpdates = try await testClient.fetchTripUpdates()

        XCTAssertGreaterThan(tripUpdates.count, 0, "Should fetch at least some trip updates")

        // Verify first trip update has required fields
        if let firstUpdate = tripUpdates.first {
            XCTAssertFalse(firstUpdate.id.isEmpty)
            XCTAssertNotNil(firstUpdate.trip)
            XCTAssertNotNil(firstUpdate.timestamp)
        }
    }

    func testFetchAlertsIntegration() async throws {
        let alerts = try await testClient.fetchAlerts()

        // Alerts may or may not be present, so just verify the call succeeds
        XCTAssertGreaterThanOrEqual(alerts.count, 0)
    }

    func testFindNearbyVehiclesIntegration() async throws {
        // Plaza Mayor, Valladolid
        let plazaMayor = Coordinate(latitude: 41.6523, longitude: -4.7245)

        let nearbyVehicles = try await testClient.findNearbyVehicles(
            coordinate: plazaMayor,
            radiusMeters: 2_000
        )

        // Should find at least some vehicles (unless none are running)
        // We'll be lenient here since it depends on real-time data
        XCTAssertGreaterThanOrEqual(nearbyVehicles.count, 0)

        // If there are vehicles, verify they're actually within radius
        for vehicle in nearbyVehicles {
            let distance = plazaMayor.distance(to: vehicle.position)
            XCTAssertLessThanOrEqual(
                distance,
                2_000,
                "Vehicle \(vehicle.id) is beyond requested radius"
            )
        }
    }
}
