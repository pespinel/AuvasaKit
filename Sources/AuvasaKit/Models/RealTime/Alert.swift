import Foundation

/// Represents a service alert affecting transit service
public struct Alert: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this alert
    public let id: String

    /// Time ranges when this alert is active
    public let activePeriods: [TimeRange]

    /// Entities (routes, stops, trips) affected by this alert
    public let informedEntities: [EntitySelector]

    /// Cause of the alert
    public let cause: AlertCause?

    /// Effect of the alert on service
    public let effect: AlertEffect?

    /// URL with more information
    public let url: URL?

    /// Short header text
    public let headerText: String

    /// Detailed description
    public let descriptionText: String

    /// Severity level
    public let severity: SeverityLevel

    /// Creates a new alert
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - activePeriods: Active time periods
    ///   - informedEntities: Affected entities
    ///   - cause: Alert cause
    ///   - effect: Alert effect
    ///   - url: More information URL
    ///   - headerText: Short header
    ///   - descriptionText: Detailed description
    ///   - severity: Severity level
    public init(
        id: String,
        activePeriods: [TimeRange] = [],
        informedEntities: [EntitySelector] = [],
        cause: AlertCause? = nil,
        effect: AlertEffect? = nil,
        url: URL? = nil,
        headerText: String,
        descriptionText: String,
        severity: SeverityLevel = .unknown
    ) {
        self.id = id
        self.activePeriods = activePeriods
        self.informedEntities = informedEntities
        self.cause = cause
        self.effect = effect
        self.url = url
        self.headerText = headerText
        self.descriptionText = descriptionText
        self.severity = severity
    }

    /// Checks if this alert is currently active
    public var isActive: Bool {
        if activePeriods.isEmpty {
            return true // No specific periods means always active
        }
        return activePeriods.contains { $0.isActive }
    }

    /// Checks if this alert affects a specific route
    /// - Parameter routeId: The route ID to check
    /// - Returns: true if the route is affected
    public func affectsRoute(_ routeId: String) -> Bool {
        informedEntities.contains { $0.routeId == routeId }
    }

    /// Checks if this alert affects a specific stop
    /// - Parameter stopId: The stop ID to check
    /// - Returns: true if the stop is affected
    public func affectsStop(_ stopId: String) -> Bool {
        informedEntities.contains { $0.stopId == stopId }
    }
}

/// Selects specific entities (routes, stops, trips) in the transit system
public struct EntitySelector: Sendable, Equatable, Codable {
    /// Agency ID
    public let agencyId: String?

    /// Route ID
    public let routeId: String?

    /// Route type
    public let routeType: RouteType?

    /// Trip descriptor
    public let trip: TripDescriptor?

    /// Stop ID
    public let stopId: String?

    /// Creates a new entity selector
    /// - Parameters:
    ///   - agencyId: Agency identifier
    ///   - routeId: Route identifier
    ///   - routeType: Route type
    ///   - trip: Trip descriptor
    ///   - stopId: Stop identifier
    public init(
        agencyId: String? = nil,
        routeId: String? = nil,
        routeType: RouteType? = nil,
        trip: TripDescriptor? = nil,
        stopId: String? = nil
    ) {
        self.agencyId = agencyId
        self.routeId = routeId
        self.routeType = routeType
        self.trip = trip
        self.stopId = stopId
    }
}
