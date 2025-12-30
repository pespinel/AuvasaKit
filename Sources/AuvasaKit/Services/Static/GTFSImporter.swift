import CoreData
import Foundation
import ZIPFoundation

/// Imports GTFS static data from AUVASA's ZIP file
public actor GTFSImporter {
    /// Errors that can occur during GTFS import
    public enum ImportError: Error, LocalizedError {
        case downloadFailed(Error)
        case invalidZipData
        case extractionFailed(Error)
        case missingRequiredFile(String)
        case csvParsingFailed(String, Error)
        case importFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .downloadFailed(let error):
                "Failed to download GTFS data: \(error.localizedDescription)"
            case .invalidZipData:
                "Downloaded data is not a valid ZIP file"
            case .extractionFailed(let error):
                "Failed to extract ZIP: \(error.localizedDescription)"
            case .missingRequiredFile(let filename):
                "Required file missing: \(filename)"
            case .csvParsingFailed(let filename, let error):
                "Failed to parse \(filename): \(error.localizedDescription)"
            case .importFailed(let error):
                "Failed to import data: \(error.localizedDescription)"
            }
        }
    }

    private let databaseManager: DatabaseManager
    private let gtfsURL: URL

    public static let defaultGTFSURL: URL = {
        guard let url = URL(string: "http://212.170.201.204:50080/GTFSRTapi/api/GTFSFile") else {
            fatalError("Invalid GTFS URL")
        }
        return url
    }()

    /// Creates a new GTFS importer
    /// - Parameters:
    ///   - databaseManager: Database manager for storing GTFS data
    ///   - gtfsURL: URL to download GTFS ZIP file (defaults to AUVASA's official URL)
    public init(
        databaseManager: DatabaseManager = .shared,
        gtfsURL: URL = defaultGTFSURL
    ) {
        self.databaseManager = databaseManager
        self.gtfsURL = gtfsURL
    }

    /// Imports GTFS static data
    /// Downloads ZIP, extracts files, parses CSV, and imports to CoreData
    public func importGTFSData() async throws {
        // 1. Download ZIP
        let zipData = try await downloadGTFSZip()

        // 2. Extract CSV files
        let csvFiles = try extractCSVFiles(from: zipData)

        // 3. Clear existing data
        try await databaseManager.clearAllData()

        // 4. Parse and import each file
        try await importStops(csvFiles["stops.txt"])
        try await importRoutes(csvFiles["routes.txt"])
        try await importTrips(csvFiles["trips.txt"])
        try await importStopTimes(csvFiles["stop_times.txt"])
        try await importCalendar(csvFiles["calendar.txt"])
        try await importCalendarDates(csvFiles["calendar_dates.txt"])
        try await importShapes(csvFiles["shapes.txt"])
    }

    // MARK: - Download

    private func downloadGTFSZip() async throws -> Data {
        do {
            Logger.database.info("Starting GTFS download from: \(gtfsURL.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: gtfsURL)

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else
            {
                Logger.database
                    .error("HTTP request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw ImportError.downloadFailed(
                    URLError(.badServerResponse)
                )
            }

            let sizeInMB = String(format: "%.2f", Double(data.count) / 1_024 / 1_024)
            Logger.database.info("Downloaded \(data.count) bytes (\(sizeInMB) MB)")

            let firstBytes = data.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " ")
            Logger.database.debug("First 4 bytes: \(firstBytes)")

            // Verify it's a valid ZIP file (should start with PK signature: 50 4B 03 04)
            let zipSignature = Data([0x50, 0x4B, 0x03, 0x04])
            if data.prefix(4) != zipSignature {
                Logger.database.error("Invalid ZIP signature! Expected: 50 4B 03 04, got: \(firstBytes)")
                throw ImportError.invalidZipData
            }

            Logger.database.info("Valid ZIP file confirmed")
            return data
        } catch {
            Logger.database.error("Download failed", error: error)
            throw ImportError.downloadFailed(error)
        }
    }

    // MARK: - Extraction

    private func extractCSVFiles(from zipData: Data) throws -> [String: String] {
        Logger.database.info("Starting ZIP extraction...")
        Logger.database.debug("ZIP data size: \(zipData.count) bytes")

        // Create temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Write ZIP to temp file
        let zipFile = tempDir.appendingPathComponent("gtfs.zip")
        try zipData.write(to: zipFile)
        Logger.database.debug("Wrote ZIP to temporary file: \(zipFile.path)")

        // Verify file was written correctly
        let writtenSize = (try? FileManager.default.attributesOfItem(atPath: zipFile.path)[.size] as? Int) ?? 0
        Logger.database.debug("Verified file size on disk: \(writtenSize) bytes")

        if writtenSize != zipData.count {
            Logger.database.warning("File size mismatch: written=\(writtenSize), expected=\(zipData.count)")
        }

        // Extract ZIP using ZIPFoundation (cross-platform)
        do {
            Logger.database.info("Extracting ZIP contents...")
            try FileManager.default.unzipItem(at: zipFile, to: tempDir)
            Logger.database.info("ZIP extracted successfully")
        } catch {
            Logger.database.error("ZIP extraction failed", error: error)
            throw ImportError.extractionFailed(error)
        }

        // Read CSV files
        var csvFiles: [String: String] = [:]
        let fileNames = [
            "stops.txt",
            "routes.txt",
            "trips.txt",
            "stop_times.txt",
            "calendar.txt",
            "calendar_dates.txt",
            "shapes.txt"
        ]

        for fileName in fileNames {
            let fileURL = tempDir.appendingPathComponent(fileName)
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                csvFiles[fileName] = content
            }
        }

        return csvFiles
    }

    // MARK: - CSV Parsing

    nonisolated private func parseCSV(_ csv: String) -> [[String: String]] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return [] }

        let headers = lines[0].components(separatedBy: ",")
        var records: [[String: String]] = []

        for line in lines.dropFirst() {
            let values = parseCSVLine(line)
            guard values.count == headers.count else { continue }

            var record: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                record[header] = values[index].trimmingCharacters(in: .whitespaces)
            }
            records.append(record)
        }

        return records
    }

    nonisolated private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        values.append(currentValue)
        return values
    }

    // MARK: - Import Stops

    private func importStops(_ csv: String?) async throws {
        guard let csv else {
            throw ImportError.missingRequiredFile("stops.txt")
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let stop = GTFSStop(context: context)
                stop.id = record["stop_id"] ?? ""
                stop.code = record["stop_code"]
                stop.name = record["stop_name"] ?? ""
                stop.desc = record["stop_desc"]
                stop.latitude = Double(record["stop_lat"] ?? "0") ?? 0
                stop.longitude = Double(record["stop_lon"] ?? "0") ?? 0
                stop.zoneId = record["zone_id"]
                stop.url = record["stop_url"]
                stop.locationType = Int16(record["location_type"] ?? "0") ?? 0
                stop.parentStation = record["parent_station"]
                stop.wheelchairBoarding = Int16(record["wheelchair_boarding"] ?? "0") ?? 0
                stop.platformCode = record["platform_code"]
            }

            try context.save()
        }
    }

    // MARK: - Import Routes

    private func importRoutes(_ csv: String?) async throws {
        guard let csv else {
            throw ImportError.missingRequiredFile("routes.txt")
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let route = GTFSRoute(context: context)
                route.id = record["route_id"] ?? ""
                route.agencyId = record["agency_id"]
                route.shortName = record["route_short_name"] ?? ""
                route.longName = record["route_long_name"] ?? ""
                route.desc = record["route_desc"]
                route.type = Int16(record["route_type"] ?? "3") ?? 3
                route.url = record["route_url"]
                route.color = record["route_color"]
                route.textColor = record["route_text_color"]
                route.sortOrder = Int32(record["route_sort_order"] ?? "0") ?? 0
            }

            try context.save()
        }
    }

    // MARK: - Import Trips

    private func importTrips(_ csv: String?) async throws {
        guard let csv else {
            throw ImportError.missingRequiredFile("trips.txt")
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let trip = GTFSTrip(context: context)
                trip.id = record["trip_id"] ?? ""
                trip.routeId = record["route_id"] ?? ""
                trip.serviceId = record["service_id"] ?? ""
                trip.headsign = record["trip_headsign"]
                trip.shortName = record["trip_short_name"]
                trip.directionId = Int16(record["direction_id"] ?? "0") ?? 0
                trip.blockId = record["block_id"]
                trip.shapeId = record["shape_id"]
                trip.wheelchairAccessible = Int16(record["wheelchair_accessible"] ?? "0") ?? 0
                trip.bikesAllowed = Int16(record["bikes_allowed"] ?? "0") ?? 0
            }

            try context.save()
        }
    }

    // MARK: - Import Stop Times

    private func importStopTimes(_ csv: String?) async throws {
        guard let csv else {
            throw ImportError.missingRequiredFile("stop_times.txt")
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let stopTime = GTFSStopTime(context: context)
                stopTime.tripId = record["trip_id"] ?? ""
                stopTime.stopId = record["stop_id"] ?? ""
                stopTime.arrivalTime = record["arrival_time"] ?? ""
                stopTime.departureTime = record["departure_time"] ?? ""
                stopTime.stopSequence = Int32(record["stop_sequence"] ?? "0") ?? 0
                stopTime.stopHeadsign = record["stop_headsign"]
                stopTime.pickupType = Int16(record["pickup_type"] ?? "0") ?? 0
                stopTime.dropOffType = Int16(record["drop_off_type"] ?? "0") ?? 0
                stopTime.shapeDistTraveled = Double(record["shape_dist_traveled"] ?? "0") ?? 0
                stopTime.timepoint = Int16(record["timepoint"] ?? "1") ?? 1
            }

            try context.save()
        }
    }

    // MARK: - Import Calendar

    private func importCalendar(_ csv: String?) async throws {
        guard let csv else {
            // calendar.txt is optional if calendar_dates.txt is present
            return
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let calendar = GTFSCalendar(context: context)
                calendar.serviceId = record["service_id"] ?? ""
                calendar.monday = record["monday"] == "1"
                calendar.tuesday = record["tuesday"] == "1"
                calendar.wednesday = record["wednesday"] == "1"
                calendar.thursday = record["thursday"] == "1"
                calendar.friday = record["friday"] == "1"
                calendar.saturday = record["saturday"] == "1"
                calendar.sunday = record["sunday"] == "1"
                calendar.startDate = record["start_date"] ?? ""
                calendar.endDate = record["end_date"] ?? ""
            }

            try context.save()
        }
    }

    // MARK: - Import Calendar Dates

    private func importCalendarDates(_ csv: String?) async throws {
        guard let csv else {
            // calendar_dates.txt is optional
            return
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let calendarDate = GTFSCalendarDate(context: context)
                calendarDate.serviceId = record["service_id"] ?? ""
                calendarDate.date = record["date"] ?? ""
                calendarDate.exceptionType = Int16(record["exception_type"] ?? "1") ?? 1
            }

            try context.save()
        }
    }

    // MARK: - Import Shapes

    private func importShapes(_ csv: String?) async throws {
        guard let csv else {
            // shapes.txt is optional
            return
        }

        let context = await databaseManager.newBackgroundContext()

        try await context.perform {
            let records = self.parseCSV(csv)

            for record in records {
                let shape = GTFSShape(context: context)
                shape.shapeId = record["shape_id"] ?? ""
                shape.latitude = Double(record["shape_pt_lat"] ?? "0") ?? 0
                shape.longitude = Double(record["shape_pt_lon"] ?? "0") ?? 0
                shape.sequence = Int32(record["shape_pt_sequence"] ?? "0") ?? 0
                shape.distTraveled = Double(record["shape_dist_traveled"] ?? "0") ?? 0
            }

            try context.save()
        }
    }
}
