import Foundation

/// Represents service calendar (which days a service runs)
public struct Calendar: Identifiable, Sendable, Equatable, Codable {
    /// Unique service identifier
    public let id: String

    /// Service runs on Mondays
    public let monday: Bool

    /// Service runs on Tuesdays
    public let tuesday: Bool

    /// Service runs on Wednesdays
    public let wednesday: Bool

    /// Service runs on Thursdays
    public let thursday: Bool

    /// Service runs on Fridays
    public let friday: Bool

    /// Service runs on Saturdays
    public let saturday: Bool

    /// Service runs on Sundays
    public let sunday: Bool

    /// Start date (YYYYMMDD)
    public let startDate: String

    /// End date (YYYYMMDD)
    public let endDate: String

    /// Creates a new calendar
    public init(
        id: String,
        monday: Bool,
        tuesday: Bool,
        wednesday: Bool,
        thursday: Bool,
        friday: Bool,
        saturday: Bool,
        sunday: Bool,
        startDate: String,
        endDate: String
    ) {
        self.id = id
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
        self.startDate = startDate
        self.endDate = endDate
    }

    /// Checks if service runs on a specific day of the week
    /// - Parameter weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    public func runsOn(weekday: Int) -> Bool {
        switch weekday {
        case 1: sunday
        case 2: monday
        case 3: tuesday
        case 4: wednesday
        case 5: thursday
        case 6: friday
        case 7: saturday
        default: false
        }
    }

    /// Checks if service runs on a specific date
    public func runsOn(date: Date) -> Bool {
        let calendar = Foundation.Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        guard runsOn(weekday: weekday) else { return false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)

        return dateString >= startDate && dateString <= endDate
    }

    /// Gets all days of the week this service runs
    public var activeDays: [String] {
        var days: [String] = []
        if monday { days.append("Monday") }
        if tuesday { days.append("Tuesday") }
        if wednesday { days.append("Wednesday") }
        if thursday { days.append("Thursday") }
        if friday { days.append("Friday") }
        if saturday { days.append("Saturday") }
        if sunday { days.append("Sunday") }
        return days
    }
}

// MARK: - Calendar Exception

/// Represents an exception to the regular calendar (special dates)
public struct CalendarDate: Sendable, Equatable, Codable {
    /// Service identifier
    public let serviceId: String

    /// Date (YYYYMMDD)
    public let date: String

    /// Exception type
    public let exceptionType: ExceptionType

    /// Creates a new calendar exception
    public init(serviceId: String, date: String, exceptionType: ExceptionType) {
        self.serviceId = serviceId
        self.date = date
        self.exceptionType = exceptionType
    }
}

/// Exception type
public enum ExceptionType: Int, Sendable, Codable {
    /// Service added for this date
    case added = 1

    /// Service removed for this date
    case removed = 2
}
