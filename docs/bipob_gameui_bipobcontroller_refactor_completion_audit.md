# BIPOB UICTRL-RF-08 — GameUI / BipobController refactor completion audit

## Purpose

This docs-only audit closes the current GameUI / BipobController feature-area unloading phase.

The purpose is not to claim these files are finished forever. The purpose is to record that the active high-value ownership seams have been extracted far enough that the project should stop doing broad GameUI/BipobController cleanup PRs and return to product/runtime work unless a concrete bug appears.

No gameplay, UI, TASK TEST, Map Constructor, movement, scan/hack, inventory, cable, airflow, mission resources, scenes, or `project.godot` are changed by this audit.

## Current baseline

The active product surface remains:

- TASK TEST runtime sandbox;
- Map Constructor;
- runtime action/object mechanics;
- runtime inventory/storage;
- scan/hack/terminal feedback;
- visual/isometric asset validation.

Previous completed decoupling/refactor tracks:

- TASK TEST is code-side decoupled from `mission_10` as semantic source of truth.
- GameUI Map Constructor orchestration was moved behind `MapConstructorUIBridge`.
- GameUI runtime Action / Connect / Heavy Claw control orchestration was moved behind `RuntimeActionPanelBridge`.
- GameUI runtime storage UI ownership was moved into `RuntimeStoragePanel`.
- Bipob runtime action orchestration was moved into `BipobActionController`.
- Bipob inventory/storage orchestration was moved into `BipobInventoryController`.
- Scan/hack capability evaluation was moved into `BipobScanHackService`.

## What was reduced

### GameUI

`GameUI` is still the runtime UI root, but it no longer needs to own detailed logic for several active surfaces.

Extracted or strengthened ownership:

| Feature area | Current owner | GameUI role now |
| --- | --- | --- |
| Map Constructor warning/readiness/overlay orchestration | `MapConstructorUIBridge` plus existing Map Constructor UI components | Create/configure bridge, keep compatibility wrappers, route high-level refresh. |
| Runtime Action / Connect / Heavy Claw controls | `RuntimeActionPanelBridge` + `RuntimeControlPanel` | Create/configure bridge, keep callback compatibility, route UI events. |
| Runtime storage/pocket/digital panel | `RuntimeStoragePanel` | Host panel and call refresh/wrapper APIs. |
| Runtime interaction presentation | `RuntimeInteractionPresenter`, `RuntimeObjectHud`, runtime UI components | Continue as UI shell and signal/callback router. |

Remaining GameUI responsibilities are still large but more appropriate:

- runtime root creation and signal wiring;
- app/screen mode transitions;
- box/constructor/programmer/charging/repair screens;
- high-level TASK TEST/dev UI;
- compatibility wrappers for existing button callbacks;
- UI composition that has not yet become a repeated product bottleneck.

### BipobController

`BipobController` is still the actor/runtime facade, but less detailed orchestration remains inline.

Extracted or strengthened ownership:

| Feature area | Current owner | BipobController role now |
| --- | --- | --- |
| Runtime action target/view-model/dispatch orchestration | `BipobActionController` plus existing execution services | Public compatibility wrapper, state/signal owner, legacy fallback owner. |
| Runtime inventory/storage mutation orchestration | `BipobInventoryController` | Public compatibility wrapper, state/signal owner. |
| Scan/hack capability evaluation | `BipobScanHackService` | Public compatibility wrapper and signal/state owner. |
| Movement/facing/action-budget core | `BipobMovementController` partially, plus BipobController | Keep for now. |
| Legacy Mission 7 cable flow | `BipobLegacyCableFlowService` | Compatibility facade and state owner where needed. |
| Legacy Mission 8 airflow flow | `BipobLegacyAirflowFlowService` | Compatibility facade and state owner where needed. |

## Current ownership map

### UI / editor / runtime panels

- `GameUI`: root UI owner, high-level screen transitions, signal setup, compatibility wrappers.
- `MapConstructorUIBridge`: Map Constructor warning/readiness/overlay bridge.
- `MapConstructorScreen`: Map Constructor screen/panel composition.
- `MapConstructorInspector`: inspector layout.
- `MapConstructorPropertyControls`: property widgets.
- `MapConstructorLinkControls`: link picker widgets.
- `MapConstructorRefreshCoordinator`: Map Constructor refresh sequencing.
- `MapConstructorSessionState`: Map Constructor UI/session state.
- `RuntimeActionPanelBridge`: runtime action/control orchestration bridge.
- `RuntimeControlPanel`: runtime control panel view/build helpers.
- `RuntimeStoragePanel`: runtime storage/pocket/digital UI ownership.
- `RuntimeInteractionPresenter`: runtime interaction presentation.
- `RuntimeObjectHud`: world-object HUD presentation.

### Bipob runtime/controller services

- `BipobController`: actor node, signals, public facade, runtime/session integration, movement/action-budget core, compatibility wrappers.
- `BipobActionController`: runtime action orchestration around target lookup, selected action, pickup, terminal/heavy-claw/world-object execution dispatch.
- `BipobInventoryController`: inventory/storage/key/digital storage mutation/query ownership.
- `BipobScanHackService`: scan/hack capability evaluation, scan/hack action flow, diagnostic/interaction state helpers.
- `BipobMovementController`: movement/facing visual update support.
- `BipobTargetingService`: facing target/object/item lookup.
- `BipobActionViewModelService`: action view-model construction.
- `BipobRuntimeActionActorService`: runtime action actor construction.
- `BipobTerminalControlExecutionService`: terminal control execution and linked target mutation.
- `BipobHeavyClawExecutionService`: Heavy Claw execution.
- `BipobWorldObjectExecutionService`: generic world-object action execution.
- `BipobItemPickupExecutionService`: runtime item pickup execution.
- `BipobLegacyCableFlowService`: legacy Mission 7 cable flow.
- `BipobLegacyAirflowFlowService`: legacy Mission 8 airflow flow.

## What should stop now

Stop broad cleanup PRs that only move code out of `GameUI` or `BipobController` because the files are large.

Do not start extracting high-risk areas merely to reduce line count.

Do not immediately extract:

- runtime session startup/reset/result routing;
- movement/action-budget core;
- body/module constructor model;
- legacy Mission 7 cable hardcoding;
- legacy Mission 8 airflow hardcoding;
- terminal linked-target mutation beyond current execution service boundaries;
- old story mission compatibility.

These areas are either core smoke paths or depend on product decisions about generic cable/airflow mechanics.

## Remaining risks

### Godot parser gate still needs local verification

Most recent PRs reported that the Godot CLI was unavailable in the execution environment. The project still needs a local/CI run:

```bash
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Run this before starting another broad code refactor.

### Service controllers now use owner/facade access

The new service/controller boundaries intentionally pass the owning controller as `Variant`/facade. This matches the current project style and avoided circular preloads, but it means:

- behavior remains coupled to `BipobController` fields/signals;
- services should not become dumping grounds;
- future changes should add clear service methods rather than deeper ad-hoc `controller.*` access.

### Legacy Mission 7 / Mission 8 are still not removable

Mission 7 cable/socket/power and Mission 8 airflow/cooling are still legacy-backed mechanics.

Do not delete old mission resources yet. Generic cable and airflow gameplay still need their own product work and TASK TEST smoke.

### GameUI still owns non-runtime screens

GameUI still owns or coordinates box constructor, programmer, charging, repair, and other menu areas. Those should be extracted only when they become active product work, not as generic cleanup.

## Recommended next direction

The GameUI/BipobController unloading phase has reached a useful stopping point.

Recommended next options:

### Option A — Return to visual/isometric asset work

Good if the current priority is visible game progress.

Candidate track:

- BIP-Visual-016 or the next visual validation task;
- floor/wall/tall-wall standardization;
- Map Constructor placement preview validation;
- TASK TEST visual smoke.

### Option B — Return to TASK TEST mechanics/editor validation

Good if the current priority is making the sandbox a better playable testbed.

Candidate work:

- TASK TEST validation/readiness panel improvements;
- Map Constructor object validation quality;
- read-only validation snapshots;
- safer object placement/import/export loops.

### Option C — Start generic cable/socket/power gameplay

Good if the current priority is retiring Mission 7 dependency.

Candidate track:

- generic cable runtime integration;
- socket/power source/sink contracts;
- TASK TEST cable smoke scene/object set;
- then legacy Mission 7 removal readiness.

### Option D — Start generic fan/airflow/cooling gameplay

Good if the current priority is retiring Mission 8 dependency.

Candidate track:

- generic airflow propagation/cooling runtime;
- fan/platform/terminal contracts;
- TASK TEST airflow smoke scene/object set;
- then legacy Mission 8 removal readiness.

## Preferred next step

Preferred next step:

**Return to visual / TASK TEST / Map Constructor product work.**

Reason:

- the code ownership cleanup has already reduced the active surfaces enough;
- continuing cleanup now risks refactor fatigue without visible player/editor value;
- visual/editor validation will immediately reveal whether the new boundaries remain stable.

If choosing a code track instead, prefer a product-motivated one:

1. generic cable/socket/power gameplay, or
2. generic airflow/cooling gameplay.

Do not continue with generic GameUI/BipobController line-count cleanup as the next default task.

## Required checks before next code phase

Run locally/CI:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Manual smoke baseline:

1. Start TASK TEST from UI.
2. Move/turn Bipob.
3. Press Runtime Action on a valid object.
4. Press Connect on a valid target if available.
5. Press Heavy Claw on a valid movable target if available.
6. Pick up/drop item if available.
7. Move item between pocket/manipulator if available.
8. Load/store digital item if available.
9. Scan a runtime object/device if available.
10. Hack/read terminal/device if available.
11. Enter Map Constructor.
12. Place/edit/delete object.
13. Confirm readiness/warnings/overlay still update.
14. Exit Map Constructor.
15. Restart/reset TASK TEST.

## Completion statement

The current GameUI / BipobController feature-area unloading phase is complete enough to stop.

Future refactors should be tied to concrete product work or a specific bug, not broad cleanup.
