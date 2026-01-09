# Plan: Replace Rust with Native Kotlin/Swift for Convex Connectivity

## Status: CRITICAL DISCOVERY - OFFICIAL SDKs ALSO USE RUST

## IMPORTANT FINDING ⚠️

The official Android and iOS SDKs **ALSO USE RUST INTERNALLY**:

**From Android SDK docs:**
> "The underlying implementation leverages the official Convex Rust client and Tokio async runtime."

**From iOS Swift SDK docs:**
> "Underlying dependency on the 'official Convex Rust client'"

### What This Means

**Switching to official SDKs will NOT reduce binary size** because they use the same Rust core:

- **Current approach**: Dart → flutter_rust_bridge → Rust → Convex
- **Official SDKs approach**: Dart → Platform channels → Kotlin/Swift → Rust → Convex

Both architectures include the Rust binaries. The official SDKs just add a Kotlin/Swift API layer on top of Rust.

### Binary Size Reality

| Approach | Includes Rust? | Binary Size |
|----------|----------------|-------------|
| Current (flutter_rust_bridge) | ✅ Yes | Baseline |
| Official Android/iOS SDKs | ✅ Yes | Similar or slightly larger (extra wrapper) |
| Pure Kotlin/Swift (reverse-engineer) | ❌ No | 30-50% smaller |
| Optimized Rust build | ✅ Yes | 30-50% smaller |

## Recommended Approach: Use Official SDKs

**Decision**: Migrate to official Convex Android (Kotlin) and iOS (Swift) SDKs via Flutter platform channels.

**Benefits**:
- Official support and maintenance from Convex team
- Better documented and tested implementations
- Idiomatic Kotlin/Swift APIs
- Future-proof (official SDKs get updates)
- Better platform integration capabilities

**Note**: Binary size will NOT significantly decrease (official SDKs also use Rust internally), but the architecture will be cleaner and officially supported.

---

## Architecture Design

### Current Architecture (flutter_rust_bridge)
```
Dart → flutter_rust_bridge (FFI) → Rust → Convex Rust SDK → Convex Backend
```

### Target Architecture (Platform Channels)
```
Dart → Platform Channels → Kotlin/Swift → Official Mobile SDKs → Convex Backend
                          ↓                ↓
                     Android SDK      iOS SDK
                    (convex-mobile)  (ConvexMobile)
                          ↓                ↓
                    Rust Core        Rust Core
```

### Platform Channel Design

**Method Channel** (`convex_flutter/methods`):
- One-shot operations: `initialize`, `query`, `mutation`, `action`, `setAuth`
- Returns JSON strings or throws PlatformException

**Event Channels** (Dynamic per subscription):
- Pattern: `convex_flutter/subscription/{subscriptionId}`
- One EventChannel per active subscription
- Emits: `{type: "update", data: "..."} | {type: "error", message: "...", data: "..."}`

**Auth State Event Channel** (`convex_flutter/auth_state`):
- Single EventChannel for authentication state changes
- Emits: `{isAuthenticated: true/false}`

---

## Implementation Plan

### Phase 1: Android Implementation (3-4 days)

#### 1.1 Update Android Configuration
**File**: `android/build.gradle`
- Remove cargokit plugin references
- Add Kotlin serialization plugin
- Add dependencies:
  ```gradle
  implementation "dev.convex:android-convexmobile:0.4.1@aar"
  implementation "org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3"
  implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
  ```

#### 1.2 Create Kotlin Plugin
**File**: `android/src/main/kotlin/com/flutter_rust_bridge/convex_flutter/ConvexFlutterPlugin.kt`

Key components:
- `ConvexClient` singleton management
- MethodCallHandler for query/mutation/action/setAuth
- Dynamic EventChannel creation for subscriptions
- Subscription lifecycle: Map of `subscriptionId → Job + StreamHandler`
- Coroutine scope management (CoroutineScope + Dispatchers.IO)
- Error mapping: ConvexError → PlatformException
- JSON argument parsing from Map<String, String>

Critical methods:
- `initialize(deploymentUrl, clientId)` - Create ConvexClient
- `query/mutation/action` - Suspend calls with error handling
- `subscribe(subscriptionId, name, args)` - Create EventChannel + Flow collection
- `cancelSubscription(subscriptionId)` - Cancel Job and clean up handler

### Phase 2: iOS Implementation (3-4 days)

#### 2.1 Update iOS Configuration
**File**: `ios/convex_flutter.podspec`
- Remove cargokit script phase
- Add Swift Package dependency to ConvexMobile
- Set minimum iOS version to 13.0+

#### 2.2 Create Swift Plugin
**File**: `ios/Classes/ConvexFlutterPlugin.swift`

Key components:
- `ConvexClient` singleton management
- FlutterMethodChannel handler for query/mutation/action/setAuth
- Dynamic FlutterEventChannel creation for subscriptions
- Subscription lifecycle: Map of `subscriptionId → AnyCancellable + StreamHandler`
- Combine Publisher handling
- Swift async/await for operations
- Error mapping: ClientError → FlutterError
- JSON argument parsing from [String: String]

Critical methods:
- `initialize(deploymentUrl:)` - Create ConvexClient
- `query/mutation/action` - Async calls with error handling
- `subscribe(subscriptionId:name:args:)` - Create EventChannel + Publisher sink
- `cancelSubscription(subscriptionId:)` - Cancel AnyCancellable and clean up

### Phase 3: Dart Client Updates (2-3 days)

#### 3.1 Create Platform Client
**File**: `lib/src/platform/convex_platform_client.dart`

Responsibilities:
- Wrap MethodChannel calls
- Manage subscription ID generation
- Create dynamic EventChannels for subscriptions
- Map PlatformException to ClientError
- Maintain same interface as current MobileConvexClient

Key APIs:
```dart
Future<void> init({deploymentUrl, clientId})
Future<String> query({name, args})
Future<String> mutation({name, args})
Future<String> action({name, args})
Future<SubscriptionHandle> subscribe({name, args, onUpdate, onError})
Future<void> setAuth({token})
```

#### 3.2 Create Auth Manager
**File**: `lib/src/platform/auth_manager.dart`

Move auth refresh logic from Rust to Dart:
- JWT expiry parsing (base64 decode)
- Timer-based refresh scheduling (60s buffer)
- Token fetch callback handling
- Auth state change notifications
- Disposal and cleanup

#### 3.3 Update ConvexClient
**File**: `lib/src/convex_client.dart`

Changes:
- Replace `MobileConvexClient` with `ConvexPlatformClient`
- Remove `RustLib.init()` call
- Keep all public APIs identical (backward compatible)
- Update internal calls to use platform client

#### 3.4 Update Exports
**File**: `lib/convex_flutter.dart`

Remove:
- `export 'src/rust/lib.dart'`
- `export 'src/rust/frb_generated.dart'`

Add:
- `export 'src/platform/convex_platform_client.dart'`

### Phase 4: Cleanup & Dependencies (1-2 days)

#### 4.1 Remove Rust Code
Delete:
- `rust/` - Entire Rust crate
- `cargokit/` - Build system
- `lib/src/rust/` - Generated bridge code
- `flutter_rust_bridge.yaml`
- `build.yaml`
- `ios/Classes/dummy_file.c`

#### 4.2 Update pubspec.yaml
```yaml
version: 3.0.0  # Major version bump

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  # REMOVE: flutter_rust_bridge: ^2.11.1
  # REMOVE: freezed_annotation

flutter:
  plugin:
    platforms:
      android:
        pluginClass: ConvexFlutterPlugin
      ios:
        pluginClass: ConvexFlutterPlugin
      # REMOVE: linux, macos, windows (mobile-only now)
```

#### 4.3 Update CHANGELOG.md
Document breaking changes:
- Migration to platform channels
- Removed desktop platform support
- Minimum iOS version: 13.0+
- Public API unchanged (backward compatible)

### Phase 5: Testing (2-3 days)

#### 5.1 Unit Tests
Create:
- `test/convex_platform_client_test.dart` - Mock MethodChannel responses
- `test/auth_manager_test.dart` - JWT parsing and refresh logic

#### 5.2 Integration Tests
**File**: `example/integration_test/convex_integration_test.dart`

Test against real Convex backend:
- Query/mutation/action operations
- Real-time subscriptions with updates
- Authentication flow
- Subscription cancellation
- Error scenarios (ConvexError, ServerError)
- Multiple concurrent subscriptions

#### 5.3 Platform-Specific Tests
- Android: Kotlin unit tests for plugin
- iOS: Swift unit tests for plugin

#### 5.4 Manual Testing
- Test example app on physical Android device
- Test example app on physical iOS device
- Memory leak detection (DevTools)
- Performance comparison vs v2.x

### Phase 6: Documentation (1-2 days)

#### 6.1 Create Migration Guide
**File**: `MIGRATION_3.0.md`

Content:
- Breaking changes summary
- Platform support changes
- Step-by-step migration instructions
- Troubleshooting section

#### 6.2 Update README.md
- Update installation instructions
- Update platform requirements
- Add "What's New in v3.0" section
- Update example code if needed

---

## Critical Files to Modify

### Must Create (Priority Order)
1. ✅ `lib/src/platform/convex_platform_client.dart` - Core platform channel interface
2. ✅ `android/src/main/kotlin/.../ConvexFlutterPlugin.kt` - Android implementation
3. ✅ `ios/Classes/ConvexFlutterPlugin.swift` - iOS implementation
4. ✅ `lib/src/platform/auth_manager.dart` - Auth refresh logic
5. ✅ `example/integration_test/convex_integration_test.dart` - Integration tests

### Must Modify
6. ✅ `lib/src/convex_client.dart` - Use platform client instead of Rust
7. ✅ `lib/convex_flutter.dart` - Update exports
8. ✅ `pubspec.yaml` - Remove Rust dependencies, bump version
9. ✅ `android/build.gradle` - Add official SDK dependencies
10. ✅ `ios/convex_flutter.podspec` - Add Swift Package dependency

### Must Delete
11. ✅ `rust/` directory (entire Rust crate)
12. ✅ `cargokit/` directory
13. ✅ `lib/src/rust/` directory

---

## Data Flow Examples

### Query Operation
```
1. Dart: client.query("messages:list", {})
2. Platform: MethodChannel.invokeMethod('query', {name: "messages:list", args: {}})
3. Kotlin/Swift: convexClient.query("messages:list", parseArgs({}))
4. Kotlin/Swift: Return JSON string or throw exception
5. Dart: Receive result or throw ClientError
```

### Subscription Operation
```
1. Dart: client.subscribe(name: "messages:list", onUpdate: callback)
2. Dart: Generate subscriptionId = 1
3. Platform: MethodChannel.invokeMethod('subscribe', {subscriptionId: 1, name: "messages:list"})
4. Kotlin/Swift: Create EventChannel("convex_flutter/subscription/1")
5. Kotlin/Swift: Start Flow/Publisher collection
6. Kotlin/Swift: On each update → eventSink.success({type: "update", data: "..."})
7. Dart: EventChannel receives event → call onUpdate callback
8. Dart: sub.cancel() → MethodChannel.invokeMethod('cancelSubscription', {subscriptionId: 1})
9. Kotlin/Swift: Cancel Job/AnyCancellable, clean up EventChannel
```

### Authentication with Auto-Refresh
```
1. Dart: client.setAuthWithRefresh(fetchToken: () => getJWT())
2. Dart (AuthManager): Start refresh loop in Dart
3. Dart: token = await fetchToken()
4. Dart: Parse JWT expiry
5. Dart: client.setAuth(token: token)
6. Platform: MethodChannel.invokeMethod('setAuth', {token: "..."})
7. Kotlin/Swift: convexClient.setAuth(token)
8. Dart: Schedule Timer for (expiry - 60s)
9. Dart: Timer fires → repeat from step 3
```

---

## Risk Assessment & Mitigation

### High-Risk Areas

**Risk 1: Subscription Lifecycle Management**
- **Issue**: Multiple concurrent subscriptions with dynamic EventChannels
- **Mitigation**:
  - Test with 10+ concurrent subscriptions
  - Use Dart DevTools for memory leak detection
  - Ensure proper cleanup on cancellation
  - Handle rapid subscribe/cancel cycles

**Risk 2: Platform SDK Version Compatibility**
- **Issue**: Official SDKs might update with breaking changes
- **Mitigation**:
  - Pin exact versions (0.4.1 for Android)
  - Monitor Convex release notes
  - Add CI tests to catch SDK updates

**Risk 3: Serialization Edge Cases**
- **Issue**: JSON encoding/decoding of complex types (undefined vs null, large payloads)
- **Mitigation**:
  - Test with various data types (nested objects, arrays, null, special chars)
  - Keep same serialization format as Rust version
  - Document limitations for large payloads

**Risk 4: App Lifecycle Handling**
- **Issue**: Subscriptions when app is backgrounded/foregrounded
- **Mitigation**:
  - Use Application-scoped ConvexClient singleton
  - Test iOS backgrounding scenarios
  - Test Android Activity lifecycle

**Risk 5: Auth Token Refresh Edge Cases**
- **Issue**: Token expires before refresh, fetch failures, multiple refresh loops
- **Mitigation**:
  - Min refresh interval (5s) prevents tight loops
  - Catch fetch errors, clear auth, notify callback
  - Cancel previous timer before starting new

### Testing Risk Mitigation

Quality gates before v3.0.0 release:
- [ ] All integration tests pass on real Convex backend
- [ ] No memory leaks (run DevTools for 1 hour with active subscriptions)
- [ ] Example app runs on 2 physical devices (Android + iOS)
- [ ] Performance: <10% regression vs v2.x
- [ ] All public APIs documented
- [ ] Beta testing with 5+ external users
- [ ] Security review (no token leaks in logs)

---

## Timeline Estimate

**Total: 3-4 weeks** (can be reduced to ~3 weeks with 2 developers working in parallel)

| Phase | Duration | Can Parallelize |
|-------|----------|-----------------|
| 1. Android Implementation | 3-4 days | ✅ Yes (with Phase 2) |
| 2. iOS Implementation | 3-4 days | ✅ Yes (with Phase 1) |
| 3. Dart Client Updates | 2-3 days | After 1&2 |
| 4. Cleanup & Dependencies | 1-2 days | After 3 |
| 5. Testing | 2-3 days | After 4 |
| 6. Documentation | 1-2 days | ✅ Can start during 5 |
| Buffer for issues | 3-5 days | - |

**Parallel Work Strategy**:
- One developer implements Android (Phase 1)
- Another developer implements iOS (Phase 2)
- Both help with Dart updates (Phase 3)
- Shared testing responsibilities (Phase 5)

---

## Breaking Changes

### For App Developers
**Good News**: ✅ **Public Dart API remains unchanged!** Existing code should work without modifications.

**Platform Support**:
- ❌ Removed: Linux, macOS, Windows (desktop platforms)
- ✅ Still supported: Android, iOS

**Requirements**:
- iOS: Minimum version 11.0+ → **13.0+**
- Android: API 21+ (unchanged)

### For Plugin Contributors
- Rust toolchain no longer required
- Build system simplified (no cargokit)
- Native platform development (Kotlin/Swift) instead of Rust
- Official SDK knowledge helpful

---

## Post-Migration Enhancements (Future)

### v3.1.0 - Typed Arguments
- Replace `Map<String, String>` (JSON-encoded) with `Map<String, dynamic>`
- Use MethodChannel's StandardMessageCodec for nested JSON
- Breaking change for plugin users

### v3.2.0 - Structured Errors
- Add structured error data fields
- Better error type hierarchy in Dart

### v4.0.0 - Web Support
- Implement WebSocket-based client for web platform
- Use conditional imports for platform-specific clients
- Web would be pure Dart (no Rust)

---

## Verification Strategy

After implementation, verify:

1. **Feature Parity**: All current features work identically
   - Query, mutation, action operations
   - Real-time subscriptions with updates
   - Authentication with auto-refresh
   - Error handling (3 error types)

2. **Performance**: No significant regressions
   - Query latency within 10% of v2.x
   - Memory usage comparable or better
   - Subscription throughput unchanged

3. **Reliability**: Edge cases handled
   - Rapid subscription create/cancel
   - App lifecycle events
   - Token refresh edge cases
   - Large payload handling

4. **Compatibility**: Example app works unchanged
   - No Dart code changes required
   - Same deployment URL works
   - Auth flow identical

---

## Next Steps After Plan Approval

1. Create feature branch: `feature/platform-channels-migration`
2. Start with Android implementation (can work in parallel with iOS)
3. Regular commits and testing after each phase
4. Integration test against real Convex backend continuously
5. Code review before merging to main
6. Beta release (v3.0.0-beta.1) for community testing
7. Address feedback and issues
8. Stable release (v3.0.0)
