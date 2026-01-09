# Real Convex WebSocket Protocol

Based on official convex-js client source code analysis.

## Connection Flow

1. **Open WebSocket** → `wss://deployment.convex.cloud/api/sync`
2. **Send Connect** → Establish session
3. **Receive Transition** → Server ready
4. **Send Operations** → Queries via ModifyQuerySet, Mutations, Actions
5. **Handle Ping** → Respond to keepalive

## Message Types

### Client → Server

#### 1. Connect (Handshake)
```json
{
  "type": "Connect",
  "sessionId": "unique-session-id",
  "maxObservedTimestamp": null
}
```

#### 2. ModifyQuerySet (Subscriptions)
```json
{
  "type": "ModifyQuerySet",
  "modifications": [{
    "type": "Add",
    "queryId": 1,
    "udfPath": "messages:list",
    "args": [{}]
  }]
}
```

To unsubscribe:
```json
{
  "type": "ModifyQuerySet",
  "modifications": [{
    "type": "Remove",
    "queryId": 1
  }]
}
```

#### 3. Mutation
```json
{
  "type": "Mutation",
  "requestId": "req-123",
  "udfPath": "messages:send",
  "args": [{ "body": "Hello", "author": "User" }]
}
```

#### 4. Action
```json
{
  "type": "Action",
  "requestId": "req-124",
  "udfPath": "actions:processPayment",
  "args": [{ "amount": 100 }]
}
```

#### 5. Authenticate
```json
{
  "type": "Authenticate",
  "token": "jwt-token-here"
}
```

### Server → Client

#### 1. Transition (Query Updates)
```json
{
  "type": "Transition",
  "startVersion": { "ts": 123, "identity": "..." },
  "endVersion": { "ts": 124, "identity": "..." },
  "modifications": [{
    "queryId": 1,
    "value": [...],  // Query result
    "logLines": []
  }]
}
```

#### 2. MutationResponse
```json
{
  "type": "MutationResponse",
  "requestId": "req-123",
  "result": { "success": true },
  "ts": 125,
  "logLines": []
}
```

#### 3. ActionResponse
```json
{
  "type": "ActionResponse",
  "requestId": "req-124",
  "result": { "status": "processed" },
  "logLines": []
}
```

#### 4. Ping
```json
{
  "type": "Ping"
}
```

Client should respond with:
```json
{
  "type": "Event",
  "event": "Pong"
}
```

#### 5. FatalError
```json
{
  "type": "FatalError",
  "error": "error message"
}
```

## Key Differences from My Original Implementation

| Feature | My Implementation | Real Protocol |
|---------|------------------|---------------|
| Initial message | None | **Connect** required |
| Subscription | `type: "subscribe"` | **ModifyQuerySet** with Add |
| Unsubscribe | `type: "unsubscribe"` | **ModifyQuerySet** with Remove |
| Function name | `name` field | **udfPath** field |
| Arguments | `args: {}` object | **args: [{}]** array |
| Query execution | Direct `query` type | Via **ModifyQuerySet** subscription |
| Ping response | Ignored | Must respond with **Event/Pong** |

## Implementation Notes

- Session ID should be generated once and reused on reconnect
- Query IDs are integers, incrementing for each subscription
- Request IDs are strings, unique per mutation/action
- Args must be in array format: `[{arg1: val1, arg2: val2}]`
- Queries don't have a "one-shot" mode - must subscribe then unsubscribe
