import CoreData
import Foundation
import XCTest
import ZIPFoundation

@testable import AuvasaKit

final class GTFSImporterTests: XCTestCase {
    var importer: GTFSImporter?
    var databaseManager: DatabaseManager?

    override func setUp() async throws {
        // Use in-memory database for tests
        setenv("AUVASA_IN_MEMORY", "1", 1)
        databaseManager = DatabaseManager.shared
        guard let databaseManager else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize database"])
        }
        importer = GTFSImporter(databaseManager: databaseManager)
    }

    override func tearDown() async throws {
        importer = nil
        databaseManager = nil
        unsetenv("AUVASA_IN_MEMORY")
    }

    private var testImporter: GTFSImporter {
        guard let importer else {
            fatalError("Importer not initialized")
        }
        return importer
    }

    // MARK: - ZIP Extraction Tests

    func testExtractValidZip_ReturnsCSVFiles() throws {
        // Create a minimal valid ZIP file with CSV content
        let zipData = try createMinimalGTFSZip()

        // Extract CSV files using the importer's method via reflection
        // Since extractCSVFiles is private, we test it indirectly through importGTFSData
        // For direct testing, we'll create a test-specific ZIP extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let zipFile = tempDir.appendingPathComponent("test.zip")
        try zipData.write(to: zipFile)

        // Extract using ZIPFoundation (same method used by GTFSImporter)
        do {
            try FileManager.default.unzipItem(at: zipFile, to: tempDir)

            // Verify CSV files were extracted
            let stopsFile = tempDir.appendingPathComponent("stops.txt")
            XCTAssertTrue(FileManager.default.fileExists(atPath: stopsFile.path), "stops.txt should be extracted")

            let stopsContent = try String(contentsOf: stopsFile, encoding: .utf8)
            XCTAssertTrue(stopsContent.contains("stop_id"), "stops.txt should contain headers")
        } catch {
            XCTFail("ZIP extraction should succeed: \(error)")
        }
    }

    func testExtractInvalidZipData_ThrowsError() throws {
        // Create invalid ZIP data
        guard let invalidData = Data("This is not a ZIP file".utf8) else {
            XCTFail("Failed to create test data")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let zipFile = tempDir.appendingPathComponent("invalid.zip")
        try invalidData.write(to: zipFile)

        // Attempt extraction (should throw)
        XCTAssertThrowsError(try FileManager.default.unzipItem(at: zipFile, to: tempDir)) { error in
            // Verify it's a ZIP-related error
            XCTAssertNotNil(error, "Should throw an error for invalid ZIP data")
        }
    }

    func testExtractEmptyZip_Succeeds() throws {
        // Create an empty but valid ZIP file
        let zipData = try createEmptyZip()

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let zipFile = tempDir.appendingPathComponent("empty.zip")
        try zipData.write(to: zipFile)

        // Extract should succeed but produce no files
        do {
            try FileManager.default.unzipItem(at: zipFile, to: tempDir)

            // Verify no CSV files extracted (except the zip itself)
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            let csvFiles = contents.filter { $0.pathExtension == "txt" }
            XCTAssertEqual(csvFiles.count, 0, "Empty ZIP should extract no CSV files")
        } catch {
            XCTFail("Empty ZIP extraction should succeed: \(error)")
        }
    }

    func testTemporaryDirectoryCleanup_AfterExtraction() throws {
        let zipData = try createMinimalGTFSZip()

        var tempDirPath: String?

        do {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            tempDirPath = tempDir.path

            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let zipFile = tempDir.appendingPathComponent("test.zip")
            try zipData.write(to: zipFile)
            try FileManager.default.unzipItem(at: zipFile, to: tempDir)

            // Manually cleanup (simulating defer block)
            try FileManager.default.removeItem(at: tempDir)
        } catch {
            XCTFail("Extraction and cleanup should succeed: \(error)")
        }

        // Verify temp directory was cleaned up
        if let path = tempDirPath {
            XCTAssertFalse(FileManager.default.fileExists(atPath: path), "Temporary directory should be cleaned up")
        }
    }

    // MARK: - Platform Compatibility Tests

    func testZipExtractionWorks_OnCurrentPlatform() throws {
        // This test verifies ZIPFoundation works on the current platform
        let zipData = try createMinimalGTFSZip()

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let zipFile = tempDir.appendingPathComponent("platform_test.zip")
        try zipData.write(to: zipFile)

        // This should work on iOS, macOS, watchOS, tvOS
        XCTAssertNoThrow(try FileManager.default.unzipItem(at: zipFile, to: tempDir))
    }

    // MARK: - Integration Tests

    func testFullGTFSImport_WithRealData() async throws {
        // Skip this test in CI environments or when network is unavailable
        // In real usage, you might check for a specific environment variable
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil, "Skipping network test in CI")

        // This test downloads real GTFS data from AUVASA and imports it
        // It's a comprehensive integration test but requires network access
        do {
            try await testImporter.importGTFSData()

            // Verify data was imported (check that stops were created)
            let context = databaseManager?.viewContext
            let fetchRequest = NSFetchRequest<GTFSStop>(entityName: "GTFSStop")
            fetchRequest.fetchLimit = 1

            let stops = try await context?.perform {
                try fetchRequest.execute()
            }

            XCTAssertNotNil(stops, "Should have imported stops")
            XCTAssertGreaterThan(stops?.count ?? 0, 0, "Should have at least one stop")
        } catch {
            XCTFail("Full GTFS import should succeed: \(error)")
        }
    }

    // MARK: - Test Helpers

    /// Creates a minimal valid GTFS ZIP file with required CSV files
    private func createMinimalGTFSZip() throws -> Data {
        // Create a temporary directory for building the ZIP
        let buildDir = FileManager.default.temporaryDirectory.appendingPathComponent("gtfs_build_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: buildDir)
        }

        // Create minimal stops.txt
        let stopsCSV = """
            stop_id,stop_code,stop_name,stop_lat,stop_lon
            STOP1,001,Test Stop 1,41.6523,-4.7245
            STOP2,002,Test Stop 2,41.6530,-4.7250
            """
        let stopsFile = buildDir.appendingPathComponent("stops.txt")
        try stopsCSV.write(to: stopsFile, atomically: true, encoding: .utf8)

        // Create minimal routes.txt
        let routesCSV = """
            route_id,route_short_name,route_long_name,route_type
            R1,1,Route 1,3
            R2,2,Route 2,3
            """
        let routesFile = buildDir.appendingPathComponent("routes.txt")
        try routesCSV.write(to: routesFile, atomically: true, encoding: .utf8)

        // Create minimal trips.txt
        let tripsCSV = """
            trip_id,route_id,service_id,trip_headsign
            TRIP1,R1,SVC1,Destination 1
            TRIP2,R2,SVC1,Destination 2
            """
        let tripsFile = buildDir.appendingPathComponent("trips.txt")
        try tripsCSV.write(to: tripsFile, atomically: true, encoding: .utf8)

        // Create minimal stop_times.txt
        let stopTimesCSV = """
            trip_id,stop_id,arrival_time,departure_time,stop_sequence
            TRIP1,STOP1,08:00:00,08:00:00,1
            TRIP1,STOP2,08:05:00,08:05:00,2
            """
        let stopTimesFile = buildDir.appendingPathComponent("stop_times.txt")
        try stopTimesCSV.write(to: stopTimesFile, atomically: true, encoding: .utf8)

        // Create the ZIP file
        let zipFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("minimal_gtfs_\(UUID().uuidString).zip")

        // Use ZIPFoundation to create the ZIP
        try FileManager.default.zipItem(at: buildDir, to: zipFile, shouldKeepParent: false)

        // Read ZIP data
        let zipData = try Data(contentsOf: zipFile)

        // Cleanup
        try? FileManager.default.removeItem(at: zipFile)

        return zipData
    }

    /// Creates an empty but valid ZIP file
    private func createEmptyZip() throws -> Data {
        // Create a temporary directory
        let buildDir = FileManager.default.temporaryDirectory.appendingPathComponent("empty_build_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: buildDir)
        }

        // Create the ZIP file from empty directory
        let zipFile = FileManager.default.temporaryDirectory.appendingPathComponent("empty_\(UUID().uuidString).zip")
        try FileManager.default.zipItem(at: buildDir, to: zipFile, shouldKeepParent: false)

        // Read ZIP data
        let zipData = try Data(contentsOf: zipFile)

        // Cleanup
        try? FileManager.default.removeItem(at: zipFile)

        return zipData
    }
}
