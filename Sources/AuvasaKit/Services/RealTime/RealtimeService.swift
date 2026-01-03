import Foundation

/// Service for fetching GTFS Real-Time data
public actor RealtimeService {
    private let apiClient: APIClient
    private let parser: ProtobufParser
    private let scheduleService: ScheduleService

    /// Creates a new real-time service
    /// - Parameters:
    ///   - apiClient: The API client to use for network requests
    ///   - scheduleService: Schedule service for accessing GTFS static data
    public init(apiClient: APIClient = APIClient(), scheduleService: ScheduleService) {
        self.apiClient = apiClient
        self.parser = ProtobufParser()
        self.scheduleService = scheduleService
    }

    // MARK: - Vehicle Positions

    /// Fetches all current vehicle positions
    /// - Returns: Array of vehicle positions
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchVehiclePositions() async throws -> [VehiclePosition] {
        let data = try await apiClient.fetch(from: .vehiclePositions)
        return try await parser.parseVehiclePositions(data)
    }

    /// Fetches vehicle positions filtered by route
    /// - Parameter routeId: The route ID to filter by
    /// - Returns: Array of vehicle positions for the specified route
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchVehiclePositions(routeId: String) async throws -> [VehiclePosition] {
        let positions = try await fetchVehiclePositions()
        return positions.filter { position in
            position.trip?.routeId == routeId
        }
    }

    /// Finds vehicles near a specific coordinate
    /// - Parameters:
    ///   - coordinate: The center coordinate
    ///   - radiusMeters: The search radius in meters
    /// - Returns: Array of vehicle positions within the radius
    /// - Throws: NetworkError or ParsingError if the request fails
    public func findNearbyVehicles(
        coordinate: Coordinate,
        radiusMeters: Double
    ) async throws -> [VehiclePosition] {
        let positions = try await fetchVehiclePositions()
        return positions.filter { position in
            coordinate.distance(to: position.position) <= radiusMeters
        }
    }

    // MARK: - Trip Updates

    /// Fetches all current trip updates
    /// - Returns: Array of trip updates
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchTripUpdates() async throws -> [TripUpdate] {
        let data = try await apiClient.fetch(from: .tripUpdates)
        return try await parser.parseTripUpdates(data)
    }

    /// Fetches trip updates filtered by stop
    /// - Parameter stopId: The stop ID to filter by
    /// - Returns: Array of trip updates affecting the specified stop
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchTripUpdates(stopId: String) async throws -> [TripUpdate] {
        let updates = try await fetchTripUpdates()
        return updates.filter { update in
            update.stopTimeUpdates.contains { stopTime in
                stopTime.stopId == stopId
            }
        }
    }

    /// Fetches real-time arrivals at a stop with future arrival times
    ///
    /// Combines GTFS-RT trip updates with GTFS static data to match stopSequence
    /// with stopId, since AUVASA's GTFS-RT feed only includes stopSequence.
    ///
    /// - Parameters:
    ///   - stopId: The stop ID to get arrivals for
    ///   - limit: Maximum number of arrivals to return
    /// - Returns: Array of trip updates sorted by arrival time
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchRealtimeArrivals(stopId: String, limit: Int = 10) async throws -> [TripUpdate] {
        let allUpdates = try await fetchTripUpdates()
        let now = Date()

        // GTFS-RT from AUVASA doesn't include stopId, only stopSequence
        // We need to match using trip data from GTFS static
        var futureArrivals: [(TripUpdate, Date)] = []

        for update in allUpdates {
            guard let tripId = update.trip.tripId else { continue }

            // Get stop times for this trip from GTFS static data
            let stopTimes: [StopTime]
            do {
                stopTimes = try await scheduleService.fetchStopTimes(tripId: tripId)
            } catch {
                // If GTFS data not available, skip this trip
                continue
            }

            // Find stop time updates that match this stop
            for stopUpdate in update.stopTimeUpdates {
                guard let sequence = stopUpdate.stopSequence else { continue }

                // Match stopSequence with stopId from static data
                if
                    let stopTime = stopTimes.first(where: { $0.stopSequence == sequence }),
                    stopTime.stopId == stopId,
                    let arrival = stopUpdate.arrival,
                    let arrivalTime = arrival.time,
                    arrivalTime > now
                {
                    futureArrivals.append((update, arrivalTime))
                    break
                }
            }
        }

        // Sort by arrival time and limit
        let sorted = futureArrivals
            .sorted { $0.1 < $1.1 }
            .prefix(limit)
            .map(\.0)

        return Array(sorted)
    }

    // MARK: - Alerts

    /// Fetches all current service alerts
    /// - Returns: Array of alerts
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchAlerts() async throws -> [Alert] {
        let data = try await apiClient.fetch(from: .alerts)
        return try await parser.parseAlerts(data)
    }

    /// Fetches alerts filtered by route
    /// - Parameter routeId: The route ID to filter by
    /// - Returns: Array of alerts affecting the specified route
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchAlerts(routeId: String) async throws -> [Alert] {
        let alerts = try await fetchAlerts()
        return alerts.filter { alert in
            alert.affectsRoute(routeId)
        }
    }

    /// Fetches alerts filtered by stop
    /// - Parameter stopId: The stop ID to filter by
    /// - Returns: Array of alerts affecting the specified stop
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchAlerts(stopId: String) async throws -> [Alert] {
        let alerts = try await fetchAlerts()
        return alerts.filter { alert in
            alert.affectsStop(stopId)
        }
    }

    /// Fetches only currently active alerts
    /// - Returns: Array of active alerts
    /// - Throws: NetworkError or ParsingError if the request fails
    public func fetchActiveAlerts() async throws -> [Alert] {
        let alerts = try await fetchAlerts()
        return alerts.filter(\.isActive)
    }
}
