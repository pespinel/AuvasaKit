import Foundation

/// Represents an arrival at a stop, combining static schedule with real-time updates
///
/// This model merges static GTFS schedule data with live trip updates to provide
/// accurate arrival predictions. It includes both scheduled and estimated times,
/// allowing applications to show delays and real-time information to users.
///
/// ## Example
/// ```swift
/// let arrivals = try await client.getNextArrivals(stopId: "STOP123", limit: 5)
/// for arrival in arrivals {
///     if arrival.realtimeAvailable {
///         print("\(arrival.route.shortName): \(arrival.estimatedTime!) (delay: \(arrival.delay!)s)")
///     } else {
///         print("\(arrival.route.shortName): \(arrival.scheduledTime) (scheduled)")
///     }
/// }
/// ```
public struct Arrival: Sendable, Equatable, Codable {
    /// Stop identifier where this arrival occurs
    public let stopId: String

    /// Route information
    public let route: Route

    /// Trip information
    public let trip: Trip

    /// Scheduled arrival time from GTFS static data
    public let scheduledTime: Date

    /// Estimated arrival time from real-time updates (if available)
    public let estimatedTime: Date?

    /// Delay in seconds (negative means ahead of schedule)
    public let delay: Int?

    /// Indicates if real-time data is available for this arrival
    public let realtimeAvailable: Bool

    /// Stop sequence in the trip
    public let stopSequence: Int?

    /// Creates a new arrival
    /// - Parameters:
    ///   - stopId: Stop identifier
    ///   - route: Route information
    ///   - trip: Trip information
    ///   - scheduledTime: Scheduled arrival time
    ///   - estimatedTime: Estimated arrival time (real-time)
    ///   - delay: Delay in seconds
    ///   - realtimeAvailable: Whether real-time data is available
    ///   - stopSequence: Stop sequence in trip
    public init(
        stopId: String,
        route: Route,
        trip: Trip,
        scheduledTime: Date,
        estimatedTime: Date? = nil,
        delay: Int? = nil,
        realtimeAvailable: Bool = false,
        stopSequence: Int? = nil
    ) {
        self.stopId = stopId
        self.route = route
        self.trip = trip
        self.scheduledTime = scheduledTime
        self.estimatedTime = estimatedTime
        self.delay = delay
        self.realtimeAvailable = realtimeAvailable
        self.stopSequence = stopSequence
    }

    /// The best available arrival time (estimated if available, otherwise scheduled)
    public var bestTime: Date {
        estimatedTime ?? scheduledTime
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

    /// Indicates if the arrival is significantly delayed (> 5 minutes)
    public var isDelayed: Bool {
        guard let delay else { return false }
        return delay > 300 // More than 5 minutes
    }
}

// MARK: - CustomStringConvertible

extension Arrival: CustomStringConvertible {
    public var description: String {
        let timeStr = estimatedTime.map { "~\($0)" } ?? "\(scheduledTime)"
        let delayStr = delay.map { " (\($0 > 0 ? "+" : "")\($0)s)" } ?? ""
        return "\(route.shortName) to \(trip.headsign ?? "destination"): \(timeStr)\(delayStr)"
    }
}
