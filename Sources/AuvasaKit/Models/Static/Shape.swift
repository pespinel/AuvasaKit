import Foundation

/// Represents a single point in a route's geographic path
public struct ShapePoint: Sendable, Equatable, Codable {
    /// Shape identifier
    public let shapeId: String

    /// Latitude
    public let latitude: Double

    /// Longitude
    public let longitude: Double

    /// Point sequence
    public let sequence: Int

    /// Distance traveled from start (optional)
    public let distTraveled: Double?

    /// Creates a new shape point
    public init(
        shapeId: String,
        latitude: Double,
        longitude: Double,
        sequence: Int,
        distTraveled: Double? = nil
    ) {
        self.shapeId = shapeId
        self.latitude = latitude
        self.longitude = longitude
        self.sequence = sequence
        self.distTraveled = distTraveled
    }

    /// Converts to Coordinate
    public var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}

/// Represents a complete route shape (collection of points)
public struct Shape: Identifiable, Sendable, Equatable {
    /// Shape identifier
    public let id: String

    /// Ordered points that make up this shape
    public let points: [ShapePoint]

    /// Creates a new shape
    public init(id: String, points: [ShapePoint]) {
        self.id = id
        self.points = points.sorted { $0.sequence < $1.sequence }
    }

    /// Gets coordinates for drawing on a map
    public var coordinates: [Coordinate] {
        points.map(\.coordinate)
    }

    /// Total distance of the shape in meters (if available)
    public var totalDistance: Double? {
        points.last?.distTraveled
    }
}
