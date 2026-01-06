import CoreData
import Foundation

/// Service for querying GTFS route data
public actor RouteService {
    private let databaseManager: DatabaseManager

    /// Creates a new route service
    /// - Parameter databaseManager: Database manager for accessing route data
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }

    // MARK: - Fetch Operations

    /// Fetches all routes
    /// - Returns: Array of all routes sorted by sort order and short name
    public func fetchAllRoutes() async throws -> [Route] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "shortName", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToRoute($0) }
        }
    }

    /// Fetches a route by ID
    /// - Parameter id: Route identifier
    /// - Returns: Route if found, nil otherwise
    public func fetchRoute(id: String) async throws -> Route? {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1

            guard let result = try context.fetch(fetchRequest).first else {
                return nil
            }

            return self.convertToRoute(result)
        }
    }

    /// Fetches routes by short name
    /// - Parameter shortName: Route short name (e.g., "L1", "L2")
    /// - Returns: Array of matching routes
    public func fetchRoutes(shortName: String) async throws -> [Route] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.predicate = NSPredicate(format: "shortName == %@", shortName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "longName", ascending: true)]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToRoute($0) }
        }
    }

    /// Searches routes by name (short or long name)
    /// - Parameter query: Search query (case-insensitive, partial match)
    /// - Returns: Array of matching routes
    public func searchRoutes(query: String) async throws -> [Route] {
        guard !query.isEmpty else {
            return []
        }

        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.predicate = NSPredicate(
                format: "shortName CONTAINS[cd] %@ OR longName CONTAINS[cd] %@",
                query,
                query
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "shortName", ascending: true)
            ]
            fetchRequest.fetchLimit = 50

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToRoute($0) }
        }
    }

    /// Fetches routes by type
    /// - Parameter type: Route type
    /// - Returns: Array of routes of the specified type
    public func fetchRoutes(type: RouteType) async throws -> [Route] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.predicate = NSPredicate(format: "type == %d", type.rawValue)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "shortName", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToRoute($0) }
        }
    }

    /// Fetches routes by agency
    /// - Parameter agencyId: Agency identifier
    /// - Returns: Array of routes operated by the agency
    public func fetchRoutes(agencyId: String) async throws -> [Route] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            fetchRequest.predicate = NSPredicate(format: "agencyId == %@", agencyId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "shortName", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToRoute($0) }
        }
    }

    /// Fetches all routes that serve a specific stop
    /// - Parameter stopId: Stop identifier
    /// - Returns: Array of routes that have trips passing through this stop
    public func fetchRoutes(servingStop stopId: String) async throws -> [Route] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            // Step 1: Get all trip IDs that stop at this stop
            let stopTimeRequest = NSFetchRequest<NSDictionary>(entityName: "GTFSStopTime")
            stopTimeRequest.predicate = NSPredicate(format: "stopId == %@", stopId)
            stopTimeRequest.propertiesToFetch = ["tripId"]
            stopTimeRequest.resultType = .dictionaryResultType
            stopTimeRequest.returnsDistinctResults = true

            let stopTimeResults = try context.fetch(stopTimeRequest)
            let tripIds = stopTimeResults.compactMap { $0["tripId"] as? String }

            guard !tripIds.isEmpty else {
                return []
            }

            // Step 2: Get route IDs from those trips
            let tripRequest = NSFetchRequest<NSDictionary>(entityName: "GTFSTrip")
            tripRequest.predicate = NSPredicate(format: "id IN %@", tripIds)
            tripRequest.propertiesToFetch = ["routeId"]
            tripRequest.resultType = .dictionaryResultType
            tripRequest.returnsDistinctResults = true

            let tripResults = try context.fetch(tripRequest)
            let routeIds = Set(tripResults.compactMap { $0["routeId"] as? String })

            guard !routeIds.isEmpty else {
                return []
            }

            // Step 3: Get the actual routes
            let routeRequest = NSFetchRequest<GTFSRoute>(entityName: "GTFSRoute")
            routeRequest.predicate = NSPredicate(format: "id IN %@", Array(routeIds))
            routeRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "shortName", ascending: true)
            ]

            let routes = try context.fetch(routeRequest)
            return routes.map { self.convertToRoute($0) }
        }
    }

    /// Fetches route IDs that serve a specific stop (lighter than fetching full Route objects)
    /// - Parameter stopId: Stop identifier
    /// - Returns: Array of route IDs
    public func fetchRouteIds(servingStop stopId: String) async throws -> [String] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            // Get all trip IDs that stop at this stop
            let stopTimeRequest = NSFetchRequest<NSDictionary>(entityName: "GTFSStopTime")
            stopTimeRequest.predicate = NSPredicate(format: "stopId == %@", stopId)
            stopTimeRequest.propertiesToFetch = ["tripId"]
            stopTimeRequest.resultType = .dictionaryResultType
            stopTimeRequest.returnsDistinctResults = true

            let stopTimeResults = try context.fetch(stopTimeRequest)
            let tripIds = stopTimeResults.compactMap { $0["tripId"] as? String }

            guard !tripIds.isEmpty else {
                return []
            }

            // Get route IDs from those trips
            let tripRequest = NSFetchRequest<NSDictionary>(entityName: "GTFSTrip")
            tripRequest.predicate = NSPredicate(format: "id IN %@", tripIds)
            tripRequest.propertiesToFetch = ["routeId"]
            tripRequest.resultType = .dictionaryResultType
            tripRequest.returnsDistinctResults = true

            let tripResults = try context.fetch(tripRequest)
            let routeIds = Set(tripResults.compactMap { $0["routeId"] as? String })

            return Array(routeIds).sorted()
        }
    }

    // MARK: - Conversion

    nonisolated private func convertToRoute(_ gtfsRoute: GTFSRoute) -> Route {
        Route(
            id: gtfsRoute.id,
            agencyId: gtfsRoute.agencyId,
            shortName: gtfsRoute.shortName,
            longName: gtfsRoute.longName,
            desc: gtfsRoute.desc,
            type: RouteType(rawValue: Int(gtfsRoute.type)) ?? .bus,
            url: gtfsRoute.url.flatMap { URL(string: $0) },
            color: gtfsRoute.color,
            textColor: gtfsRoute.textColor,
            sortOrder: gtfsRoute.sortOrder > 0 ? Int(gtfsRoute.sortOrder) : nil
        )
    }
}
