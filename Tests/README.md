# AuvasaKit Tests

## Test Structure

### Unit Tests
Located in `AuvasaKitTests/` and organized by component:
- **Models/** - Tests for data models (VehiclePosition, Arrival, TripDetails, etc.)
- **Utils/** - Tests for utility functions (Coordinate, LocationUtils)
- **Services/** - Tests for service layer components

All unit tests run in CI and are designed to be:
- **Fast** - No network calls or external dependencies
- **Deterministic** - Always produce the same results
- **Isolated** - Test individual components in isolation

### Running Unit Tests

```bash
swift test
```

## Manual Integration Testing

Integration tests against real AUVASA endpoints are **not included in CI** because:
- External APIs can be slow or unavailable
- Results are non-deterministic
- They can fail for reasons unrelated to code changes

### Testing Against Real Endpoints

To verify functionality against real AUVASA endpoints, you can:

1. **Use the Swift REPL:**
```bash
swift build
swift -I .build/debug -L .build/debug -lAuvasaKit
```

```swift
import AuvasaKit

let client = AuvasaClient()

// Test vehicle positions
let vehicles = try await client.fetchVehiclePositions()
print("Found \(vehicles.count) vehicles")

// Test trip updates
let updates = try await client.fetchTripUpdates()
print("Found \(updates.count) trip updates")

// Test alerts
let alerts = try await client.fetchAlerts()
print("Found \(alerts.count) alerts")
```

2. **Create a temporary test script:**
```swift
// test-integration.swift
import AuvasaKit

@main
struct IntegrationTest {
    static func main() async throws {
        let client = AuvasaClient()

        print("Testing vehicle positions...")
        let vehicles = try await client.fetchVehiclePositions()
        print("✓ Found \(vehicles.count) vehicles")

        print("\nTesting trip updates...")
        let updates = try await client.fetchTripUpdates()
        print("✓ Found \(updates.count) trip updates")

        print("\nTesting alerts...")
        let alerts = try await client.fetchAlerts()
        print("✓ Found \(alerts.count) alerts")
    }
}
```

Run with:
```bash
swift run
```

## Test Coverage

Current test coverage:
- ✅ Model layer (initialization, equality, codable)
- ✅ Coordinate calculations (Haversine distance)
- ✅ Location utilities (bounding box, bearing, interpolation)
- ✅ Arrival logic (delay calculations, best time)
- ✅ Trip details (stop navigation, progress)

### Future Test Improvements

To improve test coverage with proper mocking:

1. **Mock Network Layer**
   - Create `MockAPIClient` for testing services
   - Provide sample protobuf responses

2. **Service Layer Tests**
   - Test `RealtimeService` with mocked network responses
   - Test `ProtobufParser` with real protobuf fixtures

3. **Client Tests**
   - Test `AuvasaClient` methods with mocked services
   - Verify error handling and edge cases

Example structure:
```swift
final class RealtimeServiceTests: XCTestCase {
    func testFetchVehiclePositions() async throws {
        let mockClient = MockAPIClient()
        mockClient.mockResponse = loadFixture("vehicle_positions.bin")

        let service = RealtimeService(apiClient: mockClient)
        let positions = try await service.fetchVehiclePositions()

        XCTAssertEqual(positions.count, 78)
        XCTAssertEqual(positions.first?.vehicle.id, "BUS001")
    }
}
```
