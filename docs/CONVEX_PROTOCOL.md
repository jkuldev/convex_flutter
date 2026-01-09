# Convex WebSocket Wire Protocol Documentation

**Status**: Initial documentation based on Rust SDK analysis (v0.9)
**Last Updated**: 2026-01-09
**Purpose**: Guide for implementing pure Dart WebSocket client

---

## Overview

The Convex platform uses WebSockets for real-time communication between clients and the Convex backend. This document describes the wire protocol based on analysis of the official Convex Rust SDK (v0.9).

---

## Connection

### WebSocket URL Format

**Deployment URL → WebSocket URL Conversion:**
```
HTTPS:  https://your-deployment.convex.cloud
        ↓
WSS:    wss://your-deployment.convex.cloud/ws
```

**Connection Process:**
1. Client opens WebSocket connection to `wss://{deployment-url}/ws`
2. Connection is bi-directional (client ↔ server)
3. JSON-based message protocol

---

## Message Format (Inferred)

### General Structure

All messages are JSON objects with at least a `type` field to indicate message purpose.

**Common Fields:**
- `type`: String indicating message type (`"query"`, `"mutation"`, `"action"`, `"subscribe"`)
- `id`: String/number for correlating requests with responses
- `name`: Function name in format `"moduleName:functionName"` (e.g., `"messages:list"`)
- `args`: Object containing function arguments as key-value pairs

---

## Operations

### 1. Query

**Purpose**: Retrieve data from Convex backend (read-only, cacheable)

**Client Request (Inferred):**
```json
{
  "type": "query",
  "id": "unique-request-id",
  "name": "messages:list",
  "args": {
    "limit": 10,
    "author": "user123"
  }
}
```

**Server Response (Expected):**
```json
{
  "type": "queryResult",
  "id": "unique-request-id",
  "result": {
    /* Query result data */
  }
}
```

**Error Response:**
```json
{
  "type": "error",
  "id": "unique-request-id",
  "error": {
    "message": "Error description",
    "data": { /* Optional error data */ }
  }
}
```

---

### 2. Mutation

**Purpose**: Modify data in Convex backend (write operation)

**Client Request (Inferred):**
```json
{
  "type": "mutation",
  "id": "unique-request-id",
  "name": "messages:send",
  "args": {
    "body": "Hello, world!",
    "author": "user123"
  }
}
```

**Server Response:**
```json
{
  "type": "mutationResult",
  "id": "unique-request-id",
  "result": {
    /* Mutation result (e.g., created document ID) */
  }
}
```

---

### 3. Action

**Purpose**: Execute server-side actions (e.g., external API calls, file operations)

**Client Request (Inferred):**
```json
{
  "type": "action",
  "id": "unique-request-id",
  "name": "files:upload",
  "args": {
    "fileName": "document.pdf",
    "url": "https://example.com/file"
  }
}
```

**Server Response:**
```json
{
  "type": "actionResult",
  "id": "unique-request-id",
  "result": {
    /* Action result */
  }
}
```

---

### 4. Subscription

**Purpose**: Subscribe to real-time updates when query results change

**Client Subscribe Request (Inferred):**
```json
{
  "type": "subscribe",
  "id": "subscription-id",
  "name": "messages:list",
  "args": {
    "limit": 10
  }
}
```

**Server Initial Response:**
```json
{
  "type": "subscriptionResult",
  "id": "subscription-id",
  "result": {
    /* Initial query result */
  }
}
```

**Server Update (When Data Changes):**
```json
{
  "type": "subscriptionUpdate",
  "id": "subscription-id",
  "result": {
    /* Updated query result */
  }
}
```

**Client Unsubscribe Request:**
```json
{
  "type": "unsubscribe",
  "id": "subscription-id"
}
```

---

## Data Types

### Argument Types

Based on Rust SDK, Convex supports these data types:

**Primitive Types:**
- `null`
- `boolean`
- `number` (Int64, Float64)
- `string`

**Complex Types:**
- `array`: JSON arrays
- `object`: JSON objects (maps)
- `bytes`: Binary data (Base64 encoded in JSON)

**Example Argument Conversion:**
```rust
// Rust SDK (from our codebase)
HashMap<String, String> → BTreeMap<String, Value>

// Dart (for web implementation)
Map<String, String> → Map<String, dynamic>
```

---

## Result Types

### FunctionResult Enum (from Rust SDK)

```rust
pub enum FunctionResult {
    Value(Value),              // Successful result
    ErrorMessage(String),      // Server error
    ConvexError(ConvexError),  // Application error with data
}
```

**JSON Representation (Inferred):**

**Success:**
```json
{
  "status": "success",
  "result": { /* actual data */ }
}
```

**ConvexError (Application Error):**
```json
{
  "status": "error",
  "errorType": "ConvexError",
  "data": { /* error details */ }
}
```

**ErrorMessage (Server Error):**
```json
{
  "status": "error",
  "errorType": "ServerError",
  "message": "Internal server error"
}
```

---

## Authentication

### Token-Based Authentication (Inferred)

**Method 1: WebSocket URL Query Parameter**
```
wss://deployment.convex.cloud/ws?token=JWT_TOKEN_HERE
```

**Method 2: Auth Message After Connection**
```json
{
  "type": "setAuth",
  "token": "JWT_TOKEN_HERE"
}
```

**Method 3: Clear Auth**
```json
{
  "type": "setAuth",
  "token": null
}
```

From Rust SDK:
```rust
async fn set_auth(&self, token: Option<String>)
```

---

## Error Handling

### Error Types (from Rust SDK)

```rust
pub enum ClientError {
    InternalError { msg: String },      // Client-side error
    ConvexError { data: String },       // Application error from backend
    ServerError { msg: String },        // Backend server error
}
```

**Dart Error Mapping:**
- `InternalError` → Connection issues, JSON parsing errors
- `ConvexError` → Business logic errors from Convex functions
- `ServerError` → Backend infrastructure errors

---

## Connection State Management

### WebSocket States (from Rust SDK)

The Rust SDK uses `WebSocketState` enum (not exposed in our current implementation, but important for web client):

**States:**
- `Connecting`: Initial connection attempt
- `Connected`: WebSocket connection established
- `Disconnected`: Connection lost or closed
- `Reconnecting`: Attempting to reconnect

**State Transitions:**
```
Connecting → Connected → Disconnected → Reconnecting → Connected
    ↓                                         ↓
    └─────────────── Error ─────────────────┘
```

---

## Implementation Notes for Web Client

### 1. WebSocket Setup

```dart
// Dart/Web implementation
import 'package:web/web.dart' as web;

final wsUrl = deploymentUrl.replaceFirst('https', 'wss');
final ws = web.WebSocket('$wsUrl/ws');
```

### 2. Message ID Generation

Need unique IDs for request-response correlation:

```dart
String _generateId() {
  return '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
}
```

### 3. Request-Response Matching

Maintain a map of pending requests:

```dart
final _pendingRequests = <String, Completer<String>>{};

// Send request
void sendQuery(String name, Map<String, dynamic> args) {
  final id = _generateId();
  final completer = Completer<String>();
  _pendingRequests[id] = completer;

  ws.send(jsonEncode({
    'type': 'query',
    'id': id,
    'name': name,
    'args': args,
  }));
}

// Handle response
void handleMessage(String data) {
  final message = jsonDecode(data);
  final id = message['id'];

  if (_pendingRequests.containsKey(id)) {
    _pendingRequests[id]!.complete(message['result']);
    _pendingRequests.remove(id);
  }
}
```

### 4. Subscription Management

Maintain active subscriptions:

```dart
final _subscriptions = <String, StreamController>{};

// Subscribe
String subscribe(String name, Map<String, dynamic> args) {
  final id = _generateId();
  final controller = StreamController.broadcast();
  _subscriptions[id] = controller;

  ws.send(jsonEncode({
    'type': 'subscribe',
    'id': id,
    'name': name,
    'args': args,
  }));

  return id; // Return subscription ID for cancellation
}

// Handle subscription update
void handleSubscriptionUpdate(Map<String, dynamic> message) {
  final id = message['id'];
  if (_subscriptions.containsKey(id)) {
    _subscriptions[id]!.add(message['result']);
  }
}
```

---

## Testing & Verification

### Approach for Protocol Refinement

Since this is inferred from SDK analysis, we'll use **test-driven refinement**:

1. **Implement based on inferred protocol**
2. **Test against real Convex backend**
3. **Capture actual WebSocket frames** using browser DevTools
4. **Refine protocol documentation** based on observed behavior
5. **Iterate until full parity** with official SDKs

### Browser DevTools Capture

To capture actual protocol:
```javascript
// In browser console
const ws = new WebSocket('wss://your-deployment.convex.cloud/ws');
ws.onmessage = (event) => {
  console.log('RECEIVED:', event.data);
};
ws.send(JSON.stringify({
  type: 'query',
  id: '1',
  name: 'messages:list',
  args: {}
}));
```

---

## Known Gaps & TODOs

- [ ] **Exact message format**: Need to verify field names and structure
- [ ] **Auth mechanism**: Confirm how JWT tokens are passed (URL vs message)
- [ ] **Heartbeat/Ping**: Does protocol use ping/pong for keep-alive?
- [ ] **Reconnection**: How does server handle reconnect with existing subscriptions?
- [ ] **Rate limiting**: Are there protocol-level rate limit messages?
- [ ] **Binary data**: How are bytes/files handled in WebSocket messages?

---

## References

- **Convex Rust SDK**: https://github.com/get-convex/convex-rs (v0.9)
- **Convex Docs**: https://docs.convex.dev
- **Rust SDK Docs**: https://docs.rs/convex/latest/convex/
- **Our Rust Implementation**: `/Users/mohansingh/Projects/internal/convex_flutter/rust/src/lib.rs`

---

**Next Steps:**
1. Implement basic WebConvexClient with inferred protocol
2. Test against real Convex deployment
3. Capture actual WebSocket traffic
4. Refine protocol documentation
5. Achieve full parity with native SDKs

---

**Status**: 🟡 Initial draft - needs validation against live backend
