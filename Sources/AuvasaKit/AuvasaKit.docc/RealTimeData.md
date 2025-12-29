# Real-Time Data

Access live transit information from AUVASA's GTFS Real-Time feed.

## Overview

AuvasaKit provides three types of real-time data:
1. **Vehicle Positions** - GPS locations of active buses
2. **Trip Updates** - Predicted arrival times with delays
3. **Service Alerts** - Disruptions and notifications

All real-time data is updated every 15-30 seconds from AUVASA's servers.

## Vehicle Positions

### Fetch All Vehicles

Get positions of all active buses:

```swift
let vehicles = try await client.fetchVehiclePositions()

for vehicle in vehicles {
    print("Vehicle: \(vehicle.vehicle.label ?? vehicle.vehicle.id)")
    print("  Position: \(vehicle.position.latitude), \(vehicle.position.longitude)")
    print("  Bearing: \(vehicle.bearing ?? 0)°")
    print("  Speed: \(vehicle.speed ?? 0) m/s")

    if let occupancy = vehicle.occupancyStatus {
        print("  Occupancy: \(occupancy)")
    }

    if let trip = vehicle.trip {
        print("  Route: \(trip.routeId)")
        print("  Destination: \(trip.tripHeadsign ?? "?")")
    }
}
```

### Filter by Route

Get vehicles only on a specific route:

```swift
let line1Buses = try await client.fetchVehiclePositions(routeId: "L1")
```

### Find Nearby Vehicles

Search for buses within a radius:

```swift
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let nearbyBuses = try await client.findNearbyVehicles(
    coordinate: userLocation,
    radiusMeters: 1000  // 1 km radius
)

for vehicle in nearbyBuses {
    let distance = userLocation.distance(to: vehicle.position)
    print("\(vehicle.vehicle.label ?? "?"): \(Int(distance))m away")
}
```

## Trip Updates

### Get Arrivals at a Stop

Fetch predicted arrivals with real-time delays:

```swift
let updates = try await client.fetchTripUpdates(stopId: "123")

for update in updates {
    print("Trip: \(update.trip.tripId)")

    if let delay = update.delay {
        print("  Overall delay: \(delay) seconds")
    }

    for stopUpdate in update.stopTimeUpdates {
        if stopUpdate.stopId == "123" {
            if let arrival = stopUpdate.arrival {
                print("  Arrival: \(Date(timeIntervalSince1970: TimeInterval(arrival.time)))")
                if let delay = arrival.delay {
                    print("  Delay: \(delay) seconds")
                }
            }
        }
    }
}
```

### Combined Arrivals (Recommended)

Use `getNextArrivals()` for a simplified API that merges schedule + real-time:

```swift
let arrivals = try await client.getNextArrivals(stopId: "123", limit: 5)

for arrival in arrivals {
    print("\(arrival.route.shortName): \(arrival.trip.headsign ?? "?")")
    print("  Best time: \(arrival.bestTime)")  // Uses estimated or scheduled

    if arrival.realtimeAvailable {
        if let delay = arrival.delayDescription {
            print("  Status: \(delay)")  // "5 min late", "On time", etc.
        }
    } else {
        print("  Status: Scheduled (no real-time data)")
    }

    if arrival.isDelayed {
        print("  ⚠️ Delayed > 5 minutes")
    }
}
```

## Service Alerts

### Fetch All Alerts

Get current service disruptions:

```swift
let alerts = try await client.fetchAlerts()

for alert in alerts {
    print("Alert: \(alert.headerText)")
    print("  \(alert.descriptionText)")
    print("  Severity: \(alert.severity)")

    if let cause = alert.cause {
        print("  Cause: \(cause)")
    }
    if let effect = alert.effect {
        print("  Effect: \(effect)")
    }

    print("  Active periods:")
    for period in alert.activePeriods {
        print("    \(period.start) - \(period.end ?? "ongoing")")
    }
}
```

### Filter by Route

Get alerts affecting a specific route:

```swift
let route1Alerts = try await client.fetchAlerts(routeId: "L1")
```

## Trip Details

Get comprehensive information about a specific trip:

```swift
let tripDetails = try await client.getTripDetails(tripId: "TRIP_123")

print("Route: \(tripDetails.route.longName)")
print("Destination: \(tripDetails.trip.headsign ?? "?")")
print("Stops: \(tripDetails.stopCount)")

if let delay = tripDetails.delay {
    print("Current delay: \(delay) seconds")
}

if let progress = tripDetails.progress {
    print("Progress: \(Int(progress * 100))%")
}

if let nextStop = tripDetails.nextStop {
    print("Next stop: \(nextStop.stopId)")
    print("  Arrival: \(nextStop.bestTime)")
}

if let currentStop = tripDetails.currentStop {
    print("Current stop: \(currentStop.stopId)")
}
```

## Data Freshness

Real-time data typically updates every 15-30 seconds. The `timestamp` field on each entity indicates when the data was last updated:

```swift
let vehicles = try await client.fetchVehiclePositions()

for vehicle in vehicles {
    let age = Date().timeIntervalSince(vehicle.timestamp)
    print("Data age: \(Int(age)) seconds")
}
```

For continuous updates, use <doc:Subscriptions> instead of polling manually.
