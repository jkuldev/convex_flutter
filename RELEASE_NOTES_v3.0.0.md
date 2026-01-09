# Release Notes - convex_flutter v3.0.0

**Release Date**: 2026-01-10

**Release Type**: Major Feature Release (No Breaking Changes)

---

## 🎉 Highlights

### Web Platform Support is Here! 🌐

convex_flutter now works on **all Flutter platforms** including web! Build your Convex-powered Flutter apps for:

- ✅ **Web** (NEW!) - Pure Dart, no Rust required
- ✅ **Android** - Now with proper INTERNET permission
- ✅ **iOS** - Works flawlessly
- ✅ **macOS** - Fixed network permissions
- ✅ **Windows** - Ready to go
- ✅ **Linux** - Ready to go

**Same code, all platforms. One API, zero compromises.**

---

## 🌐 Web Platform Support

### Pure Dart Implementation

The web platform uses a complete pure Dart implementation of the Convex WebSocket protocol:

- **No Rust required** for web builds
- **100% API compatibility** with native platforms
- **Full feature parity**: queries, mutations, actions, subscriptions, auth
- **Automatic platform selection** via conditional imports

### Build for Web

```bash
# No Rust installation needed!
flutter build web
```

Your existing code works on web without changes:

```dart
// This exact code works on web, mobile, and desktop!
final client = ConvexClient.instance;
final messages = await client.query('messages:list', {});
```

### Technical Implementation

- **Protocol**: Complete Convex WebSocket wire protocol in Dart
- **WebSocket**: Browser native WebSocket API via `package:web`
- **UUID**: RFC 4122 compliant UUID v4 generation
- **Real-time**: Full subscription support with automatic cleanup
- **Connection**: State monitoring and automatic reconnection
- **Auth**: Token management with refresh support

**File**: `lib/src/impl/convex_client_web.dart` (~800 lines)

**See**: [ARCHITECTURE.md](ARCHITECTURE.md#web-platform-implementation-new-in-v300) for technical details

---

## 🐛 Critical Bug Fixes

### 1. macOS Network Permissions

**Issue**: macOS apps stuck in "connecting" state forever

**Root Cause**: Missing `com.apple.security.network.client` entitlement in App Sandbox configuration

**Fix**: Added network permissions to both DebugProfile.entitlements and Release.entitlements

**Impact**: macOS apps now connect successfully to Convex backend

**Files Changed**:
- `example/macos/Runner/DebugProfile.entitlements`
- `example/macos/Runner/Release.entitlements`

**User Action Required**: Add entitlements to your macOS app (see [PLATFORM_CONFIGURATION.md](PLATFORM_CONFIGURATION.md#macos))

### 2. Android INTERNET Permission

**Issue**: Android apps lacked network access

**Root Cause**: Missing `<uses-permission android:name="android.permission.INTERNET" />` in AndroidManifest.xml

**Fix**: Added INTERNET permission to example app

**Impact**: Android apps can now make network requests

**File Changed**:
- `example/android/app/src/main/AndroidManifest.xml`

**User Action Required**: Add permission to your Android app (see [PLATFORM_CONFIGURATION.md](PLATFORM_CONFIGURATION.md#android))

### 3. Rust rustls CryptoProvider Error

**Issue**: Native builds panicked with "Could not automatically determine CryptoProvider"

**Root Cause**: Convex dependency had `default-features = false`, disabling rustls crypto provider

**Fix**: Removed `default-features = false` from `rust/Cargo.toml`

**Impact**: Native platforms build without rustls panics

**File Changed**:
- `rust/Cargo.toml`

**User Action Required**: None (package-level fix)

---

## 📦 Package Updates

### Rust SDK Upgrade

**Previous**: Convex Rust SDK 0.9.0
**Current**: Convex Rust SDK 0.10.2

**Benefits**:
- Better protocol compatibility
- Latest Convex backend features
- Improved stability

### Dependencies Added (Web Only)

```yaml
dependencies:
  web: ^1.0.0    # Browser WebSocket API
  http: ^1.2.0   # HTTP client
```

---

## 📚 Documentation Improvements

### New Documentation

1. **PLATFORM_CONFIGURATION.md**
   - Comprehensive platform setup guide
   - Platform-by-platform configuration instructions
   - Troubleshooting for common issues
   - Integration checklist

2. **MIGRATION_v3.md**
   - Complete migration guide from v2.x
   - Step-by-step upgrade instructions
   - Troubleshooting tips
   - Zero code changes required!

3. **CONTRIBUTING.md**
   - Contributor guidelines
   - Development setup instructions
   - Code style guides
   - PR submission process

4. **NATIVE_PLATFORM_FIX.md**
   - Detailed documentation of native platform fixes
   - Root cause analysis
   - Before/after test results

5. **WEB_SUCCESS.md**
   - Web implementation verification
   - Protocol message examples
   - Test results

### Updated Documentation

1. **README.md**
   - Added web platform to supported platforms
   - New "Platform Configuration" section
   - Updated requirements (Rust not needed for web)
   - Enhanced troubleshooting with Rust installation links
   - Better build issue guidance

2. **ARCHITECTURE.md**
   - Complete web platform architecture section
   - Multi-platform implementation strategy
   - Web vs native comparison
   - Updated FAQs for web support

3. **CHANGELOG.md**
   - Comprehensive v3.0.0 release notes
   - Platform support matrix
   - Breaking changes (none!)
   - Migration guide reference

---

## ✨ What Hasn't Changed

### Zero Breaking Changes

**Your v2.x code will work without modifications!**

- ✅ Same API across all platforms
- ✅ Same initialization process
- ✅ Same query/mutation/subscription methods
- ✅ Same connection state monitoring
- ✅ Same authentication flow

### Backward Compatibility

All v2.x features remain:

- Singleton pattern (`ConvexClient.instance`)
- Operation timeouts
- Connection state monitoring
- Lifecycle monitoring
- Real-time subscriptions
- Authentication with token refresh

---

## 📊 Platform Support Matrix

| Platform | Status | Implementation | Network Config | Rust Required |
|----------|--------|----------------|----------------|---------------|
| **Web** | ✅ **NEW** | Pure Dart | None | ❌ No |
| **iOS** | ✅ Working | FFI + Rust | None | ✅ Build-time |
| **macOS** | ✅ **Fixed** | FFI + Rust | Entitlements | ✅ Build-time |
| **Android** | ✅ **Fixed** | FFI + Rust | INTERNET permission | ✅ Build-time |
| **Windows** | ✅ Working | FFI + Rust | None | ✅ Build-time |
| **Linux** | ✅ Working | FFI + Rust | None | ✅ Build-time |

---

## 🚀 Getting Started with v3.0.0

### Upgrade from v2.x

```bash
# Update pubspec.yaml
dependencies:
  convex_flutter: ^3.0.0

# Upgrade
flutter pub upgrade convex_flutter

# Configure platforms (one-time)
# See PLATFORM_CONFIGURATION.md

# Test on your platforms
flutter run -d chrome   # Web
flutter run -d macos     # macOS
flutter run -d android   # Android
```

### New to convex_flutter?

```bash
# Install
flutter pub add convex_flutter

# Configure platforms (if using macOS or Android)
# See PLATFORM_CONFIGURATION.md

# Initialize in your app
await ConvexClient.initialize(
  ConvexConfig(
    deploymentUrl: 'https://your-app.convex.cloud',
  ),
);

# Use anywhere
final client = ConvexClient.instance;
final data = await client.query('myQuery', {});
```

---

## 🎯 Migration Difficulty

**Difficulty**: ⭐ Very Easy
**Time Required**: 5-10 minutes (platform configuration)
**Code Changes**: None
**Risk Level**: 🟢 Low

See [MIGRATION_v3.md](MIGRATION_v3.md) for complete guide.

---

## 🧪 Testing Recommendations

Before deploying v3.0.0, test:

- [ ] Connection establishment on your target platform
- [ ] Query execution
- [ ] Mutation execution
- [ ] Subscriptions (if you use them)
- [ ] Authentication (if you use it)
- [ ] Web platform (if targeting web)

See example app for comprehensive test scenarios:

```bash
cd example
flutter run -d chrome      # Test web
flutter run -d macos        # Test macOS
flutter run -d android      # Test Android
```

---

## 📈 Performance

### Build Times

**Web** (no Rust compilation):
- First build: ~1-2 minutes
- Subsequent: ~30-60 seconds

**Native** (unchanged):
- First build: ~3-5 minutes
- Subsequent: ~1-2 minutes (cached)

### Runtime Performance

- **Web**: Excellent (browser native WebSocket)
- **Native**: Excellent (compiled Rust code)

**No performance degradation from v2.x**

---

## 🔗 Useful Links

- **Migration Guide**: [MIGRATION_v3.md](MIGRATION_v3.md)
- **Platform Setup**: [PLATFORM_CONFIGURATION.md](PLATFORM_CONFIGURATION.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Repository**: https://github.com/jkuldev/convex_flutter
- **Convex Docs**: https://docs.convex.dev

---

## 💬 Community & Support

### Issues or Questions?

- **GitHub Issues**: https://github.com/jkuldev/convex_flutter/issues
- **GitHub Discussions**: https://github.com/jkuldev/convex_flutter/discussions

### Reporting Bugs

When reporting bugs, include:
- Flutter version
- Dart version
- Platform (web, Android, iOS, macOS, etc.)
- convex_flutter version
- Error messages or stack traces
- Minimal reproduction steps

---

## 🙏 Acknowledgments

Special thanks to:
- The Convex team for building an amazing backend platform
- The Flutter community for testing and feedback
- All contributors to this release

---

## 🔮 What's Next

### Future Roadmap

- Enhanced error messages
- Performance optimizations
- Additional platform-specific features
- Improved debugging tools

### Stay Updated

Watch the repository for updates and new releases!

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details

---

## 🎊 Celebrate!

**convex_flutter is now truly multi-platform!** Build amazing real-time apps for web, mobile, and desktop with the same simple API.

```dart
// One codebase, all platforms 🌐📱💻
final client = ConvexClient.instance;
final data = await client.query('myQuery', {});
// Works on web, iOS, Android, macOS, Windows, Linux!
```

---

**Release Version**: 3.0.0
**Release Date**: 2026-01-10
**Breaking Changes**: None
**Upgrade Recommended**: ✅ Yes

**Happy coding! 🚀**
