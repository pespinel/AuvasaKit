import Foundation

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

    /// The full URL for the endpoint
    public var url: URL {
        switch self {
        case .vehiclePositions:
            Self.vehiclePositionsURL
        case .tripUpdates:
            Self.tripUpdatesURL
        case .alerts:
            Self.alertsURL
        case .staticData:
            Self.staticDataURL
        }
    }

    // MARK: - Private URL Constants

    private static let vehiclePositionsURL: URL = {
        guard let url = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/vehicleposition") else {
            fatalError("Invalid vehicle positions URL")
        }
        return url
    }()

    private static let tripUpdatesURL: URL = {
        guard let url = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/tripupdate") else {
            fatalError("Invalid trip updates URL")
        }
        return url
    }()

    private static let alertsURL: URL = {
        guard let url = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/alert") else {
            fatalError("Invalid alerts URL")
        }
        return url
    }()

    private static let staticDataURL: URL = {
        guard let url = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/GTFSFile") else {
            fatalError("Invalid static data URL")
        }
        return url
    }()
}
