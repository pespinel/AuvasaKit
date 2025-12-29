import Foundation

/// Represents a single trip on a route
public struct Trip: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this trip
    public let id: String

    /// Route this trip belongs to
    public let routeId: String

    /// Service calendar
    public let serviceId: String

    /// Trip headsign (destination shown to passengers)
    public let headsign: String?

    /// Short trip name
    public let shortName: String?

    /// Direction identifier (0 or 1)
    public let directionId: Int?

    /// Block identifier (trips that use the same vehicle)
    public let blockId: String?

    /// Shape identifier for drawing the trip path
    public let shapeId: String?

    /// Wheelchair accessibility
    public let wheelchairAccessible: WheelchairAccessibility

    /// Bikes allowed
    public let bikesAllowed: BikesAllowed

    /// Creates a new trip
    public init(
        id: String,
        routeId: String,
        serviceId: String,
        headsign: String? = nil,
        shortName: String? = nil,
        directionId: Int? = nil,
        blockId: String? = nil,
        shapeId: String? = nil,
        wheelchairAccessible: WheelchairAccessibility = .unknown,
        bikesAllowed: BikesAllowed = .unknown
    ) {
        self.id = id
        self.routeId = routeId
        self.serviceId = serviceId
        self.headsign = headsign
        self.shortName = shortName
        self.directionId = directionId
        self.blockId = blockId
        self.shapeId = shapeId
        self.wheelchairAccessible = wheelchairAccessible
        self.bikesAllowed = bikesAllowed
    }
}

// MARK: - Wheelchair Accessibility

/// Indicates wheelchair accessibility
public enum WheelchairAccessibility: Int, Sendable, Codable {
    /// No information
    case unknown = 0

    /// Wheelchair accessible
    case accessible = 1

    /// Not wheelchair accessible
    case notAccessible = 2
}

// MARK: - Bikes Allowed

/// Indicates if bikes are allowed
public enum BikesAllowed: Int, Sendable, Codable {
    /// No information
    case unknown = 0

    /// Bikes allowed
    case allowed = 1

    /// Bikes not allowed
    case notAllowed = 2
}

// MARK: - CustomStringConvertible

extension Trip: CustomStringConvertible {
    public var description: String {
        headsign ?? shortName ?? id
    }
}
