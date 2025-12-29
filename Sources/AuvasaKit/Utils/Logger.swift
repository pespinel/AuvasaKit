import Foundation
import os.log

/// Logging utility for AuvasaKit
public struct Logger {
    /// Log levels
    public enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private let subsystem: String
    private let category: String
    private let osLog: OSLog
    private static var minimumLevel: Level = .info

    /// Creates a new logger
    /// - Parameters:
    ///   - subsystem: Subsystem identifier (typically bundle ID)
    ///   - category: Category for this logger
    public init(subsystem: String = "com.auvasa.auvasakit", category: String) {
        self.subsystem = subsystem
        self.category = category
        self.osLog = OSLog(subsystem: subsystem, category: category)
    }

    /// Sets the minimum log level
    /// - Parameter level: Minimum level to log
    public static func setMinimumLevel(_ level: Level) {
        minimumLevel = level
    }

    /// Logs a debug message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Logs an info message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Logs a warning message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Logs an error message
    /// - Parameters:
    ///   - message: Message to log
    ///   - error: Optional error object
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func log(
        _ message: String,
        level: Level,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= Self.minimumLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"

        switch level {
        case .debug:
            os_log(.debug, log: osLog, "%{public}@", formattedMessage)
        case .info:
            os_log(.info, log: osLog, "%{public}@", formattedMessage)
        case .warning:
            os_log(.default, log: osLog, "⚠️ %{public}@", formattedMessage)
        case .error:
            os_log(.error, log: osLog, "❌ %{public}@", formattedMessage)
        }
    }
}

// MARK: - Convenience

public extension Logger {
    /// Shared logger for AuvasaKit
    static let `default` = Logger(category: "AuvasaKit")

    /// Logger for networking
    static let network = Logger(category: "Network")

    /// Logger for database operations
    static let database = Logger(category: "Database")

    /// Logger for subscriptions
    static let subscriptions = Logger(category: "Subscriptions")
}
