import Foundation

/// Represents a transit vehicle
public struct Vehicle: Sendable, Equatable, Codable {
    /// Unique identifier for the vehicle
    public let id: String

    /// User-visible label (e.g., "Bus 123")
    public let label: String?

    /// License plate number
    public let licensePlate: String?

    /// Creates a new vehicle
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - label: User-visible label
    ///   - licensePlate: License plate number
    public init(id: String, label: String? = nil, licensePlate: String? = nil) {
        self.id = id
        self.label = label
        self.licensePlate = licensePlate
    }
}

// MARK: - CustomStringConvertible

extension Vehicle: CustomStringConvertible {
    public var description: String {
        label ?? id
    }
}
