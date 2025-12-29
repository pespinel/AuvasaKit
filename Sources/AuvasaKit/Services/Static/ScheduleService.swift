import CoreData
import Foundation

/// Service for querying GTFS schedule data (stop times, trips, calendars)
public actor ScheduleService {
    private let databaseManager: DatabaseManager

    /// Creates a new schedule service
    /// - Parameter databaseManager: Database manager for accessing schedule data
    public init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
    }

    // MARK: - Stop Times

    /// Fetches all stop times for a specific stop
    /// - Parameters:
    ///   - stopId: Stop identifier
    ///   - date: Date to filter by service (defaults to today)
    /// - Returns: Array of stop times sorted by departure time
    public func fetchStopTimes(stopId: String, date: Date = Date()) async throws -> [StopTime] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStopTime>(entityName: "GTFSStopTime")
            fetchRequest.predicate = NSPredicate(format: "stopId == %@", stopId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "departureTime", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStopTime($0) }
        }
    }

    /// Fetches stop times for a specific trip
    /// - Parameter tripId: Trip identifier
    /// - Returns: Array of stop times sorted by stop sequence
    public func fetchStopTimes(tripId: String) async throws -> [StopTime] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStopTime>(entityName: "GTFSStopTime")
            fetchRequest.predicate = NSPredicate(format: "tripId == %@", tripId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "stopSequence", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStopTime($0) }
        }
    }

    /// Fetches upcoming departures from a stop
    /// - Parameters:
    ///   - stopId: Stop identifier
    ///   - afterTime: Time to search after (HH:MM:SS format)
    ///   - limit: Maximum number of results
    /// - Returns: Array of upcoming stop times
    public func fetchUpcomingDepartures(
        stopId: String,
        afterTime: String,
        limit: Int = 10
    ) async throws -> [StopTime] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSStopTime>(entityName: "GTFSStopTime")
            fetchRequest.predicate = NSPredicate(
                format: "stopId == %@ AND departureTime >= %@",
                stopId,
                afterTime
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "departureTime", ascending: true)
            ]
            fetchRequest.fetchLimit = limit

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToStopTime($0) }
        }
    }

    // MARK: - Trips

    /// Fetches a trip by ID
    /// - Parameter tripId: Trip identifier
    /// - Returns: Trip if found, nil otherwise
    public func fetchTrip(id: String) async throws -> Trip? {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSTrip>(entityName: "GTFSTrip")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1

            guard let result = try context.fetch(fetchRequest).first else {
                return nil
            }

            return self.convertToTrip(result)
        }
    }

    /// Fetches trips for a route
    /// - Parameter routeId: Route identifier
    /// - Returns: Array of trips for the route
    public func fetchTrips(routeId: String) async throws -> [Trip] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSTrip>(entityName: "GTFSTrip")
            fetchRequest.predicate = NSPredicate(format: "routeId == %@", routeId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "serviceId", ascending: true),
                NSSortDescriptor(key: "directionId", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToTrip($0) }
        }
    }

    /// Fetches trips by direction
    /// - Parameters:
    ///   - routeId: Route identifier
    ///   - directionId: Direction identifier (0 or 1)
    /// - Returns: Array of trips in the specified direction
    public func fetchTrips(routeId: String, directionId: Int) async throws -> [Trip] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSTrip>(entityName: "GTFSTrip")
            fetchRequest.predicate = NSPredicate(
                format: "routeId == %@ AND directionId == %d",
                routeId,
                directionId
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "serviceId", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToTrip($0) }
        }
    }

    // MARK: - Calendars

    /// Fetches calendar by service ID
    /// - Parameter serviceId: Service identifier
    /// - Returns: Calendar if found, nil otherwise
    public func fetchCalendar(serviceId: String) async throws -> Calendar? {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSCalendar>(entityName: "GTFSCalendar")
            fetchRequest.predicate = NSPredicate(format: "serviceId == %@", serviceId)
            fetchRequest.fetchLimit = 1

            guard let result = try context.fetch(fetchRequest).first else {
                return nil
            }

            return self.convertToCalendar(result)
        }
    }

    /// Fetches calendar dates for a service
    /// - Parameter serviceId: Service identifier
    /// - Returns: Array of calendar date exceptions
    public func fetchCalendarDates(serviceId: String) async throws -> [CalendarDate] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSCalendarDate>(entityName: "GTFSCalendarDate")
            fetchRequest.predicate = NSPredicate(format: "serviceId == %@", serviceId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToCalendarDate($0) }
        }
    }

    /// Checks if a service is active on a specific date
    /// - Parameters:
    ///   - serviceId: Service identifier
    ///   - date: Date to check
    /// - Returns: True if service is active on the date
    public func isServiceActive(serviceId: String, on date: Date) async throws -> Bool {
        // Check calendar
        if let calendar = try await fetchCalendar(serviceId: serviceId) {
            if !calendar.runsOn(date: date) {
                return false
            }
        }

        // Check calendar dates for exceptions
        let calendarDates = try await fetchCalendarDates(serviceId: serviceId)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)

        for calendarDate in calendarDates where calendarDate.date == dateString {
            switch calendarDate.exceptionType {
            case .added:
                return true
            case .removed:
                return false
            }
        }

        return true
    }

    // MARK: - Shapes

    /// Fetches shape points for a shape ID
    /// - Parameter shapeId: Shape identifier
    /// - Returns: Array of shape points sorted by sequence
    public func fetchShapePoints(shapeId: String) async throws -> [ShapePoint] {
        let context = await databaseManager.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = NSFetchRequest<GTFSShape>(entityName: "GTFSShape")
            fetchRequest.predicate = NSPredicate(format: "shapeId == %@", shapeId)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sequence", ascending: true)
            ]

            let results = try context.fetch(fetchRequest)
            return results.map { self.convertToShapePoint($0) }
        }
    }

    // MARK: - Conversion

    nonisolated private func convertToStopTime(_ gtfsStopTime: GTFSStopTime) -> StopTime {
        StopTime(
            tripId: gtfsStopTime.tripId,
            arrivalTime: gtfsStopTime.arrivalTime,
            departureTime: gtfsStopTime.departureTime,
            stopId: gtfsStopTime.stopId,
            stopSequence: Int(gtfsStopTime.stopSequence),
            stopHeadsign: gtfsStopTime.stopHeadsign,
            pickupType: PickupDropOffType(rawValue: Int(gtfsStopTime.pickupType)) ?? .regular,
            dropOffType: PickupDropOffType(rawValue: Int(gtfsStopTime.dropOffType)) ?? .regular,
            shapeDistTraveled: gtfsStopTime.shapeDistTraveled > 0 ? gtfsStopTime.shapeDistTraveled : nil,
            timepoint: Timepoint(rawValue: Int(gtfsStopTime.timepoint)) ?? .approximate
        )
    }

    nonisolated private func convertToTrip(_ gtfsTrip: GTFSTrip) -> Trip {
        Trip(
            id: gtfsTrip.id,
            routeId: gtfsTrip.routeId,
            serviceId: gtfsTrip.serviceId,
            headsign: gtfsTrip.headsign,
            shortName: gtfsTrip.shortName,
            directionId: gtfsTrip.directionId > 0 ? Int(gtfsTrip.directionId) : nil,
            blockId: gtfsTrip.blockId,
            shapeId: gtfsTrip.shapeId,
            wheelchairAccessible: WheelchairAccessibility(rawValue: Int(gtfsTrip.wheelchairAccessible)) ?? .unknown,
            bikesAllowed: BikesAllowed(rawValue: Int(gtfsTrip.bikesAllowed)) ?? .unknown
        )
    }

    nonisolated private func convertToCalendar(_ gtfsCalendar: GTFSCalendar) -> Calendar {
        Calendar(
            id: gtfsCalendar.serviceId,
            monday: gtfsCalendar.monday,
            tuesday: gtfsCalendar.tuesday,
            wednesday: gtfsCalendar.wednesday,
            thursday: gtfsCalendar.thursday,
            friday: gtfsCalendar.friday,
            saturday: gtfsCalendar.saturday,
            sunday: gtfsCalendar.sunday,
            startDate: gtfsCalendar.startDate,
            endDate: gtfsCalendar.endDate
        )
    }

    nonisolated private func convertToCalendarDate(_ gtfsCalendarDate: GTFSCalendarDate) -> CalendarDate {
        CalendarDate(
            serviceId: gtfsCalendarDate.serviceId,
            date: gtfsCalendarDate.date,
            exceptionType: ExceptionType(rawValue: Int(gtfsCalendarDate.exceptionType)) ?? .added
        )
    }

    nonisolated private func convertToShapePoint(_ gtfsShape: GTFSShape) -> ShapePoint {
        ShapePoint(
            shapeId: gtfsShape.shapeId,
            latitude: gtfsShape.latitude,
            longitude: gtfsShape.longitude,
            sequence: Int(gtfsShape.sequence),
            distTraveled: gtfsShape.distTraveled > 0 ? gtfsShape.distTraveled : nil
        )
    }
}
