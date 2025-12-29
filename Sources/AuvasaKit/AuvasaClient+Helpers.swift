import Foundation

// MARK: - Private Helpers Extension

extension AuvasaClient {
    /// Gets current time in HH:MM:SS format
    func getCurrentTimeString() -> String {
        let calendar = Foundation.Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }

    /// Creates a map of tripId to TripUpdate for quick lookup
    func createTripUpdateMap(from updates: [TripUpdate]) -> [String: TripUpdate] {
        var map: [String: TripUpdate] = [:]
        for update in updates {
            if let tripId = update.trip.tripId {
                map[tripId] = update
            }
        }
        return map
    }

    /// Builds arrivals from stop times and trip updates
    func buildArrivals(
        from stopTimes: [StopTime],
        stopId: String,
        tripUpdateMap: [String: TripUpdate]
    ) async throws -> [Arrival] {
        var arrivals: [Arrival] = []
        let now = Date()

        for stopTime in stopTimes {
            guard
                let trip = try await scheduleService.fetchTrip(id: stopTime.tripId),
                let route = try await routeService.fetchRoute(id: trip.routeId),
                let scheduledDate = convertStopTimeToDate(stopTime.departureTime, on: now)
            else {
                continue
            }

            let (estimatedDate, delay) = extractRealtimeInfo(
                for: stopId,
                stopTime: stopTime,
                tripUpdate: tripUpdateMap[trip.id],
                scheduledDate: scheduledDate
            )

            arrivals.append(Arrival(
                stopId: stopId,
                route: route,
                trip: trip,
                scheduledTime: scheduledDate,
                estimatedTime: estimatedDate,
                delay: delay,
                realtimeAvailable: estimatedDate != nil,
                stopSequence: stopTime.stopSequence
            ))
        }

        return arrivals
    }

    /// Extracts real-time information from trip update
    func extractRealtimeInfo(
        for stopId: String,
        stopTime: StopTime,
        tripUpdate: TripUpdate?,
        scheduledDate: Date
    ) -> (estimatedDate: Date?, delay: Int?) {
        guard let update = tripUpdate,
              let stopTimeUpdate = update.stopTimeUpdates.first(where: {
                  $0.stopId == stopId || $0.stopSequence == stopTime.stopSequence
              })
        else {
            return (nil, nil)
        }

        let event = stopTimeUpdate.departure ?? stopTimeUpdate.arrival
        guard let event else { return (nil, nil) }

        let estimatedDate = event.time ?? event.delay.map {
            scheduledDate.addingTimeInterval(TimeInterval($0))
        }

        return (estimatedDate, event.delay)
    }

    /// Fetches real-time data for a specific trip
    func fetchRealtimeData(
        tripId: String
    ) async throws -> (tripUpdate: TripUpdate?, vehiclePosition: VehiclePosition?) {
        let tripUpdates = try await realtimeService.fetchTripUpdates()
        let tripUpdate = tripUpdates.first { $0.trip.tripId == tripId }

        let vehiclePositions = try await realtimeService.fetchVehiclePositions()
        let vehiclePosition = vehiclePositions.first { $0.trip?.tripId == tripId }

        return (tripUpdate, vehiclePosition)
    }

    /// Builds stop arrivals for a trip
    func buildTripStopArrivals(
        stopTimes: [StopTime],
        trip: Trip,
        route: Route,
        tripUpdate: TripUpdate?
    ) throws -> [Arrival] {
        let now = Date()
        return stopTimes.compactMap { stopTime -> Arrival? in
            guard let scheduledDate = convertStopTimeToDate(stopTime.departureTime, on: now) else {
                return nil
            }

            let (estimatedDate, delay) = extractRealtimeInfoForTrip(
                stopTime: stopTime,
                tripUpdate: tripUpdate,
                scheduledDate: scheduledDate
            )

            return Arrival(
                stopId: stopTime.stopId,
                route: route,
                trip: trip,
                scheduledTime: scheduledDate,
                estimatedTime: estimatedDate,
                delay: delay,
                realtimeAvailable: estimatedDate != nil,
                stopSequence: stopTime.stopSequence
            )
        }
    }

    /// Extracts real-time info for trip details
    func extractRealtimeInfoForTrip(
        stopTime: StopTime,
        tripUpdate: TripUpdate?,
        scheduledDate: Date
    ) -> (estimatedDate: Date?, delay: Int?) {
        guard let update = tripUpdate,
              let stopTimeUpdate = update.stopTimeUpdates.first(where: {
                  $0.stopId == stopTime.stopId || $0.stopSequence == stopTime.stopSequence
              })
        else {
            return (nil, nil)
        }

        let event = stopTimeUpdate.departure ?? stopTimeUpdate.arrival
        guard let event else { return (nil, nil) }

        let estimatedDate = event.time ?? event.delay.map {
            scheduledDate.addingTimeInterval(TimeInterval($0))
        }

        return (estimatedDate, event.delay)
    }

    /// Calculates trip progress
    func calculateTripProgress(
        vehiclePosition: VehiclePosition?,
        stopCount: Int
    ) -> Double? {
        guard let currentStopSequence = vehiclePosition?.currentStopSequence,
              stopCount > 0
        else {
            return nil
        }
        return Double(currentStopSequence) / Double(stopCount)
    }

    /// Converts a GTFS time string (HH:MM:SS) to a Date on a specific day
    /// - Parameters:
    ///   - timeString: Time in HH:MM:SS format (can be > 24:00:00 for next day)
    ///   - date: Base date
    /// - Returns: Date combining the day with the time, or nil if invalid
    func convertStopTimeToDate(_ timeString: String, on date: Date) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 3 else { return nil }

        var hours = components[0]
        let minutes = components[1]
        let seconds = components[2]

        // Handle times > 24:00:00 (next day service)
        var dayOffset = 0
        if hours >= 24 {
            dayOffset = hours / 24
            hours = hours % 24
        }

        let calendar = Foundation.Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds

        guard var result = calendar.date(from: dateComponents) else { return nil }

        if dayOffset > 0 {
            result = calendar.date(byAdding: .day, value: dayOffset, to: result) ?? result
        }

        return result
    }
}
