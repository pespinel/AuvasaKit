import CoreData
import Foundation

/// Service for querying GTFS stop data
public actor StopService {
    private let databaseManager: DatabaseManager

    /// Creates a new stop service
    /// - Parameter databaseManager: Database manager for accessing stop data
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }

    // MARK: - Fetch Operations

    /// Fetches all stops
    /// - Returns: Array of all stops
    public func fetchAllStops() async throws -> [Stop] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStop($0) }
        }
    }

    /// Fetches a stop by ID
    /// - Parameter id: Stop identifier
    /// - Returns: Stop if found, nil otherwise
    public func fetchStop(id: String) async throws -> Stop? {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1

            guard let result = try context.fetch(fetchRequest).first else {
                return nil
            }

            return self.convertToStop(result)
        }
    }

    /// Fetches stops by code
    /// - Parameter code: Stop code
    /// - Returns: Array of matching stops
    public func fetchStops(code: String) async throws -> [Stop] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.predicate = NSPredicate(format: "code == %@", code)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStop($0) }
        }
    }

    /// Searches stops by name
    /// - Parameter query: Search query (case-insensitive, partial match)
    /// - Returns: Array of matching stops
    public func searchStops(query: String) async throws -> [Stop] {
        guard !query.isEmpty else {
            return []
        }

        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            fetchRequest.fetchLimit = 50

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStop($0) }
        }
    }

    /// Finds nearby stops within a radius
    /// - Parameters:
    ///   - coordinate: Center coordinate
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Array of nearby stops sorted by distance
    public func findNearbyStops(
        coordinate: Coordinate,
        radiusMeters: Double
    ) async throws -> [Stop] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            // Fetch all stops (we'll filter by distance in memory)
            // For better performance with large datasets, consider using bounding box query
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")

            let results = try context.fetch(fetchRequest)

            // Convert to Stop and calculate distances
            let stopsWithDistance = results.map { gtfsStop -> (stop: Stop, distance: Double) in
                let stop = self.convertToStop(gtfsStop)
                let distance = coordinate.distance(to: stop.coordinate)
                return (stop, distance)
            }

            // Filter by radius and sort by distance
            return stopsWithDistance
                .filter { $0.distance <= radiusMeters }
                .sorted { $0.distance < $1.distance }
                .map(\.stop)
        }
    }

    /// Finds nearby stops with optimized bounding box query
    /// - Parameters:
    ///   - coordinate: Center coordinate
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Array of nearby stops sorted by distance
    public func findNearbyStopsOptimized(
        coordinate: Coordinate,
        radiusMeters: Double
    ) async throws -> [Stop] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            // Calculate bounding box (approximate)
            let latDelta = radiusMeters / 111_000.0 // ~111km per degree latitude
            let lonDelta = radiusMeters / (111_000.0 * cos(coordinate.latitude * .pi / 180))

            let minLat = coordinate.latitude - latDelta
            let maxLat = coordinate.latitude + latDelta
            let minLon = coordinate.longitude - lonDelta
            let maxLon = coordinate.longitude + lonDelta

            // Query with bounding box
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.predicate = NSPredicate(
                format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f",
                minLat,
                maxLat,
                minLon,
                maxLon
            )

            let results = try context.fetch(fetchRequest)

            // Convert and calculate exact distances
            let stopsWithDistance = results.map { gtfsStop -> (stop: Stop, distance: Double) in
                let stop = self.convertToStop(gtfsStop)
                let distance = coordinate.distance(to: stop.coordinate)
                return (stop, distance)
            }

            // Filter by exact radius and sort
            return stopsWithDistance
                .filter { $0.distance <= radiusMeters }
                .sorted { $0.distance < $1.distance }
                .map(\.stop)
        }
    }

    /// Fetches stops with wheelchair boarding
    /// - Returns: Array of wheelchair accessible stops
    public func fetchWheelchairAccessibleStops() async throws -> [Stop] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.predicate = NSPredicate(format: "wheelchairBoarding == %d", 1)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStop($0) }
        }
    }

    // MARK: - Conversion

    nonisolated private func convertToStop(_ gtfsStop: GTFSStop) -> Stop {
        Stop(
            id: gtfsStop.id,
            code: gtfsStop.code,
            name: gtfsStop.name,
            desc: gtfsStop.desc,
            coordinate: Coordinate(
                latitude: gtfsStop.latitude,
                longitude: gtfsStop.longitude
            ),
            zoneId: gtfsStop.zoneId,
            url: gtfsStop.url.flatMap { URL(string: $0) },
            locationType: LocationType(rawValue: Int(gtfsStop.locationType)) ?? .stop,
            parentStation: gtfsStop.parentStation,
            wheelchairBoarding: WheelchairBoarding(rawValue: Int(gtfsStop.wheelchairBoarding)) ?? .unknown,
            platformCode: gtfsStop.platformCode
        )
    }
}
