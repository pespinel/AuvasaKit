import Foundation

/// Represents a time range with a start and optional end date
public struct TimeRange: Sendable, Equatable, Codable {
    /// The start of the time range
    public let start: Date

    /// The end of the time range (nil means indefinite)
    public let end: Date?

    /// Creates a new time range
    /// - Parameters:
    ///   - start: The start date
    ///   - end: The end date (optional, nil means indefinite)
    public init(start: Date, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    /// Checks if a given date falls within this time range
    /// - Parameter date: The date to check
    /// - Returns: true if the date is within the range
    public func contains(_ date: Date) -> Bool {
        if let end {
            return date >= start && date <= end
        }
        return date >= start
    }

    /// Checks if this time range is currently active
    public var isActive: Bool {
        contains(Date())
    }

    /// The duration of the time range in seconds (nil if indefinite)
    public var duration: TimeInterval? {
        guard let end else { return nil }
        return end.timeIntervalSince(start)
    }
}

// MARK: - CustomStringConvertible

extension TimeRange: CustomStringConvertible {
    public var description: String {
        if let end {
            return "\(start) - \(end)"
        }
        return "\(start) - indefinite"
    }
}
