# BIPOB PR-RF-27 — Legacy mission removal readiness audit

## Purpose

This audit records what still blocks safe deletion of old story mission code/resources after PR-RF-08 through PR-RF-30. PR-RF-24 intentionally added non-gameplay checks for the generic cable runtime state/service only, PR-RF-25 isolates TASK TEST restart/reset routing, PR-RF-26 routes mission-result TASK TEST restart through the explicit sandbox boundary, and PR-RF-27 centralizes remaining GameUI TASK TEST mission-index compatibility behind helper boundaries without changing gameplay mechanics, Map Constructor behavior, runtime actions, scan/hack, movement, inventory, cable behavior, airflow, cooling, power routing, terminal hack, door/path unlock, or mission resources. PR-RF-30 extracts TASK TEST seed world-object construction into a dedicated builder while keeping MissionManager compatibility wrappers.

Current product direction:

- TASK TEST / Map Constructor / runtime sandbox is the active product surface.
- Old story missions 1-9 are deprecated and will be replaced later from scratch.
- Mechanics introduced by old missions must survive if they are reusable in TASK TEST or future missions.
- Mission resources/scenes/layouts should be deleted only after TASK TEST startup, sandbox completion, Map Constructor, runtime actions, scan/hack, inventory, and movement pass smoke without relying on old mission-index branches.

## Current status after PR-RF-27

### Already isolated or removed

- TASK TEST runtime identity exists through explicit `active_runtime_mode_id` session state, `get_runtime_mode_id()`, `is_task_test_mode_active()`, and `is_sandbox_mode_active()`.
- TASK TEST startup/restart/reset has explicit entry points: `start_task_test_session()`, `restart_task_test_session()`, and `reset_task_test_session()`. `start_task_test_session()` starts the sandbox session directly instead of delegating to `start_mission(10)`, TASK TEST restart/reset now routes through the explicit TASK TEST boundary, and mission-result restart uses that boundary instead of mutating `current_mission_index` for TASK TEST.
- TASK TEST layout/catalog compatibility is named through `get_task_test_mission_id()` and `get_task_test_layout_id()`; `get_task_test_layout_id()` now exposes the non-story `task_test` alias while `mission_10` remains the compatibility mission id and fallback resource id.
- GameUI TASK TEST detection is centralized through `_is_task_test_runtime_active()`, which prefers `BipobController.is_task_test_mode_active()` and keeps the raw mission-index fallback only inside that helper boundary. The Dev TASK TEST card resolves its displayed compatibility id through controller helpers instead of embedding `mission_10` directly.
- TASK TEST completion is isolated through `complete_sandbox_run()` and checked before legacy completion in `check_mission_complete()`.
- Legacy story completion is separated into `complete_legacy_story_mission()`.
- `complete_mission()` remains as a compatibility wrapper that routes by runtime mode.
- Mission 2 terminal tutorial glue is removed; Info-Key / digital record mechanics remain.
- Mission 4 hidden-route story glue is removed; hidden route-node discovery, Route Data digital record, Scan/X-Ray visibility, and debug placement remain.
- Mission 7 cable/socket/powered-gate flow is isolated behind `BipobLegacyCableFlowService`.
- PR-RF-20 defines the planned generic cable/socket/power runtime contract in `docs/bipob_generic_cable_socket_power_contract.md`; PR-RF-22 adds `BipobCableRuntimeState` as a generic data/state helper only; PR-RF-23 adds `BipobCableRuntimeService` as a data-only service skeleton; PR-RF-24 adds non-gameplay checks for those state/service transitions. Generic cable gameplay behavior has not landed yet.
- Mission 8 fan/platform/airflow/cooling flow is isolated behind `BipobLegacyAirflowFlowService`.
- PR-RF-21 defines the planned generic fan/platform/airflow/cooling runtime contract in `docs/bipob_generic_airflow_cooling_contract.md`; implementation has not landed yet.
- `BipobLegacyCableFlowService.reset_state()` was renamed to `reset_legacy_state()` to avoid the Godot `GDScript.reset_state()` conflict.

### Still compatibility-based

- `TASK_TEST_MISSION_INDEX` still maps to the legacy-compatible mission index `10`, and `current_mission_index` is still set to `10` for compatibility during TASK TEST sessions.
- `MissionManager.TASK_TEST_LAYOUT_ID` maps to `task_test`, while `MissionManager.TASK_TEST_MISSION_ID` still maps to `mission_10` for compatibility fallback.
- `current_mission_index` still exists as legacy compatibility state for story mission flow, progression, hints, and Mission 7/8/9 branches. TASK TEST restart/reset no longer relies on mission index `10` as the only restart boundary when sandbox mode is active, including the mission-result restart UI path; GameUI keeps that index fallback only inside `_is_task_test_runtime_active()`.
- Mission 7/8 reusable mechanics still have legacy hardcoded state and should not be deleted until their generic runtime contracts are implemented and smoke-tested.

## Removal readiness matrix

| Area | Current state | Removal readiness | Next safe action |
| --- | --- | --- | --- |
| Mission 2 terminal tutorial glue | Removed from generic scan/hack/read-terminal paths. | Ready. | Old Mission 2 tutorial resources can be deleted later only with broader mission resource cleanup. Do not remove Info-Key/digital record mechanics. |
| Mission 4 hidden-route story glue | Removed from goal hints, exit gating, completion message, auto field setup, pickup hints, and discovery side effects. | Ready. | Old Mission 4 story resources can be deleted later. Keep hidden/reveal/X-Ray/Route Data mechanics and debug placement. |
| Mission 7 cable/socket/powered-gate | Isolated behind `BipobLegacyCableFlowService`, but still hardcoded to Mission 7 state, positions, and `cable_a`. PR-RF-20 adds a generic runtime cable/socket/power contract document, PR-RF-22 adds a parser-safe data/state helper only, PR-RF-23 adds a data-only service skeleton, and PR-RF-24 adds non-gameplay checks only. No generic behavior integration exists yet. | Not ready for deletion. | Implement and smoke-test a generic runtime cable/socket/power service before deleting old Mission 7 layout/state. |
| Mission 8 fan/platform/airflow/cooling | Isolated behind `BipobLegacyAirflowFlowService`, but still hardcoded to Mission 8 state, positions, airflow cells, terminal cooling/hack state, and direct door mutation. PR-RF-21 adds a generic runtime fan/platform/airflow/cooling contract document, but no generic implementation exists yet. | Not ready for deletion. | Implement and smoke-test a generic runtime fan/platform/airflow/cooling service before deleting old Mission 8 layout/state. |
| TASK TEST startup/restart/reset | Has explicit `start_task_test_session()` / `restart_task_test_session()` / `reset_task_test_session()` entry points, explicit `active_runtime_mode_id` runtime identity in the controller and MissionManager, a neutral `task_test` layout alias, and `mission_10` fallback compatibility. `start_mission(10)` still delegates to `start_task_test_session()` for compatibility, `restart_current_mission()` dispatches to TASK TEST restart when sandbox mode is active, and GameUI mission-result restart calls the TASK TEST restart/reset boundary before legacy mission-id restart fallback. Raw GameUI TASK TEST mission-index checks are centralized behind `_is_task_test_runtime_active()` and controller helper calls. | Partially ready. | Keep proving TASK TEST smoke coverage before deleting mission-index compatibility and old mission resources. |
| TASK TEST completion | Isolated through `complete_sandbox_run()`. | Mostly ready. | Smoke-test sandbox completion. Later route direct TASK TEST callers to `complete_sandbox_run()` and reduce `complete_mission()` compatibility. |
| Mission selection/progression | Still uses `current_mission_index`, `max_mission_index`, `start_mission()`, `complete_legacy_story_mission()`, and legacy hints. | Not ready. | Isolate/remove story mission selection UI/progression after TASK TEST no longer depends on mission index startup. |
| MissionManager | Still owns runtime world-object APIs, TASK TEST compatibility id, layouts, and Map Constructor catalog behavior; TASK TEST seed object construction is now delegated to `TaskTestWorldBuilder`. | Not ready for broad deletion. | Keep reducing MissionManager by separating runtime world-object/catalog responsibilities from story mission responsibilities. |
| Mission resources/scenes/layouts | Still present and should remain until smoke proof exists. | Not ready for broad deletion. | Delete in small PRs only after TASK TEST no longer references story mission startup/layout assumptions. |

## Remaining blockers before deleting old mission resources

1. **TASK TEST still retains mission index compatibility state.**
   - `start_task_test_session()` now owns TASK TEST startup and sets explicit runtime mode state.
   - `restart_task_test_session()` / `reset_task_test_session()` own TASK TEST restart/reset and are used before falling back to legacy mission restart wrappers, including GameUI mission-result restart.
   - `start_mission(10)` delegates to `start_task_test_session()` for compatibility.
   - `current_mission_index` remains compatibility state for progression, hints, and legacy story branches.
   - `task_test` is now the neutral TASK TEST layout/catalog alias, while `mission_10` remains the compatibility fallback id.

2. **Mission 7 cable mechanics are not generic yet.**
   - `BipobLegacyCableFlowService` preserves behavior but still uses hardcoded Mission 7 state, positions, tile mutations, and `cable_a`.
   - PR-RF-20 documents the generic cable/socket/power contract, PR-RF-22 adds a parser-safe data/state helper only, PR-RF-23 adds a data-only service skeleton, and PR-RF-24 adds non-gameplay checks only; deleting Mission 7 before a generic behavior implementation exists still risks losing reusable cable mechanics.

3. **Mission 8 airflow mechanics are not generic yet.**
   - `BipobLegacyAirflowFlowService` preserves behavior but still uses hardcoded Mission 8 state, positions, airflow tiles, and door mutation.
   - PR-RF-21 documents the generic fan/platform/airflow/cooling contract, but deleting Mission 8 before a generic implementation exists still risks losing reusable cooling/airflow mechanics.

4. **Legacy story completion/progression remains.**
   - `complete_legacy_story_mission()` still owns old mission completion messages/progression behavior.
   - `complete_mission()` remains a compatibility wrapper.
   - Old mission selection/progression should not be deleted until TASK TEST/session startup is fully independent.

5. **MissionManager still mixes runtime infrastructure and mission compatibility.**
   - It should not be broadly deleted.
   - TASK TEST seed world-object construction now lives in `TaskTestWorldBuilder`, but runtime world-object/catalog/Map Constructor responsibilities must remain available to TASK TEST.

## Recommended next PR sequence

### PR-RF-18 — Introduce non-story TASK TEST layout id alias

Status: completed. TASK TEST now exposes `task_test` as the neutral layout/catalog alias, MissionManager and the mission catalog resolve that alias to the existing `mission_10` layout data, and `mission_10` remains accepted as the compatibility id. No mission resources were deleted or renamed.

### PR-RF-19 — Split sandbox session state from `current_mission_index`

Goal: introduce an explicit sandbox session field/state so TASK TEST does not depend on mission index internally.

Status: completed for the startup dependency direction. `BipobController.active_runtime_mode_id` now owns the active controller runtime identity when set, `start_task_test_session()` starts TASK TEST directly through the shared runtime-start helper, and `start_mission(10)` delegates back to `start_task_test_session()` for compatibility. `current_mission_index` remains set to `10` during TASK TEST only as compatibility state, not as the sole source of sandbox identity.

### PR-RF-25 — Isolate TASK TEST restart/reset from legacy mission restart

Status: completed for the restart/reset dependency direction. `restart_task_test_session()` is the explicit TASK TEST restart entry point, `reset_task_test_session()` aliases that path, `restart_current_mission()` now dispatches to TASK TEST restart when sandbox mode is active, and `restart_legacy_story_mission()` preserves the old story restart behavior for compatibility. TASK TEST still keeps `current_mission_index = 10` only as compatibility state.


### PR-RF-26 — Route mission-result TASK TEST restart through sandbox boundary

Status: completed for the mission-result UI restart dependency direction. GameUI now detects TASK TEST through `_is_task_test_runtime_active()` on the result screen, calls `restart_task_test_session()` or `reset_task_test_session()` for TASK TEST, and leaves the raw `restart_mission_id` / `current_mission_index` mutation / `start_mission(restart_mission_id, true)` path as legacy story compatibility only.

### PR-RF-30 — Extract TASK TEST world-object builder from MissionManager

Status: completed. `scripts/game/task_test_world_builder.gd` now owns the behavior-equivalent TASK TEST seed object and item construction. MissionManager keeps the existing TASK TEST setup and validation methods as wrappers, preserving runtime startup, Map Constructor validation/build callers, `task_test`, and `mission_10` compatibility without deleting old mission resources.

### PR-RF-20 — Generic runtime cable/socket/power contract planning

Goal: prepare Mission 7 deletion by defining the non-story home for cable/socket/power mechanics.

Completed scope:

- Added `docs/bipob_generic_cable_socket_power_contract.md` as the generic cable/socket/power runtime contract.
- Identified required runtime roles, world-object properties, actions, service responsibilities, legacy Mission 7 field mappings, migration stages, and future acceptance smoke.
- Kept `BipobLegacyCableFlowService` and old Mission 7 resources in place. Mission 7 deletion remains blocked until TASK TEST can exercise generic cable behavior through an implemented runtime service.

### PR-RF-22 — Generic cable runtime data/state helper

Goal: add a parser-safe data normalization layer for future generic cable/socket/power runtime work without wiring gameplay behavior.

Completed scope:

- Added `scripts/game/bipob_cable_runtime_state.gd` as a data-only `BipobCableRuntimeState` helper.
- Supported dictionary serialization/deserialization and read-only legacy Mission 7 snapshot creation.
- Kept `BipobLegacyCableFlowService` as the behavior owner. Mission 7 deletion remains blocked because no generic cable runtime behavior is integrated yet.

### PR-RF-23 — Generic cable runtime service skeleton

Goal: add the first generic service boundary for cable/socket/power runtime state transitions without gameplay wiring.

Completed scope:

- Added `scripts/game/bipob_cable_runtime_service.gd` as a parser-safe, data-only `BipobCableRuntimeService` skeleton operating on `BipobCableRuntimeState`.
- Kept the service unwired from TASK TEST, Map Constructor, Mission 7, movement, inventory, interact, power, scan/hack, UI, and cable path drawing/clearing.
- Kept `BipobLegacyCableFlowService` as the Mission 7 cable/socket/powered-gate behavior owner. Mission 7 deletion remains blocked because the generic service is not integrated into gameplay yet.

### PR-RF-24 — Generic cable runtime non-gameplay checks

Goal: prove the parser-safe generic cable runtime state/helper and service skeleton have predictable data-only behavior before gameplay wiring.

Completed scope:

- Added `tools/ci/check_bipob_cable_runtime_service.gd` to validate empty state status, dictionary serialization roundtrip, cloned start-drag/connect/release/clear-path transitions, path extension rules, max-length handling, and legacy Mission 7 dictionary snapshot reads.
- Kept the check script independent of gameplay scenes, `BipobController`, `MissionManager`, runtime grid/tile state, UI, signals, TASK TEST mechanics, Map Constructor behavior, Mission 7 behavior, movement, inventory, interact, power, and scan/hack.
- Kept `BipobLegacyCableFlowService` as the Mission 7 cable/socket/powered-gate behavior owner. Mission 7 deletion remains blocked because the generic service is checked but still not integrated into gameplay.

### PR-RF-21 — Generic runtime fan/platform/airflow/cooling contract planning

Goal: prepare Mission 8 deletion by defining the non-story home for fan/platform/airflow/cooling mechanics.

Completed scope:

- Added `docs/bipob_generic_airflow_cooling_contract.md` as the generic fan/platform/airflow/cooling runtime contract.
- Identified required runtime roles, world-object properties, actions, service responsibilities, legacy Mission 8 field mappings, migration stages, and future acceptance smoke.
- Kept `BipobLegacyAirflowFlowService` and old Mission 8 resources in place. Mission 8 deletion remains blocked until TASK TEST can exercise generic fan/platform/airflow/cooling behavior through an implemented runtime service.

### Later deletion PRs

Only after the above boundaries pass smoke:

- Delete old Mission 2/4 resources and story-only references.
- Delete legacy story mission selection/progression UI.
- Delete old Mission 1-9 resources in small batches.
- Delete `complete_legacy_story_mission()` after no old story callers remain.
- Delete `BipobLegacyCableFlowService` only after the PR-RF-20 contract is implemented by a generic cable runtime and TASK TEST generic cable/socket/power smoke passes.
- Delete `BipobLegacyAirflowFlowService` only after generic airflow runtime replaces it.

## Do-not-delete list for now

Do not delete these yet:

- `MissionManager` as a whole.
- TASK TEST / `task_test` alias and `mission_10` compatibility layout/catalog data.
- Map Constructor catalog/preset/patch APIs.
- WorldObjectCatalog / InteractionSystem / PowerSystem runtime APIs.
- Scan/hack services and digital record storage.
- Inventory pickup/drop/storage helpers.
- Movement controller and runtime action presenter.
- `BipobLegacyCableFlowService` until the PR-RF-20 generic cable/socket/power contract has an implemented and smoke-tested runtime service.
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
