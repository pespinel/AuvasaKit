import Foundation

/// Represents which days of the week are active
public struct DayOfWeekFlags {
    public let monday: Bool
    public let tuesday: Bool
    public let wednesday: Bool
    public let thursday: Bool
    public let friday: Bool
    public let saturday: Bool
    public let sunday: Bool

    public init(
        monday: Bool = false,
        tuesday: Bool = false,
        wednesday: Bool = false,
        thursday: Bool = false,
        friday: Bool = false,
        saturday: Bool = false,
        sunday: Bool = false
    ) {
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
    }
}

/// Utilities for time and date handling
public enum TimeUtils {
    /// Parses GTFS time string (HH:MM:SS) to seconds since midnight
    /// - Parameter timeString: Time string in HH:MM:SS format
    /// - Returns: Seconds since midnight, or nil if invalid
    ///
    /// Example:
    /// ```swift
    /// TimeUtils.parseGTFSTime("14:30:00") // Returns 52200 (14*3600 + 30*60)
    /// TimeUtils.parseGTFSTime("25:15:00") // Returns 90900 (handles times > 24h)
    /// ```
    public static func parseGTFSTime(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 3 else { return nil }

        let hours = components[0]
        let minutes = components[1]
        let seconds = components[2]

        guard minutes < 60, seconds < 60 else { return nil }

        return hours * 3_600 + minutes * 60 + seconds
    }

    /// Converts seconds since midnight to GTFS time string
    /// - Parameter seconds: Seconds since midnight
    /// - Returns: Time string in HH:MM:SS format
    ///
    /// Example:
    /// ```swift
    /// TimeUtils.formatGTFSTime(52200) // Returns "14:30:00"
    /// TimeUtils.formatGTFSTime(90900) // Returns "25:15:00"
    /// ```
    public static func formatGTFSTime(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    /// Converts current time to GTFS time string
    /// - Parameter date: Date to convert (default: now)
    /// - Returns: Time string in HH:MM:SS format
    ///
    /// Example:
    /// ```swift
    /// let now = Date() // 14:30:45
    /// TimeUtils.currentGTFSTime(now) // Returns "14:30:45"
    /// ```
    public static func currentGTFSTime(_ date: Date = Date()) -> String {
        let calendar = Foundation.Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }

    /// Parses GTFS date string (YYYYMMDD) to Date
    /// - Parameter dateString: Date string in YYYYMMDD format
    /// - Returns: Date object, or nil if invalid
    ///
    /// Example:
    /// ```swift
    /// TimeUtils.parseGTFSDate("20231225") // Returns Date for Dec 25, 2023
    /// ```
    public static func parseGTFSDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")
        return formatter.date(from: dateString)
    }

    /// Converts Date to GTFS date string
    /// - Parameter date: Date to convert
    /// - Returns: Date string in YYYYMMDD format
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // Dec 25, 2023
    /// TimeUtils.formatGTFSDate(date) // Returns "20231225"
    /// ```
    public static func formatGTFSDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")
        return formatter.string(from: date)
    }

    /// Gets the day of week for a date (0 = Sunday, 6 = Saturday)
    /// - Parameter date: Date to check
    /// - Returns: Day of week (0-6)
    public static func dayOfWeek(_ date: Date) -> Int {
        let calendar = Foundation.Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        return (components.weekday ?? 1) - 1 // Convert 1-7 to 0-6
    }

    /// Checks if a date falls on a specific day of week
    /// - Parameters:
    ///   - date: Date to check
    ///   - flags: Day of week flags
    /// - Returns: True if date matches
    ///
    /// Example:
    /// ```swift
    /// let weekdayFlags = DayOfWeekFlags(monday: true, tuesday: true, wednesday: true,
    ///                                   thursday: true, friday: true)
    /// let isWeekday = TimeUtils.matchesDayOfWeek(Date(), flags: weekdayFlags)
    /// ```
    public static func matchesDayOfWeek(_ date: Date, flags: DayOfWeekFlags) -> Bool {
        let day = dayOfWeek(date)
        let dayFlags = [
            flags.sunday,
            flags.monday,
            flags.tuesday,
            flags.wednesday,
            flags.thursday,
            flags.friday,
            flags.saturday
        ]
        return dayFlags[day]
    }

    /// Calculates time difference in seconds
    /// - Parameters:
    ///   - from: Start time (HH:MM:SS)
    ///   - to: End time (HH:MM:SS)
    /// - Returns: Difference in seconds, or nil if invalid
    public static func timeDifference(from: String, to: String) -> Int? {
        guard
            let fromSeconds = parseGTFSTime(from),
            let toSeconds = parseGTFSTime(to) else
        {
            return nil
        }
        return toSeconds - fromSeconds
    }

    /// Adds seconds to a GTFS time string
    /// - Parameters:
    ///   - time: Base time (HH:MM:SS)
    ///   - seconds: Seconds to add
    /// - Returns: New time string, or nil if invalid
    public static func addSeconds(to time: String, seconds: Int) -> String? {
        guard let baseSeconds = parseGTFSTime(time) else { return nil }
        let newSeconds = baseSeconds + seconds
        return formatGTFSTime(max(0, newSeconds))
    }
}
