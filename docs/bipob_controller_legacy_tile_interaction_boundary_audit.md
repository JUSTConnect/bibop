# BipobController legacy/tile interaction boundary audit

Status: audit-only. No runtime code changes are part of this document.

This document audits the legacy tile and mission-specific interaction paths that remain in `scripts/bipob/bipob_controller.gd` after the completed execution extractions:

- `BipobTargetingService` — facing cell/object/item lookup.
- `BipobActionViewModelService` — runtime action view-model/descriptors.
- `BipobCapabilityService` — module/capability checks.
- `BipobRuntimeActionActorService` — runtime actor dictionary construction.
- `BipobTerminalControlExecutionService` — terminal `open_door` / `close_door` / `unlock_door` execution.
- `BipobHeavyClawExecutionService` — Heavy Claw `push` / `pull` movement execution.
- `BipobWorldObjectExecutionService` — generic world-object `InteractionSystem` execution.
- `BipobItemPickupExecutionService` — current/facing cell item pickup execution.

`BipobController` still remains the runtime coordinator/executor. That is expected. This audit focuses only on the remaining old tile-driven branches and mission-specific helper paths.

---

## 1. Current architecture snapshot

The modern runtime path now mostly follows this flow:

```text
TargetingService -> ActionViewModelService -> controller façade -> narrow execution services
```

However, `interact()` still contains legacy tile checks before the modern world-object path. Several old helper functions also still mutate tiles or mission flags directly.

These legacy paths are not bad by themselves, but they are risky because they mix:

- old `GridManager.TILE_*` semantics;
- mission-specific tutorial logic;
- direct `grid_manager.set_tile(...)` mutation;
- direct `hint_requested.emit(...)` / `status_changed.emit()` calls;
- old physical/digital door helpers;
- Mission 7 cable/socket logic;
- Mission 8 platform/fan/airflow logic;
- fallback tile pickup/opening after the world-object path.

The next refactor should not try to merge these into the modern action services immediately. They need a boundary first.

---

## 2. Remaining legacy interaction categories

### 2.1 Legacy digital-device blockers in `interact()`

Current tile checks still block legacy `Interact` when no selected world action is active:

```text
GridManager.TILE_TERMINAL
GridManager.TILE_DIGITAL_DOOR
GridManager.TILE_HOT_NODE
GridManager.TILE_AIRFLOW_TERMINAL
```

These checks emit messages such as:

```text
Terminal is a digital device. Use Scan Device first, then Hack Device.
Digital door cannot be opened with Interact. Use Scan Device, then Hack Device.
Hot Node is a digital device. Use Scan Device, then Hack Device.
Airflow Terminal is a digital device. Use Scan Device, then Hack Device.
```

Boundary risk:

- These are tile-level blockers, not world-object action descriptors.
- They can diverge from the modern Action / Connect UI if the tile and world object disagree.
- They should be converted only after a manual smoke pass confirms world-object contracts cover the same cases.

Recommended boundary:

- Keep these blockers in `BipobController` for now.
- Later extract to `BipobLegacyTileInteractionService` as a read-only blocker/check helper first.
- Do not rewrite messages or flow in the first extraction.

### 2.2 Mission 8 platform and fan controls

Current tile checks route several tiles directly to mission-specific functions:

```text
GridManager.TILE_PLATFORM_CONTROL
GridManager.TILE_PLATFORM_CONTROL_LEFT
GridManager.TILE_PLATFORM_CONTROL_RIGHT
GridManager.TILE_FAN_CONTROL
GridManager.TILE_FAN_SPEED_UP_CONTROL
GridManager.TILE_FAN_SPEED_DOWN_CONTROL
```

These paths call functions such as:

```text
interact_mission8_platform_control_left()
interact_mission8_platform_control_right()
increase_mission8_fan_speed()
decrease_mission8_fan_speed()
```

Boundary risk:

- These are mission-specific command routes, not generic world-object actions.
- Some are blockers with hints, while others execute immediately.
- If they are moved into generic execution too early, Mission 8 could regress.

Recommended boundary:

- Extract only as a mission-tile command router after an audit of Mission 8 functions.
- Keep function calls and return points identical.
- Do not convert to `InteractionSystem` yet.

### 2.3 Mission 7 cable/socket/powered gate logic

Current tile checks still route:

```text
GridManager.TILE_CABLE_REEL
GridManager.TILE_SOCKET
GridManager.TILE_POWERED_GATE
```

They also guard cases where Mission 7 cable dragging is active and the player faces component/key/door tiles.

Boundary risk:

- Mission 7 cable logic mixes held cable state, tile type, hints and direct mission state.
- This predates the newer cable/wire world-object contracts.
- Moving this into generic item/object execution before contract cleanup may create duplicate cable behavior.

Recommended boundary:

- Do not merge Mission 7 tile interactions with modern `power_cable` world-object execution yet.
- First document all Mission 7 cable flags and tile mutations.
- Then extract a `BipobMissionTileInteractionService` or mission-specific `Mission7CableInteractionService` if still needed.

### 2.4 Fallback tile interactions after world-object path

After modern item/world-object execution, `interact()` still falls back to `target_tile` branches such as:

```text
GridManager.TILE_COMPONENT
GridManager.TILE_KEY
GridManager.TILE_DOOR
```

These call older helpers such as:

```text
pick_up_component(...)
pick_up_key(...)
open_door(...)
```

Boundary risk:

- These can duplicate item pickup / door action semantics already represented by world objects.
- They still depend on old mission tile data.
- They may be needed for early missions or old handcrafted maps.

Recommended boundary:

- Keep fallback tile interactions until all legacy missions are converted to world-object contracts.
- Add smoke checks before deleting or converting them.
- Extract only after confirming they are still reachable and intentionally supported.

### 2.5 Legacy door helpers

Functions such as:

```text
open_door(...)
open_digital_door(...)
open_route_gate(...)
```

still directly mutate tiles and spend actions/energy.

Boundary risk:

- These helpers use old concepts such as `has_key`, `has_info_key`, legacy digital records and direct `grid_manager.set_tile(...)`.
- They are not equivalent to the newer Door `access_type` / `control_type` semantics.
- They may still be required by older missions.

Recommended boundary:

- Do not merge them into the generic Door action service yet.
- First classify which missions still call them.
- Then either wrap them as legacy door execution or convert the affected missions to modern world-object Door contracts.

### 2.6 Legacy scan/hack helpers

Functions such as:

```text
scan_device()
hack_device()
evaluate_facing_device_capability()
get_facing_device_diagnostic_result()
get_facing_device_interaction_preflight()
get_facing_device_interaction_state_flow()
```

still mix old DiagnosticResult flow with newer world-object preflight/state-flow APIs.

Boundary risk:

- `scan_device()` and `hack_device()` include mission-specific rules, overheat handling, terminal power checks and direct world-object mutation.
- They are not just UI actions; they are paid runtime executions.
- They overlap with modern `scan`, `hack`, `download`, `connect` action descriptors.

Recommended boundary:

- Do a separate `BipobController scan/hack boundary audit` before code movement.
- Do not include scan/hack in legacy tile interaction extraction.
- Later decide whether scan/hack should become world-object execution services or remain dedicated controller helpers.

---

## 3. What should stay in `BipobController` for now

Keep these responsibilities in the controller façade until later PRs:

- top-level `interact()` ordering;
- direct signal emission order;
- final fallback tile match/return flow;
- mission-specific helper calls;
- scan/hack legacy flow;
- old direct tile helpers for early missions;
- visual/world refresh ordering.

The controller is still the safest place to coordinate these branches because they cross old tile data, new world-object data and mission-specific state.

---

## 4. Proposed future boundary

Recommended target for the next code extraction:

```text
scripts/game/bipob_legacy_tile_interaction_service.gd
```

Suggested class:

```gdscript
extends RefCounted
class_name BipobLegacyTileInteractionService
```

Suggested narrow API for the first PR:

```gdscript
static func handle_pre_world_object_tile_interaction(controller: Variant, target_position: Vector2i, target_tile: int) -> Dictionary
```

Suggested result shape:

```gdscript
{
  "handled": bool,
  "message": String,
  "emit_status": bool,
  "refresh_action_panel": bool,
  "reason": String
}
```

The first implementation should handle only the safest blocker/router branch and should not touch fallback tile pickup/opening.

---

## 5. Safe PR order

### PR-L1: Extract legacy digital-device blockers only

Move only the no-selected-action blockers for:

```text
TILE_TERMINAL
TILE_DIGITAL_DOOR
TILE_HOT_NODE
TILE_AIRFLOW_TERMINAL
```

Rules:

- no execution;
- no tile mutation;
- same hint messages;
- same `status_changed.emit()` behavior;
- same return points.

This is the safest next code PR.

### PR-L2: Extract Mission 8 platform/fan tile router

Move only routing for:

```text
TILE_PLATFORM_CONTROL
TILE_PLATFORM_CONTROL_LEFT
TILE_PLATFORM_CONTROL_RIGHT
TILE_FAN_CONTROL
TILE_FAN_SPEED_UP_CONTROL
TILE_FAN_SPEED_DOWN_CONTROL
```

Rules:

- keep existing mission helper calls;
- do not rewrite Mission 8 logic;
- keep hints and return points identical.

### PR-L3: Extract Mission 7 cable/socket tile router

Move only routing for:

```text
TILE_CABLE_REEL
TILE_SOCKET
TILE_POWERED_GATE
mission7_is_dragging_cable blocker
```

Rules:

- no conversion to modern power cable contracts;
- keep old helper calls;
- keep return points identical.

### PR-L4: Audit fallback tile interactions reachability

Docs or smoke-only PR.

Verify whether these branches are still used:

```text
TILE_COMPONENT
TILE_KEY
TILE_DOOR
```

Output should say whether they are still mission-critical, test-only, or dead legacy.

### PR-L5: Extract fallback tile interactions if still needed

Move fallback tile interactions only after PR-L4 confirms the intended behavior.

Rules:

- keep `pick_up_component`, `pick_up_key`, `open_door` semantics;
- no conversion to world-object contracts in the same PR.

### PR-L6: Separate scan/hack boundary audit

Docs-only audit for:

```text
scan_device()
hack_device()
evaluate_facing_device_capability()
```

Do not combine with tile interaction extraction.

---

## 6. Non-goals

Do not do these in the legacy/tile interaction extraction phase:

- no scan/hack rewrite;
- no old mission conversion to new map format;
- no removal of legacy tile branches without smoke proof;
- no change to hint text;
- no change to action/energy spending;
- no change to movement/collision;
- no change to item pickup services already extracted;
- no change to terminal/heavy/generic execution services already extracted;
- no Russian labels in scripts.

---

## 7. Acceptance checklist for future legacy/tile PRs

Every implementation PR in this area should verify:

- `interact()` return points remain equivalent;
- hint text remains unchanged;
- `status_changed.emit()` behavior remains unchanged;
- no action/energy spend point changes;
- no mission helper behavior changes;
- old mission-specific branches remain smoke-testable;
- modern world-object Action / Connect / Heavy Claw paths still work;
- no code branch is deleted merely because it looks old;
- parser gate is green.

---

## 8. Recommended next PR

The safest next code PR is **PR-L1: Extract legacy digital-device blockers only**.

Reason: these branches are blockers only. They emit a fixed hint and return without mutating world state. This makes them safer than Mission 7/8 routers or fallback tile interactions.
