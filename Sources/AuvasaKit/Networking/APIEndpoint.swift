import Foundation

/// Configuration for API endpoints
public struct APIEndpointConfiguration {
    public let vehiclePositionsURL: URL
    public let tripUpdatesURL: URL
    public let alertsURL: URL
    public let staticDataURL: URL

    /// Default configuration using AUVASA direct endpoints
    public static let `default`: APIEndpointConfiguration = {
        guard
            let vehiclePositionsURL = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/vehicleposition"),
            let tripUpdatesURL = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/tripupdate"),
            let alertsURL = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/alert"),
            let staticDataURL = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/GTFSFile") else
        {
            fatalError("Invalid default AUVASA endpoint URLs")
        }
        return APIEndpointConfiguration(
            vehiclePositionsURL: vehiclePositionsURL,
            tripUpdatesURL: tripUpdatesURL,
            alertsURL: alertsURL,
            staticDataURL: staticDataURL
        )
    }()

    public init(
        vehiclePositionsURL: URL,
        tripUpdatesURL: URL,
        alertsURL: URL,
        staticDataURL: URL
    ) {
        self.vehiclePositionsURL = vehiclePositionsURL
        self.tripUpdatesURL = tripUpdatesURL
        self.alertsURL = alertsURL
        self.staticDataURL = staticDataURL
    }
}

/// GTFS Real-Time API endpoints
public enum APIEndpoint {
    /// Vehicle positions endpoint
    case vehiclePositions

    /// Trip updates endpoint
    case tripUpdates

    /// Service alerts endpoint
    case alerts

    /// Static GTFS data ZIP file
    case staticData

    /// Returns the URL for the endpoint using the provided configuration
    /// - Parameter configuration: The endpoint configuration to use
    /// - Returns: The full URL for the endpoint
    public func url(with configuration: APIEndpointConfiguration) -> URL {
        switch self {
        case .vehiclePositions:
            configuration.vehiclePositionsURL
        case .tripUpdates:
            configuration.tripUpdatesURL
        case .alerts:
            configuration.alertsURL
        case .staticData:
            configuration.staticDataURL
        }
    }
}
