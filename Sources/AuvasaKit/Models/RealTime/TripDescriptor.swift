import Foundation

/// Describes a trip in the transit system
public struct TripDescriptor: Sendable, Equatable, Codable {
    /// Trip ID from the GTFS feed
    public let tripId: String?

    /// Route ID from the GTFS feed
    public let routeId: String?

    /// Direction ID (typically 0 or 1)
    public let directionId: Int?

    /// Start time of the trip
    public let startTime: String?

    /// Start date of the trip (YYYYMMDD format)
    public let startDate: String?

    /// Schedule relationship
    public let scheduleRelationship: ScheduleRelationship

    /// Creates a new trip descriptor
    /// - Parameters:
    ///   - tripId: Trip identifier
    ///   - routeId: Route identifier
    ///   - directionId: Direction identifier
    ///   - startTime: Start time
    ///   - startDate: Start date
    ///   - scheduleRelationship: Schedule relationship
    public init(
        tripId: String? = nil,
        routeId: String? = nil,
        directionId: Int? = nil,
        startTime: String? = nil,
        startDate: String? = nil,
        scheduleRelationship: ScheduleRelationship = .scheduled
    ) {
        self.tripId = tripId
        self.routeId = routeId
        self.directionId = directionId
        self.startTime = startTime
        self.startDate = startDate
        self.scheduleRelationship = scheduleRelationship
    }
}
