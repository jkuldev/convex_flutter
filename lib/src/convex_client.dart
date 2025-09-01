import 'package:convex_flutter/convex_flutter.dart';
import 'package:convex_flutter/src/lib/utils.dart';

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
/// client.cancelSubscription(subscription);
/// ```
/// A client class for interacting with Convex backend services
/// Implements singleton pattern to ensure only one instance exists
class ConvexClient {
  /// Private static instance for singleton pattern
  static ConvexClient? _instance;

  /// The underlying mobile client that handles communication with Convex
  late final MobileConvexClient _client;

  /// Public getter to access singleton instance
  /// Throws if accessed before initialization
  static ConvexClient get instance => _instance!;

  /// Initializes the ConvexClient singleton instance
  ///
  /// [deploymentUrl] - The URL of your Convex deployment
  /// [clientId] - A unique identifier for this client instance
  ///
  /// Returns the singleton instance after initialization
  /// Will reuse existing instance if already initialized
  static Future<ConvexClient> init({
    required String deploymentUrl,
    required String clientId,
  }) async {
    if (_instance == null) {
      // Initialize Rust FFI library
      await RustLib.init();

      // Create new mobile client instance
      final client = MobileConvexClient(
        deploymentUrl: deploymentUrl,
        clientId: clientId,
      );

      // Create singleton instance
      _instance = ConvexClient._internal(client);
    }
    return _instance!;
  }

  /// Private constructor to prevent direct instantiation
  /// Takes the mobile client instance
  ConvexClient._internal(this._client);

  /// Executes a Convex query operation
  ///
  /// [name] - Name of the query function to execute
  /// [args] - Map of arguments to pass to the query
  ///
  /// Returns the query result as a JSON string
  Future<String> query(String name, Map<String, String> args) async {
    final formattedArgs = buildArgs(args);
    return await _client.query(name: name, args: formattedArgs);
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

  /// Executes a Convex mutation operation
  ///
  /// [name] - Name of the mutation function to execute
  /// [args] - Map of arguments to pass to the mutation
  ///
  /// Returns the mutation result as a JSON string
  Future<String> mutation({
    required String name,
    required Map<String, dynamic> args,
  }) async {
    final formattedArgs = buildArgs(args);
    return await _client.mutation(name: name, args: formattedArgs);
  }

  /// Executes a Convex action operation
  ///
  /// [name] - Name of the action function to execute
  /// [args] - Map of arguments to pass to the action
  ///
  /// Returns the action result as a JSON string
  Future<String> action({
    required String name,
    required Map<String, dynamic> args,
  }) async {
    final formattedArgs = buildArgs(args);
    return await _client.action(name: name, args: formattedArgs);
  }

  /// Sets the authentication token for the client
  ///
  /// [token] - The authentication token to set, or null to clear
  ///
  /// Used to authenticate requests to the Convex backend
  Future<void> setAuth({required String? token}) async {
    return await _client.setAuth(token: token);
  }
}
