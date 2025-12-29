import Foundation

/// Complete trip information combining static schedule with real-time updates
///
/// This model provides comprehensive information about a specific trip,
/// including all stops, schedule, real-time vehicle position, and delay information.
///
/// ## Example
/// ```swift
/// let details = try await client.getTripDetails(tripId: "trip123")
/// print("Trip: \(details.trip.headsign ?? "")")
/// print("Route: \(details.route.shortName)")
/// if let vehicle = details.vehiclePosition {
///     print("Vehicle at: \(vehicle.position)")
/// }
/// for stopArrival in details.stopArrivals {
///     print("Stop \(stopArrival.stopId): \(stopArrival.bestTime)")
/// }
/// ```
public struct TripDetails: Sendable, Equatable, Codable {
    /// Trip information
    public let trip: Trip

    /// Route information
    public let route: Route

    /// All stop arrivals for this trip
    public let stopArrivals: [Arrival]

    /// Current vehicle position (if available)
    public let vehiclePosition: VehiclePosition?

    /// Overall trip delay in seconds (if available)
    public let delay: Int?

    /// Whether real-time data is available for this trip
    public let realtimeAvailable: Bool

    /// Trip progress (0.0 to 1.0) based on current stop sequence
    public let progress: Double?

    /// Creates new trip details
    /// - Parameters:
    ///   - trip: Trip information
    ///   - route: Route information
    ///   - stopArrivals: All stop arrivals for the trip
    ///   - vehiclePosition: Current vehicle position
    ///   - delay: Overall trip delay in seconds
    ///   - realtimeAvailable: Whether real-time data is available
    ///   - progress: Trip progress (0.0 to 1.0)
    public init(
        trip: Trip,
        route: Route,
        stopArrivals: [Arrival],
        vehiclePosition: VehiclePosition? = nil,
        delay: Int? = nil,
        realtimeAvailable: Bool = false,
        progress: Double? = nil
    ) {
        self.trip = trip
        self.route = route
        self.stopArrivals = stopArrivals
        self.vehiclePosition = vehiclePosition
        self.delay = delay
        self.realtimeAvailable = realtimeAvailable
        self.progress = progress
    }

    /// Number of stops in this trip
    public var stopCount: Int {
        stopArrivals.count
    }

    /// Next upcoming stop (nil if trip is completed)
    public var nextStop: Arrival? {
        let now = Date()
        return stopArrivals.first { $0.bestTime > now }
    }

    /// Current stop (the last passed stop)
    public var currentStop: Arrival? {
        let now = Date()
        return stopArrivals.last { $0.bestTime <= now }
    }

    /// Indicates if the trip is significantly delayed (> 5 minutes)
    public var isDelayed: Bool {
        guard let delay else { return false }
        return delay > 300
    }

    /// Human-readable delay description
    public var delayDescription: String? {
        guard let delay else { return nil }

        if delay == 0 {
            return "On time"
        } else if delay > 0 {
            let minutes = delay / 60
            return minutes > 0 ? "\(minutes) min late" : "\(delay) sec late"
        } else {
            let minutes = abs(delay) / 60
            return minutes > 0 ? "\(minutes) min early" : "\(abs(delay)) sec early"
        }
    }
}

// MARK: - CustomStringConvertible

extension TripDetails: CustomStringConvertible {
    public var description: String {
        var desc = "\(route.shortName)"
        if let headsign = trip.headsign {
            desc += " to \(headsign)"
        }
        if let delay {
            desc += " (\(delay > 0 ? "+" : "")\(delay)s)"
        }
        desc += " - \(stopCount) stops"
        return desc
    }
}
