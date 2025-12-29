# Getting Started with AuvasaKit

Learn how to integrate AuvasaKit into your app and make your first API calls.

## Installation

### Swift Package Manager

Add AuvasaKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/AuvasaKit.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["AuvasaKit"]
)
```

## Quick Start

### 1. Initialize the Client

```swift
import AuvasaKit

let client = AuvasaClient()
```

The client is an actor that manages all API requests and data operations. You can customize its behavior with a configuration:

```swift
let config = AuvasaClient.Configuration(
    timeout: 30,
    pollingInterval: 15  // For subscriptions
)
let client = AuvasaClient(configuration: config)
```

### 2. Fetch Real-Time Vehicle Positions

Get current positions of all active buses:

```swift
let vehicles = try await client.fetchVehiclePositions()

for vehicle in vehicles {
    print("Bus \(vehicle.vehicle.label ?? "?"): \(vehicle.position)")
    if let speed = vehicle.speed {
        print("  Speed: \(speed) m/s")
    }
}
```

Filter by a specific route:

```swift
let route1Vehicles = try await client.fetchVehiclePositions(routeId: "L1")
```

### 3. Get Next Arrivals at a Stop

Combine static schedules with real-time predictions:

```swift
let arrivals = try await client.getNextArrivals(stopId: "123", limit: 5)

for arrival in arrivals {
    print("\(arrival.route.shortName) to \(arrival.trip.headsign ?? "?")")
    print("  Scheduled: \(arrival.scheduledTime)")

    if let estimated = arrival.estimatedTime {
        print("  Estimated: \(estimated)")
        if let delay = arrival.delay {
            print("  Delay: \(delay) seconds")
        }
    }
}
```

### 4. Find Nearby Stops

Search for stops within a radius:

```swift
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let nearbyStops = try await client.findNearbyStops(
    coordinate: userLocation,
    radiusMeters: 500
)

for stop in nearbyStops {
    print("\(stop.name) - \(stop.coordinate)")
}
```

### 5. Subscribe to Real-Time Updates

Use AsyncStream for continuous updates:

```swift
for await positions in client.subscribeToVehiclePositions(routeId: "L1") {
    print("Received \(positions.count) vehicle positions")
    // Update your UI with latest positions
}
```

## Importing Static Data

On first use, download the GTFS static data:

```swift
// Download and import GTFS data (one-time operation)
try await client.updateStaticData()
```

This downloads stops, routes, schedules, and other static information. The data is stored locally in CoreData and only needs to be updated occasionally.

## Error Handling

Handle errors using Swift's standard error handling:

```swift
do {
    let vehicles = try await client.fetchVehiclePositions()
    // Process vehicles
} catch {
    print("Error fetching vehicles: \(error)")
}
```

## Next Steps

- Learn about <doc:RealTimeData> features
- Explore <doc:StaticData> queries
- Set up <doc:Subscriptions> for live updates
