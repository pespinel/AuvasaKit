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
    let realtimeService: RealtimeService
    let stopService: StopService
    let routeService: RouteService
    let scheduleService: ScheduleService
    let gtfsImporter: GTFSImporter
    let databaseManager: DatabaseManager
    let subscriptionManager: SubscriptionManager

    /// Configuration options for the client
    public struct Configuration {
        /// Request timeout in seconds
        public let timeout: TimeInterval
        /// Database manager for static data
        public let databaseManager: DatabaseManager
        /// Polling interval for subscriptions in seconds
        public let pollingInterval: TimeInterval

        /// Creates a new configuration
        /// - Parameters:
        ///   - timeout: Request timeout in seconds (default: 30)
        ///   - databaseManager: Database manager (default: .shared)
        ///   - pollingInterval: Polling interval for subscriptions (default: 30)
        public init(
            timeout: TimeInterval = 30,
            databaseManager: DatabaseManager = .shared,
            pollingInterval: TimeInterval = 30
        ) {
            self.timeout = timeout
            self.databaseManager = databaseManager
            self.pollingInterval = pollingInterval
        }

        /// Default configuration
        public static let `default` = Configuration()
    }

    /// Creates a new AUVASA client
    /// - Parameter configuration: Client configuration
    public init(configuration: Configuration = .default) {
        let apiClient = APIClient(timeout: configuration.timeout)
        self.realtimeService = RealtimeService(apiClient: apiClient)
        self.databaseManager = configuration.databaseManager
        self.stopService = StopService(databaseManager: databaseManager)
        self.routeService = RouteService(databaseManager: databaseManager)
        self.scheduleService = ScheduleService(databaseManager: databaseManager)
        self.gtfsImporter = GTFSImporter(databaseManager: databaseManager)
        self.subscriptionManager = SubscriptionManager(
            realtimeService: realtimeService,
            pollingInterval: configuration.pollingInterval
        )
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

    /// Gets next arrivals at a stop combining schedule and real-time data
    ///
    /// This method merges static GTFS schedule data with live trip updates
    /// to provide accurate arrival predictions. It shows scheduled times
    /// along with real-time estimates and delays when available.
    ///
    /// - Parameters:
    ///   - stopId: The stop ID
    ///   - limit: Maximum number of arrivals to return (default: 5)
    /// - Returns: Array of arrivals sorted by best available time
    /// - Throws: `NetworkError` if the request fails, database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let nextBuses = try await client.getNextArrivals(stopId: "123", limit: 3)
    /// for arrival in nextBuses {
    ///     if arrival.realtimeAvailable {
    ///         print("\(arrival.route.shortName): \(arrival.estimatedTime!) (\(arrival.delayDescription ?? ""))")
    ///     } else {
    ///         print("\(arrival.route.shortName): \(arrival.scheduledTime) (scheduled)")
    ///     }
    /// }
    /// ```
    public func getNextArrivals(
        stopId: String,
        limit: Int = 5
    ) async throws -> [Arrival] {
        let currentTime = getCurrentTimeString()
        let stopTimes = try await scheduleService.fetchUpcomingDepartures(
            stopId: stopId,
            afterTime: currentTime,
            limit: limit * 3
        )

        let tripUpdates = try await realtimeService.fetchTripUpdates(stopId: stopId)
        let tripUpdateMap = createTripUpdateMap(from: tripUpdates)

        let arrivals = try await buildArrivals(
            from: stopTimes,
            stopId: stopId,
            tripUpdateMap: tripUpdateMap
        )

        return Array(arrivals.sorted { $0.bestTime < $1.bestTime }.prefix(limit))
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

    // MARK: - Static Data Import

    /// Downloads and imports GTFS static data
    ///
    /// This operation downloads the GTFS ZIP file from AUVASA and imports
    /// all static data (stops, routes, trips, schedules) into the local database.
    /// This is a long-running operation that should typically be done on first launch
    /// or when updating the static data.
    ///
    /// - Throws: Import errors if download or parsing fails
    ///
    /// Example:
    /// ```swift
    /// // On first launch
    /// try await client.updateStaticData()
    /// ```
    public func updateStaticData() async throws {
        try await gtfsImporter.importGTFSData()
    }

    // MARK: - Stops

    /// Searches stops by name
    ///
    /// - Parameter query: Search query (case-insensitive, partial match)
    /// - Returns: Array of matching stops
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let stops = try await client.searchStops(query: "plaza")
    /// ```
    public func searchStops(query: String) async throws -> [Stop] {
        try await stopService.searchStops(query: query)
    }

    /// Finds stops near a coordinate
    ///
    /// - Parameters:
    ///   - coordinate: Center point for search
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Array of nearby stops sorted by distance
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let coordinate = Coordinate(latitude: 41.6523, longitude: -4.7245)
    /// let nearbyStops = try await client.findNearbyStops(
    ///     coordinate: coordinate,
    ///     radiusMeters: 500
    /// )
    /// ```
    public func findNearbyStops(
        coordinate: Coordinate,
        radiusMeters: Double
    ) async throws -> [Stop] {
        try await stopService.findNearbyStopsOptimized(
            coordinate: coordinate,
            radiusMeters: radiusMeters
        )
    }

    /// Gets a stop by ID
    ///
    /// - Parameter id: Stop identifier
    /// - Returns: Stop if found, nil otherwise
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// if let stop = try await client.getStop(id: "123") {
    ///     print("Stop: \(stop.name)")
    /// }
    /// ```
    public func getStop(id: String) async throws -> Stop? {
        try await stopService.fetchStop(id: id)
    }

    /// Fetches all stops
    ///
    /// - Returns: Array of all stops
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let allStops = try await client.fetchAllStops()
    /// ```
    public func fetchAllStops() async throws -> [Stop] {
        try await stopService.fetchAllStops()
    }

    /// Fetches wheelchair accessible stops
    ///
    /// - Returns: Array of stops with wheelchair boarding
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let accessibleStops = try await client.fetchWheelchairAccessibleStops()
    /// ```
    public func fetchWheelchairAccessibleStops() async throws -> [Stop] {
        try await stopService.fetchWheelchairAccessibleStops()
    }

    // MARK: - Routes

    /// Fetches all routes
    ///
    /// - Returns: Array of all routes sorted by sort order and name
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let routes = try await client.fetchRoutes()
    /// for route in routes {
    ///     print("\(route.shortName): \(route.longName)")
    /// }
    /// ```
    public func fetchRoutes() async throws -> [Route] {
        try await routeService.fetchAllRoutes()
    }

    /// Gets a route by ID
    ///
    /// - Parameter id: Route identifier
    /// - Returns: Route if found, nil otherwise
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// if let route = try await client.getRoute(id: "L1") {
    ///     print("Route: \(route.longName)")
    /// }
    /// ```
    public func getRoute(id: String) async throws -> Route? {
        try await routeService.fetchRoute(id: id)
    }

    /// Searches routes by name
    ///
    /// - Parameter query: Search query (case-insensitive, partial match)
    /// - Returns: Array of matching routes
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let routes = try await client.searchRoutes(query: "circular")
    /// ```
    public func searchRoutes(query: String) async throws -> [Route] {
        try await routeService.searchRoutes(query: query)
    }

    /// Fetches routes by type
    ///
    /// - Parameter type: Route type (bus, tram, etc.)
    /// - Returns: Array of routes of specified type
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let buses = try await client.fetchRoutes(type: .bus)
    /// ```
    public func fetchRoutes(type: RouteType) async throws -> [Route] {
        try await routeService.fetchRoutes(type: type)
    }

    // MARK: - Schedules

    /// Gets the schedule for a stop on a specific date
    ///
    /// - Parameters:
    ///   - stopId: Stop identifier
    ///   - date: Date to get schedule for (default: today)
    /// - Returns: Array of stop times for the date
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let schedule = try await client.getSchedule(stopId: "123")
    /// for stopTime in schedule {
    ///     print("Departure: \(stopTime.departureTime)")
    /// }
    /// ```
    public func getSchedule(
        stopId: String,
        date: Date = Date()
    ) async throws -> [StopTime] {
        try await scheduleService.fetchStopTimes(stopId: stopId, date: date)
    }

    /// Gets all stop times for a specific trip in order
    ///
    /// Returns the complete list of stops for a trip in the correct sequence,
    /// useful for showing the full route and calculating remaining stops.
    ///
    /// - Parameter tripId: Trip identifier
    /// - Returns: Array of stop times sorted by stop sequence
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let stopTimes = try await client.getStopTimes(tripId: "L6A6_L6A4_17")
    /// for stopTime in stopTimes {
    ///     print("\(stopTime.stopSequence): Stop \(stopTime.stopId) at \(stopTime.departureTime)")
    /// }
    /// ```
    public func getStopTimes(tripId: String) async throws -> [StopTime] {
        try await scheduleService.fetchStopTimes(tripId: tripId)
    }

    /// Fetches upcoming departures from a stop
    ///
    /// - Parameters:
    ///   - stopId: Stop identifier
    ///   - afterTime: Time to search after (HH:MM:SS format)
    ///   - limit: Maximum number of results (default: 10)
    /// - Returns: Array of upcoming stop times
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let now = "14:30:00"
    /// let upcoming = try await client.fetchUpcomingDepartures(
    ///     stopId: "123",
    ///     afterTime: now,
    ///     limit: 5
    /// )
    /// ```
    public func fetchUpcomingDepartures(
        stopId: String,
        afterTime: String,
        limit: Int = 10
    ) async throws -> [StopTime] {
        try await scheduleService.fetchUpcomingDepartures(
            stopId: stopId,
            afterTime: afterTime,
            limit: limit
        )
    }

    /// Gets a trip by ID
    ///
    /// - Parameter tripId: Trip identifier
    /// - Returns: Trip if found, nil otherwise
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// if let trip = try await client.getTrip(id: "trip123") {
    ///     print("Trip headsign: \(trip.headsign ?? "")")
    /// }
    /// ```
    public func getTrip(id: String) async throws -> Trip? {
        try await scheduleService.fetchTrip(id: id)
    }

    /// Fetches trips for a route
    ///
    /// - Parameter routeId: Route identifier
    /// - Returns: Array of trips for the route
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let trips = try await client.fetchTrips(routeId: "L1")
    /// ```
    public func fetchTrips(routeId: String) async throws -> [Trip] {
        try await scheduleService.fetchTrips(routeId: routeId)
    }

    /// Checks if a service is active on a date
    ///
    /// - Parameters:
    ///   - serviceId: Service identifier
    ///   - date: Date to check
    /// - Returns: True if service is active
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let isActive = try await client.isServiceActive(
    ///     serviceId: "weekday",
    ///     on: Date()
    /// )
    /// ```
    public func isServiceActive(
        serviceId: String,
        on date: Date
    ) async throws -> Bool {
        try await scheduleService.isServiceActive(serviceId: serviceId, on: date)
    }

    /// Fetches shape points for a route
    ///
    /// - Parameter shapeId: Shape identifier
    /// - Returns: Array of shape points sorted by sequence
    /// - Throws: Database errors if query fails
    ///
    /// Example:
    /// ```swift
    /// let points = try await client.fetchShapePoints(shapeId: "shape1")
    /// // Use points to draw route on map
    /// ```
    public func fetchShapePoints(shapeId: String) async throws -> [ShapePoint] {
        try await scheduleService.fetchShapePoints(shapeId: shapeId)
    }

    // MARK: - Advanced Features

    /// Gets complete details for a specific trip with real-time updates
    ///
    /// Provides comprehensive information about a trip including all stops,
    /// schedule, real-time vehicle position, delays, and trip progress.
    ///
    /// - Parameter tripId: Trip identifier
    /// - Returns: Complete trip details with real-time data
    /// - Throws: Database errors if query fails, or if trip not found
    ///
    /// Example:
    /// ```swift
    /// let details = try await client.getTripDetails(tripId: "trip123")
    /// print("Route: \(details.route.shortName) - \(details.trip.headsign ?? "")")
    /// if let vehicle = details.vehiclePosition {
    ///     print("Vehicle at: \(vehicle.position)")
    /// }
    /// print("Progress: \(Int((details.progress ?? 0) * 100))%")
    /// ```
    public func getTripDetails(tripId: String) async throws -> TripDetails {
        guard let trip = try await scheduleService.fetchTrip(id: tripId) else {
            throw AuvasaError.notFound("Trip not found: \(tripId)")
        }

        guard let route = try await routeService.fetchRoute(id: trip.routeId) else {
            throw AuvasaError.notFound("Route not found: \(trip.routeId)")
        }

        let stopTimes = try await scheduleService.fetchStopTimes(tripId: tripId)
        let (tripUpdate, vehiclePosition) = try await fetchRealtimeData(tripId: tripId)

        let stopArrivals = try buildTripStopArrivals(
            stopTimes: stopTimes,
            trip: trip,
            route: route,
            tripUpdate: tripUpdate
        )

        let progress = calculateTripProgress(
            vehiclePosition: vehiclePosition,
            stopCount: stopArrivals.count
        )

        return TripDetails(
            trip: trip,
            route: route,
            stopArrivals: stopArrivals,
            vehiclePosition: vehiclePosition,
            delay: tripUpdate?.delay,
            realtimeAvailable: tripUpdate != nil,
            progress: progress
        )
    }

    // MARK: - Real-Time Subscriptions

    /// Subscribes to all vehicle position updates
    ///
    /// Creates a stream that automatically polls for vehicle positions
    /// at the configured interval and yields updates as they become available.
    ///
    /// - Returns: AsyncStream of vehicle position arrays
    ///
    /// Example:
    /// ```swift
    /// for await positions in client.subscribeToVehiclePositions() {
    ///     print("Received \(positions.count) vehicles")
    ///     // Update UI with new positions
    /// }
    /// ```
    public func subscribeToVehiclePositions() -> AsyncStream<[VehiclePosition]> {
        subscriptionManager.subscribeToVehiclePositions()
    }

    /// Subscribes to vehicle position updates for a specific route
    ///
    /// - Parameter routeId: Route identifier to filter by
    /// - Returns: AsyncStream of vehicle position arrays for the route
    ///
    /// Example:
    /// ```swift
    /// for await positions in client.subscribeToVehiclePositions(routeId: "L1") {
    ///     print("Line 1 has \(positions.count) buses")
    ///     // Update map markers for line 1
    /// }
    /// ```
    public func subscribeToVehiclePositions(routeId: String) -> AsyncStream<[VehiclePosition]> {
        subscriptionManager.subscribeToVehiclePositions(routeId: routeId)
    }

    /// Subscribes to all trip update notifications
    ///
    /// - Returns: AsyncStream of trip update arrays
    ///
    /// Example:
    /// ```swift
    /// for await updates in client.subscribeToTripUpdates() {
    ///     print("Received \(updates.count) trip updates")
    ///     // Process arrival predictions
    /// }
    /// ```
    public func subscribeToTripUpdates() -> AsyncStream<[TripUpdate]> {
        subscriptionManager.subscribeToTripUpdates()
    }

    /// Subscribes to trip updates for a specific stop
    ///
    /// - Parameter stopId: Stop identifier to filter by
    /// - Returns: AsyncStream of trip update arrays for the stop
    ///
    /// Example:
    /// ```swift
    /// for await updates in client.subscribeToTripUpdates(stopId: "123") {
    ///     print("Stop has \(updates.count) upcoming arrivals")
    ///     // Update real-time arrival board
    /// }
    /// ```
    public func subscribeToTripUpdates(stopId: String) -> AsyncStream<[TripUpdate]> {
        subscriptionManager.subscribeToTripUpdates(stopId: stopId)
    }

    /// Subscribes to all service alert notifications
    ///
    /// - Returns: AsyncStream of alert arrays
    ///
    /// Example:
    /// ```swift
    /// for await alerts in client.subscribeToAlerts() {
    ///     print("Active alerts: \(alerts.count)")
    ///     // Display alerts in notification area
    /// }
    /// ```
    public func subscribeToAlerts() -> AsyncStream<[Alert]> {
        subscriptionManager.subscribeToAlerts()
    }

    /// Subscribes to alerts affecting a specific route
    ///
    /// - Parameter routeId: Route identifier to filter by
    /// - Returns: AsyncStream of alert arrays for the route
    ///
    /// Example:
    /// ```swift
    /// for await alerts in client.subscribeToAlerts(routeId: "L1") {
    ///     print("Line 1 alerts: \(alerts.count)")
    ///     // Show route-specific alerts
    /// }
    /// ```
    public func subscribeToAlerts(routeId: String) -> AsyncStream<[Alert]> {
        subscriptionManager.subscribeToAlerts(routeId: routeId)
    }

    /// Subscribes to alerts affecting a specific stop
    ///
    /// - Parameter stopId: Stop identifier to filter by
    /// - Returns: AsyncStream of alert arrays for the stop
    ///
    /// Example:
    /// ```swift
    /// for await alerts in client.subscribeToAlerts(stopId: "123") {
    ///     print("Stop alerts: \(alerts.count)")
    ///     // Show stop-specific service disruptions
    /// }
    /// ```
    public func subscribeToAlerts(stopId: String) -> AsyncStream<[Alert]> {
        subscriptionManager.subscribeToAlerts(stopId: stopId)
    }

    /// Subscribes to only currently active alerts
    ///
    /// - Returns: AsyncStream of currently active alert arrays
    ///
    /// Example:
    /// ```swift
    /// for await alerts in client.subscribeToActiveAlerts() {
    ///     for alert in alerts {
    ///         print("⚠️ \(alert.headerText)")
    ///     }
    /// }
    /// ```
    public func subscribeToActiveAlerts() -> AsyncStream<[Alert]> {
        subscriptionManager.subscribeToActiveAlerts()
    }

    /// Cancels all active subscriptions
    ///
    /// Call this when you no longer need real-time updates,
    /// such as when a view disappears or the app goes to background.
    ///
    /// Example:
    /// ```swift
    /// // In your view controller
    /// override func viewWillDisappear(_ animated: Bool) {
    ///     super.viewWillDisappear(animated)
    ///     await client.cancelAllSubscriptions()
    /// }
    /// ```
    public func cancelAllSubscriptions() async {
        await subscriptionManager.cancelAllSubscriptions()
    }
}
