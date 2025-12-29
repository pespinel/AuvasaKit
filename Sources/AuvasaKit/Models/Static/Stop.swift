import CoreLocation
import Foundation

/// Represents a physical bus stop
public struct Stop: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this stop
    public let id: String

    /// Stop code (usually displayed to passengers)
    public let code: String?

    /// Stop name
    public let name: String

    /// Stop description
    public let desc: String?

    /// Geographic location
    public let coordinate: Coordinate

    /// Zone identifier
    public let zoneId: String?

    /// Stop URL with more information
    public let url: URL?

    /// Location type
    public let locationType: LocationType

    /// Parent station ID (if this stop is part of a larger station)
    public let parentStation: String?

    /// Wheelchair accessibility
    public let wheelchairBoarding: WheelchairBoarding

    /// Platform code
    public let platformCode: String?

    /// Creates a new stop
    public init(
        id: String,
        code: String? = nil,
        name: String,
        desc: String? = nil,
        coordinate: Coordinate,
        zoneId: String? = nil,
        url: URL? = nil,
        locationType: LocationType = .stop,
        parentStation: String? = nil,
        wheelchairBoarding: WheelchairBoarding = .unknown,
        platformCode: String? = nil
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.desc = desc
        self.coordinate = coordinate
        self.zoneId = zoneId
        self.url = url
        self.locationType = locationType
        self.parentStation = parentStation
        self.wheelchairBoarding = wheelchairBoarding
        self.platformCode = platformCode
    }

    /// Calculates distance to another stop in meters
    public func distance(to other: Stop) -> Double {
        coordinate.distance(to: other.coordinate)
    }

    /// Converts to CLLocationCoordinate2D
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
        coordinate.clLocationCoordinate2D
    }
}

// MARK: - Location Type

/// Type of location
public enum LocationType: Int, Sendable, Codable {
    /// A stop or platform where passengers board or alight
    case stop = 0

    /// A station containing multiple stops
    case station = 1

    /// An entrance or exit to a station
    case entranceExit = 2

    /// A generic node (for pathways)
    case genericNode = 3

    /// A boarding area
    case boardingArea = 4
}

// MARK: - CustomStringConvertible

extension Stop: CustomStringConvertible {
    public var description: String {
        if let code {
            return "\(name) (\(code))"
        }
        return name
    }
}
