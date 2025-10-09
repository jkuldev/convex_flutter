# convex_flutter

A Flutter plugin for integrating with the Convex backend. It provides a simple Dart API over the Convex Rust core to run queries, mutations, and actions, and to subscribe to real-time updates.

This package wraps the [Convex Rust library](https://github.com/get-convex/convex-rs) and exposes a Flutter-friendly interface.

## Features

- Real-time subscriptions to Convex queries
- Simple Dart API for queries, mutations, and actions
- Authentication token support via `setAuth`
- Works on Android, iOS, macOS, Windows, and Linux (FFI)

## Installation

```
flutter pub add convex_flutter
```

## Requirements

- Dart SDK ≥ 3.8.1 and Flutter ≥ 3.3.0
- A working Rust toolchain (rustup + cargo) to build native code
- Platform toolchains:
  - Android: JDK 11 and Android SDK/NDK
  - iOS/macOS: Xcode and CocoaPods
  - Windows: Visual Studio Build Tools (C++)
  - Linux: clang, pkg-config, and build essentials

## Quick start

```dart
import 'package:convex_flutter/convex_flutter.dart';

Future<void> main() async {
  // Initialize the client once (singleton)
  final client = await ConvexClient.init(
    deploymentUrl: 'https://my-app.convex.cloud',
    clientId: 'flutter-app-1.0',
  );

  // Optional: authenticate
  await client.setAuth(token: 'YOUR_AUTH_TOKEN');

  // Query
  final users = await client.query('users:list', {'limit': '10'});
  print('Users: $users');

  // Subscribe to real-time updates
  final sub = await client.subscribe(
    name: 'messages:list',
    args: {},
    onUpdate: (value) => print('Update: $value'),
    onError: (message, value) => print('Error: $message ${value ?? ''}'),
  );

  // Mutation
  await client.mutation(
    name: 'messages:send',
    args: {'body': 'Hello!', 'author': 'User123'},
  );

  // Action (if you have actions defined)
  // final res = await client.action(name: 'files:upload', args: {...});

  // Later, when done
  sub.cancel();
}
```

## API overview

- `ConvexClient.init({ deploymentUrl, clientId })` → initializes a singleton client
- `query(String name, Map<String, String> args)` → runs a query
- `mutation({ required String name, required Map<String, dynamic> args })` → runs a mutation
- `action({ required String name, required Map<String, dynamic> args })` → runs an action
- `subscribe({ name, args, onUpdate, onError })` → returns a `SubscriptionHandle`
- `setAuth({ String? token })` → sets/clears the auth token

See the inline docs in `lib/src/convex_client.dart` for details.

## Example app

An example is provided under `example/`:

```
cd example
flutter run
```

## Troubleshooting

- Rust not found: install via `rustup` and ensure `cargo` is on your PATH
- Android build issues: use JDK 11, ensure NDK is installed via Android SDK Manager
- iOS/macOS: run `pod install` inside the `example/ios` or your app's `ios` folder if needed
- Windows: install Visual Studio Build Tools with C++ workload

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.