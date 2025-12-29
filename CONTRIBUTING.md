# Contributing to AuvasaKit

Thank you for your interest in contributing to AuvasaKit! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive in all interactions with the community.

## Development Setup

### Prerequisites

- macOS 13+ or later
- Xcode 15.0+ with Swift 5.9+
- [SwiftLint](https://github.com/realm/SwiftLint) and [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/pespinel/AuvasaKit.git
cd AuvasaKit

# Install development tools and git hooks
make setup
```

This will:
- Install SwiftLint and SwiftFormat via Homebrew
- Set up pre-commit hooks for automatic formatting and linting

### Manual Setup

If you prefer manual setup:

```bash
# Install tools
brew install swiftlint swiftformat

# Install git hooks
make install-hooks
```

## Development Workflow

### Making Changes

1. **Create a branch** for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines below

3. **Run tests** to ensure everything works:
   ```bash
   make test
   ```

4. **Run all checks** before committing:
   ```bash
   make pre-commit
   ```
   This runs SwiftFormat, SwiftLint, and tests.

### Available Make Commands

```bash
make help           # Show all available commands
make setup          # Install tools and git hooks
make lint           # Run SwiftLint
make format         # Run SwiftFormat
make test           # Run tests
make pre-commit     # Format, lint, and test
make check          # Run all checks (CI simulation)
make clean          # Clean build artifacts
```

## Code Style Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftFormat for automatic formatting (configured in `.swiftformat`)
- Follow SwiftLint rules (configured in `.swiftlint.yml`)
- Maximum line length: 120 characters
- Maximum file length: 500 lines
- Maximum function body length: 60 lines

### Naming Conventions

- Use clear, descriptive names
- Types: `PascalCase` (e.g., `AuvasaClient`, `NetworkError`)
- Functions/variables: `camelCase` (e.g., `fetchVehiclePositions`, `routeId`)
- Constants: `camelCase` (e.g., `defaultTimeout`)
- Enums cases: `camelCase` (e.g., `.success`, `.notFound`)

### Documentation

All public APIs must have complete DocC documentation:

```swift
/// Brief description of the function.
///
/// More detailed description if needed, explaining the purpose,
/// behavior, and any important notes.
///
/// - Parameters:
///   - paramName: Description of the parameter
///   - anotherParam: Description of another parameter
/// - Returns: Description of the return value
/// - Throws: Description of errors that can be thrown
///
/// ## Example
/// ```swift
/// let positions = try await client.fetchVehiclePositions()
/// print(positions)
/// ```
///
/// - Note: Additional notes or warnings
/// - SeeAlso: Related types or functions
public func someFunction(param: String) async throws -> Result {
    // Implementation
}
```

### Concurrency

- Use Swift's structured concurrency (`async`/`await`, actors)
- Mark types as `Sendable` when appropriate
- Use actors for mutable shared state (e.g., `CacheManager`, `SubscriptionManager`)
- Avoid data races with proper isolation

### Error Handling

- Use typed errors (`AuvasaError`, `NetworkError`, etc.)
- Provide clear, actionable error messages with `LocalizedError`
- Include recovery suggestions when possible
- Don't use force unwraps (`!`) or force try (`try!`)

## Testing

### Writing Tests

- Use Swift Testing framework when available
- Test file names should match the tested file: `FileName.swift` → `FileNameTests.swift`
- Group related tests in test suites
- Use descriptive test names that explain what is being tested

Example:

```swift
final class VehiclePositionTests: XCTestCase {
    func testParseValidProtobuf() async throws {
        // Arrange
        let parser = ProtobufParser()
        let data = loadFixture("vehicle_positions.bin")

        // Act
        let positions = try await parser.parseVehiclePositions(data)

        // Assert
        XCTAssertFalse(positions.isEmpty)
        XCTAssertNotNil(positions.first?.position)
    }
}
```

### Integration Tests

Integration tests use live AUVASA endpoints (public, no API key required):

```bash
swift test
```

Consider adding fixtures for offline testing to reduce network dependency.

### Test Coverage

- Aim for high test coverage (>80%)
- All new features must include tests
- Bug fixes should include regression tests
- Test both success and error paths

## Pull Request Process

### Before Submitting

1. **Update documentation** if you changed public APIs
2. **Add tests** for new functionality
3. **Update CHANGELOG.md** under `[Unreleased]` section
4. **Run all checks**:
   ```bash
   make check
   ```
5. **Ensure all tests pass**:
   ```bash
   swift test
   ```

### PR Guidelines

- Use a clear, descriptive title following [Conventional Commits](https://www.conventionalcommits.org/):
  - `feat: add new feature`
  - `fix: correct bug in X`
  - `docs: update documentation for Y`
  - `refactor: improve code structure in Z`
  - `test: add tests for W`
  - `ci: update GitHub Actions workflow`

- Fill out the PR template completely
- Link related issues using "Closes #123" or "Fixes #456"
- Keep PRs focused on a single feature or fix
- Respond to review feedback promptly

### What Happens Next

1. **CI checks** will run automatically (build, lint, format, tests)
2. **Code review** by maintainers
3. **Approval and merge** once all checks pass and review is complete

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <short summary>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `ci`: CI/CD changes
- `chore`: Maintenance tasks
- `style`: Code style changes (formatting, etc.)

Example:
```
feat: add support for service alerts filtering

- Add filterAlerts method to AlertService
- Support filtering by route and stop ID
- Add tests for alert filtering

Closes #42
```

## Reporting Issues

### Bug Reports

Use the bug report template and include:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Code sample demonstrating the issue
- Platform and version information (iOS version, Xcode version)

### Feature Requests

Use the feature request template and include:
- Problem you're trying to solve
- Proposed solution
- Alternative solutions considered
- Example API usage

### Questions

For questions, use [GitHub Discussions](https://github.com/pespinel/AuvasaKit/discussions) instead of issues.

## Project Structure

```
AuvasaKit/
├── Sources/AuvasaKit/
│   ├── AuvasaClient.swift        # Main client API
│   ├── AuvasaError.swift         # Unified error handling
│   ├── Models/
│   │   ├── RealTime/             # GTFS Real-Time models
│   │   │   ├── VehiclePosition.swift
│   │   │   ├── TripUpdate.swift
│   │   │   └── Alert.swift
│   │   ├── Static/               # GTFS Static models
│   │   │   ├── Stop.swift
│   │   │   ├── Route.swift
│   │   │   ├── Trip.swift
│   │   │   └── Calendar.swift
│   │   └── Common/               # Shared models
│   │       ├── Coordinate.swift
│   │       └── TimeRange.swift
│   ├── Services/
│   │   ├── RealTime/
│   │   │   ├── RealtimeService.swift
│   │   │   └── ProtobufParser.swift
│   │   ├── Static/
│   │   │   ├── StopService.swift
│   │   │   ├── RouteService.swift
│   │   │   ├── ScheduleService.swift
│   │   │   └── GTFSImporter.swift
│   │   ├── Database/
│   │   │   └── DatabaseManager.swift
│   │   └── Subscription/
│   │       └── SubscriptionManager.swift
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   └── NetworkError.swift
│   ├── Cache/
│   │   ├── CacheManager.swift
│   │   ├── MemoryCache.swift
│   │   ├── DiskCache.swift
│   │   └── CachePolicy.swift
│   └── Utils/
│       ├── Logger.swift
│       ├── TimeUtils.swift
│       └── LocationUtils.swift
├── Tests/AuvasaKitTests/
│   ├── Models/                   # Model tests
│   ├── Services/                 # Service tests
│   ├── Networking/               # Network tests
│   └── Fixtures/                 # Test fixtures (protobuf data)
└── Examples/                     # Usage examples
    └── README.md
```

## Code Review Checklist

When reviewing PRs, check for:

- [ ] Code follows Swift style guidelines
- [ ] Public APIs have complete DocC documentation
- [ ] All tests pass locally and in CI
- [ ] New features have tests
- [ ] No force unwraps or force casts
- [ ] Proper error handling with `AuvasaError`
- [ ] Sendable conformance where appropriate
- [ ] CHANGELOG.md updated
- [ ] No unnecessary dependencies added
- [ ] Performance considerations addressed
- [ ] Breaking changes documented
- [ ] Cache policies considered for new endpoints
- [ ] Actor isolation properly implemented

## GTFS Specifications

When working with GTFS data:

- Follow [GTFS Real-Time specification](https://gtfs.org/documentation/realtime/reference/)
- Follow [GTFS Static specification](https://gtfs.org/schedule/reference/)
- Handle times > 24 hours correctly (GTFS allows this for late-night service)
- Use proper timezone handling (Europe/Madrid for AUVASA)
- Validate required vs optional fields per specification

## Performance Guidelines

- Cache appropriately using `CacheManager`
- Use proper cache policies for different data types
- Minimize database queries with efficient predicates
- Use batch operations for CoreData inserts
- Profile memory usage for large datasets
- Consider pagination for large result sets

## Security Considerations

- Validate all user inputs
- Sanitize data before storage
- Don't log sensitive information
- Use HTTPS for all network requests
- Handle errors without exposing internal details

## Getting Help

- **Questions**: Use [GitHub Discussions](https://github.com/pespinel/AuvasaKit/discussions)
- **Bugs**: Open an issue using the bug report template
- **Features**: Open an issue using the feature request template
- **Documentation**: Open an issue using the documentation template

## License

By contributing to AuvasaKit, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in the project's README and release notes.

Thank you for contributing to AuvasaKit! 🚍
