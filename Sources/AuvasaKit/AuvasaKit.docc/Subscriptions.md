# Subscriptions

Subscribe to continuous real-time updates using AsyncStream.

## Overview

Instead of manually polling for updates, AuvasaKit provides subscription APIs that deliver continuous data streams. Subscriptions use Swift's `AsyncStream` and automatically handle:

- Periodic polling (configurable interval, default 30s)
- Error recovery with automatic retries
- Proper cleanup when cancelled
- Thread-safe operation with actors

## Vehicle Position Subscriptions

### Subscribe to All Vehicles

Receive updates for all active buses:

```swift
for await positions in client.subscribeToVehiclePositions() {
    print("Received \(positions.count) vehicle positions")

    // Update your map or UI
    for vehicle in positions {
        updateMapMarker(
            id: vehicle.id,
            coordinate: vehicle.position,
            bearing: vehicle.bearing
        )
    }
}
```

### Subscribe to Specific Route

Track only buses on a particular route:

```swift
for await positions in client.subscribeToVehiclePositions(routeId: "L1") {
    print("Line 1 has \(positions.count) active buses")

    for vehicle in positions {
        print("  \(vehicle.vehicle.label ?? "?"): \(vehicle.position)")
    }
}
```

### Track Nearby Vehicles

Use a Task to filter positions by distance:

```swift
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)

for await positions in client.subscribeToVehiclePositions() {
    let nearbyBuses = positions.filter {
        userLocation.distance(to: $0.position) < 1000  // Within 1km
    }

    if !nearbyBuses.isEmpty {
        print("\(nearbyBuses.count) buses nearby")
        // Trigger notification or update UI
    }
}
```

## Trip Update Subscriptions

### Subscribe to Stop Arrivals

Get continuous arrival predictions for a stop:

```swift
for await updates in client.subscribeToTripUpdates(stopId: "123") {
    print("Arrival updates for stop 123:")

    for update in updates {
        // Find arrival time for this specific stop
        for stopUpdate in update.stopTimeUpdates where stopUpdate.stopId == "123" {
            if let arrival = stopUpdate.arrival {
                let arrivalDate = Date(timeIntervalSince1970: TimeInterval(arrival.time))
                print("  Trip \(update.trip.routeId): \(arrivalDate)")

                if let delay = arrival.delay {
                    print("    Delay: \(delay)s")
                }
            }
        }
    }
}
```

### Subscribe to All Trip Updates

Monitor all active trips:

```swift
for await updates in client.subscribeToTripUpdates() {
    print("Received \(updates.count) trip updates")

    // Find trips with significant delays
    let delayedTrips = updates.filter { ($0.delay ?? 0) > 300 }  // > 5 min

    if !delayedTrips.isEmpty {
        print("⚠️ \(delayedTrips.count) trips delayed > 5 minutes")
    }
}
```

## Alert Subscriptions

### Subscribe to All Alerts

Monitor service disruptions:

```swift
for await alerts in client.subscribeToAlerts() {
    if !alerts.isEmpty {
        print("⚠️ \(alerts.count) active alerts:")

        for alert in alerts {
            print("  \(alert.headerText)")
            print("  Severity: \(alert.severity)")
        }

        // Show notification to user
        showAlertNotification(alerts)
    }
}
```

### Subscribe to Route Alerts

Track alerts for a specific route:

```swift
for await alerts in client.subscribeToAlerts(routeId: "L1") {
    if !alerts.isEmpty {
        print("Line 1 alerts:")
        for alert in alerts {
            print("  \(alert.descriptionText)")
        }
    }
}
```

### Subscribe to Stop Alerts

Monitor alerts affecting a particular stop:

```swift
for await alerts in client.subscribeToAlerts(stopId: "123") {
    for alert in alerts {
        // Check if alert affects our stop
        if alert.informedEntities.contains(where: { $0.stopId == "123" }) {
            print("Alert at stop: \(alert.headerText)")
        }
    }
}
```

### Subscribe to Active Alerts Only

Filter for currently active alerts:

```swift
for await alerts in client.subscribeToActiveAlerts() {
    print("\(alerts.count) alerts active right now")
}
```

## Managing Subscriptions

### Cancellation

Subscriptions run until cancelled. Use Swift's structured concurrency:

```swift
let task = Task {
    for await positions in client.subscribeToVehiclePositions() {
        updateUI(with: positions)
    }
}

// Later, cancel the subscription
task.cancel()
```

### Structured Concurrency

Use task groups for multiple subscriptions:

```swift
await withTaskGroup(of: Void.self) { group in
    // Subscribe to vehicles
    group.addTask {
        for await positions in client.subscribeToVehiclePositions() {
            updateVehicles(positions)
        }
    }

    // Subscribe to alerts
    group.addTask {
        for await alerts in client.subscribeToAlerts() {
            updateAlerts(alerts)
        }
    }

    // Subscriptions run until task group is cancelled
}
```

### SwiftUI Integration

Use `@State` and `Task` in SwiftUI:

```swift
struct BusMapView: View {
    @State private var vehicles: [VehiclePosition] = []
    @State private var subscriptionTask: Task<Void, Never>?

    var body: some View {
        Map {
            ForEach(vehicles) { vehicle in
                Annotation(vehicle.vehicle.label ?? "?", coordinate: vehicle.position.clLocation) {
                    BusMarker(vehicle: vehicle)
                }
            }
        }
        .onAppear {
            subscriptionTask = Task {
                for await positions in client.subscribeToVehiclePositions() {
                    vehicles = positions
                }
            }
        }
        .onDisappear {
            subscriptionTask?.cancel()
        }
    }
}
```

## Configuration

### Polling Interval

Configure the polling interval when creating the client:

```swift
let config = AuvasaClient.Configuration(
    pollingInterval: 15  // Poll every 15 seconds
)
let client = AuvasaClient(configuration: config)
```

Shorter intervals provide more up-to-date data but increase network usage. The default 30 seconds balances freshness with efficiency.

### Error Handling

Subscriptions automatically retry on transient errors:

```swift
for await positions in client.subscribeToVehiclePositions() {
    // Stream continues even if individual requests fail
    // Errors are logged but don't break the subscription
}
```

For critical errors (e.g., authentication failure), the stream will terminate and you can catch the error:

```swift
do {
    for await positions in client.subscribeToVehiclePositions() {
        updateUI(with: positions)
    }
} catch {
    print("Subscription failed: \(error)")
    // Handle fatal error
}
```

## Best Practices

1. **Cancel Properly**: Always cancel subscriptions when no longer needed to free resources
2. **Use Structured Concurrency**: Leverage task groups and task hierarchies for automatic cleanup
3. **Filter Early**: Apply filters to reduce data processing
4. **Batch Updates**: Consider debouncing UI updates when processing high-frequency streams
5. **Monitor Memory**: Large subscription buffers can consume memory - cancel inactive subscriptions

## See Also

- <doc:RealTimeData> for one-time data fetching
- ``AuvasaClient`` for the full API reference
