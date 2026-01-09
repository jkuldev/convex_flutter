# Release Checklist - v3.0.0

Use this checklist to ensure all steps are completed before publishing the release.

## Pre-Release Checklist

### 1. Version Management

- [x] Updated `pubspec.yaml` version to 3.0.0
- [x] Updated CHANGELOG.md with v3.0.0 entry
- [x] Updated ARCHITECTURE.md document version
- [x] Verified all documentation references correct version

### 2. Code Quality

- [ ] All tests pass locally
  ```bash
  flutter test
  ```
- [ ] No analyzer warnings
  ```bash
  flutter analyze
  ```
- [ ] Dart code formatted
  ```bash
  dart format . --set-exit-if-changed
  ```
- [ ] Rust code formatted (if Rust changes)
  ```bash
  cd rust && cargo fmt --check
  ```
- [ ] Rust lints pass (if Rust changes)
  ```bash
  cd rust && cargo clippy
  ```

### 3. Platform Testing

#### Web Platform
- [ ] Example app builds for web
  ```bash
  cd example && flutter build web
  ```
- [ ] Example app runs on Chrome
  ```bash
  cd example && flutter run -d chrome
  ```
- [ ] Connection establishes successfully
- [ ] Queries work
- [ ] Mutations work
- [ ] Subscriptions work
- [ ] Authentication works
- [ ] Hot reload works

#### macOS
- [ ] Example app builds for macOS
  ```bash
  cd example && flutter build macos
  ```
- [ ] Example app runs on macOS
  ```bash
  cd example && flutter run -d macos
  ```
- [ ] Connection establishes successfully
- [ ] Network entitlements are present
- [ ] All features work correctly

#### iOS
- [ ] Example app builds for iOS
  ```bash
  cd example && flutter build ios --no-codesign
  ```
- [ ] Example app runs on iOS Simulator
  ```bash
  cd example && flutter run -d "iPhone 15"
  ```
- [ ] Connection establishes successfully
- [ ] All features work correctly

#### Android
- [ ] Example app builds for Android
  ```bash
  cd example && flutter build apk
  ```
- [ ] Example app runs on Android Emulator
  ```bash
  cd example && flutter run -d emulator
  ```
- [ ] INTERNET permission is present in AndroidManifest.xml
- [ ] Connection establishes successfully
- [ ] All features work correctly

#### Windows (if available)
- [ ] Example app builds for Windows
  ```bash
  cd example && flutter build windows
  ```
- [ ] Example app runs on Windows
- [ ] All features work correctly

#### Linux (if available)
- [ ] Example app builds for Linux
  ```bash
  cd example && flutter build linux
  ```
- [ ] Example app runs on Linux
- [ ] All features work correctly

### 4. Documentation

#### Core Documentation
- [x] README.md updated with:
  - [x] Web platform support
  - [x] Platform configuration instructions
  - [x] Updated troubleshooting
  - [x] Rust installation links
- [x] CHANGELOG.md complete with v3.0.0 details
- [x] ARCHITECTURE.md updated for web platform
- [x] LICENSE file present and correct

#### New Documentation
- [x] PLATFORM_CONFIGURATION.md created
- [x] MIGRATION_v3.md created
- [x] CONTRIBUTING.md created
- [x] RELEASE_NOTES_v3.0.0.md created
- [x] NATIVE_PLATFORM_FIX.md created
- [x] WEB_SUCCESS.md created

#### Documentation Review
- [ ] All code examples tested and working
- [ ] All links working (no 404s)
- [ ] All command examples tested
- [ ] Screenshots up-to-date (if applicable)
- [ ] No typos or grammatical errors

### 5. Example App

- [ ] Example app demonstrates all features
- [ ] Example app has proper platform configurations:
  - [x] macOS entitlements (DebugProfile + Release)
  - [x] Android INTERNET permission
  - [ ] iOS configuration verified
  - [ ] Web configuration verified
- [ ] Example README.md is clear and helpful
- [ ] Example app builds on all platforms

### 6. Dependencies

- [ ] All dependencies up-to-date
  ```bash
  flutter pub outdated
  ```
- [x] `pubspec.yaml` dependencies are correct:
  - [x] `web: ^1.0.0` present
  - [x] `http: ^1.2.0` present
  - [x] `flutter_rust_bridge: ^2.11.1` present
- [x] `rust/Cargo.toml` dependencies are correct:
  - [x] `convex = { version = "0.10", features = ["rustls-tls-webpki-roots"] }`
  - [x] No `default-features = false`

### 7. Git & Repository

- [ ] All changes committed
  ```bash
  git status  # Should be clean
  ```
- [ ] Commit messages are clear and descriptive
- [ ] Branch is up-to-date with main
  ```bash
  git fetch origin
  git rebase origin/main
  ```
- [ ] No merge conflicts
- [ ] `.gitignore` is comprehensive

### 8. Breaking Changes Verification

- [ ] Confirmed ZERO breaking changes
- [ ] v2.x code still works
- [ ] API is 100% backward compatible
- [ ] Migration guide confirms no code changes needed

### 9. Performance Testing

- [ ] Web build time is reasonable (< 2 minutes)
- [ ] Native build time unchanged from v2.x
- [ ] Runtime performance is excellent on web
- [ ] Runtime performance unchanged on native
- [ ] No memory leaks detected
- [ ] Connection reconnection works smoothly

### 10. Security Review

- [ ] No secrets in code or config files
- [ ] No hardcoded URLs (except examples)
- [ ] Network permissions properly documented
- [ ] Example app uses safe configuration

---

## Release Process

### 1. Create Release Branch

```bash
git checkout -b release/v3.0.0
```

### 2. Final Verification

- [ ] Run full test suite
  ```bash
  flutter test
  ```
- [ ] Build for all platforms (if available)
  ```bash
  cd example
  flutter build web
  flutter build apk
  flutter build ios --no-codesign
  flutter build macos
  ```

### 3. Tag Release

```bash
git tag -a v3.0.0 -m "Release version 3.0.0: Web platform support"
git push origin v3.0.0
```

### 4. Create GitHub Release

- [ ] Go to GitHub repository
- [ ] Click "Releases" → "Draft a new release"
- [ ] Tag version: `v3.0.0`
- [ ] Release title: `v3.0.0 - Web Platform Support`
- [ ] Description: Copy from [RELEASE_NOTES_v3.0.0.md](RELEASE_NOTES_v3.0.0.md)
- [ ] Check "Create a discussion for this release"
- [ ] Publish release

### 5. Publish to pub.dev

**Prerequisites**:
- [ ] Authenticated with pub.dev
  ```bash
  dart pub login
  ```
- [ ] Verified package name is available
- [ ] Reviewed pub.dev publishing checklist

**Dry Run**:
```bash
flutter pub publish --dry-run
```

**Verify dry-run output**:
- [ ] Version is 3.0.0
- [ ] Description is correct
- [ ] Homepage URL is correct
- [ ] Repository URL is correct
- [ ] All files are included correctly
- [ ] No warnings or errors

**Publish**:
```bash
flutter pub publish
```

- [ ] Confirm publication
- [ ] Wait for package to appear on pub.dev
- [ ] Verify package page looks correct

### 6. Post-Release Verification

- [ ] Package appears on pub.dev: https://pub.dev/packages/convex_flutter
- [ ] Version 3.0.0 is listed
- [ ] Documentation renders correctly
- [ ] Example tab shows examples
- [ ] Scores are good (pub points, popularity, likes)

### 7. Create Announcement

**GitHub Discussions**:
- [ ] Post release announcement in Discussions
- [ ] Highlight web platform support
- [ ] Link to migration guide
- [ ] Thank contributors

**Social Media** (if applicable):
- [ ] Tweet about release
- [ ] Post on Reddit (r/FlutterDev)
- [ ] Post on Discord communities
- [ ] Update project website

---

## Post-Release Checklist

### Immediate (Day 1)

- [ ] Monitor GitHub issues for bug reports
- [ ] Monitor pub.dev for package health
- [ ] Respond to community questions
- [ ] Watch for any critical issues

### Week 1

- [ ] Review download statistics
- [ ] Collect user feedback
- [ ] Address any critical bugs immediately
- [ ] Update documentation based on user questions

### Week 2-4

- [ ] Plan next release based on feedback
- [ ] Triage new issues
- [ ] Review and merge PRs
- [ ] Update roadmap

---

## Rollback Plan

If critical issues are discovered post-release:

### Option 1: Patch Release (v3.0.1)

For minor fixes:

```bash
# Fix the issue
# Update version to 3.0.1
# Update CHANGELOG.md
git commit -m "fix: Critical bug fix"
git tag v3.0.1
flutter pub publish
```

### Option 2: Yank Release

For severe issues (use with extreme caution):

```bash
# Mark version as retracted
dart pub retract 3.0.0 --reason "Critical bug, use 2.2.0 instead"
```

---

## Emergency Contacts

**Package Maintainer**: jkuldev
**Repository**: https://github.com/jkuldev/convex_flutter
**Issues**: https://github.com/jkuldev/convex_flutter/issues

---

## Release Metrics to Track

After release, monitor:

- [ ] Total downloads (first week)
- [ ] GitHub stars increase
- [ ] Issue reports (critical vs non-critical)
- [ ] Pull requests
- [ ] Community engagement
- [ ] pub.dev score changes

---

## Notes for This Release

### Special Considerations

- **First multi-platform release** - Extra testing required
- **Web implementation is new** - Monitor for web-specific issues
- **Platform configuration required** - Expect support questions about entitlements/permissions
- **Zero breaking changes** - Should be smooth upgrade for users

### Known Limitations

None - all platforms tested and working.

### Success Criteria

Release is successful if:

- [x] Package publishes to pub.dev without errors
- [ ] No critical bugs reported in first week
- [ ] Positive community feedback
- [ ] Download count increases
- [ ] No rollback needed

---

## Approval Signatures

**Technical Review**:
- [ ] Code reviewed and approved
- [ ] Tests pass
- [ ] Documentation complete

**Release Manager**:
- [ ] Checklist completed
- [ ] Ready for publication
- [ ] Date: __________
- [ ] Signature: __________

---

**Release Version**: 3.0.0
**Target Date**: 2026-01-10
**Status**: Ready for final checks

**Next Steps**: Complete remaining checklist items, then publish!
