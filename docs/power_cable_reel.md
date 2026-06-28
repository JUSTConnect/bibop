# Runtime Power Cable Reel

`power_cable_reel` is a portable physical runtime connection. It is separate from authored stationary `power_cable` topology and separate from logical `BindingStore` relations.

## Canonical physical state

```gdscript
{
    "end_1": {"state": "on_reel|held|connected", "target_id": ""},
    "end_2": {"state": "on_reel|held|connected", "target_id": ""},
    "path_cells": [],
    "connection_state": "disconnected|partial|complete|invalid|broken"
}
```

End numbers do not define direction. The resolver classifies a connected endpoint as a powered socket or compatible target from the endpoint object type/profile.

Flat `end_1_state`, `end_1_target_id`, `end_2_state`, `end_2_target_id`, and `cable_path_cells` fields remain derived compatibility aliases. Nested endpoints and `path_cells` are the runtime source of truth.

## Complete feed

A reel feed is complete only when:

- both ends are connected;
- exactly one endpoint is a `power_socket`;
- the other endpoint explicitly accepts `runtime_reel_feed`;
- the path is contiguous, non-repeating, within length, and not blocked;
- the reel is healthy;
- the socket has computed `power_state = powered` and a non-empty `resolved_source_id`.

The target inherits:

```gdscript
resolved_source_id = socket.resolved_source_id
resolved_circuit_id = "main"
```

The feed does not mutate `intent_state`, `operational_state`, or authored `preferred_source_id`.

## Power loss and restoration

When the socket becomes unpowered, the endpoint connection and path remain intact. The target becomes unpowered and records the socket reason. A scoped socket recalculation restores the target automatically when the socket becomes powered again.

Damage or a cut changes the reel to `broken` and removes power. Repair does not silently restore the feed; an explicit `reconnect` action is required.

## Actions

The runtime API supports:

- `hold_end`
- `release_end`
- `connect_end`
- `disconnect_end`
- `set_path`
- `damage`
- `repair`
- `reconnect`

`preview_power_cable_reel_action` never mutates world state. `apply_power_cable_reel_action` commits exactly one successful physical action through `WorldStateStore`. Feed resolution details are returned separately from action success.

## Scope and notifications

Recalculation is scoped to one reel or all reels connected to one socket. The service returns affected IDs and changes; it does not run a global power pass.

Autonomous power loss/restoration returns an empty `notification_event`. UI aggregation remains outside this service, so one player command can still produce at most one final notification.

## BindingStore exclusion

No `runtime_power_feed` binding is created. Reel endpoints, socket connection, and path are physical topology owned by the reel entity. `BindingStore` continues to hold logical relations only.
