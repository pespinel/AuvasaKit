import Foundation

/// Cache policy configuration
public struct CachePolicy {
    /// Maximum age for cached data (seconds)
    public let maxAge: TimeInterval

    /// How often to check for fresh data (seconds)
    public let refreshInterval: TimeInterval

    /// Creates a new cache policy
    /// - Parameters:
    ///   - maxAge: Maximum age for cached data (seconds)
    ///   - refreshInterval: How often to check for fresh data (seconds)
    public init(maxAge: TimeInterval, refreshInterval: TimeInterval) {
        self.maxAge = maxAge
        self.refreshInterval = refreshInterval
    }
}

// MARK: - Predefined Policies

public extension CachePolicy {
    /// Cache policy for real-time vehicle positions (30 seconds)
    static let vehiclePosition = CachePolicy(
        maxAge: 30,
        refreshInterval: 15
    )

    /// Cache policy for trip updates (60 seconds)
    static let tripUpdate = CachePolicy(
        maxAge: 60,
        refreshInterval: 30
    )

    /// Cache policy for service alerts (5 minutes)
    static let alert = CachePolicy(
        maxAge: 300,
        refreshInterval: 120
    )

    /// Cache policy for static GTFS data (1 week)
    static let staticData = CachePolicy(
        maxAge: 604_800, // 1 week
        refreshInterval: 86_400 // Check daily
    )

    /// Cache policy for stop searches (1 hour)
    static let stopSearch = CachePolicy(
        maxAge: 3_600,
        refreshInterval: 1_800
    )

    /// No caching
    static let none = CachePolicy(
        maxAge: 0,
        refreshInterval: 0
    )
}

/// Wrapper for cached data with metadata
struct CachedValue<T: Codable>: Codable {
    let value: T
    let timestamp: Date
    let key: String

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    func isExpired(policy: CachePolicy) -> Bool {
        age > policy.maxAge
    }
}
