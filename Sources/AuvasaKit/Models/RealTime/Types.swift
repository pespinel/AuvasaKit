import Foundation

// MARK: - Occupancy Status

/// Represents the occupancy status of a vehicle
public enum OccupancyStatus: String, Sendable, Codable {
    case empty = "EMPTY"
    case manySeatsAvailable = "MANY_SEATS_AVAILABLE"
    case fewSeatsAvailable = "FEW_SEATS_AVAILABLE"
    case standingRoomOnly = "STANDING_ROOM_ONLY"
    case crushedStandingRoomOnly = "CRUSHED_STANDING_ROOM_ONLY"
    case full = "FULL"
    case notAcceptingPassengers = "NOT_ACCEPTING_PASSENGERS"
    case unknown = "UNKNOWN"
}

// MARK: - Vehicle Status

/// Represents the current status of a vehicle
public enum VehicleStatus: String, Sendable, Codable {
    case incomingAt = "INCOMING_AT"
    case stoppedAt = "STOPPED_AT"
    case inTransitTo = "IN_TRANSIT_TO"
}

// MARK: - Schedule Relationship

/// Defines how the trip or stop time relates to the schedule
public enum ScheduleRelationship: String, Sendable, Codable {
    case scheduled = "SCHEDULED"
    case skipped = "SKIPPED"
    case noData = "NO_DATA"
    case unscheduled = "UNSCHEDULED"
}

// MARK: - Alert Severity

/// The severity level of a service alert
public enum SeverityLevel: Int, Sendable, Codable {
    case unknown = 0
    case info = 1
    case warning = 2
    case severe = 3
}

// MARK: - Alert Cause

/// The cause of a service alert
public enum AlertCause: String, Sendable, Codable {
    case unknownCause = "UNKNOWN_CAUSE"
    case otherCause = "OTHER_CAUSE"
    case technicalProblem = "TECHNICAL_PROBLEM"
    case strike = "STRIKE"
    case demonstration = "DEMONSTRATION"
    case accident = "ACCIDENT"
    case holiday = "HOLIDAY"
    case weather = "WEATHER"
    case maintenance = "MAINTENANCE"
    case construction = "CONSTRUCTION"
    case policeActivity = "POLICE_ACTIVITY"
    case medicalEmergency = "MEDICAL_EMERGENCY"
}

// MARK: - Alert Effect

/// The effect of a service alert on service
public enum AlertEffect: String, Sendable, Codable {
    case noService = "NO_SERVICE"
    case reducedService = "REDUCED_SERVICE"
    case significantDelays = "SIGNIFICANT_DELAYS"
    case detour = "DETOUR"
    case additionalService = "ADDITIONAL_SERVICE"
    case modifiedService = "MODIFIED_SERVICE"
    case otherEffect = "OTHER_EFFECT"
    case unknownEffect = "UNKNOWN_EFFECT"
    case stopMoved = "STOP_MOVED"
}

// MARK: - Route Type

/// The type of transportation used on a route
public enum RouteType: Int, Sendable, Codable {
    case tram = 0
    case subway = 1
    case rail = 2
    case bus = 3
    case ferry = 4
    case cableTram = 5
    case aerialLift = 6
    case funicular = 7
}

// MARK: - Wheelchair Boarding

/// Indicates wheelchair accessibility
public enum WheelchairBoarding: Int, Sendable, Codable {
    case unknown = 0
    case possible = 1
    case notPossible = 2
}
