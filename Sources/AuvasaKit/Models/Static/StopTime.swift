import Foundation

/// Represents a scheduled stop time for a trip
public struct StopTime: Sendable, Equatable, Codable {
    /// Trip identifier
    public let tripId: String

    /// Arrival time (HH:MM:SS format, can be > 24:00:00)
    public let arrivalTime: String

    /// Departure time (HH:MM:SS format, can be > 24:00:00)
    public let departureTime: String

    /// Stop identifier
    public let stopId: String

    /// Stop sequence (order of stops in trip)
    public let stopSequence: Int

    /// Headsign at this stop
    public let stopHeadsign: String?

    /// Pickup type
    public let pickupType: PickupDropOffType

    /// Drop off type
    public let dropOffType: PickupDropOffType

    /// Shape distance traveled (meters from start of trip)
    public let shapeDistTraveled: Double?

    /// Timepoint indicator
    public let timepoint: Timepoint

    /// Creates a new stop time
    public init(
        tripId: String,
        arrivalTime: String,
        departureTime: String,
        stopId: String,
        stopSequence: Int,
        stopHeadsign: String? = nil,
        pickupType: PickupDropOffType = .regular,
        dropOffType: PickupDropOffType = .regular,
        shapeDistTraveled: Double? = nil,
        timepoint: Timepoint = .approximate
    ) {
        self.tripId = tripId
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
        self.stopId = stopId
        self.stopSequence = stopSequence
        self.stopHeadsign = stopHeadsign
        self.pickupType = pickupType
        self.dropOffType = dropOffType
        self.shapeDistTraveled = shapeDistTraveled
        self.timepoint = timepoint
    }

    /// Converts arrival time string to seconds since midnight
    public var arrivalTimeInSeconds: Int? {
        timeStringToSeconds(arrivalTime)
    }

    /// Converts departure time string to seconds since midnight
    public var departureTimeInSeconds: Int? {
        timeStringToSeconds(departureTime)
    }

    private func timeStringToSeconds(_ time: String) -> Int? {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return components[0] * 3_600 + components[1] * 60 + components[2]
    }
}

// MARK: - Pickup/Drop Off Type

/// Indicates pickup or drop off availability
public enum PickupDropOffType: Int, Sendable, Codable {
    /// Regular pickup/drop off
    case regular = 0

    /// No pickup/drop off available
    case none = 1

    /// Must phone agency to arrange pickup/drop off
    case mustPhone = 2

    /// Must coordinate with driver
    case mustCoordinate = 3
}

// MARK: - Timepoint

/// Indicates if times are exact or approximate
public enum Timepoint: Int, Sendable, Codable {
    /// Approximate times
    case approximate = 0

    /// Exact times
    case exact = 1
}
