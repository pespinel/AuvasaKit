import Foundation

private let logger = Logger(category: "DiskCache")

/// Actor-based disk cache for persistent data storage
actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskSize: Int64 // bytes

    /// Creates a new disk cache
    /// - Parameters:
    ///   - directory: Custom cache directory (optional)
    ///   - maxDiskSize: Maximum disk usage in bytes (default: 50MB)
    init(directory: URL? = nil, maxDiskSize: Int64 = 50 * 1_024 * 1_024) throws {
        if let directory {
            self.cacheDirectory = directory
        } else {
            // Use system cache directory
            guard
                let cacheDir = fileManager.urls(
                    for: .cachesDirectory,
                    in: .userDomainMask
                ).first else
            {
                throw AuvasaError.invalidConfiguration("Cannot access cache directory")
            }
            self.cacheDirectory = cacheDir.appendingPathComponent("com.auvasa.auvasakit")
        }

        self.maxDiskSize = maxDiskSize

        // Create cache directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    /// Stores a value in disk cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - value: Value to cache
    func set(_ key: String, value: some Codable) async throws {
        let cached = CachedValue(value: value, timestamp: Date(), key: key)
        let fileURL = cacheFileURL(for: key)

        do {
            let data = try JSONEncoder().encode(cached)

            // Check disk usage and evict if necessary
            let diskUsage = try await calculateDiskUsage()
            if diskUsage + Int64(data.count) > maxDiskSize {
                try await evictOldest()
            }

            try data.write(to: fileURL)
            logger.debug("Cached \(key) to disk (\(data.count) bytes)")
        } catch {
            logger.error("Failed to cache \(key) to disk", error: error)
            throw AuvasaError.cacheWriteFailed(error)
        }
    }

    /// Retrieves a value from disk cache
    /// - Parameter key: Cache key
    /// - Returns: Cached value if found, nil otherwise
    func get<T: Codable>(_ key: String) async -> CachedValue<T>? {
        let fileURL = cacheFileURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cached = try JSONDecoder().decode(CachedValue<T>.self, from: data)
            logger.debug("Retrieved \(key) from disk")
            return cached
        } catch {
            logger.error("Failed to read \(key) from disk", error: error)
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }

    /// Removes a value from disk cache
    /// - Parameter key: Cache key
    func remove(_ key: String) async throws {
        let fileURL = cacheFileURL(for: key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            logger.debug("Removed \(key) from disk")
        }
    }

    /// Clears all cached data
    func clear() async throws {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }

        logger.info("Cleared disk cache")
    }

    /// Returns total disk usage in bytes
    func diskUsage() async throws -> Int64 {
        try await calculateDiskUsage()
    }

    // MARK: - Private Helpers

    private func cacheFileURL(for key: String) -> URL {
        let filename = key.addingPercentEncoding(
            withAllowedCharacters: .alphanumerics
        ) ?? key.hash.description
        return cacheDirectory.appendingPathComponent(filename)
    }

    private func calculateDiskUsage() async throws -> Int64 {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return 0
        }

        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )

        var totalSize: Int64 = 0
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    private func evictOldest() async throws {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        )

        // Sort by creation date (oldest first)
        let sorted = contents.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 < date2
        }

        // Remove oldest 20% of files
        let countToRemove = max(1, contents.count / 5)
        for fileURL in sorted.prefix(countToRemove) {
            try? fileManager.removeItem(at: fileURL)
        }

        logger.info("Evicted \(countToRemove) oldest items from disk cache")
    }
}
