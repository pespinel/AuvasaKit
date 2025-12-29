# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Core API**: AuvasaClient public API as main entry point for the SDK
- **Real-Time Features**:
  - Vehicle position tracking with GTFS Real-Time protobuf support
  - Trip updates and arrival predictions
  - Service alerts and notifications
  - Real-time subscriptions with AsyncStream support
  - SubscriptionManager for automatic polling with configurable intervals
- **Static GTFS Data**:
  - Complete GTFS static data models (Stop, Route, Trip, StopTime, Calendar, Shape)
  - CoreData database manager with optimized schema
  - GTFS data importer supporting ZIP/CSV files
  - StopService for stop searches and nearby stops
  - RouteService for route queries
  - ScheduleService for trip and calendar queries
- **Utilities**:
  - AuvasaError enum with comprehensive error handling and LocalizedError support
  - Logger with os.log backend and multiple log levels (debug, info, warning, error)
  - TimeUtils for GTFS time/date parsing and manipulation
  - LocationUtils for geographic calculations (Haversine distance, bearing, bounding box)
  - BoundingBox struct for efficient spatial queries
  - DayOfWeekFlags struct for day-of-week filtering
- **Caching System**:
  - Multi-layer cache with memory and disk storage
  - MemoryCache actor with LRU eviction
  - DiskCache actor with size limits and automatic cleanup
  - CacheManager coordinating both caches
  - Predefined cache policies for different data types
- **CI/CD**:
  - GitHub Actions workflow for automated build, test, and lint
  - SwiftLint strict checking with comprehensive rules
  - SwiftFormat for consistent code style
  - Code coverage reporting with Codecov integration
  - Release workflow with automatic changelog parsing

### Changed

- SwiftFormat configuration updated to align with SwiftLint (extensionacl on-extension)

### Technical Details

- iOS 15+ minimum requirement for native async/await and AsyncStream
- Actor-based concurrency for thread-safe operations
- URLSession for networking without external dependencies
- CoreData for efficient GTFS static data storage
- SwiftProtobuf for GTFS Real-Time parsing
