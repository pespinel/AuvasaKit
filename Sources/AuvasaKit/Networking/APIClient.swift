import Foundation

/// HTTP client for making API requests
actor APIClient {
    private let session: URLSession
    private let timeout: TimeInterval

    /// Creates a new API client
    /// - Parameters:
    ///   - configuration: URL session configuration
    ///   - timeout: Request timeout in seconds (default: 30)
    init(
        configuration: URLSessionConfiguration = .default,
        timeout: TimeInterval = 30
    ) {
        self.timeout = timeout

        var config = configuration
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)
    }

    /// Fetches raw data from an endpoint
    /// - Parameter endpoint: The API endpoint to fetch from
    /// - Returns: Raw data from the response
    /// - Throws: NetworkError if the request fails
    func fetch(from endpoint: APIEndpoint) async throws -> Data {
        let url = endpoint.url

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200..<300:
                return data
            case 408:
                throw NetworkError.timeout
            case 400..<600:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.invalidResponse
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    /// Maps URLError to NetworkError
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            .noConnection
        case .timedOut:
            .timeout
        case .cancelled:
            .cancelled
        default:
            .unknown(error)
        }
    }
}
