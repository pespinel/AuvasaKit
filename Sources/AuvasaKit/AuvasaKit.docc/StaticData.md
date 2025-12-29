# Static Data

Query GTFS static data for stops, routes, schedules, and more.

## Overview

AuvasaKit downloads and stores static transit data from AUVASA's GTFS feed. This includes:
- **Stops**: Physical bus stop locations and information
- **Routes**: Bus lines and their properties
- **Trips**: Scheduled service patterns
- **Schedules**: Stop times and departure information
- **Calendar**: Service days and exceptions

Static data is stored locally in CoreData for fast, offline access.

## Initial Setup

### Import GTFS Data

Download and import static data on first use:

```swift
// One-time import (or when data needs updating)
try await client.updateStaticData()
```

This downloads the GTFS ZIP file from AUVASA, extracts it, parses all CSV files, and imports the data into the local database. The process typically takes 10-30 seconds.

**When to update:**
- On first app launch
- Periodically (weekly/monthly) to get schedule updates
- When AUVASA announces changes to routes or stops

## Working with Stops

### Get a Specific Stop

Fetch a stop by ID:

```swift
if let stop = try await client.getStop(id: "123") {
    print("Stop: \(stop.name)")
    print("  Code: \(stop.code ?? "N/A")")
    print("  Location: \(stop.coordinate)")
    print("  Wheelchair: \(stop.wheelchairBoarding)")
}
```

### Search Stops by Name

Find stops matching a query:

```swift
let stops = try await client.searchStops(query: "plaza")

for stop in stops {
    print("\(stop.name) (\(stop.code ?? "?"))")
}
```

### Find Nearby Stops

Search for stops within a radius:

```swift
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let nearbyStops = try await client.findNearbyStops(
    coordinate: userLocation,
    radiusMeters: 500
)

for stop in nearbyStops {
    let distance = userLocation.distance(to: stop.coordinate)
    print("\(stop.name): \(Int(distance))m away")
}
```

### Get All Stops

Fetch the complete stop database:

```swift
let allStops = try await client.fetchAllStops()
print("Total stops: \(allStops.count)")
```

### Filter Wheelchair Accessible Stops

Find stops with wheelchair boarding:

```swift
let accessibleStops = try await client.fetchWheelchairAccessibleStops()

for stop in accessibleStops {
    print("♿️ \(stop.name)")
}
```

## Working with Routes

### Get All Routes

Fetch all bus lines:

```swift
let routes = try await client.fetchRoutes()

for route in routes {
    print("\(route.shortName): \(route.longName)")
    if let color = route.color {
        print("  Color: #\(color)")
    }
}
```

### Get a Specific Route

Fetch a route by ID:

```swift
if let route = try await client.getRoute(id: "L1") {
    print("Route: \(route.longName)")
    print("  Type: \(route.type)")  // .bus, .tram, etc.
}
```

### Search Routes

Find routes by name:

```swift
let routes = try await client.searchRoutes(query: "circular")

for route in routes {
    print("\(route.shortName): \(route.longName)")
}
```

### Filter by Route Type

Get routes of a specific type:

```swift
let buses = try await client.fetchRoutes(type: .bus)
print("Bus routes: \(buses.count)")
```

## Working with Schedules

### Get Schedule for a Stop

Fetch all scheduled departures from a stop:

```swift
let schedule = try await client.getSchedule(stopId: "123")

for stopTime in schedule {
    print("Trip \(stopTime.tripId)")
    print("  Departure: \(stopTime.departureTime)")  // "14:30:00"
    print("  Sequence: \(stopTime.stopSequence)")
}
```

### Get Schedule for a Specific Date

Fetch schedule for a particular day:

```swift
let tomorrow = Date().addingTimeInterval(86400)
let schedule = try await client.getSchedule(stopId: "123", date: tomorrow)
```

### Get Upcoming Departures

Fetch next departures after a specific time:

```swift
// Current time in HH:MM:SS format
let now = "14:30:00"

let upcoming = try await client.fetchUpcomingDepartures(
    stopId: "123",
    afterTime: now,
    limit: 10
)

for stopTime in upcoming {
    print("Departure: \(stopTime.departureTime)")
}
```

## Working with Trips

### Get Trip Information

Fetch details about a specific trip:

```swift
if let trip = try await client.getTrip(id: "TRIP_123") {
    print("Trip: \(trip.headsign ?? "?")")
    print("  Route: \(trip.routeId)")
    print("  Direction: \(trip.directionId ?? 0)")
    print("  Wheelchair: \(trip.wheelchairAccessible)")
}
```

### Get Trips for a Route

Find all trips on a route:

```swift
let trips = try await client.fetchTrips(routeId: "L1")

for trip in trips {
    print("\(trip.headsign ?? "?")")
    print("  Direction: \(trip.directionId ?? 0)")
}
```

### Get Trips by Direction

Filter trips by direction:

```swift
let outbound = try await client.fetchTrips(routeId: "L1", directionId: 0)
let inbound = try await client.fetchTrips(routeId: "L1", directionId: 1)
```

## Working with Calendars

### Check Service Availability

Determine if a service runs on a specific date:

```swift
if let calendar = try await client.getCalendar(serviceId: "WEEKDAY") {
    let today = Date()

    if calendar.runsOn(date: today) {
        print("Service is running today")
    } else {
        print("Service is not running today")
    }

    print("Active days: \(calendar.activeDays.joined(separator: ", "))")
}
```

### Get Active Services

Find which services are active today:

```swift
let activeCalendars = try await client.fetchActiveCalendars(date: Date())

for calendar in activeCalendars {
    print("Service \(calendar.id) is active")
}
```

## Data Models

### Stop

```swift
public struct Stop {
    let id: String
    let code: String?
    let name: String
    let coordinate: Coordinate
    let wheelchairBoarding: WheelchairBoarding
    let locationType: LocationType
    // ... more properties
}
```

### Route

```swift
public struct Route {
    let id: String
    let shortName: String  // "1", "L2"
    let longName: String   // "Universidad - Circular"
    let type: RouteType    // .bus, .tram, etc.
    let color: String?     // Hex color
    // ... more properties
}
```

### StopTime

```swift
public struct StopTime {
    let tripId: String
    let stopId: String
    let arrivalTime: String      // "14:30:00"
    let departureTime: String    // "14:30:00"
    let stopSequence: Int        // Order in trip
    // ... more properties
}
```

### Trip

```swift
public struct Trip {
    let id: String
    let routeId: String
    let serviceId: String
    let headsign: String?         // Destination
    let directionId: Int?         // 0 or 1
    let wheelchairAccessible: WheelchairAccessibility
    // ... more properties
}
```

## Performance Tips

1. **Use Nearby Search**: When searching geographically, use `findNearbyStops()` instead of fetching all stops and filtering manually

2. **Limit Results**: Use the `limit` parameter to reduce data transfer:
   ```swift
   let stops = try await client.fetchUpcomingDepartures(stopId: "123", limit: 5)
   ```

3. **Cache Results**: Static data rarely changes, so cache results in your app if you access them frequently

4. **Background Import**: Run `updateStaticData()` in the background on app launch

## See Also

- <doc:RealTimeData> for live updates
- <doc:Searches> for advanced search examples
- ``Stop``, ``Route``, ``Trip`` for detailed model documentation
