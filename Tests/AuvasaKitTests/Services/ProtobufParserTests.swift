import Foundation
import XCTest

@testable import AuvasaKit

final class ProtobufParserTests: XCTestCase {
    var parser: ProtobufParser?

    override func setUp() async throws {
        parser = ProtobufParser()
    }

    private var testParser: ProtobufParser {
        guard let parser else {
            fatalError("Parser not initialized")
        }
        return parser
    }

    // MARK: - Vehicle Position Tests

    func testParseVehiclePositions_WithValidData() async throws {
        // Create a minimal valid FeedMessage with vehicle positions
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        // Create a vehicle position entity
        var entity = TransitRealtime_FeedEntity()
        entity.id = "test_vehicle_1"

        var vehicle = TransitRealtime_VehiclePosition()
        vehicle.timestamp = UInt64(Date().timeIntervalSince1970)

        var position = TransitRealtime_Position()
        position.latitude = 41.6523
        position.longitude = -4.7245
        position.bearing = 90.0
        position.speed = 10.5
        vehicle.position = position

        var vehicleDescriptor = TransitRealtime_VehicleDescriptor()
        vehicleDescriptor.id = "V123"
        vehicleDescriptor.label = "Bus 1"
        vehicleDescriptor.licensePlate = "ABC123"
        vehicle.vehicle = vehicleDescriptor

        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = "TRIP_123"
        trip.routeID = "L1"
        trip.directionID = 0
        vehicle.trip = trip

        vehicle.currentStopSequence = 5
        vehicle.stopID = "STOP_813"
        vehicle.currentStatus = .inTransitTo
        vehicle.occupancyStatus = .manySeatsAvailable

        entity.vehicle = vehicle
        feedMessage.entity = [entity]

        // Serialize to Data
        let data = try feedMessage.serializedData()

        // Parse
        let positions = try await testParser.parseVehiclePositions(data)

        // Assert
        XCTAssertEqual(positions.count, 1)

        let parsedPosition = positions[0]
        XCTAssertEqual(parsedPosition.id, "test_vehicle_1")
        XCTAssertEqual(parsedPosition.vehicle.id, "V123")
        XCTAssertEqual(parsedPosition.vehicle.label, "Bus 1")
        XCTAssertEqual(parsedPosition.vehicle.licensePlate, "ABC123")
        XCTAssertEqual(parsedPosition.position.latitude, 41.6523, accuracy: 0.0001)
        XCTAssertEqual(parsedPosition.position.longitude, -4.7245, accuracy: 0.0001)
        XCTAssertEqual(parsedPosition.bearing, 90.0)
        XCTAssertEqual(parsedPosition.speed, 10.5)
        XCTAssertEqual(parsedPosition.currentStopSequence, 5)
        XCTAssertEqual(parsedPosition.currentStopId, "STOP_813")
        XCTAssertEqual(parsedPosition.trip?.tripId, "TRIP_123")
        XCTAssertEqual(parsedPosition.trip?.routeId, "L1")
        XCTAssertEqual(parsedPosition.trip?.directionId, 0)
        XCTAssertEqual(parsedPosition.occupancyStatus, .manySeatsAvailable)
    }

    func testParseVehiclePositions_WithMissingPosition() async throws {
        // Create a FeedMessage with vehicle but missing required position
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        var entity = TransitRealtime_FeedEntity()
        entity.id = "test_vehicle"

        var vehicle = TransitRealtime_VehiclePosition()
        vehicle.timestamp = UInt64(Date().timeIntervalSince1970)
        // Missing position - this should cause an error
        entity.vehicle = vehicle
        feedMessage.entity = [entity]

        let data = try feedMessage.serializedData()

        do {
            _ = try await testParser.parseVehiclePositions(data)
            XCTFail("Should have thrown an error")
        } catch let error as ProtobufParser.ParsingError {
            if case .missingRequiredField(let field) = error {
                XCTAssertEqual(field, "position")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testParseVehiclePositions_WithInvalidData() async throws {
        let invalidData = Data("This is not protobuf data".utf8)

        do {
            _ = try await testParser.parseVehiclePositions(invalidData)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw
            XCTAssertTrue(true)
        }
    }

    func testParseVehiclePositions_WithEmptyFeed() async throws {
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)
        feedMessage.entity = []

        let data = try feedMessage.serializedData()
        let positions = try await testParser.parseVehiclePositions(data)

        XCTAssertEqual(positions.count, 0)
    }

    // MARK: - Trip Update Tests

    func testParseTripUpdates_WithValidData() async throws {
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        var entity = TransitRealtime_FeedEntity()
        entity.id = "test_trip_update_1"

        var tripUpdate = TransitRealtime_TripUpdate()

        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = "TRIP_456"
        trip.routeID = "L2"
        tripUpdate.trip = trip

        var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
        stopTimeUpdate.stopSequence = 10
        stopTimeUpdate.stopID = "STOP_999"

        var arrival = TransitRealtime_TripUpdate.StopTimeEvent()
        arrival.delay = 120 // 2 minutes delay
        arrival.time = Int64(Date().timeIntervalSince1970 + 300)
        stopTimeUpdate.arrival = arrival

        tripUpdate.stopTimeUpdate = [stopTimeUpdate]
        tripUpdate.timestamp = UInt64(Date().timeIntervalSince1970)
        tripUpdate.delay = 120

        entity.tripUpdate = tripUpdate
        feedMessage.entity = [entity]

        let data = try feedMessage.serializedData()
        let updates = try await testParser.parseTripUpdates(data)

        XCTAssertEqual(updates.count, 1)

        let update = updates[0]
        XCTAssertEqual(update.id, "test_trip_update_1")
        XCTAssertEqual(update.trip.tripId, "TRIP_456")
        XCTAssertEqual(update.trip.routeId, "L2")
        XCTAssertEqual(update.delay, 120)
        XCTAssertEqual(update.stopTimeUpdates.count, 1)

        let stopUpdate = update.stopTimeUpdates[0]
        XCTAssertEqual(stopUpdate.stopSequence, 10)
        XCTAssertEqual(stopUpdate.stopId, "STOP_999")
        XCTAssertEqual(stopUpdate.arrival?.delay, 120)
    }

    // MARK: - Alert Tests

    func testParseAlerts_WithValidData() async throws {
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        var entity = TransitRealtime_FeedEntity()
        entity.id = "test_alert_1"

        var alert = TransitRealtime_Alert()

        // Add active period
        var activePeriod = TransitRealtime_TimeRange()
        activePeriod.start = UInt64(Date().timeIntervalSince1970)
        activePeriod.end = UInt64(Date().timeIntervalSince1970 + 3_600)
        alert.activePeriod = [activePeriod]

        // Add informed entity
        var informedEntity = TransitRealtime_EntitySelector()
        informedEntity.routeID = "L1"
        informedEntity.stopID = "STOP_813"
        alert.informedEntity = [informedEntity]

        // Add header text
        var headerText = TransitRealtime_TranslatedString()
        var translation = TransitRealtime_TranslatedString.Translation()
        translation.text = "Service disruption"
        translation.language = "en"
        headerText.translation = [translation]
        alert.headerText = headerText

        // Add description
        var descriptionText = TransitRealtime_TranslatedString()
        var descTranslation = TransitRealtime_TranslatedString.Translation()
        descTranslation.text = "Delays expected"
        descTranslation.language = "en"
        descriptionText.translation = [descTranslation]
        alert.descriptionText = descriptionText

        alert.cause = .accident
        alert.effect = .significantDelays // This is the protobuf enum value
        alert.severityLevel = .warning // This is the protobuf enum value

        entity.alert = alert
        feedMessage.entity = [entity]

        let data = try feedMessage.serializedData()
        let alerts = try await testParser.parseAlerts(data)

        XCTAssertEqual(alerts.count, 1)

        let parsedAlert = alerts[0]
        XCTAssertEqual(parsedAlert.id, "test_alert_1")
        XCTAssertEqual(parsedAlert.headerText, "Service disruption")
        XCTAssertEqual(parsedAlert.descriptionText, "Delays expected")
        XCTAssertEqual(parsedAlert.cause, .accident)
        XCTAssertEqual(parsedAlert.effect, .significantDelays)
        XCTAssertEqual(parsedAlert.severity, .warning)
        XCTAssertEqual(parsedAlert.activePeriods.count, 1)
        XCTAssertEqual(parsedAlert.informedEntities.count, 1)
    }

    // MARK: - Edge Cases

    func testParseVehiclePositions_WithOptionalFieldsMissing() async throws {
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        var entity = TransitRealtime_FeedEntity()
        entity.id = "minimal_vehicle"

        var vehicle = TransitRealtime_VehiclePosition()
        vehicle.timestamp = UInt64(Date().timeIntervalSince1970)

        var position = TransitRealtime_Position()
        position.latitude = 41.0
        position.longitude = -4.0
        // No bearing, speed, etc.
        vehicle.position = position

        var vehicleDescriptor = TransitRealtime_VehicleDescriptor()
        vehicleDescriptor.id = "V999"
        // No label or license plate
        vehicle.vehicle = vehicleDescriptor

        // No trip, stop sequence, etc.

        entity.vehicle = vehicle
        feedMessage.entity = [entity]

        let data = try feedMessage.serializedData()
        let positions = try await testParser.parseVehiclePositions(data)

        XCTAssertEqual(positions.count, 1)

        let parsedPositionResult = positions[0]
        XCTAssertEqual(parsedPositionResult.vehicle.id, "V999")
        XCTAssertNil(parsedPositionResult.vehicle.label)
        XCTAssertNil(parsedPositionResult.vehicle.licensePlate)
        XCTAssertNil(parsedPositionResult.bearing)
        XCTAssertNil(parsedPositionResult.speed)
        XCTAssertNil(parsedPositionResult.trip)
        XCTAssertNil(parsedPositionResult.currentStopSequence)
        XCTAssertNil(parsedPositionResult.currentStopId)
    }

    func testParseTripUpdates_WithMultipleStopTimeUpdates() async throws {
        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header.gtfsRealtimeVersion = "2.0"
        feedMessage.header.timestamp = UInt64(Date().timeIntervalSince1970)

        var entity = TransitRealtime_FeedEntity()
        entity.id = "multi_stop_update"

        var tripUpdate = TransitRealtime_TripUpdate()
        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = "TRIP_MULTI"
        tripUpdate.trip = trip

        // Add multiple stop time updates
        for stopIndex in 1...5 {
            var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
            stopTimeUpdate.stopSequence = UInt32(stopIndex)
            stopTimeUpdate.stopID = "STOP_\(stopIndex)"

            var arrival = TransitRealtime_TripUpdate.StopTimeEvent()
            arrival.delay = Int32(stopIndex * 60) // Increasing delays
            stopTimeUpdate.arrival = arrival

            tripUpdate.stopTimeUpdate.append(stopTimeUpdate)
        }

        entity.tripUpdate = tripUpdate
        feedMessage.entity = [entity]

        let data = try feedMessage.serializedData()
        let updates = try await testParser.parseTripUpdates(data)

        XCTAssertEqual(updates.count, 1)
        XCTAssertEqual(updates[0].stopTimeUpdates.count, 5)

        for (index, stopUpdate) in updates[0].stopTimeUpdates.enumerated() {
            XCTAssertEqual(stopUpdate.stopSequence, index + 1)
            let expectedDelay = (index + 1) * 60
            XCTAssertEqual(stopUpdate.arrival?.delay, expectedDelay)
        }
    }
}
