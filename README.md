# AuvasaKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
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

// Get real-time vehicle positions
let positions = try await client.fetchVehiclePositions()
for position in positions {
    print("Bus \(position.vehicle.label ?? ""): \(position.position)")
}

// Find nearby stops
let stops = try await client.findNearbyStops(
    coordinate: Coordinate(latitude: 41.6523, longitude: -4.7245),
    radiusMeters: 500
)

// Subscribe to live updates
for await updates in client.subscribeToTripUpdates(stopId: "813") {
    print("Updated arrivals: \(updates.count)")
}
```

## 📦 Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 🏗️ Project Status

**Current Status**: 🚧 In Development

This project is in active development. Implementation follows a structured phase plan:

- [x] **Phase 0**: Planning and architecture design
- [x] **Phase 1**: Project foundation (base structure, Package.swift)
- [ ] **Phase 2**: Real-time data (networking, protobuf parsing)
- [ ] **Phase 3**: Public API and caching
- [ ] **Phase 4**: Real-time subscriptions
- [ ] **Phase 5**: Static GTFS data
- [ ] **Phase 6**: Advanced features
- [ ] **Phase 7**: Documentation
- [ ] **Phase 8**: Testing and v1.0.0 release

## 📚 Documentation

_(Full documentation coming soon with DocC)_

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
