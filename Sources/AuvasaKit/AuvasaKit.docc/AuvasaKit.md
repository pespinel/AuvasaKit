# ``AuvasaKit``

Modern Swift SDK for accessing AUVASA (Autobuses Urbanos de Valladolid) transit data.

## Overview

AuvasaKit provides a comprehensive Swift interface to access real-time and static transit data from AUVASA, the public bus system in Valladolid, Spain. Built with modern Swift concurrency (async/await), the SDK makes it easy to:

- 🚍 Track bus locations in real-time
- ⏱️ Get accurate arrival predictions
- 📍 Find nearby stops and routes
- 📅 Access schedules and trip information
- 🔔 Subscribe to live updates with AsyncStream

## Features

### Real-Time Data
- Vehicle positions with GPS coordinates
- Live arrival predictions with delays
- Service alerts and disruptions
- Subscription support for continuous updates

### Static GTFS Data
- Comprehensive stop database
- Route and trip information
- Schedule lookup by stop and time
- Geographic search with distance calculations

### Advanced Features
- Combines real-time updates with static schedules
- Trip tracking with progress monitoring
- Nearby vehicle and stop discovery
- Multi-layer caching for performance

## Topics

### Getting Started
- <doc:GettingStarted>
- <doc:Installation>

### Real-Time Features
- <doc:RealTimeData>
- <doc:Subscriptions>

### Static Data
- <doc:StaticData>
- <doc:Searches>

### Core Types
- ``AuvasaClient``
- ``VehiclePosition``
- ``TripUpdate``
- ``Alert``
- ``Stop``
- ``Route``
- ``Arrival``
