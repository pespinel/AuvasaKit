import CoreLocation
import Foundation

/// Represents a geographic bounding box
public struct BoundingBox {
    public let minLatitude: Double
    public let maxLatitude: Double
    public let minLongitude: Double
    public let maxLongitude: Double

    public init(minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }
}

/// Utilities for location and distance calculations
public enum LocationUtils {
    /// Earth's radius in meters
    private static let earthRadiusMeters: Double = 6_371_000

    /// Calculates distance between two coordinates using Haversine formula
    /// - Parameters:
    ///   - from: Starting coordinate
    ///   - to: Ending coordinate
    /// - Returns: Distance in meters
    ///
    /// Example:
    /// ```swift
    /// let madrid = Coordinate(latitude: 40.4168, longitude: -3.7038)
    /// let barcelona = Coordinate(latitude: 41.3851, longitude: 2.1734)
    /// let distance = LocationUtils.distance(from: madrid, to: barcelona)
    /// print("Distance: \(distance / 1000) km") // ~504 km
    /// ```
    public static func distance(from: Coordinate, to: Coordinate) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1) * cos(lat2) *
            sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMeters * c
    }

    /// Calculates bearing (direction) from one coordinate to another
    /// - Parameters:
    ///   - from: Starting coordinate
    ///   - to: Ending coordinate
    /// - Returns: Bearing in degrees (0-360), where 0 is North
    ///
    /// Example:
    /// ```swift
    /// let bearing = LocationUtils.bearing(from: coordA, to: coordB)
    /// print("Direction: \(bearing)°") // e.g., 45° (Northeast)
    /// ```
    public static func bearing(from: Coordinate, to: Coordinate) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Calculates bounding box for a coordinate with a given radius
    /// - Parameters:
    ///   - center: Center coordinate
    ///   - radiusMeters: Radius in meters
    /// - Returns: BoundingBox representing the area
    ///
    /// Example:
    /// ```swift
    /// let center = Coordinate(latitude: 41.6523, longitude: -4.7245)
    /// let bbox = LocationUtils.boundingBox(center: center, radiusMeters: 1000)
    /// // Use bbox to query database efficiently
    /// ```
    public static func boundingBox(
        center: Coordinate,
        radiusMeters: Double
    ) -> BoundingBox {
        let latDelta = radiusMeters / 111_000.0 // ~111km per degree latitude
        let lonDelta = radiusMeters / (111_000.0 * cos(center.latitude * .pi / 180))

        return BoundingBox(
            minLatitude: center.latitude - latDelta,
            maxLatitude: center.latitude + latDelta,
            minLongitude: center.longitude - lonDelta,
            maxLongitude: center.longitude + lonDelta
        )
    }

    /// Checks if a coordinate is within a bounding box
    /// - Parameters:
    ///   - coordinate: Coordinate to check
    ///   - boundingBox: BoundingBox to check against
    /// - Returns: True if coordinate is within bounds
    public static func isWithinBounds(
        _ coordinate: Coordinate,
        boundingBox: BoundingBox
    ) -> Bool {
        coordinate.latitude >= boundingBox.minLatitude &&
            coordinate.latitude <= boundingBox.maxLatitude &&
            coordinate.longitude >= boundingBox.minLongitude &&
            coordinate.longitude <= boundingBox.maxLongitude
    }

    /// Finds the nearest coordinate from a list
    /// - Parameters:
    ///   - to: Target coordinate
    ///   - coordinates: List of coordinates to search
    /// - Returns: Nearest coordinate and its distance, or nil if list is empty
    public static func nearest(
        to target: Coordinate,
        from coordinates: [Coordinate]
    ) -> (coordinate: Coordinate, distance: Double)? {
        guard !coordinates.isEmpty else { return nil }

        var nearest: (coordinate: Coordinate, distance: Double)?

        for coord in coordinates {
            let dist = distance(from: target, to: coord)
            if nearest.map({ dist < $0.distance }) ?? true {
                nearest = (coord, dist)
            }
        }

        return nearest
    }

    /// Formats distance for display
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string (e.g., "500 m" or "1.5 km")
    public static func formatDistance(_ meters: Double) -> String {
        if meters < 1_000 {
            String(format: "%.0f m", meters)
        } else {
            String(format: "%.1f km", meters / 1_000)
        }
    }

    /// Checks if two coordinates are approximately equal within a tolerance
    /// - Parameters:
    ///   - coord1: First coordinate
    ///   - coord2: Second coordinate
    ///   - toleranceMeters: Tolerance in meters (default: 10)
    /// - Returns: True if coordinates are within tolerance
    public static func areApproximatelyEqual(
        _ coord1: Coordinate,
        _ coord2: Coordinate,
        toleranceMeters: Double = 10
    ) -> Bool {
        distance(from: coord1, to: coord2) <= toleranceMeters
    }

    /// Interpolates between two coordinates
    /// - Parameters:
    ///   - from: Starting coordinate
    ///   - to: Ending coordinate
    ///   - fraction: Fraction of distance (0.0 to 1.0)
    /// - Returns: Interpolated coordinate
    ///
    /// Example:
    /// ```swift
    /// let start = Coordinate(latitude: 0, longitude: 0)
    /// let end = Coordinate(latitude: 1, longitude: 1)
    /// let midpoint = LocationUtils.interpolate(from: start, to: end, fraction: 0.5)
    /// // Returns coordinate at halfway point
    /// ```
    public static func interpolate(
        from: Coordinate,
        to: Coordinate,
        fraction: Double
    ) -> Coordinate {
        let clampedFraction = max(0, min(1, fraction))
        let lat = from.latitude + (to.latitude - from.latitude) * clampedFraction
        let lon = from.longitude + (to.longitude - from.longitude) * clampedFraction
        return Coordinate(latitude: lat, longitude: lon)
    }
}

// MARK: - CLLocationCoordinate2D Extension

public extension LocationUtils {
    /// Converts Coordinate to CLLocationCoordinate2D
    /// - Parameter coordinate: AuvasaKit coordinate
    /// - Returns: CoreLocation coordinate
    static func toCLLocationCoordinate(_ coordinate: Coordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    /// Converts CLLocationCoordinate2D to Coordinate
    /// - Parameter clCoordinate: CoreLocation coordinate
    /// - Returns: AuvasaKit coordinate
    static func fromCLLocationCoordinate(_ clCoordinate: CLLocationCoordinate2D) -> Coordinate {
        Coordinate(
            latitude: clCoordinate.latitude,
            longitude: clCoordinate.longitude
        )
    }
}
