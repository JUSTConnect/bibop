# BIPOB UICTRL-RF-07 — Scan / hack / terminal boundary audit

## Purpose

This docs-only audit starts UICTRL-RF-07 after the GameUI and BipobController ownership reduction work.

The goal is to map scan / hack / terminal ownership before moving more code. This area touches runtime actions, terminal control, digital records, inventory keys, MissionManager world objects, and UI feedback, so it should not be extracted blindly.

This audit does not change gameplay, UI, scan/hack semantics, terminal behavior, inventory, movement, Map Constructor, TASK TEST, mission resources, scenes, or `project.godot`.

## Context

Recent completed work:

- UICTRL-RF-02 extracted the GameUI Map Constructor UI bridge.
- UICTRL-RF-03 extracted the GameUI runtime action/control panel bridge.
- UICTRL-RF-04 moved runtime storage UI ownership into `RuntimeStoragePanel`.
- UICTRL-RF-05 extracted runtime action orchestration into `BipobActionController`.
- UICTRL-RF-06 moved inventory/storage orchestration into `BipobInventoryController`.

The next medium-risk seam is scan / hack / terminal.

This seam is more dangerous than inventory because it crosses several systems:

- `BipobController` public wrappers and signals;
- `BipobScanHackService` scan/hack state evaluation;
- `BipobTerminalControlExecutionService` terminal control actions;
- `BipobActionController` runtime Action / Connect / terminal dispatch;
- `BipobInventoryController` digital/key access helpers;
- `MissionManager` world-object runtime mutation and terminal linked targets;
- `GameUI` runtime interaction/control panel and status/hint rendering.

## Current known owners

### `scripts/bipob/bipob_controller.gd`

Current role:

- public API surface for UI and services;
- signal owner for hint/status/diagnostic updates;
- runtime session owner;
- wrappers around scan/hack/device methods;
- still owns some terminal/device helper methods that are used by action execution and scan services.

Expected future role:

- remain the public compatibility facade;
- keep signals and high-level state;
- delegate scan/hack/read-terminal evaluation to `BipobScanHackService`;
- delegate terminal action execution to `BipobTerminalControlExecutionService` / `BipobActionController`;
- avoid owning detailed scan/hack branching.

Do not remove public wrappers yet because GameUI/runtime panels may still call them.

### `scripts/game/bipob_scan_hack_service.gd`

Current intended role:

- scan/hack/read-terminal capability checks;
- facing diagnostic result;
- facing device interaction state flow;
- scan/hack availability and messages;
- no UI rendering;
- no world mutation except through explicit owner/controller methods if already established.

Recommended future role:

- become the single owner for scan/hack/read-terminal evaluation and result normalization;
- expose small static APIs that `BipobController` wrappers call;
- keep terminal control mutation out of this service unless it is strictly scan/hack-specific.

### `scripts/game/bipob_terminal_control_execution_service.gd`

Current intended role:

- execute terminal control actions such as door/platform target commands;
- validate linked target restrictions;
- return execution dictionaries for action refresh/hints/status.

Recommended future role:

- remain execution owner for terminal control actions triggered from runtime action flow;
- not absorb scan/hack capability evaluation that belongs to `BipobScanHackService`;
- avoid inventory/digital storage mutation except when a terminal action explicitly produces a digital result and the existing behavior already does so.

### `scripts/bipob/bipob_action_controller.gd`

Current role after UICTRL-RF-05:

- runtime action orchestration owner;
- calls terminal control execution service for terminal door-control actions;
- calls action view-model and world-object execution services;
- keeps selected action / world action panel refresh orchestration.

Recommended future role:

- continue to dispatch terminal actions, but do not grow into a scan/hack service;
- for scan/hack-specific checks, call `BipobScanHackService` through existing controller wrappers or a thin direct service boundary.

### `scripts/bipob/bipob_inventory_controller.gd`

Current role after UICTRL-RF-06:

- inventory/storage owner;
- key/access/digital storage helper owner;
- digital buffer/storage and physical storage mutation owner.

Recommended future role:

- remain owner for key/digital record storage checks;
- scan/hack services may query controller public wrappers that delegate to inventory controller;
- do not move scan/hack branching into inventory controller.

### `scripts/ui/game_ui.gd` and runtime UI bridges

Current role:

- UI rendering and callback routing;
- should not own scan/hack rules;
- should call BipobController public API and display returned/hinted status.

Recommended future role:

- no scan/hack mechanics;
- if a runtime scan/hack panel extraction is needed later, it should be UI-only and call existing controller wrappers.

## Boundary principles

### Keep scan/hack evaluation separate from terminal control execution

Scan/hack evaluation asks:

- Can Bipob scan this?
- Can Bipob read this terminal/device?
- Can Bipob hack this?
- What module/capability is missing?
- What message should be shown when unavailable?
- What diagnostic state should be returned?

Terminal control execution asks:

- Given a valid terminal/control action, which linked target is affected?
- Does the target accept this action?
- What world-object/runtime mutation happens?
- What refresh/hint/status signals should follow?

These should stay separate.

### Keep inventory/digital access separate from scan/hack logic

Inventory controller should answer key/digital possession questions, but it should not decide terminal scan/hack flow.

Good:

- `BipobScanHackService` asks whether a required digital key/record is available through a controller wrapper.

Bad:

- `BipobInventoryController` starts deciding whether a terminal can be hacked.

### Keep GameUI as caller/display only

GameUI and runtime UI bridges should not evaluate scan/hack rules. They should trigger controller public methods and render resulting hints/status.

### Keep MissionManager as world-object truth

MissionManager owns world-object runtime dictionaries and linked target mutation. Scan/hack/terminal services may call MissionManager helpers, but should not duplicate object state or keep their own object cache.

## High-risk areas

Do not extract these first:

- terminal linked-target mutation;
- Mission 7 cable-specific terminal/control behavior;
- Mission 8 airflow-specific terminal/control behavior;
- generic cable gameplay;
- generic airflow gameplay;
- movement/action-budget spending;
- digital storage mutation from scan/hack unless already present.

## Lower-risk extraction candidates

These are safer candidates for the next code PR:

1. Move remaining `BipobController` scan/hack wrapper internals into `BipobScanHackService` if any wrappers still contain direct branching.
2. Add explicit scan/hack service result helpers so `BipobController` wrappers are one-line delegates.
3. Normalize scan/hack result dictionaries in `BipobScanHackService` only.
4. Add docs/comments marking terminal execution as separate from scan/hack evaluation.
5. Replace any unsafe `:=` or untyped Variant locals in scan/hack service if found by safety gates.

## Status update — UICTRL-RF-07A

UICTRL-RF-07A moved scan/hack device capability evaluation into `BipobScanHackService.evaluate_device_capability(controller, device)`. `BipobController.evaluate_device_capability(device)` remains as a public compatibility wrapper, and terminal control execution remains outside scan/hack evaluation.

## UICTRL-RF-07A code PR

**UICTRL-RF-07A — Thin Bipob scan/hack wrappers to BipobScanHackService**

Goal:

- make `BipobController` scan/hack/read-terminal public methods mostly delegate to `BipobScanHackService`;
- preserve all public method names;
- preserve all hints/status messages and result shapes;
- do not change terminal control execution;
- do not change inventory/digital storage semantics;
- do not touch Mission 7/8 adapters.

Target files:

- `scripts/bipob/bipob_controller.gd`
- `scripts/game/bipob_scan_hack_service.gd`
- docs file update only if needed

Acceptance:

- `BipobController` keeps public scan/hack wrappers;
- wrappers delegate to `BipobScanHackService` where behavior-equivalent;
- terminal control execution remains in `BipobTerminalControlExecutionService` / `BipobActionController`;
- inventory/key checks remain through existing controller/inventory boundaries;
- no scan/hack behavior changes.

## Required checks for UICTRL-RF-07A

Run:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

If Godot CLI is unavailable, the PR must say so clearly.

Manual smoke:

1. Start TASK TEST.
2. Face a scannable object/device.
3. Run scan/diagnostic if available.
4. Read terminal/device if available.
5. Hack terminal/device if available.
6. Confirm failed scan/hack does not mutate state.
7. Confirm unpowered/damaged terminal still blocks hack/execute as before.
8. Press Runtime Action on a valid object.
9. Press Connect if available.
10. Pick up/drop item if available.
11. Enter Map Constructor.
12. Place/edit/delete object.
13. Exit Map Constructor.
14. Restart/reset TASK TEST.

## Non-goals

- Do not implement generic cable gameplay.
- Do not touch airflow.
- Do not rewrite terminal control execution.
- Do not change scan/hack semantics.
- Do not change inventory.
- Do not change movement/action budget.
- Do not redesign UI.
- Do not delete old missions.
