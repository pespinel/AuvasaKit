import Foundation

/// Main client for accessing AUVASA bus data
///
/// AuvasaClient provides a simple interface to access real-time GTFS data
/// from AUVASA (Autobuses Urbanos de Valladolid).
///
/// Example usage:
/// ```swift
/// let client = AuvasaClient()
///
/// // Fetch vehicle positions
/// let vehicles = try await client.fetchVehiclePositions()
///
/// // Get nearby vehicles
/// let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)
/// let nearby = try await client.findNearbyVehicles(
///     coordinate: coordinate,
///     radiusMeters: 500
/// )
/// ```
public actor AuvasaClient {
    private let realtimeService: RealtimeService

    /// Configuration options for the client
    public struct Configuration {
        /// Request timeout in seconds
        public let timeout: TimeInterval

        /// Creates a new configuration
        /// - Parameter timeout: Request timeout in seconds (default: 30)
        public init(timeout: TimeInterval = 30) {
            self.timeout = timeout
        }

        /// Default configuration
        public static let `default` = Configuration()
    }

    /// Creates a new AUVASA client
    /// - Parameter configuration: Client configuration
    public init(configuration: Configuration = .default) {
        let apiClient = APIClient(timeout: configuration.timeout)
        self.realtimeService = RealtimeService(apiClient: apiClient)
    }

    // MARK: - Vehicle Positions

    /// Fetches all current vehicle positions
    ///
    /// - Returns: Array of vehicle positions with location, speed, and occupancy data
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let vehicles = try await client.fetchVehiclePositions()
    /// for vehicle in vehicles {
    ///     print("Bus \(vehicle.vehicle.label ?? "?"): \(vehicle.position)")
    /// }
    /// ```
    public func fetchVehiclePositions() async throws -> [VehiclePosition] {
        try await realtimeService.fetchVehiclePositions()
    }

    /// Fetches vehicle positions for a specific route
    ///
    /// - Parameter routeId: The route ID to filter by (e.g., "L1", "L2")
    /// - Returns: Array of vehicle positions for the specified route
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let line1Buses = try await client.fetchVehiclePositions(routeId: "L1")
    /// ```
    public func fetchVehiclePositions(routeId: String) async throws -> [VehiclePosition] {
        try await realtimeService.fetchVehiclePositions(routeId: routeId)
    }

    /// Finds vehicles near a specific location
    ///
    /// - Parameters:
    ///   - coordinate: The center point for the search
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Array of vehicles within the specified radius
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let plazaMayor = Coordinate(latitude: 41.6523, longitude: -4.7245)
    /// let nearbyBuses = try await client.findNearbyVehicles(
    ///     coordinate: plazaMayor,
    ///     radiusMeters: 500
    /// )
    /// ```
    public func findNearbyVehicles(
        coordinate: Coordinate,
        radiusMeters: Double
    ) async throws -> [VehiclePosition] {
        try await realtimeService.findNearbyVehicles(
            coordinate: coordinate,
            radiusMeters: radiusMeters
        )
    }

    // MARK: - Trip Updates

    /// Fetches all current trip updates with arrival/departure predictions
    ///
    /// - Returns: Array of trip updates with timing information
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let updates = try await client.fetchTripUpdates()
    /// for update in updates {
    ///     if let delay = update.delay {
    ///         print("Trip \(update.trip.tripId ?? "?") is \(delay)s delayed")
    ///     }
    /// }
    /// ```
    public func fetchTripUpdates() async throws -> [TripUpdate] {
        try await realtimeService.fetchTripUpdates()
    }

    /// Fetches trip updates for a specific stop
    ///
    /// - Parameter stopId: The stop ID to get predictions for
    /// - Returns: Array of trip updates affecting the specified stop
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let arrivals = try await client.fetchTripUpdates(stopId: "123")
    /// ```
    public func fetchTripUpdates(stopId: String) async throws -> [TripUpdate] {
        try await realtimeService.fetchTripUpdates(stopId: stopId)
    }

    /// Gets next arrivals at a stop with delay information
    ///
    /// - Parameters:
    ///   - stopId: The stop ID
    ///   - limit: Maximum number of arrivals to return (default: 5)
    /// - Returns: Array of trip updates sorted by arrival time
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let nextBuses = try await client.getNextArrivals(stopId: "123", limit: 3)
    /// for update in nextBuses {
    ///     print("Next bus in \(update.delay ?? 0)s")
    /// }
    /// ```
    public func getNextArrivals(
        stopId: String,
        limit: Int = 5
    ) async throws -> [TripUpdate] {
        let updates = try await fetchTripUpdates(stopId: stopId)

        return Array(
            updates
                .filter { update in
                    update.stopTimeUpdates.contains { $0.stopId == stopId }
                }
                .sorted { lhs, rhs in
                    // Sort by timestamp, earlier first
                    lhs.timestamp < rhs.timestamp
                }
                .prefix(limit)
        )
    }

    // MARK: - Service Alerts

    /// Fetches all current service alerts
    ///
    /// - Returns: Array of service alerts
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let alerts = try await client.fetchAlerts()
    /// for alert in alerts {
    ///     print("⚠️ \(alert.headerText)")
    /// }
    /// ```
    public func fetchAlerts() async throws -> [Alert] {
        try await realtimeService.fetchAlerts()
    }

    /// Fetches alerts affecting a specific route
    ///
    /// - Parameter routeId: The route ID to filter by
    /// - Returns: Array of alerts affecting the specified route
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let line1Alerts = try await client.fetchAlerts(routeId: "L1")
    /// ```
    public func fetchAlerts(routeId: String) async throws -> [Alert] {
        try await realtimeService.fetchAlerts(routeId: routeId)
    }

    /// Fetches alerts affecting a specific stop
    ///
    /// - Parameter stopId: The stop ID to filter by
    /// - Returns: Array of alerts affecting the specified stop
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let stopAlerts = try await client.fetchAlerts(stopId: "123")
    /// ```
    public func fetchAlerts(stopId: String) async throws -> [Alert] {
        try await realtimeService.fetchAlerts(stopId: stopId)
    }

    /// Fetches only currently active alerts
    ///
    /// Filters alerts to only include those that are active right now
    /// based on their active period.
    ///
    /// - Returns: Array of currently active alerts
    /// - Throws: `NetworkError` if the request fails
    ///
    /// Example:
    /// ```swift
    /// let activeAlerts = try await client.fetchActiveAlerts()
    /// if activeAlerts.isEmpty {
    ///     print("No active service alerts")
    /// }
    /// ```
    public func fetchActiveAlerts() async throws -> [Alert] {
        try await realtimeService.fetchActiveAlerts()
    }
}
