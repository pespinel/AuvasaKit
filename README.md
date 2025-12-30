# AuvasaKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015%2B%20%7C%20macOS%2012%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CI](https://github.com/pespinel/AuvasaKit/actions/workflows/ci.yml/badge.svg)](https://github.com/pespinel/AuvasaKit/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/pespinel/AuvasaKit/branch/main/graph/badge.svg)](https://codecov.io/gh/pespinel/AuvasaKit)
[![Documentation](https://img.shields.io/badge/docs-online-brightgreen.svg)](https://pespinel.github.io/AuvasaKit/documentation/auvasakit)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A modern Swift SDK for accessing **AUVASA** (Autobuses Urbanos de Valladolid) data through GTFS Real-Time and static GTFS feeds.

## 📋 Features

- ✅ **GTFS Real-Time**: Vehicle positions, trip updates, and service alerts in real-time
- 🗺️ **Static GTFS Data**: Stops, routes, schedules, and shapes
- ⚡ **Async/Await**: Modern API using native Swift concurrency
- 🔄 **Subscriptions**: AsyncStream for live updates
- 💾 **Smart Caching**: Multi-layer caching system for better performance
- 📍 **Geospatial Search**: Find nearby stops and vehicles
- 🎯 **Type-Safe**: Strongly typed models with Sendable conformance
- ✨ **Minimal Dependencies**: Only SwiftProtobuf required

## 🚀 Installation

### Swift Package Manager

Add AuvasaKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pespinel/AuvasaKit.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/pespinel/AuvasaKit`
3. Select version

## 📱 Quick Start

```swift
import AuvasaKit

// Initialize the client
let client = AuvasaClient()

// 1️⃣ Import static GTFS data (first time only)
try await client.updateStaticData()

// 2️⃣ Find nearby stops
let userLocation = Coordinate(latitude: 41.6523, longitude: -4.7245)
let stops = try await client.findNearbyStops(
    coordinate: userLocation,
    radiusMeters: 500
)

// 3️⃣ Get next arrivals (combines schedules + real-time)
let arrivals = try await client.getNextArrivals(stopId: "813", limit: 5)
for arrival in arrivals {
    let delay = arrival.delay ?? 0
    print("\(arrival.route.shortName): \(arrival.bestTime) (delay: \(delay)s)")
}

// 4️⃣ Track buses in real-time
let positions = try await client.fetchVehiclePositions(routeId: "L1")
for position in positions {
    print("Bus \(position.vehicle.label ?? ""): \(position.position)")
}

// 5️⃣ Subscribe to live updates
for await updates in client.subscribeToTripUpdates(stopId: "813") {
    print("📍 Updated arrivals: \(updates.count)")
}
```

### SwiftUI Example

```swift
struct BusMapView: View {
    @State private var vehicles: [VehiclePosition] = []
    @State private var subscriptionTask: Task<Void, Never>?

    var body: some View {
        Map {
            ForEach(vehicles) { vehicle in
                Annotation(vehicle.vehicle.label ?? "?",
                          coordinate: vehicle.position.clLocation) {
                    Image(systemName: "bus.fill")
                        .foregroundColor(.blue)
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

## 📦 Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 📚 Documentation

**📖 [Read the full documentation](https://pespinel.github.io/AuvasaKit/documentation/auvasakit)**

### Guides

- [Installation](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/installation) - Setup with Swift Package Manager
- [Getting Started](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/gettingstarted) - Quick start tutorial
- [Real-Time Data](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/realtimedata) - Vehicle positions, trip updates, alerts
- [Subscriptions](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/subscriptions) - AsyncStream patterns for live updates
- [Static Data](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/staticdata) - GTFS queries (stops, routes, schedules)
- [Search Examples](https://pespinel.github.io/AuvasaKit/documentation/auvasakit/searches) - Advanced search patterns

### API Reference

Browse the complete API documentation including all public types, methods, and properties in the [online documentation](https://pespinel.github.io/AuvasaKit/documentation/auvasakit).

### AUVASA Endpoints

The SDK uses the following public AUVASA endpoints:

**GTFS Real-Time (Protobuf)**:
- Vehicle Positions: `http://212.170.201.204:50080/GTFSRTapi/api/vehicleposition`
- Trip Updates: `http://212.170.201.204:50080/GTFSRTapi/api/tripupdate`
- Alerts: `http://212.170.201.204:50080/GTFSRTapi/api/alert`

**GTFS Static (ZIP)**:
- Static data: `https://www.auvasa.es/wp-file-download/datos-gtfs/`

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [AUVASA](https://www.auvasa.es/) for providing public open data APIs
- [GTFS Real-Time Specification](https://gtfs.org/documentation/realtime/)
- [SwiftProtobuf](https://github.com/apple/swift-protobuf)

## ⚠️ Disclaimer

This project is not officially affiliated, associated, authorized, endorsed by, or in any way officially connected with AUVASA or any of its subsidiaries or affiliates.

---

Made with ❤️ for the Valladolid community
