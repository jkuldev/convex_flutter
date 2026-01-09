## 1.0.2

- Added support for Dart 3.7.0
- Added support for Flutter 3.3.0
- Added support for Flutter 3.10.0
- Added support for Flutter 3.11.0
- Added support for Flutter 3.12.0
- Added support for Flutter 3.13.0
- Added support for Flutter 3.14.0

## 1.0.3

- Updated flutter_rust_bridge package to 2.9.0

## 1.0.4

- Updated flutter_rust_bridge package to 2.10.0

## 1.2.0

 - Package version updated

## 2.0.0

- Replaced ArcSubscriptionHandle with SubscriptionHandle

## 2.1.0

### New Features

- **Singleton Pattern**: New `ConvexClient.initialize(ConvexConfig)` method with `ConvexClient.instance` access
- **Operation Timeouts**: Configurable timeout for all queries, mutations, and actions (default: 30 seconds)
- **Connection Management**: Manual connection checking with `checkConnection()` and `reconnect()` methods
- **Lifecycle Monitoring**: Stream of app lifecycle events (resumed, paused, inactive, detached)
- **Configuration Class**: New `ConvexConfig` class for cleaner initialization

### Bug Fixes

- Fixed critical Rust subscription panic when WebSocket connection closes unexpectedly
- Subscription streams now exit gracefully instead of crashing the app

### Improvements

- Better error handling for connection issues with `ConnectionStatus` enum
- App lifecycle integration with `AppLifecycleObserver`
- Comprehensive documentation updates with new usage examples
- Example app updated to demonstrate new features

### API Changes

- **Deprecated**: `ConvexClient.init()` is now deprecated, use `ConvexClient.initialize(ConvexConfig)` instead
- **New**: `ConvexClient.instance` - Access singleton anywhere
- **New**: `ConvexClient.initialize(ConvexConfig)` - Initialize with configuration
- **New**: `checkConnection()` - Manual connection status check
- **New**: `reconnect()` - Manual reconnection attempt
- **New**: `lifecycleEvents` stream - Monitor app lifecycle
- **Enhanced**: All queries, mutations, and actions now respect `operationTimeout`

### Breaking Changes

None - backward compatibility maintained through deprecated methods

## 2.2.0

### New Features

- **Real-Time WebSocket Connection State**: Monitor WebSocket connection status via reactive streams
  - `connectionState` stream - Real-time connection state updates (Connected/Connecting)
  - `currentConnectionState` getter - Synchronous access to current state
  - `isConnected` getter - Quick boolean check for connection status
  - Automatic state transitions when WebSocket connects/disconnects
  - No polling required - pure event-driven updates

### Bug Fixes

- **Fixed critical race condition in WebSocket connection initialization**
  - Issue: State change callback was registered after WebSocket connection began, causing state transitions to be lost
  - Root cause: Async task spawning in `connected_client()` created unpredictable timing delays
  - Solution: Removed task spawning and build ConvexClient directly in async context
  - Result: Callback is now guaranteed to be registered before `builder.build()` is called

- **Fixed WebSocket connection state stuck on "connecting"**
  - Issue: Example app showed "connecting" forever without transitioning to "connected"
  - Root cause: No operations were triggered on app startup, so `connected_client()` was never called
  - Solution: Added auto-connection trigger in example app's HomeScreen initialization
  - Result: Connection establishes automatically on startup with proper state transitions

### Improvements

- Enhanced example app with comprehensive WebSocket connection state demonstrations:
  - Connection status indicator in app bar with real-time visual feedback
  - Dedicated Connection screen showing current state and history
  - Automatic connection on app startup
  - All 5 screens demonstrating different SDK capabilities

- Comprehensive debug logging for troubleshooting connection issues
- Updated documentation with WebSocket connection state usage examples
- Deprecated `checkConnection()` in favor of real-time `connectionState` stream

### API Changes

- **New**: `connectionState` stream - Real-time WebSocket connection state updates (`Stream<WebSocketConnectionState>`)
- **New**: `currentConnectionState` getter - Synchronous access to current connection state
- **New**: `isConnected` getter - Boolean check for WebSocket connection status
- **Deprecated**: `checkConnection()` - Use `connectionState` stream for real-time monitoring instead

### Breaking Changes

None - all changes are additive and maintain backward compatibility