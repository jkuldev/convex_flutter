import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:convex_flutter/convex_flutter.dart';
import 'package:convex_flutter/src/utils.dart';
import 'package:convex_flutter/src/connection_status.dart';
import 'package:convex_flutter/src/convex_config.dart';
import 'package:convex_flutter/src/app_lifecycle_event.dart';
import 'package:convex_flutter/src/app_lifecycle_observer.dart';

/// Callback type for fetching authentication tokens.
/// Should return a JWT token string, or null to sign out.
typedef TokenFetcher = Future<String?> Function();

/// Callback type for authentication state changes.
typedef AuthStateCallback = void Function(bool isAuthenticated);

/// A client for interacting with a Convex backend service.
///
/// The ConvexClient provides methods for executing queries, mutations, actions and
/// managing real-time subscriptions with a Convex backend.
///
/// Example usage:
///
/// ```dart
/// // Initialize the client
/// final client = await ConvexClient.init(
///   deploymentUrl: "https://my-app.convex.cloud",
///   clientId: "flutter-app-1.0"
/// );
///
/// // Execute a query
/// final result = await client.query(
///   "messages:list",
///   {"limit": "10"}
/// );
///
/// // Subscribe to real-time updates
/// final subscription = await client.subscribe(
///   name: "messages:list",
///   args: {},
///   onUpdate: (value) {
///     print("New messages: $value");
///   },
///   onError: (message, value) {
///     print("Error: $message");
///   }
/// );
///
/// // Execute a mutation
/// await client.mutation(
///   name: "messages:send",
///   args: {
///     "body": "Hello!",
///     "author": "User123"
///   }
/// );
///
/// // Cancel subscription when done
/// subscription.cancel();
/// ```
/// A client class for interacting with Convex backend services
/// Implements singleton pattern to ensure only one instance exists
class ConvexClient {
  /// Private static instance for singleton pattern
  static ConvexClient? _instance;

  /// The underlying mobile client that handles communication with Convex
  late final MobileConvexClient _client;

  /// Configuration for this client instance
  final ConvexConfig config;

  /// Stream controller for auth state changes
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  /// Stream controller for lifecycle events
  final StreamController<AppLifecycleEvent> _lifecycleController =
      StreamController<AppLifecycleEvent>.broadcast();

  /// Stream controller for WebSocket connection state changes
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();

  /// Current connection state (cached for sync access)
  WebSocketConnectionState _currentConnectionState =
      WebSocketConnectionState.connecting;

  /// Current auth handle (if using refresh-based auth)
  AuthHandle? _currentAuthHandle;

  /// Lifecycle observer for app state changes
  late final AppLifecycleObserver _lifecycleObserver;

  /// Public getter to access singleton instance
  /// Throws StateError if accessed before initialization
  static ConvexClient get instance {
    if (_instance == null) {
      throw StateError(
        'ConvexClient not initialized. '
        'Call ConvexClient.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Stream of authentication state changes.
  /// Emits `true` when authenticated, `false` when not.
  ///
  /// Example usage:
  /// ```dart
  /// ConvexClient.instance.authState.listen((isAuthenticated) {
  ///   setState(() => _isLoggedIn = isAuthenticated);
  /// });
  /// ```
  Stream<bool> get authState => _authStateController.stream;

  /// Stream of app lifecycle events.
  ///
  /// Emits events when the app transitions between foreground/background states.
  /// Useful for handling reconnection or other lifecycle-based logic.
  ///
  /// Example usage:
  /// ```dart
  /// ConvexClient.instance.lifecycleEvents.listen((event) {
  ///   if (event == AppLifecycleEvent.resumed) {
  ///     // App came to foreground
  ///     ConvexClient.instance.reconnect();
  ///   }
  /// });
  /// ```
  Stream<AppLifecycleEvent> get lifecycleEvents => _lifecycleController.stream;

  /// Stream of WebSocket connection state changes.
  ///
  /// Emits state whenever the underlying WebSocket connection changes
  /// between Connected and Connecting states. This provides real-time
  /// connection monitoring without manual polling.
  ///
  /// Example usage:
  /// ```dart
  /// ConvexClient.instance.connectionState.listen((state) {
  ///   if (state == WebSocketConnectionState.connected) {
  ///     print('Connected to Convex!');
  ///   }
  /// });
  /// ```
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Current WebSocket connection state (synchronous).
  /// Returns the most recent state from the WebSocket connection.
  WebSocketConnectionState get currentConnectionState => _currentConnectionState;

  /// Convenience getter - returns true if WebSocket is currently connected.
  bool get isConnected =>
      _currentConnectionState == WebSocketConnectionState.connected;

  /// Current authentication state (synchronous).
  /// Returns `true` if authenticated via [setAuthWithRefresh], `false` otherwise.
  bool get isAuthenticated => _currentAuthHandle?.isAuthenticated() ?? false;

  /// Initializes the ConvexClient singleton instance with configuration.
  ///
  /// This method must be called once before accessing [instance].
  /// Subsequent calls will throw a StateError.
  ///
  /// Example usage:
  /// ```dart
  /// await ConvexClient.initialize(
  ///   ConvexConfig(
  ///     deploymentUrl: "https://your-app.convex.cloud",
  ///     clientId: "flutter-app",
  ///     operationTimeout: Duration(seconds: 30),
  ///   ),
  /// );
  /// ```
  static Future<void> initialize(ConvexConfig config) async {
    if (_instance != null) {
      throw StateError('ConvexClient already initialized');
    }

    // Initialize Rust FFI library
    await RustLib.init();

    // Create new mobile client instance
    final client = MobileConvexClient(
      deploymentUrl: config.deploymentUrl,
      clientId: config.clientId ?? 'flutter-client',
    );

    // Create singleton instance
    _instance = ConvexClient._internal(client, config);

    // CRITICAL: Setup connection state listener BEFORE any operations can run
    // This ensures the state_change_sender is registered before connected_client()
    // can be called, preventing the race condition where state changes are missed
    await _instance!._setupConnectionStateListener();

    // Setup lifecycle observer (can be after state listener)
    _instance!._lifecycleObserver = AppLifecycleObserver(
      onLifecycleChange: (event) {
        _instance!._lifecycleController.add(event);
      },
    );
  }

  /// Initializes the ConvexClient singleton instance (DEPRECATED).
  ///
  /// This method is deprecated. Use [initialize] with [ConvexConfig] instead.
  ///
  /// Example migration:
  /// ```dart
  /// // Old way (deprecated)
  /// await ConvexClient.init(deploymentUrl: "...", clientId: "...");
  ///
  /// // New way
  /// await ConvexClient.initialize(
  ///   ConvexConfig(deploymentUrl: "...", clientId: "..."),
  /// );
  /// ```
  @Deprecated('Use initialize(ConvexConfig) instead')
  static Future<ConvexClient> init({
    required String deploymentUrl,
    required String clientId,
  }) async {
    if (_instance == null) {
      await initialize(
        ConvexConfig(
          deploymentUrl: deploymentUrl,
          clientId: clientId,
        ),
      );
    }
    return _instance!;
  }

  /// Private constructor to prevent direct instantiation
  ConvexClient._internal(this._client, this.config);

  /// Sets up the WebSocket connection state listener.
  /// This must be called before any queries/mutations to capture all state changes.
  Future<void> _setupConnectionStateListener() async {
    debugPrint('=== Setting up WebSocket connection state listener ===');
    debugPrint('=== Current state before setup: ${_currentConnectionState.name} ===');
    try {
      await _client.onWebsocketStateChange(
        onStateChange: (state) async {
          debugPrint('=== WebSocket state changed: ${state.name} ===');
          debugPrint('=== Updating internal state and emitting to stream ===');
          _currentConnectionState = state;
          _connectionStateController.add(state);
          debugPrint('=== Stream emission complete ===');
        },
      );
      debugPrint('=== Connection state listener registered successfully ===');
      debugPrint('=== Current state after setup: ${_currentConnectionState.name} ===');
    } catch (e) {
      // Log error and rethrow - this is critical for proper operation
      debugPrint('ERROR: Could not set up connection state listener: $e');
      rethrow;
    }
  }

  /// Executes a Convex query operation with timeout.
  ///
  /// [name] - Name of the query function to execute
  /// [args] - Map of arguments to pass to the query
  ///
  /// Returns the query result as a JSON string
  /// Throws [TimeoutException] if the operation exceeds [config.operationTimeout]
  Future<String> query(String name, Map<String, String> args) async {
    final formattedArgs = buildArgs(args);
    return await _client
        .query(name: name, args: formattedArgs)
        .timeout(config.operationTimeout);
  }

  /// Creates a real-time subscription to a Convex query
  ///
  /// [name] - Name of the query function to subscribe to
  /// [args] - Map of arguments for the subscription
  /// [onUpdate] - Callback function called when new data arrives
  /// [onError] - Callback function called when an error occurs
  ///
  /// Returns a handle that can be used to manage the subscription
  Future<SubscriptionHandle> subscribe({
    required String name,
    required Map<String, String> args,
    required void Function(String) onUpdate,
    required void Function(String, String?) onError,
  }) async {
    final formattedArgs = buildArgs(args);
    return await _client.subscribe(
      name: name,
      args: formattedArgs,
      onUpdate: (value) => onUpdate(value),
      onError: (message, value) => onError(message, value),
    );
  }

  /// Executes a Convex mutation operation with timeout.
  ///
  /// [name] - Name of the mutation function to execute
  /// [args] - Map of arguments to pass to the mutation
  ///
  /// Returns the mutation result as a JSON string
  /// Throws [TimeoutException] if the operation exceeds [config.operationTimeout]
  Future<String> mutation({
    required String name,
    required Map<String, dynamic> args,
  }) async {
    final formattedArgs = buildArgs(args);
    return await _client
        .mutation(name: name, args: formattedArgs)
        .timeout(config.operationTimeout);
  }

  /// Executes a Convex action operation with timeout.
  ///
  /// [name] - Name of the action function to execute
  /// [args] - Map of arguments to pass to the action
  ///
  /// Returns the action result as a JSON string
  /// Throws [TimeoutException] if the operation exceeds [config.operationTimeout]
  Future<String> action({
    required String name,
    required Map<String, dynamic> args,
  }) async {
    final formattedArgs = buildArgs(args);
    return await _client
        .action(name: name, args: formattedArgs)
        .timeout(config.operationTimeout);
  }

  /// Manually checks the connection status to the Convex backend.
  ///
  /// **DEPRECATED:** Use the [connectionState] stream for real-time state tracking.
  /// This method is slower and less accurate than the WebSocket state stream.
  ///
  /// This method uses the [ConvexConfig.healthCheckQuery] to verify connectivity.
  /// If no health check query is configured, throws a [StateError].
  ///
  /// Returns [ConnectionStatus.connected] if the connection is working,
  /// [ConnectionStatus.timeout] if the check times out, or
  /// [ConnectionStatus.error] if an error occurs.
  ///
  /// Example usage (deprecated):
  /// ```dart
  /// final status = await ConvexClient.instance.checkConnection();
  /// if (status == ConnectionStatus.connected) {
  ///   print('Connected!');
  /// }
  /// ```
  ///
  /// Recommended alternative - use the real-time connection state stream:
  /// ```dart
  /// ConvexClient.instance.connectionState.listen((state) {
  ///   if (state == WebSocketConnectionState.connected) {
  ///     print('Connected!');
  ///   }
  /// });
  /// ```
  @Deprecated('Use connectionState stream for real-time connection monitoring')
  Future<ConnectionStatus> checkConnection() async {
    if (config.healthCheckQuery == null) {
      throw StateError(
        'No health check query configured. '
        'Set healthCheckQuery in ConvexConfig or use a real query.',
      );
    }

    try {
      await _client
          .query(name: config.healthCheckQuery!, args: {})
          .timeout(config.operationTimeout);
      return ConnectionStatus.connected;
    } on TimeoutException {
      return ConnectionStatus.timeout;
    } catch (e) {
      return ConnectionStatus.error;
    }
  }

  /// Attempts to reconnect to the Convex backend.
  ///
  /// This method calls [checkConnection] and returns true if the
  /// connection check succeeds, false otherwise.
  ///
  /// Typically called after the app resumes from background or
  /// after detecting a network interruption.
  ///
  /// Example usage:
  /// ```dart
  /// ConvexClient.instance.lifecycleEvents.listen((event) {
  ///   if (event == AppLifecycleEvent.resumed) {
  ///     final connected = await ConvexClient.instance.reconnect();
  ///     if (connected) {
  ///       print('Reconnected successfully');
  ///     }
  ///   }
  /// });
  /// ```
  Future<bool> reconnect() async {
    try {
      final status = await checkConnection();
      return status == ConnectionStatus.connected;
    } catch (e) {
      // If healthCheckQuery not configured, just return false
      return false;
    }
  }

  /// Sets the authentication token for the client (simple/static).
  ///
  /// Use this for simple auth scenarios where you manage token refresh externally.
  /// For automatic token refresh, use [setAuthWithRefresh] instead.
  ///
  /// [token] - The authentication token to set, or null to clear auth.
  ///
  /// Example usage:
  /// ```dart
  /// // Set auth with a token
  /// await client.setAuth(token: 'eyJhbGciOiJSUzI1NiIs...');
  ///
  /// // Clear auth
  /// await client.setAuth(token: null);
  /// ```
  Future<void> setAuth({required String? token}) async {
    // Clear any existing refresh-based auth
    _currentAuthHandle?.dispose();
    _currentAuthHandle = null;

    await _client.setAuth(token: token);
    _authStateController.add(token != null);
  }

  /// Sets up authentication with automatic token refresh.
  ///
  /// This is the recommended way to handle authentication. The [fetchToken]
  /// callback will be called:
  /// - Immediately to get the initial token
  /// - Automatically when the token is about to expire (60 seconds before)
  ///
  /// Example usage:
  /// ```dart
  /// final authHandle = await client.setAuthWithRefresh(
  ///   fetchToken: () async {
  ///     // Get token from your auth provider (Clerk, Auth0, Firebase, etc.)
  ///     return await FirebaseAuth.instance.currentUser?.getIdToken();
  ///   },
  ///   onAuthChange: (isAuthenticated) {
  ///     print('Auth state changed: $isAuthenticated');
  ///   },
  /// );
  ///
  /// // Later, when signing out:
  /// authHandle.dispose();
  /// ```
  ///
  /// [fetchToken] - Async function that returns a JWT token, or null to sign out.
  /// [onAuthChange] - Optional callback invoked when auth state changes.
  ///
  /// Returns an [AuthHandleWrapper] that can be used to dispose the auth session.
  Future<AuthHandleWrapper> setAuthWithRefresh({
    required TokenFetcher fetchToken,
    AuthStateCallback? onAuthChange,
  }) async {
    // Dispose any existing auth handle
    _currentAuthHandle?.dispose();

    final handle = await _client.setAuthWithRefresh(
      fetchToken: () async => await fetchToken(),
      onAuthChange: (bool isAuth) async {
        onAuthChange?.call(isAuth);
        _authStateController.add(isAuth);
      },
    );

    _currentAuthHandle = handle;
    return AuthHandleWrapper._(handle);
  }

  /// Clears authentication and disposes any active auth refresh loop.
  ///
  /// This will:
  /// - Stop any running token refresh loop
  /// - Clear the auth token from the Convex client
  /// - Emit `false` on the [authState] stream
  Future<void> clearAuth() async {
    _currentAuthHandle?.dispose();
    _currentAuthHandle = null;
    await _client.setAuth(token: null);
    _authStateController.add(false);
  }

  /// Dispose the client and clean up resources.
  ///
  /// Call this when you're done using the client to free up resources.
  /// Note: This is typically not needed as the client is a singleton,
  /// but can be useful in testing scenarios.
  void dispose() {
    _currentAuthHandle?.dispose();
    _lifecycleObserver.dispose();
    _authStateController.close();
    _lifecycleController.close();
    _connectionStateController.close();
  }
}

/// Wrapper for auth handle providing Dart-friendly API.
///
/// Returned by [ConvexClient.setAuthWithRefresh] to control the auth session.
class AuthHandleWrapper {
  final AuthHandle _handle;

  AuthHandleWrapper._(this._handle);

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _handle.isAuthenticated();

  /// Dispose the auth session, stopping token refresh and clearing auth.
  ///
  /// Call this when signing out or when you no longer need automatic token refresh.
  void dispose() => _handle.dispose();
}
