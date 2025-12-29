import Foundation

/// Represents a transit route (e.g., a bus line)
public struct Route: Identifiable, Sendable, Equatable, Codable {
    /// Unique identifier for this route
    public let id: String

    /// Agency that operates this route
    public let agencyId: String?

    /// Short name (e.g., "L1", "L2")
    public let shortName: String

    /// Full name (e.g., "Línea 1: Plaza Mayor - Campus")
    public let longName: String

    /// Description
    public let desc: String?

    /// Route type (bus, tram, etc.)
    public let type: RouteType

    /// Route URL with more information
    public let url: URL?

    /// Route color in hex format (e.g., "FF0000" for red)
    public let color: String?

    /// Route text color in hex format
    public let textColor: String?

    /// Sort order for displaying routes
    public let sortOrder: Int?

    /// Creates a new route
    public init(
        id: String,
        agencyId: String? = nil,
        shortName: String,
        longName: String,
        desc: String? = nil,
        type: RouteType,
        url: URL? = nil,
        color: String? = nil,
        textColor: String? = nil,
        sortOrder: Int? = nil
    ) {
        self.id = id
        self.agencyId = agencyId
        self.shortName = shortName
        self.longName = longName
        self.desc = desc
        self.type = type
        self.url = url
        self.color = color
        self.textColor = textColor
        self.sortOrder = sortOrder
    }

    /// Display name (prefers short name)
    public var displayName: String {
        shortName.isEmpty ? longName : shortName
    }
}

// MARK: - CustomStringConvertible

extension Route: CustomStringConvertible {
    public var description: String {
        "\(shortName): \(longName)"
    }
}
