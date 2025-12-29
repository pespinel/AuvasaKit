import Foundation
import SwiftProtobuf

/// Parser for GTFS Real-Time protobuf data
actor ProtobufParser {
    /// Errors that can occur during parsing
    enum ParsingError: Error, LocalizedError {
        case invalidProtobuf
        case missingRequiredField(String)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .invalidProtobuf:
                "Invalid protobuf data"
            case .missingRequiredField(let field):
                "Missing required field: \(field)"
            case .invalidData:
                "Invalid data format"
            }
        }
    }

    /// Parses vehicle positions from protobuf data
    /// - Parameter data: Raw protobuf data
    /// - Returns: Array of vehicle positions
    /// - Throws: ParsingError if parsing fails
    func parseVehiclePositions(_ data: Data) throws -> [VehiclePosition] {
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)

        guard feedMessage.hasHeader else {
            throw ParsingError.missingRequiredField("header")
        }

        let entities = feedMessage.entity.filter(\.hasVehicle)

        return try entities.compactMap { entity in
            try convertVehiclePosition(entity.vehicle, id: entity.id)
        }
    }

    /// Parses trip updates from protobuf data
    /// - Parameter data: Raw protobuf data
    /// - Returns: Array of trip updates
    /// - Throws: ParsingError if parsing fails
    func parseTripUpdates(_ data: Data) throws -> [TripUpdate] {
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)

        guard feedMessage.hasHeader else {
            throw ParsingError.missingRequiredField("header")
        }

        let entities = feedMessage.entity.filter(\.hasTripUpdate)

        return try entities.compactMap { entity in
            try convertTripUpdate(entity.tripUpdate, id: entity.id)
        }
    }

    /// Parses alerts from protobuf data
    /// - Parameter data: Raw protobuf data
    /// - Returns: Array of alerts
    /// - Throws: ParsingError if parsing fails
    func parseAlerts(_ data: Data) throws -> [Alert] {
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)

        guard feedMessage.hasHeader else {
            throw ParsingError.missingRequiredField("header")
        }

        let entities = feedMessage.entity.filter(\.hasAlert)

        return try entities.compactMap { entity in
            try convertAlert(entity.alert, id: entity.id)
        }
    }

    // MARK: - Private Conversion Methods

    private func convertVehiclePosition(
        _ proto: TransitRealtime_VehiclePosition,
        id: String
    ) throws -> VehiclePosition {
        guard proto.hasPosition else {
            throw ParsingError.missingRequiredField("position")
        }

        guard proto.hasVehicle else {
            throw ParsingError.missingRequiredField("vehicle")
        }

        return VehiclePosition(
            id: id,
            vehicle: convertVehicle(proto.vehicle),
            trip: proto.hasTrip ? convertTripDescriptor(proto.trip) : nil,
            position: Coordinate(
                latitude: Double(proto.position.latitude),
                longitude: Double(proto.position.longitude)
            ),
            bearing: proto.position.hasBearing ? Double(proto.position.bearing) : nil,
            speed: proto.position.hasSpeed ? Double(proto.position.speed) : nil,
            currentStopSequence: proto.hasCurrentStopSequence ? Int(proto.currentStopSequence) : nil,
            currentStopId: proto.hasStopID ? proto.stopID : nil,
            status: proto.hasCurrentStatus ? convertVehicleStatus(proto.currentStatus) : nil,
            occupancyStatus: proto.hasOccupancyStatus ? convertOccupancyStatus(proto.occupancyStatus) : nil,
            timestamp: proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : Date()
        )
    }

    private func convertTripUpdate(
        _ proto: TransitRealtime_TripUpdate,
        id: String
    ) throws -> TripUpdate {
        guard proto.hasTrip else {
            throw ParsingError.missingRequiredField("trip")
        }

        let stopTimeUpdates = proto.stopTimeUpdate.compactMap { update in
            convertStopTimeUpdate(update)
        }

        return TripUpdate(
            id: id,
            trip: convertTripDescriptor(proto.trip),
            vehicle: proto.hasVehicle ? convertVehicle(proto.vehicle) : nil,
            stopTimeUpdates: stopTimeUpdates,
            delay: proto.hasDelay ? Int(proto.delay) : nil,
            timestamp: proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : Date()
        )
    }

    private func convertAlert(
        _ proto: TransitRealtime_Alert,
        id: String
    ) throws -> Alert {
        let activePeriods = proto.activePeriod.compactMap { period in
            convertTimeRange(period)
        }

        let informedEntities = proto.informedEntity.compactMap { entity in
            convertEntitySelector(entity)
        }

        return Alert(
            id: id,
            activePeriods: activePeriods,
            informedEntities: informedEntities,
            cause: proto.hasCause ? convertAlertCause(proto.cause) : nil,
            effect: proto.hasEffect ? convertAlertEffect(proto.effect) : nil,
            url: proto.hasURL ? URL(string: proto.url.translation.first?.text ?? "") : nil,
            headerText: proto.headerText.translation.first?.text ?? "",
            descriptionText: proto.descriptionText.translation.first?.text ?? "",
            severity: proto.hasSeverityLevel ? convertSeverityLevel(proto.severityLevel) : .unknown
        )
    }

    private func convertVehicle(_ proto: TransitRealtime_VehicleDescriptor) -> Vehicle {
        Vehicle(
            id: proto.hasID ? proto.id : "",
            label: proto.hasLabel ? proto.label : nil,
            licensePlate: proto.hasLicensePlate ? proto.licensePlate : nil
        )
    }

    private func convertTripDescriptor(_ proto: TransitRealtime_TripDescriptor) -> TripDescriptor {
        TripDescriptor(
            tripId: proto.hasTripID ? proto.tripID : nil,
            routeId: proto.hasRouteID ? proto.routeID : nil,
            directionId: proto.hasDirectionID ? Int(proto.directionID) : nil,
            startTime: proto.hasStartTime ? proto.startTime : nil,
            startDate: proto.hasStartDate ? proto.startDate : nil,
            scheduleRelationship: proto.hasScheduleRelationship
                ? convertScheduleRelationship(proto.scheduleRelationship)
                : .scheduled
        )
    }

    private func convertStopTimeUpdate(_ proto: TransitRealtime_TripUpdate.StopTimeUpdate) -> StopTimeUpdate {
        StopTimeUpdate(
            stopSequence: proto.hasStopSequence ? Int(proto.stopSequence) : nil,
            stopId: proto.hasStopID ? proto.stopID : nil,
            arrival: proto.hasArrival ? convertTimeEvent(proto.arrival) : nil,
            departure: proto.hasDeparture ? convertTimeEvent(proto.departure) : nil,
            scheduleRelationship: proto.hasScheduleRelationship
                ? convertStopTimeScheduleRelationship(proto.scheduleRelationship)
                : .scheduled
        )
    }

    private func convertTimeEvent(_ proto: TransitRealtime_TripUpdate.StopTimeEvent) -> TimeEvent {
        TimeEvent(
            delay: proto.hasDelay ? Int(proto.delay) : nil,
            time: proto.hasTime ? Date(timeIntervalSince1970: TimeInterval(proto.time)) : nil,
            uncertainty: proto.hasUncertainty ? Int(proto.uncertainty) : nil
        )
    }

    private func convertTimeRange(_ proto: TransitRealtime_TimeRange) -> TimeRange {
        let start = proto.hasStart ? Date(timeIntervalSince1970: TimeInterval(proto.start)) : Date()
        let end = proto.hasEnd ? Date(timeIntervalSince1970: TimeInterval(proto.end)) : nil
        return TimeRange(start: start, end: end)
    }

    private func convertEntitySelector(_ proto: TransitRealtime_EntitySelector) -> EntitySelector {
        let routeType: RouteType? = if proto.hasRouteType {
            RouteType(rawValue: Int(proto.routeType))
        } else {
            nil
        }

        return EntitySelector(
            agencyId: proto.hasAgencyID ? proto.agencyID : nil,
            routeId: proto.hasRouteID ? proto.routeID : nil,
            routeType: routeType,
            trip: proto.hasTrip ? convertTripDescriptor(proto.trip) : nil,
            stopId: proto.hasStopID ? proto.stopID : nil
        )
    }

    // MARK: - Enum Conversions

    private func convertOccupancyStatus(_ proto: TransitRealtime_VehiclePosition.OccupancyStatus) -> OccupancyStatus {
        switch proto {
        case .empty: .empty
        case .manySeatsAvailable: .manySeatsAvailable
        case .fewSeatsAvailable: .fewSeatsAvailable
        case .standingRoomOnly: .standingRoomOnly
        case .crushedStandingRoomOnly: .crushedStandingRoomOnly
        case .full: .full
        case .notAcceptingPassengers: .notAcceptingPassengers
        default: .notAcceptingPassengers
        }
    }

    private func convertVehicleStatus(_ proto: TransitRealtime_VehiclePosition.VehicleStopStatus) -> VehicleStatus {
        switch proto {
        case .incomingAt: .incomingAt
        case .stoppedAt: .stoppedAt
        case .inTransitTo: .inTransitTo
        default: .inTransitTo
        }
    }

    private func convertScheduleRelationship(
        _ proto: TransitRealtime_TripDescriptor.ScheduleRelationship
    ) -> ScheduleRelationship {
        switch proto {
        case .scheduled: .scheduled
        case .added: .added
        case .unscheduled: .unscheduled
        case .canceled: .canceled
        default: .scheduled
        }
    }

    private func convertStopTimeScheduleRelationship(
        _ proto: TransitRealtime_TripUpdate.StopTimeUpdate.ScheduleRelationship
    ) -> StopTimeScheduleRelationship {
        switch proto {
        case .scheduled: .scheduled
        case .skipped: .skipped
        case .noData: .noData
        default: .scheduled
        }
    }

    private func convertAlertCause(_ proto: TransitRealtime_Alert.Cause) -> AlertCause {
        switch proto {
        case .unknownCause: .unknown
        case .otherCause: .otherCause
        case .technicalProblem: .technicalProblem
        case .strike: .strike
        case .demonstration: .demonstration
        case .accident: .accident
        case .holiday: .holiday
        case .weather: .weather
        case .maintenance: .maintenance
        case .construction: .construction
        case .policeActivity: .policeActivity
        case .medicalEmergency: .medicalEmergency
        default: .unknown
        }
    }

    private func convertAlertEffect(_ proto: TransitRealtime_Alert.Effect) -> AlertEffect {
        switch proto {
        case .noService: .noService
        case .reducedService: .reducedService
        case .significantDelays: .significantDelays
        case .detour: .detour
        case .additionalService: .additionalService
        case .modifiedService: .modifiedService
        case .otherEffect: .otherEffect
        case .stopMoved: .stopMoved
        default: .unknownEffect
        }
    }

    private func convertSeverityLevel(_ proto: TransitRealtime_Alert.SeverityLevel) -> SeverityLevel {
        switch proto {
        case .unknownSeverity: .unknown
        case .info: .info
        case .warning: .warning
        case .severe: .severe
        default: .unknown
        }
    }
}
