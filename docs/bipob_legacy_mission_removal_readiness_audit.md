# BIPOB PR-RF-17 — Legacy mission removal readiness audit

## Purpose

This audit records what still blocks safe deletion of old story mission code/resources after PR-RF-08 through PR-RF-16. It is intentionally documentation-only: no gameplay, TASK TEST, Map Constructor, runtime action, scan/hack, movement, inventory, cable, airflow, or mission resource behavior is changed by this change.

Current product direction:

- TASK TEST / Map Constructor / runtime sandbox is the active product surface.
- Old story missions 1-9 are deprecated and will be replaced later from scratch.
- Mechanics introduced by old missions must survive if they are reusable in TASK TEST or future missions.
- Mission resources/scenes/layouts should be deleted only after TASK TEST startup, sandbox completion, Map Constructor, runtime actions, scan/hack, inventory, and movement pass smoke without relying on old mission-index branches.

## Current status after PR-RF-16

### Already isolated or removed

- TASK TEST runtime identity exists through `get_runtime_mode_id()`, `is_task_test_mode_active()`, and `is_sandbox_mode_active()`.
- TASK TEST startup has explicit entry points: `start_task_test_session()` and `reset_task_test_session()`.
- TASK TEST layout/catalog compatibility is named through `get_task_test_mission_id()` and `get_task_test_layout_id()`, but still maps to `mission_10` for now.
- TASK TEST completion is isolated through `complete_sandbox_run()` and checked before legacy completion in `check_mission_complete()`.
- Legacy story completion is separated into `complete_legacy_story_mission()`.
- `complete_mission()` remains as a compatibility wrapper that routes by runtime mode.
- Mission 2 terminal tutorial glue is removed; Info-Key / digital record mechanics remain.
- Mission 4 hidden-route story glue is removed; hidden route-node discovery, Route Data digital record, Scan/X-Ray visibility, and debug placement remain.
- Mission 7 cable/socket/powered-gate flow is isolated behind `BipobLegacyCableFlowService`.
- Mission 8 fan/platform/airflow/cooling flow is isolated behind `BipobLegacyAirflowFlowService`.
- `BipobLegacyCableFlowService.reset_state()` was renamed to `reset_legacy_state()` to avoid the Godot `GDScript.reset_state()` conflict.

### Still compatibility-based

- `start_task_test_session()` still delegates to `start_mission(TASK_TEST_MISSION_INDEX, save_snapshot)`.
- `TASK_TEST_MISSION_INDEX` still maps to the legacy-compatible mission index `10`.
- `MissionManager.TASK_TEST_MISSION_ID` still maps to `mission_10`.
- `current_mission_index` still exists as the central runtime/session selector.
- Mission 7/8 reusable mechanics still have legacy hardcoded state and should not be deleted until generic runtime contracts exist.

## Removal readiness matrix

| Area | Current state | Removal readiness | Next safe action |
| --- | --- | --- | --- |
| Mission 2 terminal tutorial glue | Removed from generic scan/hack/read-terminal paths. | Ready. | Old Mission 2 tutorial resources can be deleted later only with broader mission resource cleanup. Do not remove Info-Key/digital record mechanics. |
| Mission 4 hidden-route story glue | Removed from goal hints, exit gating, completion message, auto field setup, pickup hints, and discovery side effects. | Ready. | Old Mission 4 story resources can be deleted later. Keep hidden/reveal/X-Ray/Route Data mechanics and debug placement. |
| Mission 7 cable/socket/powered-gate | Isolated behind `BipobLegacyCableFlowService`, but still hardcoded to Mission 7 state, positions, and `cable_a`. | Not ready for deletion. | Create a generic runtime cable/socket/power world-object contract before deleting old Mission 7 layout/state. |
| Mission 8 fan/platform/airflow/cooling | Isolated behind `BipobLegacyAirflowFlowService`, but still hardcoded to Mission 8 state and positions. | Not ready for deletion. | Create a generic runtime airflow/fan/platform/cooling world-object contract before deleting old Mission 8 layout/state. |
| TASK TEST startup | Has explicit `start_task_test_session()` wrapper but still delegates to `start_mission(10)`. | Not fully ready. | Move TASK TEST session state off `current_mission_index` and introduce a non-story sandbox layout id before deleting mission-index startup code. |
| TASK TEST completion | Isolated through `complete_sandbox_run()`. | Mostly ready. | Smoke-test sandbox completion. Later route direct TASK TEST callers to `complete_sandbox_run()` and reduce `complete_mission()` compatibility. |
| Mission selection/progression | Still uses `current_mission_index`, `max_mission_index`, `start_mission()`, `complete_legacy_story_mission()`, and legacy hints. | Not ready. | Isolate/remove story mission selection UI/progression after TASK TEST no longer depends on mission index startup. |
| MissionManager | Still owns runtime world-object APIs, TASK TEST compatibility id, layouts, and Map Constructor catalog behavior. | Not ready for broad deletion. | Keep MissionManager until its runtime world-object/catalog responsibilities are separated from story mission responsibilities. |
| Mission resources/scenes/layouts | Still present and should remain until smoke proof exists. | Not ready for broad deletion. | Delete in small PRs only after TASK TEST no longer references story mission startup/layout assumptions. |

## Remaining blockers before deleting old mission resources

1. **TASK TEST still starts through legacy mission index compatibility.**
   - `start_task_test_session()` exists but still calls `start_mission(10)`.
   - `current_mission_index` remains the runtime/session selector.
   - `mission_10` remains the TASK TEST layout/catalog compatibility id.

2. **Mission 7 cable mechanics are not generic yet.**
   - `BipobLegacyCableFlowService` preserves behavior but still uses hardcoded Mission 7 state, positions, tile mutations, and `cable_a`.
   - Deleting Mission 7 before a generic cable/socket/power contract exists risks losing reusable cable mechanics.

3. **Mission 8 airflow mechanics are not generic yet.**
   - `BipobLegacyAirflowFlowService` preserves behavior but still uses hardcoded Mission 8 state, positions, airflow tiles, and door mutation.
   - Deleting Mission 8 before a generic fan/platform/airflow/cooling contract exists risks losing reusable cooling/airflow mechanics.

4. **Legacy story completion/progression remains.**
   - `complete_legacy_story_mission()` still owns old mission completion messages/progression behavior.
   - `complete_mission()` remains a compatibility wrapper.
   - Old mission selection/progression should not be deleted until TASK TEST/session startup is fully independent.

5. **MissionManager still mixes runtime infrastructure and mission compatibility.**
   - It should not be broadly deleted.
   - Runtime world-object/catalog/Map Constructor responsibilities must remain available to TASK TEST.

## Recommended next PR sequence

### PR-RF-18 — Introduce non-story TASK TEST layout id alias

Goal: make TASK TEST use a neutral sandbox layout id, while keeping `mission_10` as a fallback alias.

Suggested direction:

- Add `TASK_TEST_LAYOUT_ID := "task_test"` or `"sandbox_task_test"`.
- Keep `TASK_TEST_MISSION_ID := "mission_10"` as compatibility fallback.
- Make `get_task_test_layout_id()` return the new non-story id only after MissionManager can resolve it.
- Let MissionManager accept both ids during transition.
- Do not delete `mission_10` resources in this PR.

Acceptance:

- TASK TEST starts as before.
- `mission_10` fallback still works.
- Map Constructor, runtime actions, scan/hack, inventory, movement, and sandbox completion are unchanged.

### PR-RF-19 — Split sandbox session state from `current_mission_index`

Goal: introduce an explicit sandbox session field/state so TASK TEST does not depend on mission index internally.

Suggested direction:

- Add a minimal `runtime_mode_id` or `active_session_mode` field if not already present.
- Keep `current_mission_index` for legacy stories only.
- Make `start_task_test_session()` set sandbox state explicitly.
- Keep `start_mission(10)` compatibility by delegating to `start_task_test_session()` instead of the other way around.

Acceptance:

- TASK TEST can start without treating index `10` as the source of truth.
- Old `start_mission(10)` compatibility still works.

### PR-RF-20 — Generic runtime cable/socket/power contract planning or thin service

Goal: prepare Mission 7 deletion by defining the non-story home for cable/socket/power mechanics.

Suggested direction:

- Create a small doc or service plan first if implementation is risky.
- Identify required world-object properties for cable reel, cable endpoint, socket, powered gate, and power event filter.
- Do not delete `BipobLegacyCableFlowService` until TASK TEST can exercise generic cable behavior.

### PR-RF-21 — Generic runtime fan/platform/airflow/cooling contract planning or thin service

Goal: prepare Mission 8 deletion by defining the non-story home for fan/platform/airflow/cooling mechanics.

Suggested direction:

- Create a small doc or service plan first if implementation is risky.
- Identify required world-object properties for fan direction/speed, airflow cells, cooling target, platform controls, and linked door/path mutation.
- Do not delete `BipobLegacyAirflowFlowService` until TASK TEST can exercise generic airflow behavior.

### Later deletion PRs

Only after the above boundaries pass smoke:

- Delete old Mission 2/4 resources and story-only references.
- Delete legacy story mission selection/progression UI.
- Delete old Mission 1-9 resources in small batches.
- Delete `complete_legacy_story_mission()` after no old story callers remain.
- Delete `BipobLegacyCableFlowService` only after generic cable runtime replaces it.
- Delete `BipobLegacyAirflowFlowService` only after generic airflow runtime replaces it.

## Do-not-delete list for now

Do not delete these yet:

- `MissionManager` as a whole.
- TASK TEST / `mission_10` compatibility layout/catalog data.
- Map Constructor catalog/preset/patch APIs.
- WorldObjectCatalog / InteractionSystem / PowerSystem runtime APIs.
- Scan/hack services and digital record storage.
- Inventory pickup/drop/storage helpers.
- Movement controller and runtime action presenter.
- `BipobLegacyCableFlowService` until generic cable/socket/power exists.
- `BipobLegacyAirflowFlowService` until generic fan/platform/airflow/cooling exists.
- Mission resources/scenes/layouts until TASK TEST startup and completion smoke pass without old story dependencies.

## Required smoke before any resource deletion

Run this before deleting mission resources/scenes:

1. Start TASK TEST from UI through `start_task_test_session()`.
2. Confirm the same TASK TEST layout/catalog data loads.
3. Enter Map Constructor.
4. Place/edit/delete an object.
5. Exit Map Constructor.
6. Move/turn Bipob.
7. Check runtime Action / Connect / Heavy Claw refresh and execution.
8. Scan/hack a runtime device if available.
9. Pick up/drop item if available.
10. Reach exit/completion if available and confirm `complete_sandbox_run()` behavior.
11. Confirm no old story mission resource is required for these paths.

## Required checks for cleanup PRs

- `git diff --check`
- `python tools/check_gdscript_safety_patterns.py`
- `python tools/check_map_constructor_sections.py`
- `godot --headless --path . --script res://tools/ci/parse_all_gd.gd`

If Godot CLI is unavailable in the PR environment, parser verification must be completed locally before accepting deletion PRs.
