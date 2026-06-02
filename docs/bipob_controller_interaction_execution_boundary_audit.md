# BipobController interaction execution boundary audit

Status: execution-boundary audit and extraction roadmap. PR-X6 item pickup execution helper extraction is complete.

This document audits the current interaction execution responsibilities in `scripts/bipob/bipob_controller.gd` after the completed read-only extractions:

- `scripts/game/bipob_targeting_service.gd` owns facing cell/object/item and action target context lookup.
- `scripts/game/bipob_action_view_model_service.gd` owns read-only runtime action descriptors and action view-model construction.
- `scripts/game/bipob_capability_service.gd` owns read-only module/capability checks.

`BipobController` still remains the runtime coordinator/executor. This is expected for now. The goal of the next implementation PRs should be to extract execution boundaries without changing behavior.

## 1. Current architecture snapshot

### `BipobController`

Current responsibilities still mixed inside the controller:

- input-facing runtime commands such as `interact`, `scan_device`, `hack_device`, old mission-specific interactions and door helpers;
- action execution orchestration for world objects, items, terminals, doors, power objects, cables, fuses, circuit switches, platforms and heavy objects;
- resource spending and paid-action bookkeeping;
- direct mutation of `grid_manager`, `mission_manager`, local flags and runtime inventory buffers;
- direct UI feedback via `hint_requested.emit`, `status_changed.emit`, `refresh_world_action_panel`, `refresh_world_object_overlay`, `update_threat_detection_preview`;
- action preflight and execution routing through `InteractionSystemRef` and `MissionManager`;
- post-action power network apply/recalculation calls for explicit power events.

### `BipobTargetingService`

Already extracted and should remain read-only:

- facing cell calculation;
- facing object lookup;
- facing item lookup;
- action target context snapshot.

It must not execute or mutate actions.

### `BipobActionViewModelService`

Already extracted and should remain read-only:

- available action id ordering;
- descriptors, labels and disabled reasons;
- primary action selection;
- UI-facing target/action dictionary shape.

It still calls controller façade methods for actor/capability data. That is acceptable while execution remains in the controller.

### `BipobCapabilityService`

Already extracted and should remain read-only:

- module id/version checks;
- connector/manipulator/heavy claw availability;
- physical hand availability.

It must not install/remove modules or mutate inventory.

### `InteractionSystem`

Currently used as the rule gate and effect producer for many world-object actions:

- `can_apply_action(...)` is used by the action view-model gate;
- `apply_action(...)` returns an action result/effects payload;
- `normalize_action_result(...)` normalizes execution results.

`InteractionSystem` should remain a rule/effect service. The next execution wrapper should not rewrite these rules.

### `MissionManager`

Currently owns many concrete world/inventory mutations used by action execution:

- item pickup and runtime inventory state;
- world object lookup/update;
- terminal door control execution;
- heavy claw object movement;
- power-network event filtering and world-state updates;
- key cleanup after key-card unlock;
- platform/power/link helper APIs.

A controller execution service may call these existing APIs, but it must not change their semantics.

## 2. Execution responsibilities that should remain outside read-only services

These operations are side-effectful and should not be moved into targeting, capability or view-model helpers:

- `spend_action`, energy spending and paid-action bookkeeping;
- `hint_requested.emit`, `status_changed.emit` and UI refresh side effects;
- `grid_manager.set_tile` and visual/world position mutation;
- `mission_manager.set_world_object_at_cell`, `update_world_object_by_id`, item pickup, key cleanup and power-network apply;
- `buffer_item` mutation and digital/physical item storage changes;
- `InteractionSystemRef.apply_action` execution;
- terminal-control execution through `mission_manager.execute_terminal_control_action`;
- heavy-claw movement through `mission_manager.move_world_object_by_heavy_claw`;
- mission-specific interactions and legacy tile interactions.

## 3. Current execution hotspots in `BipobController`

### Legacy physical and digital helpers

Functions such as `open_door`, `open_digital_door`, `scan_device`, `hack_device`, and `open_route_gate` still perform direct checks, resource spending, grid mutations, mission flag mutations and user feedback.

These should not be mixed into a generic world-action execution PR until the normal action path has been isolated. They include mission-specific behavior and legacy mission/tutorial rules.

### `interact()`

`interact()` is the largest execution hotspot. It currently does all of the following:

- sets active Bipob reference in `MissionManager`;
- resolves facing tile/cell;
- handles legacy tile-specific interactions and mission-specific controls;
- attempts item pickup from current/facing cells;
- builds an actor dictionary for world-object execution;
- resolves selected/current world action;
- performs terminal/platform/power preflight checks;
- executes terminal door controls;
- executes generic world-object actions through `InteractionSystemRef.apply_action`;
- handles heavy-claw push/pull movement;
- consumes held items for fuse/repair actions;
- applies world-object effects and writes updated world objects back into `MissionManager`;
- triggers key-card cleanup after unlock;
- applies power-network updates after switch/fuse actions;
- refreshes overlay/HUD/action panel and emits hints/status.

This function should be split carefully, with wrappers preserving existing behavior.

### Item pickup branch

The item pickup branch inside `interact()` handles both current-cell and facing-cell pickup. It performs:

- storage class checks;
- `InteractionSystemRef.apply_action(..., "pickup")`;
- `mission_manager.pickup_world_item`;
- `buffer_item` mutation for digital items;
- `digital_world_records` mutation;
- UI feedback and refresh.

This should become a distinct execution path later, not part of a generic object-action service in the first PR.

### Terminal control branch

The terminal door-control branch is already a specialized execution path:

- action ids: `open_door`, `close_door`, `unlock_door`;
- calls `mission_manager.execute_terminal_control_action`;
- spends action only on successful terminal result;
- emits fixed feedback and refreshes runtime UI.

This is a good candidate for an early narrow extraction because it is relatively self-contained, but the existing success/spend semantics must remain identical.

### Generic world-object action branch

The generic branch performs:

- `InteractionSystemRef.apply_action`;
- paid-action checking;
- heavy-claw special handling;
- fuse/repair held-item consumption;
- `_apply_world_object_effects`;
- world object write-back;
- key cleanup;
- power-network apply for switch/fuse events;
- refresh/hint/status.

This should be extracted only after a thin execution result contract is documented.

### Heavy Claw branch

Heavy Claw has a special movement path:

- action ids: `push`, `pull`;
- target destination via `get_heavy_claw_move_destination`;
- movement via `mission_manager.move_world_object_by_heavy_claw`;
- action spending only on successful move;
- overlay/threat/action-panel refresh.

Do not merge this path with generic `InteractionSystemRef.apply_action` effects without a manual smoke pass.

### Power side effects

Power-related actions are currently coupled to explicit post-action recalculation:

- switch/circuit breaker/light switch routes to `apply_power_network_after_explicit_power_event`;
- fuse insertion routes to the same apply flow;
- power filter is resolved through `mission_manager._get_power_event_filter_for_object` when available.

These should remain in the executor boundary and must not be hidden inside read-only services.

## 4. Proposed execution service boundary

Recommended target for a future implementation PR:

`/scripts/game/bipob_interaction_execution_service.gd`

Suggested class:

```gdscript
extends RefCounted
class_name BipobInteractionExecutionService
```

Suggested narrow API:

```gdscript
static func execute_world_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary
static func execute_terminal_control_action(controller: Variant, terminal: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary
static func execute_heavy_claw_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary
static func execute_item_pickup(controller: Variant, item: Dictionary, item_cell: Vector2i) -> Dictionary
```

The service should return a result dictionary and let the controller façade keep top-level UI signal emission until a later PR.

Initial result shape:

```gdscript
{
  "success": bool,
  "message": String,
  "spent_action": bool,
  "paid_action": bool,
  "refresh_overlay": bool,
  "refresh_action_panel": bool,
  "refresh_threats": bool,
  "clear_selected_action": bool,
  "world_object": Dictionary,
  "target_position": Vector2i,
  "power_apply_report": Dictionary,
  "reason": String
}
```

The first implementation should preserve existing hints and refresh order by keeping the controller as the façade that interprets this result.

## 5. Safe extraction order

### PR-X1: Document execution result contract

Docs-only or very small code comments.

- Define the action execution result shape.
- List which side effects remain in controller.
- No code movement.

### PR-X2: Extract actor builder — completed

Extracted `_build_runtime_action_actor(...)` dictionary construction to the read-only `scripts/game/bipob_runtime_action_actor_service.gd` service.

- No execution moved.
- Actor dictionary keys remain unchanged.
- `BipobController._build_runtime_action_actor(...)` remains as a wrapper.

### PR-X3: Extract terminal control execution helper — completed

Extracted only the terminal branch for `open_door`, `close_door`, `unlock_door` to `scripts/game/bipob_terminal_control_execution_service.gd`.

- Keep spend-on-success behavior.
- Keep hint text and refresh behavior in controller wrapper.
- No generic world-object execution yet.

### PR-X4: Extract Heavy Claw execution helper — completed

Extracted only the push/pull movement path to `scripts/game/bipob_heavy_claw_execution_service.gd`.

- Preserve `get_heavy_claw_move_destination` behavior or keep it as a controller wrapper.
- Preserve spend-on-success behavior.
- Preserve overlay/threat/action-panel refresh flags.

### PR-X5: Extract generic world-object execution helper — completed

Extracted the generic `InteractionSystemRef.apply_action` path to `scripts/game/bipob_world_object_execution_service.gd` after the terminal and Heavy Claw paths were isolated.

- Kept `_apply_world_object_effects` stable.
- Kept power-network post-action apply stable.
- Kept key cleanup stable.
- Kept item consumption stable.
- Kept controller refresh ordering before paid-action finalization and hint emission.

### PR-X6: Extract item pickup execution helper — completed

Extracted the physical/digital item pickup path to `scripts/game/bipob_item_pickup_execution_service.gd`.

- Preserve current-cell/facing-cell lookup order.
- Preserve digital `buffer_item` behavior.
- Preserve `digital_world_records` behavior.
- Preserve `MissionManager.pickup_world_item` behavior.

## 6. Non-goals

Do not do these during execution extraction:

- no action id renames;
- no label or hint text rewrites;
- no change to Action / Connect / Heavy Claw availability;
- no change to movement/collision;
- no change to inventory/storage contracts;
- no change to MissionManager save/load formats;
- no change to InteractionSystem rules;
- no change to power traversal semantics;
- no Russian labels in scripts.

## 7. Acceptance checklist for future execution PRs

Every implementation PR in this area should verify:

- `BipobController` remains callable through existing public methods;
- `interact()` behavior is unchanged from the player perspective;
- Action / Connect / Heavy Claw buttons behave the same;
- action id ordering and selected action behavior are unchanged;
- spending action/energy happens at the same point as before;
- failure paths do not spend action unless they already did before;
- hints and status refreshes remain in the same user-visible flow;
- world object write-back behavior is unchanged;
- item pickup and digital buffer behavior are unchanged;
- power-network apply is triggered only for the same action ids as before;
- CI parser gate is green.

## 8. Recommended next PR

**PR-X6: Extract item pickup execution helper** is complete. The next candidates are:

- BipobController legacy/tile interaction boundary audit;
- MissionManager cleanup/autofix boundary audit;
- MissionManager save/load/preset persistence boundary audit.

These follow-up audits must preserve the existing controller façade, execution ordering, spend-on-success behavior, and refresh flow. Legacy tile interactions and legacy scan/hack/open_door helpers are not extracted yet.
