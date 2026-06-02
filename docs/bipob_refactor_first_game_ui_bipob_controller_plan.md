# BIPOB — refactor-first plan for GameUI and BipobController

**Version:** 2026-06-02  
**Scope:** docs-only planning update  
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

---

## 1. Current verified state

### 1.1 GameUI session state extraction is already done

`MapConstructorSessionState` already exists:

```text
scripts/ui/map_constructor/map_constructor_session_state.gd
```

`game_ui.gd` already preloads it and keeps:

```gdscript
var map_constructor_state: MapConstructorSessionState = MapConstructorSessionStateRef.new()
```

The session state holder already contains constructor selection, pending placement, picker, filters, issue/preset/patch/template names, overlay visibility, overview settings, and reset helpers.

So the next PR must **not** be “extract session state”. That would repeat completed work.

### 1.2 Existing Bipob seams

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

### 1.3 Existing GameUI / Map Constructor seams

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

The problem is not that no seams exist. The problem is that `game_ui.gd` and `bipob_controller.gd` still contain too much orchestration and many callback/execution branches.

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

## 3. Updated refactor sequence

The previous idea of starting with a call-surface audit or session-state extraction is no longer the best next step:

- a pure call-surface audit is too passive;
- session state extraction is already implemented.

The next useful PR should be a narrow behavior-preserving code extraction.

---

## PR-RF-01 — Extract GameUI Map Constructor refresh coordinator

**Type:** narrow code PR  
**Goal:** remove post-mutation refresh sequencing from `game_ui.gd` without changing behavior.

Create candidate:

```text
scripts/ui/map_constructor/map_constructor_refresh_coordinator.gd
```

Move only sequencing and routing like:

```text
refresh Map Constructor panels
refresh inspector after property/preset/link mutation
request field visual refresh
restore inspector scroll/expanded state when safe
focus selected issue/entity after refresh
refresh validation overlay visibility/update
refresh runtime object HUD if needed
clear/rebuild placement confirmation panel if needed
```

The coordinator should receive the current `GameUI` owner and/or explicit context. It must not become a semantic service.

Rules:

```text
- No gameplay behavior changes.
- No TASK TEST mechanic changes.
- No MissionManager behavior changes.
- No validation semantics.
- No mutation decisions.
- No power/cooling recalculation decisions.
- No UI redesign.
- Keep existing callback order unless a bug is explicitly fixed.
```

Acceptance:

```text
- game_ui.gd has shorter property/link/placement/preset callbacks.
- Existing Map Constructor selection, placement, inspector, validation view, overlay, and visual refresh still work.
- Parser gate passes.
- GDScript safety checks pass.
```

Why this is first:

```text
Session state is already extracted, but callbacks still repeatedly do:
show hint → refresh panels → request visual refresh → reopen inspector → focus selection.
That pattern should move out before new mechanics add more copies.
```

---

## PR-RF-02 — Extract GameUI runtime interaction presenter/facade

**Type:** narrow code PR  
**Goal:** prevent runtime Action / Connect / Heavy Claw UI growth inside `game_ui.gd`.

Create candidate:

```text
scripts/ui/runtime/runtime_interaction_presenter.gd
```

Responsibilities:

```text
read target action context from BipobController
prepare Action / Connect / Heavy Claw button labels
enable/disable buttons from existing view model
prepare tooltip/reason text
route Action button click
route Connect button click
route Heavy Claw button click
clear stale action pulses after target changes
```

Rules:

```text
- The presenter does not decide game semantics.
- It renders Bipob action/view-model data.
- It does not call InteractionSystem directly unless already part of an existing read-model path.
- It does not mutate world state except through existing BipobController public methods.
```

Acceptance:

```text
- GameUI no longer owns detailed Action/Connect/Heavy Claw button logic.
- Runtime controls still behave exactly the same.
- Stale pulse clearing still works.
```

---

## PR-RF-03 — BipobController movement boundary

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
movement/collision checks
movement-related stale action clearing
movement-related mission complete checks
visual world position update if safe
visual facing update if safe
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

## PR-RF-04 — BipobController legacy tile quarantine

**Type:** narrow code PR after local code inspection  
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

---

## PR-RF-05 — BipobController scan/hack boundary

**Type:** narrow code PR, possibly preceded by small inspection note  
**Goal:** remove scan/hack diagnostic policy from the controller.

Candidate service:

```text
scripts/game/bipob_scan_hack_service.gd
```

Move only after verifying current call order:

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

---

## PR-RF-06 — BipobController inventory boundary

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

## PR-RF-07 — Pause and return to TASK TEST mechanics

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

## 4. Rules for all refactor-first PRs

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

## 5. Codex prompt for the immediate next PR

```text
BIPOB PR-RF-01 — Extract GameUI Map Constructor refresh coordinator

Goal:
Reduce scripts/ui/game_ui.gd by moving Map Constructor post-mutation refresh sequencing into a dedicated coordinator, without changing runtime behavior.

Create:
- scripts/ui/map_constructor/map_constructor_refresh_coordinator.gd

Target:
- scripts/ui/game_ui.gd
- scripts/ui/map_constructor/map_constructor_refresh_coordinator.gd

Context:
MapConstructorSessionState already exists and is already used by GameUI. Do not repeat session-state extraction. The next remaining problem is that many GameUI callbacks still manually perform the same refresh sequence: show hint, refresh constructor panels, request visual refresh, reopen inspector, restore/focus selected state.

Scope:
Move only refresh sequencing/routing helpers used after Map Constructor mutations:
- refresh Map Constructor panels
- refresh inspector after property/preset/link mutation
- request field visual refresh
- restore/focus selected entity or issue after refresh where current behavior already does this
- refresh validation overlay visibility/update where current behavior already does this
- keep placement confirmation refresh behavior unchanged

Rules:
- No gameplay behavior changes.
- No TASK TEST mechanic changes.
- No MissionManager behavior changes.
- No project.godot changes.
- No UI redesign.
- No semantic decisions in the new coordinator.
- No validation rule changes.
- No power/cooling recalculation decisions.
- Keep existing GameUI public behavior and callbacks working.
- Runtime labels remain English.

Acceptance:
- game_ui.gd has fewer repeated post-mutation refresh blocks.
- Existing Map Constructor selection, placement, picker, filter, validation focus, inspector refresh, overlay, and field visual refresh still work.
- Parser gate passes.
- GDScript safety checks pass.
- Manual smoke: place object, edit property, apply preset, link object, focus validation issue, delete object, confirm inspector/overlay/field visual refresh still update.
```

---

## 6. Final note

The previous TASK TEST contract audit is still useful as a sandbox/runtime reference, but it is not the immediate execution plan.

The immediate execution plan is:

```text
Refactor big files first.
Do not redo already-completed session-state extraction.
Next: extract Map Constructor refresh coordinator.
Then: extract runtime interaction presenter.
Then: continue BipobController boundaries.
Then: return to TASK TEST mechanics.
```
