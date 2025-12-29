# Search Examples

Advanced search patterns and use cases.

## Geographic Searches

### Find Nearest Stop

Find the single closest stop to a location:

```swift
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let nearbyStops = try await client.findNearbyStops(
    coordinate: userLocation,
    radiusMeters: 5000  // Wide radius to ensure results
)

if let nearest = nearbyStops.first {
    let distance = userLocation.distance(to: nearest.coordinate)
    print("Nearest stop: \(nearest.name) (\(Int(distance))m away)")
}
```

### Stops Within Walking Distance

Find all stops within a 10-minute walk (~800m):

```swift
let walkingRadius = 800.0  // meters
let stops = try await client.findNearbyStops(
    coordinate: userLocation,
    radiusMeters: walkingRadius
)

print("Found \(stops.count) stops within walking distance:")
for stop in stops {
    let distance = userLocation.distance(to: stop.coordinate)
    let walkTime = Int(distance / 1.33)  // ~1.33 m/s walking speed
    print("  \(stop.name) - \(walkTime) min walk")
}
```

### Stops Along a Route

Find stops within a corridor along a route:

```swift
let start = Coordinate(latitude: 41.6523, longitude: -4.7245)
let end = Coordinate(latitude: 41.6600, longitude: -4.7300)

// Find stops near both endpoints
let startStops = try await client.findNearbyStops(coordinate: start, radiusMeters: 300)
let endStops = try await client.findNearbyStops(coordinate: end, radiusMeters: 300)

// Find route connections
let startStopIds = Set(startStops.map(\.id))
let endStopIds = Set(endStops.map(\.id))

let allRoutes = try await client.fetchRoutes()

for route in allRoutes {
    let routeTrips = try await client.fetchTrips(routeId: route.id)

    for trip in routeTrips {
        let tripStopTimes = try await client.fetchStopTimes(tripId: trip.id)
        let tripStops = Set(tripStopTimes.map(\.stopId))

        // Check if route connects start and end
        if !tripStops.intersection(startStopIds).isEmpty &&
           !tripStops.intersection(endStopIds).isEmpty {
            print("Route \(route.shortName) connects these locations")
        }
    }
}
```

## Text Searches

### Fuzzy Stop Search

Search for stops with tolerance for typos:

```swift
let queries = ["plasa", "plaza", "plaça"]  // Variations and typos

var allResults: Set<Stop> = []
for query in queries {
    let results = try await client.searchStops(query: query)
    allResults.formUnion(results)
}

print("Found \(allResults.count) unique stops matching variations")
```

### Multi-keyword Search

Search for stops matching multiple keywords:

```swift
func searchStopsMultiKeyword(keywords: [String]) async throws -> [Stop] {
    var results: Set<Stop> = []

    for keyword in keywords {
        let matches = try await client.searchStops(query: keyword)
        if results.isEmpty {
            results = Set(matches)
        } else {
            // Intersection - stops matching ALL keywords
            results.formIntersection(matches)
        }
    }

    return Array(results)
}

// Find stops with both "plaza" and "mayor"
let stops = try await searchStopsMultiKeyword(keywords: ["plaza", "mayor"])
```

### Search by Stop Code

Find stops by their display code:

```swift
let allStops = try await client.fetchAllStops()
let stopsByCode = allStops.filter { stop in
    stop.code?.lowercased().contains("123") == true
}
```

## Route Searches

### Find Routes Serving a Stop

Get all routes that stop at a specific location:

```swift
let stopId = "123"
let stopTimes = try await client.getSchedule(stopId: stopId)

// Get unique route IDs
let routeIds = Set(stopTimes.compactMap { stopTime -> String? in
    try? await client.getTrip(id: stopTime.tripId)?.routeId
})

// Fetch route details
var routes: [Route] = []
for routeId in routeIds {
    if let route = try await client.getRoute(id: routeId) {
        routes.append(route)
    }
}

print("Routes serving this stop:")
for route in routes.sorted(by: { $0.shortName < $1.shortName }) {
    print("  \(route.shortName): \(route.longName)")
}
```

### Find Wheelchair Accessible Routes

Find routes with wheelchair-accessible vehicles:

```swift
let allTrips = try await client.fetchAllTrips()
let accessibleTripRoutes = Set(
    allTrips
        .filter { $0.wheelchairAccessible == .accessible }
        .map(\.routeId)
)

var accessibleRoutes: [Route] = []
for routeId in accessibleTripRoutes {
    if let route = try await client.getRoute(id: routeId) {
        accessibleRoutes.append(route)
    }
}

print("♿️ \(accessibleRoutes.count) routes with wheelchair accessibility")
```

## Time-Based Searches

### Next Departures After Current Time

Get upcoming buses in the next hour:

```swift
let now = Date()
let calendar = Calendar.current

// Format current time
let hour = calendar.component(.hour, from: now)
let minute = calendar.component(.minute, from: now)
let currentTime = String(format: "%02d:%02d:00", hour, minute)

// Get next hour of departures
let departures = try await client.fetchUpcomingDepartures(
    stopId: "123",
    afterTime: currentTime,
    limit: 20
)

// Filter to next hour
let oneHourLater = now.addingTimeInterval(3600)

let nextHourDepartures = departures.filter { stopTime in
    // Parse time and check if within next hour
    guard let departureDate = parseGTFSTime(stopTime.departureTime, baseDate: now) else {
        return false
    }
    return departureDate <= oneHourLater
}

print("\(nextHourDepartures.count) buses in the next hour")
```

### Late Night Service

Find routes running late at night:

```swift
let lateNightTrips = try await client.fetchAllStopTimes()
    .filter { stopTime in
        // GTFS times can be > 24:00:00 for next-day service
        if let hour = Int(stopTime.departureTime.prefix(2)) {
            return hour >= 23 || hour <= 5
        }
        return false
    }

let lateNightRoutes = Set(
    try await lateNightTrips.asyncMap { stopTime -> String? in
        try? await client.getTrip(id: stopTime.tripId)?.routeId
    }.compactMap { $0 }
)

print("Routes with late night service: \(lateNightRoutes.count)")
```

## Real-Time Searches

### Find Available Buses

Get vehicles that are currently in service:

```swift
let allVehicles = try await client.fetchVehiclePositions()

// Filter by occupancy
let availableBuses = allVehicles.filter { vehicle in
    switch vehicle.occupancyStatus {
    case .manySeatsAvailable, .fewSeatsAvailable:
        return true
    default:
        return false
    }
}

print("\(availableBuses.count) buses with available seats")
```

### Buses Approaching a Stop

Find buses that will arrive soon:

```swift
let stopLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let maxDistance = 500.0  // meters
let maxSpeed = 50.0  // km/h

let vehicles = try await client.fetchVehiclePositions()

let approaching = vehicles.filter { vehicle in
    let distance = stopLocation.distance(to: vehicle.position)

    // Within max distance
    guard distance <= maxDistance else { return false }

    // Calculate bearing to stop
    if let bearing = vehicle.bearing {
        let bearingToStop = LocationUtils.bearing(from: vehicle.position, to: stopLocation)

        // Check if heading towards stop (within 45°)
        let diff = abs(bearing - bearingToStop)
        return diff < 45 || diff > 315
    }

    return true
}

print("\(approaching.count) buses approaching stop")
```

## Combined Searches

### Best Next Bus

Find the soonest bus to a destination:

```swift
func findBestBus(
    from: String,  // Stop ID
    to: String,    // Stop ID
    client: AuvasaClient
) async throws -> (route: Route, arrival: Date)? {

    // Get arrivals at origin stop
    let arrivals = try await client.getNextArrivals(stopId: from, limit: 20)

    // Check which routes serve destination
    for arrival in arrivals {
        let tripStopTimes = try await client.fetchStopTimes(tripId: arrival.trip.id)

        // Check if trip goes to destination
        if tripStopTimes.contains(where: { $0.stopId == to }) {
            return (arrival.route, arrival.bestTime)
        }
    }

    return nil
}

if let best = try await findBestBus(from: "123", to: "456", client: client) {
    print("Take route \(best.route.shortName) at \(best.arrival)")
}
```

## Performance Optimization

### Caching Search Results

Cache frequently accessed data:

```swift
actor SearchCache {
    private var stopCache: [String: [Stop]] = [:]

    func cachedNearbyStops(
        coordinate: Coordinate,
        radius: Double,
        client: AuvasaClient
    ) async throws -> [Stop] {
        let key = "\(coordinate.latitude),\(coordinate.longitude),\(radius)"

        if let cached = stopCache[key] {
            return cached
        }

        let results = try await client.findNearbyStops(
            coordinate: coordinate,
            radiusMeters: radius
        )

        stopCache[key] = results
        return results
    }
}
```

### Batch Requests

Minimize API calls by batching:

```swift
// Instead of this:
for stopId in stopIds {
    let stop = try await client.getStop(id: stopId)
    // Process stop
}

// Do this:
let allStops = try await client.fetchAllStops()
let stopsById = Dictionary(uniqueKeysWithValues: allStops.map { ($0.id, $0) })

for stopId in stopIds {
    if let stop = stopsById[stopId] {
        // Process stop
    }
}
```

## See Also

- <doc:StaticData> for more query examples
- <doc:RealTimeData> for live data searches
- ``LocationUtils`` for geographic calculations
