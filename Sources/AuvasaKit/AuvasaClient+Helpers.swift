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

    /// Finds a matching trip update using multiple strategies
    /// 1. First tries exact tripId match
    /// 2. Then tries routeId + startTime match
    /// 3. Falls back to routeId + stopSequence (if route+time fails, pick trip with our stop)
    func findMatchingTripUpdate(
        for trip: Trip,
        firstDepartureTime: String,
        stopSequence: Int,
        in updates: [TripUpdate]
    ) async -> TripUpdate? {
        // Strategy 1: Exact trip ID match
        if let exactMatch = updates.first(where: { $0.trip.tripId == trip.id }) {
            return exactMatch
        }

        // Strategy 2: Match by route + start time (most reliable when available)
        // GTFS-RT provides start_time which should match the first departure time of the trip
        if
            let routeTimeMatch = updates.first(where: { update in
                guard
                    let rtRouteId = update.trip.routeId,
                    let rtStartTime = update.trip.startTime else
                {
                    return false
                }
                return rtRouteId == trip.routeId && rtStartTime == firstDepartureTime
            })
        {
            return routeTimeMatch
        }

        // Strategy 3: Match by route + stopSequence (fallback when startTime doesn't match)
        // Find trips with matching route that have our stopSequence
        return updates.first { update in
            guard let rtRouteId = update.trip.routeId else { return false }
            guard rtRouteId == trip.routeId else { return false }

            // Check if this trip update has our stopSequence
            return update.stopTimeUpdates.contains { st in
                guard let seq = st.stopSequence else { return false }
                return seq == Int32(stopSequence)
            }
        }
    }

    /// Builds arrivals from stop times and trip updates using smart matching
    /// Filters out trips whose service is not active on the current date
    /// Uses multiple matching strategies: exact tripId, then route+startTime
    func buildArrivals(
        from stopTimes: [StopTime],
        stopId: String,
        realtimeUpdates: [TripUpdate]
    ) async throws -> [Arrival] {
        var arrivals: [Arrival] = []
        let now = Date()

        for stopTime in stopTimes {
            guard
                let trip = try await scheduleService.fetchTrip(id: stopTime.tripId),
                let route = try await routeService.fetchRoute(id: trip.routeId),
                let scheduledDate = convertStopTimeToDate(stopTime.departureTime, on: now) else
            {
                continue
            }

            // Filter out trips whose service is not active today
            let isActive = try await scheduleService.isServiceActive(serviceId: trip.serviceId, on: now)
            guard isActive else {
                Logger.database.debug(
                    "Skipping trip \(trip.id) with inactive service \(trip.serviceId)"
                )
                continue
            }

            // Get first departure time of this trip for matching with GTFS-RT start_time
            let tripStopTimes = try await scheduleService.fetchStopTimes(tripId: trip.id)
            guard let firstDepartureTime = tripStopTimes.first?.departureTime else {
                continue
            }

            // Use smart matching to find corresponding real-time update
            let matchingUpdate = await findMatchingTripUpdate(
                for: trip,
                firstDepartureTime: firstDepartureTime,
                stopSequence: Int(stopTime.stopSequence),
                in: realtimeUpdates
            )

            let (estimatedDate, delay) = extractRealtimeInfo(
                for: stopId,
                stopTime: stopTime,
                tripUpdate: matchingUpdate,
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

    /// Builds arrivals from stop times and trip updates
    /// Filters out trips whose service is not active on the current date
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
                let scheduledDate = convertStopTimeToDate(stopTime.departureTime, on: now) else
            {
                continue
            }

            // Filter out trips whose service is not active today
            // This prevents showing trips from special calendars (holidays, etc.)
            let isActive = try await scheduleService.isServiceActive(serviceId: trip.serviceId, on: now)
            guard isActive else {
                Logger.database.debug(
                    "Skipping trip \(trip.id) with inactive service \(trip.serviceId)"
                )
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
    /// If the feed provides `time` but not `delay`, calculates delay from the difference
    func extractRealtimeInfo(
        for stopId: String,
        stopTime: StopTime,
        tripUpdate: TripUpdate?,
        scheduledDate: Date
    ) -> (estimatedDate: Date?, delay: Int?) {
        guard
            let update = tripUpdate,
            let stopTimeUpdate = update.stopTimeUpdates.first(where: {
                $0.stopId == stopId || $0.stopSequence == stopTime.stopSequence
            }) else
        {
            return (nil, nil)
        }

        let event = stopTimeUpdate.departure ?? stopTimeUpdate.arrival
        guard let event else { return (nil, nil) }

        let estimatedDate = event.time ?? event.delay.map {
            scheduledDate.addingTimeInterval(TimeInterval($0))
        }

        // Use explicit delay if provided, otherwise calculate from time difference
        let delay: Int?
        if let explicitDelay = event.delay {
            delay = explicitDelay
        } else if let estimated = estimatedDate {
            delay = Int(estimated.timeIntervalSince(scheduledDate))
        } else {
            delay = nil
        }

        return (estimatedDate, delay)
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
    /// If the feed provides `time` but not `delay`, calculates delay from the difference
    func extractRealtimeInfoForTrip(
        stopTime: StopTime,
        tripUpdate: TripUpdate?,
        scheduledDate: Date
    ) -> (estimatedDate: Date?, delay: Int?) {
        guard
            let update = tripUpdate,
            let stopTimeUpdate = update.stopTimeUpdates.first(where: {
                $0.stopId == stopTime.stopId || $0.stopSequence == stopTime.stopSequence
            }) else
        {
            return (nil, nil)
        }

        let event = stopTimeUpdate.departure ?? stopTimeUpdate.arrival
        guard let event else { return (nil, nil) }

        let estimatedDate = event.time ?? event.delay.map {
            scheduledDate.addingTimeInterval(TimeInterval($0))
        }

        // Use explicit delay if provided, otherwise calculate from time difference
        let delay: Int?
        if let explicitDelay = event.delay {
            delay = explicitDelay
        } else if let estimated = estimatedDate {
            delay = Int(estimated.timeIntervalSince(scheduledDate))
        } else {
            delay = nil
        }

        return (estimatedDate, delay)
    }

    /// Calculates trip progress
    func calculateTripProgress(
        vehiclePosition: VehiclePosition?,
        stopCount: Int
    ) -> Double? {
        guard
            let currentStopSequence = vehiclePosition?.currentStopSequence,
            stopCount > 0 else
        {
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
