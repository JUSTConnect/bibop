# BIPOB — refactor-first plan for GameUI and BipobController

**Version:** 2026-06-02  
**Scope:** docs-only planning  
**Primary decision:** split the big files before continuing TASK TEST mechanics  
**Target files:** `scripts/ui/game_ui.gd`, `scripts/bipob/bipob_controller.gd`, supporting services

---

## 0. Corrected strategic decision

The next phase is not to keep polishing TASK TEST mechanics directly.

TASK TEST and Map Constructor are already the active sandbox/editor/runtime surface, but continuing mechanic work now creates the same problem repeatedly:

```text
new mechanic detail
→ more branches in GameUI
→ more branches in BipobController
→ harder runtime/action/debug flow
→ slower future TASK TEST work
```

Therefore the correct order is:

```text
1. Reduce GameUI and BipobController responsibility.
2. Stabilize service boundaries around runtime actions and constructor UI callbacks.
3. Only then return to TASK TEST mechanics, editor polish, and runtime gameplay iteration.
```

This document replaces a TASK-TEST-first interpretation with a refactor-first strategy.

---

## 1. What is already true

The project is not starting from a raw monolith. Several seams already exist.

### 1.1 Existing Bipob seams

Current extracted helpers include:

```text
scripts/game/bipob_targeting_service.gd
scripts/game/bipob_action_view_model_service.gd
scripts/game/bipob_capability_service.gd
scripts/game/bipob_runtime_action_actor_service.gd
scripts/game/bipob_terminal_control_execution_service.gd
scripts/game/bipob_heavy_claw_execution_service.gd
scripts/game/bipob_world_object_execution_service.gd
scripts/game/bipob_item_pickup_execution_service.gd
```

These are useful and should not be bypassed by new mechanic work.

### 1.2 Existing GameUI / Map Constructor seams

Current extracted helpers include:

```text
scripts/ui/runtime/*
scripts/ui/map_constructor/*
scripts/game/map_constructor_service.gd
scripts/game/map_constructor_validation_service.gd
scripts/game/map_constructor_property_update_service.gd
scripts/game/map_constructor_link_read_model_service.gd
scripts/game/map_constructor_power_link_validation_rules.gd
scripts/game/map_constructor_readiness_validation_service.gd
```

These are also useful, but `game_ui.gd` remains too stateful and too central.

---

## 2. Real blocker

The blocker is not that TASK TEST is unclear.

The blocker is that every mechanic improvement still tends to require edits in one or both big files:

```text
scripts/ui/game_ui.gd
scripts/bipob/bipob_controller.gd
```

This creates a bad development loop:

```text
Door polish touches GameUI + BipobController.
Terminal polish touches GameUI + BipobController.
Cable polish touches GameUI + BipobController.
Heavy Claw polish touches GameUI + BipobController.
Inventory polish touches GameUI + BipobController.
Map Constructor polish touches GameUI + MissionManager.
```

The next phase should break this loop.

---

## 3. Target architecture before more TASK TEST mechanics

### 3.1 GameUI target shape

`game_ui.gd` should become a thin application/root coordinator.

It may keep:

```text
boot UI
screen switching
root node creation
signal binding
selected screen ownership
high-level refresh routing
modal/panel visibility orchestration
calls to focused controllers/services
```

It should not keep growing:

```text
Map Constructor property semantics
link validity decisions
validation severity decisions
autofix/cleanup planning
runtime action availability decisions
inventory display truth
object-type hardcoded presentation branches
large callback bodies for mechanic-specific UI
```

### 3.2 BipobController target shape

`bipob_controller.gd` should become a thin owner/coordinator for the Bipob node.

It may keep:

```text
node state
signals
high-level input methods used by UI
basic delegation
mission-manager reference
service wiring
status/hint forwarding
```

It should not keep growing:

```text
object-type execution branches
tile-specific legacy routers
inventory internals
scan/hack diagnostic policy
movement/path/collision implementation details
runtime action descriptor construction
terminal/door/power/cable/heavy-claw special cases
visual feedback details
```

---

## 4. Refactor sequence

The order below intentionally avoids broad rewrites. Each step must be narrow and should preserve behavior.

---

## PR-RF-01 — GameUI call-surface audit

**Type:** docs-only or script-assisted audit  
**Goal:** list and classify every direct runtime call and large callback in `game_ui.gd`.

Target files:

```text
scripts/ui/game_ui.gd
scripts/ui/map_constructor/*.gd
scripts/ui/runtime/*.gd
docs/bipob_game_ui_call_surface_audit.md
```

Classify each direct call to `mission_manager_runtime`, `bipob`, or constructor helper as:

```text
screen/root coordination
render-read
refresh coordination
callback route
mutation facade
semantic decision
mechanic-specific branch
legacy compatibility
```

Acceptance:

```text
- No behavior changes.
- No UI redesign.
- No TASK TEST mechanic changes.
- Output identifies exact extraction candidates and blockers.
```

Why first:

```text
Without this audit, every later UI extraction risks moving the wrong thing or preserving hidden semantic decisions in another helper.
```

---

## PR-RF-02 — Extract GameUI constructor selection/session state

**Type:** narrow code PR  
**Goal:** move Map Constructor session state out of `game_ui.gd` without changing behavior.

Create candidate:

```text
scripts/ui/map_constructor/map_constructor_session_state.gd
```

Move state like:

```text
map_constructor_mode_active
map_constructor_active_tab
selected_map_constructor_prefab_id
pending_map_constructor_cell
map_constructor_pending_place_prefab_id
map_constructor_pending_place_cell
map_constructor_pending_place_rotation
selected_map_constructor_entity_kind
selected_map_constructor_entity_id
selected_map_constructor_entity_cell
selected_map_constructor_wall_side
selected_map_constructor_mounting_mode
available_map_constructor_wall_sides
picker field/entity state
filters/search/recent/favorites state
selected issue/template/patch/preset names
```

Rules:

```text
- Data container only.
- No semantic decisions.
- No mutation policy.
- GameUI may still own refresh ordering.
- Existing public behavior stays the same.
```

Acceptance:

```text
- game_ui.gd loses a large block of state variables.
- All previous UI flows compile and use the same values through the session object.
- Parser/safety checks pass.
```

---

## PR-RF-03 — Extract GameUI refresh coordinator

**Type:** narrow code PR  
**Goal:** isolate post-mutation refresh sequencing so callbacks do not keep growing.

Create candidate:

```text
scripts/ui/map_constructor/map_constructor_refresh_coordinator.gd
```

Move only sequencing like:

```text
refresh inspector
refresh palette
refresh validation view
refresh overlays
refresh runtime object HUD
request field visual refresh
restore scroll/expanded state
focus selected issue/entity
```

Rules:

```text
- No validation semantics.
- No mutation decisions.
- No power/cooling recalculation decisions.
- Coordinator receives explicit mutation/read results and refreshes UI.
```

Acceptance:

```text
- GameUI callbacks become shorter.
- The refresh order remains unchanged.
- No runtime mechanic behavior changes.
```

---

## PR-RF-04 — Extract GameUI runtime interaction presenter/facade

**Type:** narrow code PR  
**Goal:** prevent runtime Action / Connect / Heavy Claw UI growth inside `game_ui.gd`.

Create candidate:

```text
scripts/ui/runtime/runtime_interaction_presenter.gd
```

Responsibilities:

```text
read target action context from BipobController
prepare button labels/enabled/tooltip/pulse state
route Action button click
route Connect button click
route Heavy Claw button click
clear stale action pulses after target changes
```

Rules:

```text
- The presenter does not decide game semantics.
- It renders `BipobActionViewModelService` output.
- It does not call InteractionSystem directly unless already part of existing read model flow.
- It does not mutate world state except through existing controller methods.
```

Acceptance:

```text
- GameUI no longer owns detailed Action/Connect/Heavy Claw button logic.
- Runtime controls still behave exactly the same.
- Stale pulse clearing still works.
```

---

## PR-RF-05 — BipobController movement boundary

**Type:** narrow code PR  
**Goal:** move movement/collision/visual-position update implementation out of `bipob_controller.gd`.

Create candidate:

```text
scripts/bipob/bipob_movement_controller.gd
```

Move or delegate:

```text
move_forward
move_backward
try_move_to
turn_left
turn_right
get_direction_vector
get_facing_device_position if not already fully delegated
update_world_position
update_rotation/update_visual_facing if safe
movement-related stale action clearing
movement-related mission complete checks
```

Rules:

```text
- Preserve public BipobController methods used by UI.
- UI still calls BipobController.
- BipobController delegates to movement controller.
- Do not change pathfinding/passability.
- Do not change isometric positioning behavior unless explicitly required.
```

Acceptance:

```text
- Movement smoke still passes.
- Facing target after turn/move remains correct.
- Runtime action panel refreshes after movement/turn.
- No TASK TEST mechanics are changed.
```

---

## PR-RF-06 — BipobController legacy tile quarantine

**Type:** narrow code PR after audit  
**Goal:** prevent old tile/device logic from living inline beside modern world-object action flow.

Create candidate:

```text
scripts/game/bipob_legacy_tile_interaction_service.gd
```

Move in stages:

```text
1. read-only legacy digital tile blockers
2. old platform/fan tile routing
3. old cable/socket tile routing
4. TILE_COMPONENT/TILE_KEY/TILE_DOOR fallback audit
```

Rules:

```text
- This is not story mission development.
- This is quarantine so TASK TEST world-object flow stays clean.
- Preserve old behavior until proven unreachable.
- No new mechanics.
```

Acceptance:

```text
- Modern world-object action path remains preferred.
- Legacy tile checks are isolated and easier to delete later.
- No action/energy spending changes unless explicitly scoped.
```

---

## PR-RF-07 — BipobController scan/hack boundary audit and extraction

**Type:** docs-only first, then narrow code PR  
**Goal:** remove scan/hack diagnostic policy from the controller.

Candidate service:

```text
scripts/game/bipob_scan_hack_service.gd
```

Move only after audit:

```text
get_facing_device_diagnostic_result
get_facing_device_interaction_preflight
get_facing_device_interaction_state_flow
evaluate_device_capability
scan_device
hack_device
format scan/hack hints
```

Rules:

```text
- Do not rewrite terminal behavior.
- Do not rewrite action contracts.
- Do not add new scan/X-Ray mechanics.
- Preserve messages unless a separate UX PR changes them.
```

Acceptance:

```text
- Controller delegates scan/hack.
- Runtime scan/hack smoke remains identical.
- Device preflight/state-flow still reads MissionManager/InteractionSystem contracts.
```

---

## PR-RF-08 — BipobController inventory boundary

**Type:** narrow code PR  
**Goal:** remove inventory internals from `BipobController` after item pickup execution helper is stable.

Candidate service:

```text
scripts/bipob/bipob_inventory_controller.gd
```

Responsibilities:

```text
physical hand availability
held item checks
pocket/key/digital convenience wrappers
pickup/drop/use delegation
storage route helpers used by action gating
```

Rules:

```text
- Do not redesign inventory storage model in this PR.
- Keep current MVP shape unless a later inventory normalization PR changes it.
- Preserve public wrappers on BipobController for UI compatibility.
```

---

## PR-RF-09 — Pause and return to TASK TEST mechanics

Only after the above boundaries are in place should mechanic work resume.

At that point, new mechanic work should mostly touch:

```text
WorldObjectCatalog
InteractionSystem
PowerSystem / scoped system helpers
MissionManager focused service APIs
MapConstructor focused services
Runtime UI presenter/helper
Bipob execution services
```

and should not require large edits in:

```text
game_ui.gd
bipob_controller.gd
```

---

## 5. File-size / responsibility acceptance target

This project does not need a strict line-count gate yet, but the direction should be measurable.

Soft target after the refactor-first phase:

```text
game_ui.gd:
- mostly root/screen coordinator
- fewer constructor state fields
- fewer direct mutation callbacks
- no mechanic-specific runtime action UI branches

bipob_controller.gd:
- public facade for UI
- service delegation for targeting/action/execution/movement/scan/inventory
- no large inline object-type execution tree
- legacy tile logic isolated
```

A PR is considered suspicious if it adds new mechanic-specific branches to either big file without also explaining why no existing service boundary can own them.

---

## 6. Rules for all refactor-first PRs

```text
[ ] No new TASK TEST mechanic behavior unless explicitly scoped.
[ ] No normal mission content changes.
[ ] No project.godot changes.
[ ] No Test Build files/folders.
[ ] No save/preset/patch format changes unless explicitly scoped.
[ ] No validation mutation.
[ ] No broad power/cooling recalculation added.
[ ] Public methods used by UI remain as compatibility wrappers until callers migrate.
[ ] Game-facing labels remain English.
[ ] GDScript safety checks pass.
[ ] Godot parser gate passes.
[ ] Manual smoke checklist is included for behavior-preserving refactors.
```

---

## 7. Codex prompt for the immediate next PR

```text
BIPOB PR-RF-01 — GameUI call-surface audit before further TASK TEST mechanics

Goal:
Perform a documentation-only audit of scripts/ui/game_ui.gd and UI helper call surfaces so we can split GameUI before continuing TASK TEST mechanic development.

Reason:
TASK TEST is already the active sandbox/editor/runtime mode, but every mechanic polish currently risks adding more branches to GameUI or BipobController. The next phase is refactor-first: reduce big-file responsibility before returning to TASK TEST mechanics.

Scope:
- scripts/ui/game_ui.gd
- scripts/ui/map_constructor/*.gd
- scripts/ui/runtime/*.gd
- docs/bipob_game_ui_call_surface_audit.md

Audit:
List direct calls and callback paths involving:
- mission_manager_runtime
- bipob
- map_constructor services/helpers
- runtime action controls
- constructor mutation callbacks
- validation/overlay refresh callbacks

Classify each call as:
- screen/root coordination
- render-read
- refresh coordination
- callback route
- mutation facade
- semantic decision
- mechanic-specific branch
- legacy compatibility

Rules:
- Documentation-only.
- Do not modify gameplay behavior.
- Do not add or edit TASK TEST mechanics.
- Do not edit normal mission content.
- Do not change project.godot.
- Do not create Test Build files/folders.
- Do not add Russian game-facing labels.

Deliverable:
Create docs/bipob_game_ui_call_surface_audit.md with:
- current GameUI responsibility map;
- list of largest remaining state/callback clusters;
- exact extraction candidates;
- recommended next PR sequence;
- non-goals;
- smoke checklist for later extraction PRs.

Acceptance:
- The doc explicitly says mechanic work should pause until GameUI/BipobController boundaries are improved.
- The doc does not propose story mission work.
- The doc identifies where future mechanic work should go instead of GameUI.
```

---

## 8. Final note

The previous TASK TEST contract audit is still useful as a sandbox/runtime reference, but it is not the immediate execution plan.

The immediate execution plan is:

```text
Refactor big files first.
Then continue TASK TEST mechanics.
```
