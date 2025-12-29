import Foundation

/// Represents an update to a trip's timing information
public struct TripUpdate: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this update
    public let id: String

    /// Trip being updated
    public let trip: TripDescriptor

    /// Vehicle performing this trip
    public let vehicle: Vehicle?

    /// Updates for individual stops
    public let stopTimeUpdates: [StopTimeUpdate]

    /// Overall delay in seconds (negative means ahead of schedule)
    public let delay: Int?

    /// Timestamp of this update
    public let timestamp: Date

    /// Creates a new trip update
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - trip: Trip descriptor
    ///   - vehicle: Vehicle
    ///   - stopTimeUpdates: Stop time updates
    ///   - delay: Overall delay in seconds
    ///   - timestamp: Update timestamp
    public init(
        id: String,
        trip: TripDescriptor,
        vehicle: Vehicle? = nil,
        stopTimeUpdates: [StopTimeUpdate],
        delay: Int? = nil,
        timestamp: Date
    ) {
        self.id = id
        self.trip = trip
        self.vehicle = vehicle
        self.stopTimeUpdates = stopTimeUpdates
        self.delay = delay
        self.timestamp = timestamp
    }
}

/// Represents timing information for a specific stop in a trip
public struct StopTimeUpdate: Sendable, Equatable, Codable {
    /// Stop sequence number
    public let stopSequence: Int?

    /// Stop ID
    public let stopId: String?

    /// Arrival time information
    public let arrival: TimeEvent?

    /// Departure time information
    public let departure: TimeEvent?

    /// Schedule relationship for this stop
    public let scheduleRelationship: StopTimeScheduleRelationship

    /// Creates a new stop time update
    /// - Parameters:
    ///   - stopSequence: Stop sequence number
    ///   - stopId: Stop identifier
    ///   - arrival: Arrival time event
    ///   - departure: Departure time event
    ///   - scheduleRelationship: Schedule relationship
    public init(
        stopSequence: Int? = nil,
        stopId: String? = nil,
        arrival: TimeEvent? = nil,
        departure: TimeEvent? = nil,
        scheduleRelationship: StopTimeScheduleRelationship = .scheduled
    ) {
        self.stopSequence = stopSequence
        self.stopId = stopId
        self.arrival = arrival
        self.departure = departure
        self.scheduleRelationship = scheduleRelationship
    }
}

/// Represents a time event (arrival or departure)
public struct TimeEvent: Sendable, Equatable, Codable {
    /// Delay in seconds (negative means ahead of schedule)
    public let delay: Int?

    /// Absolute time of the event
    public let time: Date?

    /// Uncertainty in seconds
    public let uncertainty: Int?

    /// Creates a new time event
    /// - Parameters:
    ///   - delay: Delay in seconds
    ///   - time: Absolute time
    ///   - uncertainty: Uncertainty in seconds
    public init(delay: Int? = nil, time: Date? = nil, uncertainty: Int? = nil) {
        self.delay = delay
        self.time = time
        self.uncertainty = uncertainty
    }
}
