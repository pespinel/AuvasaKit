/// AuvasaKit - Modern Swift SDK for AUVASA bus data
///
/// Provides access to real-time and static GTFS data for AUVASA (Autobuses Urbanos de Valladolid).
///
/// ## Getting Started
///
/// Create an `AuvasaClient` to start fetching bus data:
///
/// ```swift
/// import AuvasaKit
///
/// let client = AuvasaClient()
///
/// // Fetch real-time vehicle positions
/// let vehicles = try await client.fetchVehiclePositions()
///
/// // Get next arrivals at a stop
/// let arrivals = try await client.getNextArrivals(stopId: "123")
///
/// // Check for service alerts
/// let alerts = try await client.fetchActiveAlerts()
/// ```
///
/// ## Features
///
/// - Real-time vehicle positions with GPS coordinates
/// - Trip updates with arrival/departure predictions
/// - Service alerts and disruptions
/// - Geographic search for nearby vehicles
/// - Modern Swift concurrency with async/await
///
/// ## Requirements
///
/// - iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+
/// - Swift 5.9+
public enum AuvasaKit {
    /// The current version of AuvasaKit
    public static let version = "0.1"

    /// Creates a new AUVASA client with default configuration
    ///
    /// This is a convenience method that creates an `AuvasaClient` instance.
    ///
    /// - Returns: A configured `AuvasaClient` instance
    ///
    /// Example:
    /// ```swift
    /// let client = AuvasaKit.client()
    /// let buses = try await client.fetchVehiclePositions()
    /// ```
    public static func client() -> AuvasaClient {
        AuvasaClient()
    }

    /// Creates a new AUVASA client with custom configuration
    ///
    /// - Parameter configuration: Client configuration
    /// - Returns: A configured `AuvasaClient` instance
    ///
    /// Example:
    /// ```swift
    /// let config = AuvasaClient.Configuration(timeout: 60)
    /// let client = AuvasaKit.client(configuration: config)
    /// ```
    public static func client(configuration: AuvasaClient.Configuration) -> AuvasaClient {
        AuvasaClient(configuration: configuration)
    }
}
