# BIPOB PR-RF-20 — Generic cable/socket/power runtime contract

## Purpose

This document defines the generic runtime contract that should replace the old Mission 7 cable/socket/powered-gate implementation after the reusable mechanic has a safe TASK TEST / Map Constructor home.

PR-RF-20 is documentation-first. It does not implement new cable behavior, does not delete old Mission 7 resources, and does not remove `BipobLegacyCableFlowService`. The legacy Mission 7 flow remains the source of current behavior until a later PR introduces and proves a generic runtime service.

## PR-RF-22 initial data helper

PR-RF-22 adds `BipobCableRuntimeState` as a parser-safe, data-only helper for normalized cable/socket/power runtime state. The helper can store cable ids, socket/target ids, connection state, path cells, power metadata, and a read-only snapshot of current legacy Mission 7 controller fields.

This helper is not wired into gameplay yet. It must not change TASK TEST, Map Constructor, Mission 7 cable drawing/clearing, powered-gate behavior, movement, inventory, scan/hack, action execution, or power routing.

`BipobLegacyCableFlowService` remains the owner of current Mission 7 cable/socket/powered-gate behavior until a future generic runtime service is implemented and smoke-tested. Mission 7 deletion remains blocked while behavior still depends on that legacy service.

## Boundary: reusable mechanic vs. old Mission 7 story glue

### Reusable cable/socket/power mechanic

The reusable mechanic is a runtime world-object interaction where Bipob can take a cable end, drag a cable path through grid cells, connect that cable to a compatible socket, and apply a power event to a linked target such as a powered gate.

This mechanic should eventually work in:

- TASK TEST runtime sandbox sessions.
- Map Constructor-authored layouts.
- Future non-story missions.
- Any runtime layout that provides the required world-object records and action contracts.

### Legacy Mission 7 story glue

Old Mission 7 currently owns hardcoded positions, Mission 7-specific state fields, direct tile mutations, and the hardcoded cable id `cable_a`. Those details are legacy adapter data, not the reusable contract. They must not be treated as the future API.

Future deletion remains blocked until the generic service can reproduce the shared cable/socket/power behavior without depending on old Mission 7 layout resources or Mission 7 state names.

## Runtime object roles

### `cable_reel`

A static world object that stores or anchors a cable. It is the source object for `take_cable_end` and owns or references the active cable record.

Expected behavior:

- Offers an action when Bipob is adjacent or otherwise eligible to interact.
- Creates or exposes a carried cable endpoint when the player's hand/manipulator is free.
- Provides stable object identity for path, state, and UI/status reporting.

### `cable_endpoint` / `carried_cable_end`

The active cable end held by Bipob while dragging. This may be represented as a separate world object, a runtime-only hand state, or a field on the cable object, but the contract must expose enough state for movement tracking and release/connect actions.

Expected behavior:

- Tracks which `cable_id` is being dragged.
- Knows whether it is currently carried, released, or connected.
- Blocks other hand-occupied actions while carried.

### `cable_socket`

A target socket that can receive a compatible cable end. It is the main target for `connect_cable_to_socket`.

Expected behavior:

- Advertises compatibility by `socket_id`, `power_filter`, tags, or equivalent object fields.
- Records the connected cable id after a successful connect.
- Triggers or routes a power event to the linked powered target.

### `powered_gate` / `powered_target`

A world object whose runtime state changes after receiving a matching power event. Mission 7 uses a powered gate, but the generic role should allow other powered targets.

Expected behavior:

- References or can be found by `target_id` / `linked_target_id`.
- Receives `apply_power_event` or equivalent service output.
- Updates `state`, collision/passability, and visual state through generic runtime object/tile update paths rather than Mission 7 hardcoded tile edits.

### Optional `power_network` / `power_event`

A normalized power-routing layer may be added if direct cable-to-target linking becomes too narrow.

Expected behavior:

- Stores event identity through `power_event_id`.
- Matches events to targets through `power_filter` or tags.
- Allows future multi-socket, multi-target, or conditional power networks without changing the cable drag contract.

## Required object fields/properties

The generic implementation should operate on world-object records by id and position. Field names below are the expected contract vocabulary; a service may normalize aliases internally, but callers should not need old Mission 7 state names.

| Field/property | Applies to | Purpose |
| --- | --- | --- |
| `id` | All roles | Stable runtime object id. Replaces the hardcoded Mission 7-only `cable_a` assumption. |
| `type` / `family` | All roles | Identifies object role such as `cable_reel`, `cable_socket`, `powered_gate`, or broader families such as `power`. |
| `position` | Static objects and optionally path endpoints | Grid cell used for interaction, placement, path rendering, and connection checks. |
| `state` | All mutable roles | Runtime state such as `idle`, `carried`, `dragging`, `connected`, `powered`, `open`, or `inactive`. |
| `connected` | Cable, endpoint, socket | Boolean connection flag for quick checks and action gating. |
| `cable_id` | Cable endpoint, socket, path records | The cable being dragged, rendered, connected, released, or cleared. |
| `socket_id` | Cable, endpoint, socket | Socket identity or required socket target for matching. |
| `target_id` / `linked_target_id` | Socket, power event, powered target | Links a socket or power event to the powered object that should change state. |
| `power_event_id` | Socket, power event, powered target | Event identity emitted by connection and consumed by powered targets or a power network. |
| `power_filter` | Cable, socket, target, power event | Compatibility filter for cable/socket/target matching, such as voltage class, color, or access tier. |
| `max_length` | Cable or cable reel | Optional path-length limit. If omitted or disabled, the service may preserve current unrestricted behavior. |
| `path_cells` | Cable runtime state | Ordered grid cells occupied by the dragged cable path. |
| `visual_tile` / `visual_state` | Any visualized role | Optional visual mapping for object/tile rendering. This must not depend on Mission 7 hardcoded tile constants except through an adapter. |

## Required actions

| Action | Runtime meaning | Notes |
| --- | --- | --- |
| `take_cable_end` | Start carrying the end of a cable from a reel or endpoint. | Must fail safely if the hand/manipulator is occupied or no compatible cable is available. |
| `drag_cable` | Extend/update the active cable path as Bipob moves. | Usually service-driven from movement callbacks rather than direct player command text. |
| `connect_cable_to_socket` | Connect the carried cable end to a compatible socket. | Must validate cable/socket compatibility and update both object states. |
| `release_cable_end` | Stop carrying the cable without a successful connection. | Should clean up or preserve path according to service rules; current Mission 7 behavior should be preserved by its adapter until migration. |
| `clear_cable_path` | Remove path visuals and reset path runtime state. | Used on release, reset, layout reload, or failed drag cleanup. |
| `open_powered_target` / `apply_power_event` | Apply the socket/cable power result to a linked target. | Should update the powered target through generic state and visual/collision APIs. |

## Runtime service responsibilities

A future `BipobCableRuntimeService` should own generic behavior currently trapped behind the legacy Mission 7 service.

Required responsibilities:

1. Start cable drag from a `cable_reel` or available endpoint.
2. Track the cable path while Bipob moves and keep `path_cells` synchronized with runtime movement.
3. Validate `max_length` if and when length limits are enabled by object data.
4. Prevent taking a cable when Bipob's hand/manipulator is occupied.
5. Connect a carried cable to a matching `cable_socket` using `socket_id`, `power_filter`, or equivalent compatibility data.
6. Update world object state for cable, endpoint, socket, and powered target records.
7. Update a power network or directly apply a linked target power event.
8. Update visual path state without depending on Mission 7 hardcoded positions or tile mutations.
9. Clean up cable path state and visuals on release, layout reset, session reset, or failed interaction.
10. Expose concise status text for the UI/action panel, including drag state, connection success/failure, and powered target result.
11. Preserve parser safety by keeping action ids/data contracts explicit and avoiding broad dynamic method calls.

## Current legacy Mission 7 mapping

The table below names how the existing Mission 7 implementation should be translated into future generic runtime data. These are migration mappings only; new runtime layouts should use the generic fields directly.

| Current legacy Mission 7 field/constant | Future generic contract field/role |
| --- | --- |
| `mission7_cable_reel_position` | `cable_reel.position` |
| `mission7_socket_position` | `cable_socket.position` |
| `mission7_powered_gate_position` | `powered_target.position` and/or `linked_target_id` |
| `mission7_is_dragging_cable` | Runtime cable drag state, such as `state = "dragging"` on `cable_id` or carried endpoint state. |
| `mission7_cable_connected` | Cable object `connected` state, with matching socket state. |
| `mission7_cable_path` | Cable `path_cells`. |
| `mission7_cable_max_length` | Cable or cable reel `max_length`. |
| Hardcoded `cable_a` | Cable object `id`. |
| `GridManager.TILE_CABLE_REEL` | `cable_reel` visual/object type through `visual_tile` / catalog mapping. |
| `GridManager.TILE_SOCKET` | `cable_socket` visual/object type through `visual_tile` / catalog mapping. |
| `GridManager.TILE_POWERED_GATE` | `powered_target` visual/object type through `visual_tile` / catalog mapping. |

## Migration plan

### Stage A — PR-RF-20 contract only

- Keep `BipobLegacyCableFlowService` in place.
- Add this generic contract document.
- Update legacy mission readiness/dependency docs.
- Make no gameplay, TASK TEST, Map Constructor, parser, movement, inventory, scan/hack, cable, or power behavior changes.

### Stage B — Generic runtime service

- Add `BipobCableRuntimeService` as the non-story home for cable/socket/power behavior.
- Make the service operate on world objects by `id`, `position`, and explicit object fields instead of Mission 7 state names.
- Allow TASK TEST / Map Constructor layouts to place cable reels, sockets, and powered targets through catalog/world-object data.
- Keep legacy Mission 7 behavior unchanged while the new service is developed and smoke-tested separately.

### Stage C — Legacy adapter

- Make the old Mission 7 adapter generate generic object data from its existing hardcoded positions/state.
- Route legacy Mission 7 cable interactions through the generic service.
- Preserve old Mission 7 behavior, status text, and completion expectations during adapter migration.
- Keep Mission 7 resources until both old behavior and TASK TEST generic behavior are proven.

### Stage D — Legacy retirement

- Remove `BipobLegacyCableFlowService` only after old Mission 7 resources are retired and generic TASK TEST cable/socket/power smoke passes.
- Delete Mission 7-specific state, hardcoded positions, and `cable_a` only after no runtime path depends on them.
- Keep reusable cable/socket/power world-object support in TASK TEST and future missions.

## Acceptance smoke for future implementation

A future implementation PR should pass at least this smoke flow before Mission 7 deletion continues:

1. Place a cable reel in TASK TEST / Map Constructor.
2. Take the cable end.
3. Move while dragging the cable.
4. Confirm the path appears and updates.
5. Connect the cable to a compatible socket.
6. Confirm the powered gate/target opens or receives the configured power event.
7. Release the cable end where applicable.
8. Confirm the path clears on release/reset according to the contract.
9. Confirm action panel/status text updates for available actions and results.
10. Confirm no old Mission 7 state, positions, `current_mission_index` branch, or `cable_a` id is required.

## Non-goals for PR-RF-20

- Do not implement full generic cable runtime behavior.
- Do not delete Mission 7 resources.
- Do not remove `BipobLegacyCableFlowService`.
- Do not convert old Mission 7 layout data.
- Do not change TASK TEST or Map Constructor behavior.
- Do not change movement, inventory, scan/hack, cable, or power behavior.
