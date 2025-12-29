# Installation

Add AuvasaKit to your iOS or macOS project.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Swift Package Manager

### Xcode

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/yourusername/AuvasaKit.git
   ```
4. Select version: **1.0.0** or **Up to Next Major Version**
5. Click **Add Package**
6. Select **AuvasaKit** and click **Add Package** again

### Package.swift

Add AuvasaKit as a dependency in your `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/AuvasaKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["AuvasaKit"]
        )
    ]
)
```

## Importing

Import AuvasaKit in your Swift files:

```swift
import AuvasaKit
```

## First Steps

After installation, see <doc:GettingStarted> to begin using AuvasaKit.

## Dependencies

AuvasaKit has one dependency:
- **SwiftProtobuf** (1.27.0+) - For parsing GTFS Real-Time data

This dependency is automatically managed by Swift Package Manager.

## Platform Support

AuvasaKit supports:
- **iOS 15.0+**: Full support including SwiftUI
- **macOS 12.0+**: Complete API access
- **watchOS**: Not currently supported (CoreData limitations)
- **tvOS**: Not currently supported

## Build Considerations

### Debug vs Release

AuvasaKit uses the same configuration for both debug and release builds. For testing, you can use an in-memory CoreData store:

```swift
// Set environment variable for in-memory database (useful for testing)
ProcessInfo.processInfo.environment["AUVASA_IN_MEMORY"] = "1"
```

### Network Requirements

AuvasaKit requires internet access to:
- Fetch real-time data from AUVASA servers
- Download GTFS static data (one-time or periodic updates)

Ensure your app has appropriate network permissions in Info.plist if needed.

## Troubleshooting

### Build Errors

**Error: "Missing SwiftProtobuf"**
- Solution: Clean build folder (Cmd+Shift+K) and rebuild

**Error: "Module 'AuvasaKit' not found"**
- Solution: Ensure package is added to your target's dependencies

### Runtime Issues

**Error: "Failed to load Core Data stack"**
- Solution: Check disk space and app permissions
- For testing, use in-memory store (see above)

**Error: "Network request failed"**
- Solution: Verify internet connection
- Check AUVASA endpoints are accessible
- Ensure proper timeout configuration

## Next Steps

Once installed, proceed to:
- <doc:GettingStarted> - Quick start guide
- <doc:RealTimeData> - Real-time features
- <doc:StaticData> - Static data queries
