import Foundation

/// Errors that can occur during network operations
public enum NetworkError: Error, LocalizedError {
    /// No internet connection available
    case noConnection

    /// Request timed out
    case timeout

    /// Server returned an error status code
    case serverError(statusCode: Int)

    /// Invalid response from server
    case invalidResponse

    /// Failed to decode response data
    case decodingFailed(Error)

    /// Invalid URL
    case invalidURL

    /// Request was cancelled
    case cancelled

    /// Unknown network error
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .noConnection:
            "No internet connection available"
        case .timeout:
            "Request timed out"
        case .serverError(let statusCode):
            "Server error with status code: \(statusCode)"
        case .invalidResponse:
            "Invalid response from server"
        case .decodingFailed(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .invalidURL:
            "Invalid URL"
        case .cancelled:
            "Request was cancelled"
        case .unknown(let error):
            "Unknown network error: \(error.localizedDescription)"
        }
    }
}
