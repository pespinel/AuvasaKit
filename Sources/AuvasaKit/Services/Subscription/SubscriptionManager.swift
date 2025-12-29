import Foundation

/// Manages real-time subscriptions with automatic polling
actor SubscriptionManager {
    private let realtimeService: RealtimeService
    private let pollingInterval: TimeInterval
    private var activeSubscriptions: [UUID: Task<Void, Never>] = [:]

    /// Creates a new subscription manager
    /// - Parameters:
    ///   - realtimeService: Service for fetching real-time data
    ///   - pollingInterval: Polling interval in seconds (default: 30)
    init(
        realtimeService: RealtimeService,
        pollingInterval: TimeInterval = 30
    ) {
        self.realtimeService = realtimeService
        self.pollingInterval = pollingInterval
    }

    // MARK: - Vehicle Position Subscriptions

    /// Creates a subscription stream for all vehicle positions
    ///
    /// The stream automatically polls for updates at the configured interval
    /// and yields new positions as they become available.
    ///
    /// - Returns: AsyncStream of vehicle position arrays
    ///
    /// Example:
    /// ```swift
    /// for await positions in manager.subscribeToVehiclePositions() {
    ///     print("Received \(positions.count) vehicles")
    /// }
    /// ```
    nonisolated func subscribeToVehiclePositions() -> AsyncStream<[VehiclePosition]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchVehiclePositions() ?? []
        }
    }

    /// Creates a subscription stream for vehicle positions on a specific route
    ///
    /// - Parameter routeId: Route identifier to filter by
    /// - Returns: AsyncStream of vehicle position arrays for the route
    ///
    /// Example:
    /// ```swift
    /// for await positions in manager.subscribeToVehiclePositions(routeId: "L1") {
    ///     print("Line 1 has \(positions.count) buses")
    /// }
    /// ```
    nonisolated func subscribeToVehiclePositions(routeId: String) -> AsyncStream<[VehiclePosition]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchVehiclePositions(routeId: routeId) ?? []
        }
    }

    // MARK: - Trip Update Subscriptions

    /// Creates a subscription stream for all trip updates
    ///
    /// - Returns: AsyncStream of trip update arrays
    ///
    /// Example:
    /// ```swift
    /// for await updates in manager.subscribeToTripUpdates() {
    ///     print("Received \(updates.count) trip updates")
    /// }
    /// ```
    nonisolated func subscribeToTripUpdates() -> AsyncStream<[TripUpdate]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchTripUpdates() ?? []
        }
    }

    /// Creates a subscription stream for trip updates at a specific stop
    ///
    /// - Parameter stopId: Stop identifier to filter by
    /// - Returns: AsyncStream of trip update arrays for the stop
    ///
    /// Example:
    /// ```swift
    /// for await updates in manager.subscribeToTripUpdates(stopId: "123") {
    ///     print("Stop has \(updates.count) upcoming arrivals")
    /// }
    /// ```
    nonisolated func subscribeToTripUpdates(stopId: String) -> AsyncStream<[TripUpdate]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchTripUpdates(stopId: stopId) ?? []
        }
    }

    // MARK: - Alert Subscriptions

    /// Creates a subscription stream for all service alerts
    ///
    /// - Returns: AsyncStream of alert arrays
    ///
    /// Example:
    /// ```swift
    /// for await alerts in manager.subscribeToAlerts() {
    ///     print("Active alerts: \(alerts.count)")
    /// }
    /// ```
    nonisolated func subscribeToAlerts() -> AsyncStream<[Alert]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchAlerts() ?? []
        }
    }

    /// Creates a subscription stream for alerts affecting a specific route
    ///
    /// - Parameter routeId: Route identifier to filter by
    /// - Returns: AsyncStream of alert arrays for the route
    ///
    /// Example:
    /// ```swift
    /// for await alerts in manager.subscribeToAlerts(routeId: "L1") {
    ///     print("Line 1 alerts: \(alerts.count)")
    /// }
    /// ```
    nonisolated func subscribeToAlerts(routeId: String) -> AsyncStream<[Alert]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchAlerts(routeId: routeId) ?? []
        }
    }

    /// Creates a subscription stream for alerts affecting a specific stop
    ///
    /// - Parameter stopId: Stop identifier to filter by
    /// - Returns: AsyncStream of alert arrays for the stop
    ///
    /// Example:
    /// ```swift
    /// for await alerts in manager.subscribeToAlerts(stopId: "123") {
    ///     print("Stop alerts: \(alerts.count)")
    /// }
    /// ```
    nonisolated func subscribeToAlerts(stopId: String) -> AsyncStream<[Alert]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchAlerts(stopId: stopId) ?? []
        }
    }

    /// Creates a subscription stream for only currently active alerts
    ///
    /// - Returns: AsyncStream of currently active alert arrays
    ///
    /// Example:
    /// ```swift
    /// for await alerts in manager.subscribeToActiveAlerts() {
    ///     for alert in alerts {
    ///         print("⚠️ \(alert.headerText)")
    ///     }
    /// }
    /// ```
    nonisolated func subscribeToActiveAlerts() -> AsyncStream<[Alert]> {
        createStream { [weak self] in
            try await self?.realtimeService.fetchActiveAlerts() ?? []
        }
    }

    // MARK: - Private Helpers

    /// Creates a generic subscription stream with automatic polling
    ///
    /// - Parameter fetcher: Async closure that fetches data
    /// - Returns: AsyncStream that yields fetched data
    nonisolated private func createStream<T>(
        fetcher: @escaping @Sendable () async throws -> T
    ) -> AsyncStream<T> {
        AsyncStream { continuation in
            let subscriptionId = UUID()

            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                while !Task.isCancelled {
                    do {
                        let data = try await fetcher()
                        continuation.yield(data)

                        // Wait for next polling interval
                        try await Task.sleep(
                            nanoseconds: UInt64(pollingInterval * 1_000_000_000)
                        )
                    } catch is CancellationError {
                        // Task was cancelled, exit gracefully
                        break
                    } catch {
                        // Log error but continue polling
                        // TODO: Use proper logger when available
                        // Silently continue for now

                        // Wait a bit before retrying on error
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    }
                }

                continuation.finish()
                await removeSubscription(id: subscriptionId)
            }

            // Store the task
            Task {
                await self.storeSubscription(id: subscriptionId, task: task)
            }

            // Handle stream termination
            continuation.onTermination = { @Sendable [weak self] _ in
                task.cancel()
                Task {
                    await self?.removeSubscription(id: subscriptionId)
                }
            }
        }
    }

    /// Stores an active subscription task
    private func storeSubscription(id: UUID, task: Task<Void, Never>) {
        activeSubscriptions[id] = task
    }

    /// Removes a subscription task
    private func removeSubscription(id: UUID) {
        activeSubscriptions[id]?.cancel()
        activeSubscriptions.removeValue(forKey: id)
    }

    /// Cancels all active subscriptions
    func cancelAllSubscriptions() {
        for (_, task) in activeSubscriptions {
            task.cancel()
        }
        activeSubscriptions.removeAll()
    }

    /// Returns the number of active subscriptions
    var activeSubscriptionCount: Int {
        activeSubscriptions.count
    }
}
