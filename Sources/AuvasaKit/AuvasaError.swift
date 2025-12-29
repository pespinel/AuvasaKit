import Foundation

/// Errors that can occur when using AuvasaKit
public enum AuvasaError: Error, LocalizedError {
    // MARK: - Network Errors

    /// Network request failed
    case networkError(NetworkError)

    /// Invalid URL
    case invalidURL

    /// Request timeout
    case timeout

    /// No internet connection
    case noConnection

    // MARK: - Data Errors

    /// Failed to parse protobuf data
    case invalidProtobuf(String)

    /// Failed to parse CSV data
    case invalidCSV(String)

    /// Failed to extract ZIP file
    case zipExtractionFailed(String)

    /// Missing required data field
    case missingRequiredField(String)

    // MARK: - Database Errors

    /// CoreData operation failed
    case databaseError(String)

    /// Failed to import GTFS data
    case importFailed(String)

    /// Entity not found
    case notFound(String)

    // MARK: - Configuration Errors

    /// Invalid configuration
    case invalidConfiguration(String)

    /// Service unavailable
    case serviceUnavailable

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"

        case .invalidURL:
            "Invalid URL provided"

        case .timeout:
            "Request timed out"

        case .noConnection:
            "No internet connection available"

        case .invalidProtobuf(let details):
            "Failed to parse protobuf data: \(details)"

        case .invalidCSV(let details):
            "Failed to parse CSV data: \(details)"

        case .zipExtractionFailed(let details):
            "Failed to extract ZIP file: \(details)"

        case .missingRequiredField(let field):
            "Missing required field: \(field)"

        case .databaseError(let details):
            "Database error: \(details)"

        case .importFailed(let details):
            "Failed to import GTFS data: \(details)"

        case .notFound(let entity):
            "\(entity) not found"

        case .invalidConfiguration(let details):
            "Invalid configuration: \(details)"

        case .serviceUnavailable:
            "Service is currently unavailable"
        }
    }

    public var failureReason: String? {
        switch self {
        case .networkError:
            "The network request could not be completed"

        case .invalidURL:
            "The provided URL is malformed"

        case .timeout:
            "The server did not respond in time"

        case .noConnection:
            "The device is not connected to the internet"

        case .invalidProtobuf:
            "The protobuf data is corrupted or invalid"

        case .invalidCSV:
            "The CSV file is malformed"

        case .zipExtractionFailed:
            "The ZIP archive could not be extracted"

        case .missingRequiredField:
            "Required data is missing"

        case .databaseError:
            "The database operation failed"

        case .importFailed:
            "The data import operation failed"

        case .notFound:
            "The requested entity does not exist"

        case .invalidConfiguration:
            "The configuration is invalid"

        case .serviceUnavailable:
            "The service is temporarily unavailable"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkError, .timeout:
            "Check your internet connection and try again"

        case .noConnection:
            "Connect to the internet and try again"

        case .invalidURL:
            "Verify the URL is correct"

        case .invalidProtobuf, .invalidCSV:
            "Try downloading the data again"

        case .zipExtractionFailed:
            "Ensure you have enough disk space and try again"

        case .missingRequiredField:
            "Contact support if this persists"

        case .databaseError, .importFailed:
            "Try clearing app data or reinstalling"

        case .notFound:
            "Verify the ID is correct"

        case .invalidConfiguration:
            "Check your configuration settings"

        case .serviceUnavailable:
            "Try again later"
        }
    }
}
