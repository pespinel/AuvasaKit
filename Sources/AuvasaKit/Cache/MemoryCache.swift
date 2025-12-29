import Foundation

/// Actor-based in-memory cache for fast data access
actor MemoryCache {
    private var storage: [String: Any] = [:]
    private let maxItems: Int

    /// Creates a new memory cache
    /// - Parameter maxItems: Maximum number of items to store (default: 100)
    init(maxItems: Int = 100) {
        self.maxItems = maxItems
    }

    /// Stores a value in memory cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - value: Value to cache
    func set(_ key: String, value: some Codable) {
        let cached = CachedValue(value: value, timestamp: Date(), key: key)

        // Evict oldest item if at capacity
        if storage.count >= maxItems, storage[key] == nil {
            evictOldest()
        }

        storage[key] = cached
    }

    /// Retrieves a value from memory cache
    /// - Parameter key: Cache key
    /// - Returns: Cached value if found, nil otherwise
    func get<T: Codable>(_ key: String) -> CachedValue<T>? {
        storage[key] as? CachedValue<T>
    }

    /// Removes a value from memory cache
    /// - Parameter key: Cache key
    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Clears all cached data
    func clear() {
        storage.removeAll()
    }

    /// Returns the number of cached items
    var count: Int {
        storage.count
    }

    // MARK: - Private Helpers

    private func evictOldest() {
        var oldestKey: String?
        var oldestDate = Date()

        for (key, value) in storage {
            if let cached = value as? (any CachedValueProtocol) {
                if cached.timestamp < oldestDate {
                    oldestDate = cached.timestamp
                    oldestKey = key
                }
            }
        }

        if let key = oldestKey {
            storage.removeValue(forKey: key)
        }
    }
}

// MARK: - Helper Protocol

private protocol CachedValueProtocol {
    var timestamp: Date { get }
}

extension CachedValue: CachedValueProtocol {}
