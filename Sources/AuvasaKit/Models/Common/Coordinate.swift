import Foundation
import CoreLocation

/// Represents a geographic coordinate with latitude and longitude
public struct Coordinate: Sendable, Equatable, Codable {
    /// The latitude in degrees
    public let latitude: Double

    /// The longitude in degrees
    public let longitude: Double

    /// Creates a new coordinate
    /// - Parameters:
    ///   - latitude: The latitude in degrees (-90 to 90)
    ///   - longitude: The longitude in degrees (-180 to 180)
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Calculates the distance to another coordinate in meters using the Haversine formula
    /// - Parameter other: The target coordinate
    /// - Returns: The distance in meters
    public func distance(to other: Coordinate) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters

        let lat1Rad = latitude * .pi / 180
        let lat2Rad = other.latitude * .pi / 180
        let deltaLat = (other.latitude - latitude) * .pi / 180
        let deltaLon = (other.longitude - longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Converts to CLLocationCoordinate2D for CoreLocation integration
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - CustomStringConvertible

extension Coordinate: CustomStringConvertible {
    public var description: String {
        String(format: "(%.6f, %.6f)", latitude, longitude)
    }
}
