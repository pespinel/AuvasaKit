import Foundation

/// Represents the real-time position of a vehicle
public struct VehiclePosition: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this position update
    public let id: String

    /// The vehicle
    public let vehicle: Vehicle

    /// Trip information
    public let trip: TripDescriptor?

    /// Current geographic position
    public let position: Coordinate

    /// Current bearing in degrees (0-360, where 0 is North)
    public let bearing: Double?

    /// Current speed in meters per second
    public let speed: Double?

    /// Current stop sequence number
    public let currentStopSequence: Int?

    /// ID of the current stop
    public let currentStopId: String?

    /// Current status of the vehicle
    public let status: VehicleStatus?

    /// Occupancy status of the vehicle
    public let occupancyStatus: OccupancyStatus?

    /// Timestamp of this position update
    public let timestamp: Date

    /// Creates a new vehicle position
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - vehicle: The vehicle
    ///   - trip: Trip information
    ///   - position: Geographic position
    ///   - bearing: Bearing in degrees
    ///   - speed: Speed in m/s
    ///   - currentStopSequence: Current stop sequence
    ///   - currentStopId: Current stop ID
    ///   - status: Vehicle status
    ///   - occupancyStatus: Occupancy status
    ///   - timestamp: Update timestamp
    public init(
        id: String,
        vehicle: Vehicle,
        trip: TripDescriptor? = nil,
        position: Coordinate,
        bearing: Double? = nil,
        speed: Double? = nil,
        currentStopSequence: Int? = nil,
        currentStopId: String? = nil,
        status: VehicleStatus? = nil,
        occupancyStatus: OccupancyStatus? = nil,
        timestamp: Date
    ) {
        self.id = id
        self.vehicle = vehicle
        self.trip = trip
        self.position = position
        self.bearing = bearing
        self.speed = speed
        self.currentStopSequence = currentStopSequence
        self.currentStopId = currentStopId
        self.status = status
        self.occupancyStatus = occupancyStatus
        self.timestamp = timestamp
    }

    /// Speed in kilometers per hour
    public var speedKmh: Double? {
        speed.map { $0 * 3.6 }
    }
}
