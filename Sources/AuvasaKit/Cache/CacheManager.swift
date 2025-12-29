import Foundation

private let logger = Logger(category: "Cache")

/// Multi-layer cache manager coordinating memory and disk caches
public actor CacheManager {
    private let memoryCache: MemoryCache
    private let diskCache: DiskCache?
    private let enableDiskCache: Bool

    /// Creates a new cache manager
    /// - Parameters:
    ///   - memoryMaxItems: Maximum items in memory cache (default: 100)
    ///   - diskMaxSize: Maximum disk cache size in bytes (default: 50MB)
    ///   - enableDiskCache: Whether to enable disk caching (default: true)
    ///   - cacheDirectory: Custom cache directory (optional)
    public init(
        memoryMaxItems: Int = 100,
        diskMaxSize: Int64 = 50 * 1024 * 1024,
        enableDiskCache: Bool = true,
        cacheDirectory: URL? = nil
    ) {
        self.memoryCache = MemoryCache(maxItems: memoryMaxItems)
        self.enableDiskCache = enableDiskCache

        if enableDiskCache {
            do {
                self.diskCache = try DiskCache(
                    directory: cacheDirectory,
                    maxDiskSize: diskMaxSize
                )
                logger.info("Disk cache initialized")
            } catch {
                logger.error("Failed to initialize disk cache", error: error)
                self.diskCache = nil
            }
        } else {
            self.diskCache = nil
            logger.info("Disk cache disabled")
        }
    }

    // MARK: - Get

    /// Retrieves a value from cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - policy: Cache policy for expiration
    /// - Returns: Cached value if found and not expired, nil otherwise
    ///
    /// Example:
    /// ```swift
    /// let positions: [VehiclePosition]? = await cache.get(
    ///     key: "vehicle_positions_L1",
    ///     policy: .vehiclePosition
    /// )
    /// ```
    public func get<T: Codable>(
        key: String,
        policy: CachePolicy
    ) async -> T? {
        // 1. Check memory cache first (fastest)
        if let cached: CachedValue<T> = await memoryCache.get(key) {
            if !cached.isExpired(policy: policy) {
                logger.debug("Cache hit (memory): \(key)")
                return cached.value
            }
            logger.debug("Cache expired (memory): \(key)")
        }

        // 2. Check disk cache
        if let diskCache {
            if let cached: CachedValue<T> = await diskCache.get(key) {
                if !cached.isExpired(policy: policy) {
                    logger.debug("Cache hit (disk): \(key)")
                    // Promote to memory cache
                    await memoryCache.set(key, value: cached.value)
                    return cached.value
                }
                logger.debug("Cache expired (disk): \(key)")
            }
        }

        logger.debug("Cache miss: \(key)")
        return nil
    }

    // MARK: - Set

    /// Stores a value in cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - value: Value to cache
    ///   - policy: Cache policy (optional, used for logging)
    ///
    /// Example:
    /// ```swift
    /// await cache.set(
    ///     key: "vehicle_positions_L1",
    ///     value: positions,
    ///     policy: .vehiclePosition
    /// )
    /// ```
    public func set<T: Codable>(
        key: String,
        value: T,
        policy: CachePolicy? = nil
    ) async {
        // Always cache in memory
        await memoryCache.set(key, value: value)
        logger.debug("Cached to memory: \(key)")

        // Cache to disk if enabled
        if let diskCache {
            do {
                try await diskCache.set(key, value: value)
                logger.debug("Cached to disk: \(key)")
            } catch {
                logger.error("Failed to cache \(key) to disk", error: error)
            }
        }
    }

    // MARK: - Remove

    /// Removes a value from cache
    /// - Parameter key: Cache key
    ///
    /// Example:
    /// ```swift
    /// await cache.remove(key: "vehicle_positions_L1")
    /// ```
    public func remove(key: String) async {
        await memoryCache.remove(key)

        if let diskCache {
            do {
                try await diskCache.remove(key)
                logger.debug("Removed from cache: \(key)")
            } catch {
                logger.error("Failed to remove \(key) from disk", error: error)
            }
        }
    }

    // MARK: - Clear

    /// Clears all cached data
    ///
    /// Example:
    /// ```swift
    /// await cache.clear()
    /// ```
    public func clear() async {
        await memoryCache.clear()

        if let diskCache {
            do {
                try await diskCache.clear()
                logger.info("Cleared all caches")
            } catch {
                logger.error("Failed to clear disk cache", error: error)
            }
        }
    }

    // MARK: - Statistics

    /// Returns cache statistics
    /// - Returns: Tuple of (memory count, disk usage bytes)
    ///
    /// Example:
    /// ```swift
    /// let (memoryCount, diskUsage) = await cache.statistics()
    /// print("Memory: \(memoryCount) items, Disk: \(diskUsage) bytes")
    /// ```
    public func statistics() async -> (memoryCount: Int, diskUsage: Int64) {
        let memoryCount = await memoryCache.count

        var diskUsage: Int64 = 0
        if let diskCache {
            diskUsage = (try? await diskCache.diskUsage()) ?? 0
        }

        return (memoryCount, diskUsage)
    }
}
