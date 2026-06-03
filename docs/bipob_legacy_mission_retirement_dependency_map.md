# BIPOB legacy mission retirement dependency map

PR-RF-08 through PR-RF-26 prepare legacy story missions for future removal without deleting shared mechanics or mission resources. The active product surface remains TASK TEST / Map Constructor / runtime sandbox.

## Classification key

- **Reusable mechanic, must keep** — behavior that can remain useful for TASK TEST, Map Constructor, runtime sandbox, or future missions, but may need a better runtime service home later.
- **Story glue, safe to remove later** — behavior tied only to old story/career missions and not required by TASK TEST once old missions are retired.
- **Story glue still blocking TASK TEST safety, needs extraction first** — old story branch touches generic paths or shared mechanics strongly enough that it should be extracted or replaced by runtime world-object contracts before deletion.
- **Unknown, keep for now** — insufficient proof to delete safely in this PR.

## Runtime and compatibility boundaries added through PR-RF-26

`scripts/bipob/bipob_controller.gd` now exposes explicit runtime and legacy wrappers so external reusable services do not need direct story mission checks:

- `BipobController.active_runtime_mode_id` stores the explicit active controller runtime identity when a runtime session starts; `MissionManager.active_runtime_mode_id` mirrors mode identity from the active mission/layout id for manager helpers.
- `get_runtime_mode_id()` prefers `active_runtime_mode_id` and falls back to `current_mission_index` only for compatibility.
- `is_task_test_mode_active()` and `is_sandbox_mode_active()` identify the active TASK TEST / runtime sandbox surface without requiring mission `10` to be the sole source of truth.
- `start_task_test_session()`, `restart_task_test_session()`, and `reset_task_test_session()` provide explicit TASK TEST session boundaries, while `start_mission(10)` delegates to `start_task_test_session()` as compatibility.
- `get_task_test_mission_id()` keeps `mission_10` as the compatibility mission id, while `get_task_test_layout_id()` names the neutral `task_test` layout/catalog alias so UI callers do not depend on raw mission index `10`.
- GameUI gates TASK TEST / Map Constructor runtime-only actions through `_is_task_test_runtime_active()`, which uses controller runtime identity first and confines the raw mission-index fallback to that helper boundary.
- `restart_current_mission()` remains a compatibility dispatcher: it calls `restart_task_test_session()` when sandbox mode is active and otherwise calls `restart_legacy_story_mission()` for old story flow.
- GameUI mission-result restart now uses `_is_task_test_runtime_active()` and the explicit TASK TEST restart/reset methods before any mission-id restart fallback, so remaining `restart_mission_id`, `current_mission_index`, and `start_mission(restart_mission_id, true)` result-screen paths are legacy-story compatibility only.
- `is_legacy_story_mission_active()` separates missions `1..9` from TASK TEST sandbox mode.
- `is_legacy_mission7_cable_flow_active()` and `is_legacy_mission7_cable_drag_active()` name the cable path branch.
- `is_legacy_mission8_airflow_flow_active()` names the fan/platform/airflow branch.
- `unlock_airflow_terminal_path()` preserves the reusable airflow-terminal unlock effect; `complete_legacy_mission8_airflow_terminal_hack()` remains as a compatibility wrapper and does not complete a mission.
- `is_sandbox_completion_cell()` and `complete_sandbox_run()` isolate TASK TEST / runtime sandbox exit completion from legacy story mission progression.
- `complete_legacy_story_mission()` contains the remaining old story completion message/progression branch, while `complete_mission()` remains only as a compatibility wrapper that routes by runtime mode.

These wrappers are compatibility boundaries only. PR-RF-10 neutralizes legacy completion side effects in generic scan/hack/read-terminal flows while preserving shared mechanics for later extraction. PR-RF-11 isolates the old Mission 7 cable reel/socket/powered-gate implementation behind `scripts/game/bipob_legacy_cable_flow_service.gd`; the hardcoded Mission 7 state remains legacy. PR-RF-20 adds `docs/bipob_generic_cable_socket_power_contract.md` as the planned generic runtime replacement contract for that reusable cable/socket/power concept, PR-RF-22 adds `scripts/game/bipob_cable_runtime_state.gd` as a parser-safe data-state helper only, PR-RF-23 adds `scripts/game/bipob_cable_runtime_service.gd` as a data-only service skeleton, and PR-RF-24 adds `tools/ci/check_bipob_cable_runtime_service.gd` as non-gameplay checks for generic cable runtime state/service transitions. Generic cable gameplay integration and TASK TEST smoke coverage are still required before deletion. PR-RF-12 isolates the old Mission 8 fan/platform/airflow/terminal implementation behind `scripts/game/bipob_legacy_airflow_flow_service.gd`; the hardcoded Mission 8 state remains legacy. PR-RF-21 adds `docs/bipob_generic_airflow_cooling_contract.md` as the planned generic runtime replacement contract for that reusable fan/platform/airflow/cooling concept, but implementation and TASK TEST smoke coverage are still required before deletion. PR-RF-13 removes the retired Mission 2 terminal tutorial predicate, completion no-op wrapper, and generic scan/hack/read-terminal tutorial feedback branches while preserving Info-Key and digital record mechanics. PR-RF-14 removes the retired Mission 4 hidden route story predicate, route-node exit gate, recovered-module story hints, auto hidden-route setup, and Mission 4-specific hidden-route discovery feedback while preserving generic hidden route-node discovery, Scan/X-Ray visibility, Route Data digital records, TASK TEST, and Map Constructor behavior. PR-RF-15 routes exit-tile completion through the sandbox boundary before the legacy story boundary so TASK TEST completion no longer conceptually depends on `complete_mission()` or old story progression. PR-RF-16 adds the explicit TASK TEST startup/session boundary and routes the developer TASK TEST UI start through it while preserving `start_mission(10)` and `mission_10` layout/catalog compatibility. PR-RF-18 introduces the neutral `task_test` layout/catalog alias while preserving `mission_10` fallback compatibility and the existing TASK TEST behavior. PR-RF-19 makes `active_runtime_mode_id` the explicit runtime identity state and flips the startup dependency so `start_mission(10)` is the compatibility wrapper around `start_task_test_session()`. PR-RF-20 and PR-RF-21 are contract/audit work only, PR-RF-22 adds data-state helpers only, PR-RF-23 adds a data-only service skeleton only, and PR-RF-24 adds non-gameplay checks only; none of these changes wires new runtime behavior.

## Removed Mission 2 terminal tutorial glue in PR-RF-13

- `is_legacy_mission2_terminal_tutorial_active()` was removed because no runtime caller remains after deleting the Mission 2 hack/read tutorial branches.
- `complete_legacy_mission_from_story_glue()` was removed because scan/hack/read-terminal no longer call story completion compatibility glue.
- `BipobScanHackService.hack_device()` no longer contains a Mission 2-only terminal tutorial branch; terminal `download_info_key` hacks fall through to the existing generic Info-Key / digital record branch.
- `BipobController.read_terminal()` no longer contains a Mission 2-only terminal calibration tutorial branch; no scan/hack/read-terminal path completes a story mission.
- Info-Key / digital record storage, digital door unlocks, TASK TEST startup, Map Constructor behavior, Mission 7 cable boundaries, and Mission 8 airflow boundaries remain preserved.


## Removed Mission 4 hidden route story glue in PR-RF-14

- `is_legacy_mission4_hidden_route_flow_active()` was removed because no generic runtime caller remains after deleting the Mission 4 hidden route-node story branches.
- `get_mission4_context_hint()` and the Mission 4 goal-hint case were removed so generic goal/help paths no longer emit recovered-module or route-node story guidance.
- Mission start no longer auto-runs `setup_mission4_field_modules()`; the setup helper was removed. Debug-only field module and hidden route-node placement remain available behind their explicit debug exports.
- Exit completion no longer blocks Mission 4 on `mission4_hidden_route_node_discovered`, and the Mission 4-specific completion message was removed from `complete_mission()`. Hidden route-node discovery no longer toggles Mission 4 story state.
- Generic hidden route-node detection still discovers hidden nodes, stores the Route Data digital record, emits the generic detection hint, and refreshes status. Hidden object flags, discovered/revealed state, Scan Device / X-Ray vision behavior, digital records, TASK TEST startup, Map Constructor behavior, Mission 7 cable boundary, and Mission 8 airflow boundary remain preserved.

## Isolated TASK TEST sandbox completion in PR-RF-15

- `check_mission_complete()` now checks the existing exit tile through `is_sandbox_completion_cell()` first, then routes TASK TEST / runtime sandbox completion to `complete_sandbox_run("exit_tile")`.
- `complete_sandbox_run()` preserves the existing TASK TEST completion side effects, including `sector_completed`, `last_diagnostic_result` reset, `status_changed`, `mission_completed`, and the existing TASK TEST completion hint, but it does not run legacy story mission message/progression branches.
- `complete_legacy_story_mission()` keeps the old story mission completion messages and compatibility behavior for missions 1-9.
- `complete_mission()` remains as a public compatibility wrapper and routes by runtime mode instead of serving as the common TASK TEST and story completion implementation.
- Future mission resource or scene deletion should depend on a passing TASK TEST completion smoke test proving sandbox exit completion, Map Constructor entry/exit, runtime Action / Connect / Heavy Claw, scan/hack, and pickup/drop still work without old story mission resources.


## Isolated TASK TEST startup/restart/session boundary through PR-RF-26

- `BipobController.start_task_test_session()` is the public TASK TEST startup entry point. It now sets the TASK TEST runtime mode through the shared runtime-start helper, keeps `current_mission_index = TASK_TEST_MISSION_INDEX` only for compatibility, and preserves behavior, default modules, layout loading, and save-snapshot behavior.
- `BipobController.restart_task_test_session()` is the explicit TASK TEST restart wrapper, and `reset_task_test_session()` is the canonical reset alias for future callers that need to reload the sandbox without naming the legacy mission index.
- `BipobController.get_task_test_mission_id()` exposes the `mission_10` compatibility id, `get_task_test_layout_id()` exposes the neutral `task_test` layout alias through MissionManager, and `get_mission_layout_id()` uses that boundary before falling back to legacy `mission_%d` ids. Remaining `mission_10` references should stay compatibility fallback only, not new UI/runtime gating.
- `MissionManager.get_task_test_mission_id()`, `get_task_test_layout_id()`, and `is_task_test_mission_id()` accept both `task_test` and `mission_10`, keeping `mission_10` as the fallback compatibility id. This PR intentionally does not remove or rename `mission_10` resources.
- `GameUI` starts TASK TEST through `start_task_test_session()` instead of calling the older developer mission-start wrapper directly. The old `start_dev_task_test_mission()` wrapper remains for compatibility and delegates to the new boundary. Mission-result restart also detects TASK TEST with `_is_task_test_runtime_active()` and calls `restart_task_test_session()` / `reset_task_test_session()` instead of mutating `current_mission_index`; the remaining mission-id restart path is legacy-only.
- Remaining blockers before deleting old mission resources: `current_mission_index` still remains compatibility state for story mission flow and some legacy branches, `task_test` is the neutral catalog/layout alias and `mission_10` remains the fallback compatibility id, Mission 7 cable behavior has a generic runtime cable contract plus state helper, service skeleton, and non-gameplay checks but still requires gameplay integration, Mission 8 airflow/cooling still requires a generic runtime airflow contract, and old story mission resources/scenes must remain until a TASK TEST smoke pass proves startup, Map Constructor, runtime actions, scan/hack, inventory, movement, and sandbox completion do not rely on them.

## Remaining usage map

### `scripts/bipob/bipob_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `117` | `current_mission_index` mission selector state. | Story glue still blocking TASK TEST safety, needs extraction first. | PR-RF-16 adds an explicit TASK TEST session boundary, PR-RF-18 adds the `task_test` layout alias, and PR-RF-19 adds `active_runtime_mode_id` so TASK TEST identity no longer depends only on legacy mission numbering. Keep as compatibility until legacy story mission selection/progression is removed. |
| `175-188` | `mission8_*` fan speed/direction, terminal/door positions, and airflow cells. | Story glue still blocking TASK TEST safety, needs extraction first. | Fan/platform/airflow is reusable, but this state is hardcoded to Mission 8 positions. Extract to runtime cooling/airflow world-object state before deleting. |
| `189-195` | `mission7_*` cable drag/connect positions, path, and length. | Story glue still blocking TASK TEST safety, needs extraction first. | Cable/socket/power is reusable, but this state is hardcoded to Mission 7 positions and object IDs. Extract to runtime cable/power state before deleting. |
| `1246-1253` | Remaining legacy wrapper predicates read `current_mission_index`, `mission7_is_dragging_cable`, and Mission 8 activation. The retired Mission 2 tutorial and Mission 4 hidden-route predicates have been removed. | Story glue, safe to remove later. | Remaining wrappers intentionally isolate direct Mission 7/8 checks. Remove with old missions after callers move to runtime contracts. |
| `1280-1284` | `unlock_airflow_terminal_path()` and `complete_legacy_mission8_airflow_terminal_hack()` are compatibility wrappers that delegate through `BipobLegacyAirflowFlowService`. | Isolated legacy boundary, safe to remove after replacement. | The generic hack flow still calls the controller wrapper. Replace the service's hardcoded Mission 8 tile mutation with a runtime Action/Hack result that mutates a world object or connection target before deleting the old Mission 8 state. |
| `1261-1262` | Current goal hint delegates to the legacy mission hint table, with the retired Mission 4 hidden-route story hint removed. | Story glue, safe to remove later. | TASK TEST should eventually use runtime objective/help text independent of story missions. |
| `1277-1307`, `1383`, `1386`, `1449-1450` | Mission start/restart/progression uses `current_mission_index`; TASK TEST startup/restart/reset now has `start_task_test_session()` / `restart_task_test_session()` / `reset_task_test_session()` wrappers, GameUI result-screen restart routes TASK TEST through those wrappers, GameUI TASK TEST runtime gating goes through `_is_task_test_runtime_active()`, and explicit `active_runtime_mode_id` runtime identity plus layout-id helpers exist in the controller and MissionManager; `restart_current_mission()` dispatches by sandbox runtime mode before legacy restart; `task_test` resolves through the existing `mission_10` layout fallback. | TASK TEST session boundary partially isolated. | `start_mission(10)` and `mission_10` compatibility still work, but `start_mission(10)` is now a wrapper around `start_task_test_session()`, TASK TEST restart/reset can avoid the legacy restart path, and remaining `mission_10` checks should be compatibility fallback only. Future removal can target remaining mission-index compatibility after TASK TEST smoke coverage. |
| `1323` | Mission 7 cable state reset on mission start now delegates to `BipobLegacyCableFlowService.reset_legacy_state()`. | Isolated legacy boundary, safe to remove later. | Hardcoded Mission 7 state is still legacy and removable only after the generic cable runtime is wired into gameplay; PR-RF-23 provides a service skeleton and PR-RF-24 provides non-gameplay checks, but no gameplay integration exists, so Mission 7 is not ready for deletion. |
| `1297-1303` | Mission-specific setup dispatch for Missions 7, 8, and 9; Mission 4 hidden-route auto setup has been removed. | Story glue, safe to remove later. | Remove with old mission layouts after TASK TEST startup no longer depends on this switch. |
| `1395-1396` | Return-to-box releases active Mission 7 cable drag through wrapper. | Story glue, safe to remove later. | Keep until cable drag is extracted or old mission return flow is removed. |
| `1408` | Mission 9 return-to-box context hint. | Story glue, safe to remove later. | Old story hint only. |
| `6576-6583` | Exit completion routing checks sandbox completion first, then legacy story completion. | TASK TEST sandbox boundary isolated. | Keep this routing while TASK TEST still uses the existing exit tile; future objective systems can replace the sandbox predicate without touching legacy story progression. |
| `6585-6635` | `is_sandbox_completion_cell()` and `complete_sandbox_run()` own TASK TEST / runtime sandbox exit completion side effects. | TASK TEST sandbox boundary isolated. | Sandbox completion preserves the existing TASK TEST hint/signals/status behavior and does not advance legacy story mission progression. Smoke TASK TEST completion before deleting old mission resources. |
| `6637-6670` | `complete_legacy_story_mission()` owns remaining old story completion messages; `complete_mission()` remains a compatibility wrapper that routes by runtime mode. | Story glue, safe to remove later. | Remove or narrow only after all old mission callers and resources are retired; TASK TEST should continue to use `complete_sandbox_run()` directly. |
| `7075` | Scan diagnostic checks `mission8_terminal_cooled`. | Story glue still blocking TASK TEST safety, needs extraction first. | Airflow cooled/hot state is reusable; read from runtime cooling state instead of Mission 8 variable. |
| `7800-7824` | Legacy tile interaction dispatches Mission 8 control tiles through controller wrappers, then delegates Mission 7 cable/socket/gate branches to `BipobLegacyCableFlowService.handle_interact_tile()`. | Isolated legacy boundaries, safe to remove after replacement. | Mission 8 fan/platform/airflow and Mission 7 cable/socket/power behavior are preserved behind legacy boundaries. Later work should replace both with data-driven world-object actions/contracts before old missions are deleted. |
| `8299-8341` | Mission 8 setup, fan/platform control, airflow, terminal state, and unlock helpers are compatibility wrappers that delegate through `BipobLegacyAirflowFlowService`; Mission 8 tile branches still call those wrappers. | Isolated legacy boundary, safe to remove after replacement. | Fan/platform/airflow/cooling is reusable and must later move to generic runtime world-object contracts. The hardcoded old Mission 8 state is still legacy and removable after that generic airflow runtime exists. |
| `8358-8359` | Mission 7 cable status text wrapper delegates to `BipobLegacyCableFlowService.get_status_text()`. | Isolated legacy boundary, safe to remove later. | Status text is old mission UI glue. Runtime cable status should come from generic runtime cable state. |
| `8361-8380` | Mission 7 setup, cable reel/socket interactions, path drawing/clearing, and release are compatibility wrappers that delegate to `BipobLegacyCableFlowService`. | Isolated legacy boundary, safe to remove later. | The old implementation still uses hardcoded Mission 7 positions and `cable_a`, but it is no longer inline in `BipobController`. Keep until a generic runtime cable/socket/power contract replaces it. |
| `8644-8661` | `read_terminal()` still switches on `current_mission_index` for the old Mission 3 Info-Key read path, but the retired Mission 2 terminal calibration tutorial branch has been removed. | Retired Mission 2 tutorial glue removed; remaining Mission 3 Info-Key compatibility path preserved. | Generic read-terminal no longer emits Mission 2 tutorial feedback or completes a story mission. Info-Key/digital record storage remains for compatibility. |

### `scripts/game/bipob_legacy_cable_flow_service.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| Entire file | Owns the legacy Mission 7 cable setup, cable reel/socket interactions, cable path drawing/clearing, drop/release behavior, powered-gate tile mutation, `cable_a` power event, status text, and Mission 7 tile interaction result shaping. | Isolated legacy boundary, safe to remove after replacement. | This preserves current Mission 7 behavior without deleting cable/socket/power mechanics. The concepts are reusable and must later move to generic runtime world-object contracts; the hardcoded old Mission 7 state is still legacy and removable after that generic runtime exists. |

### `scripts/game/bipob_legacy_airflow_flow_service.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| Entire file | Owns the legacy Mission 8 fan/platform setup, status text, rotation controls, speed controls, airflow tile drawing/clearing, terminal cooled/hot state, and airflow-terminal door unlock. | Isolated legacy boundary, safe to remove after replacement. | This preserves current Mission 8 behavior without deleting fan/platform/airflow/cooling mechanics. The concepts are reusable and must later move to generic runtime world-object contracts; the hardcoded old Mission 8 state is still legacy and removable after that generic runtime exists. |

### `scripts/game/bipob_scan_hack_service.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `209-217` | `download_info_key` now falls directly through the generic Info-Key / digital record storage path; the retired Mission 2-only tutorial hack branch has been removed. | Retired Mission 2 tutorial glue removed; reusable mechanic preserved. | Generic scan/hack no longer checks `is_legacy_mission2_terminal_tutorial_active()` and no longer calls `complete_legacy_mission_from_story_glue()`. Info-Key digital record storage remains in this branch. |
| `230-237` | Calls `controller.unlock_airflow_terminal_path()` for the airflow-terminal hack effect; the controller wrapper delegates to `BipobLegacyAirflowFlowService`. | Isolated legacy boundary, safe to remove after replacement. | `unlock_airflow_terminal` remains available and does not call `complete_mission()`. Replace the service's hardcoded Mission 8 door state with runtime world-object contracts later. |

### `scripts/bipob/bipob_inventory_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `123-124` | Drop action checks `is_legacy_mission7_cable_drag_active()` and releases the cable through the controller wrapper, which now delegates to `BipobLegacyCableFlowService.release_cable_end()`. | Isolated legacy boundary, safe to remove later. | Generic inventory pickup/drop remains unchanged. Cable-drop behavior is preserved behind the legacy boundary until a generic cable runtime replaces old Mission 7 state. |

### `scripts/bipob/bipob_movement_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `147-148` | Movement checks `is_legacy_mission7_cable_drag_active()` and appends cable path through the controller wrapper, which now delegates to `BipobLegacyCableFlowService.add_current_cell_to_path()`. | Isolated legacy boundary, safe to remove later. | Generic movement remains unchanged. Cable path tracking is preserved behind the legacy boundary until a generic cable-follow runtime replaces old Mission 7 state. |

### `scripts/game/bipob_legacy_tile_interaction_service.gd`

No remaining `current_mission_index`, `mission7_*`, `mission8_*`, or `complete_mission()` usage. This service still contains legacy tile handling, but its current branches are generic digital-device guardrails and not old mission-index glue.

### `scripts/game/mission_manager.gd`

No remaining `current_mission_index`, `mission7_*`, `mission8_*`, or `complete_mission()` usage found in this file. MissionManager still owns runtime world-object APIs and mission layout compatibility, so it should not be broadly deleted in the legacy mission retirement work. PR-RF-16 added `get_task_test_mission_id()`, `get_task_test_layout_id()`, and `is_task_test_mission_id()`; PR-RF-18 updates that boundary so `task_test` is the explicit TASK TEST layout/catalog alias while `mission_10` remains the compatibility fallback id. PR-RF-30 extracts TASK TEST seed object/item construction into `TaskTestWorldBuilder`, leaving MissionManager setup and validation methods as compatibility wrappers for runtime and Map Constructor callers.

## Reusable mechanics that must survive

- Runtime scan/hack command flow and digital record storage. Generic scan/hack no longer completes legacy story missions and no longer contains the Mission 2 terminal tutorial feedback branch. Hidden route-node discovery still stores Route Data as a reusable digital record without Mission 4 story gating.
- Inventory pickup/drop, manipulator hand, and pocket logic.
- Runtime movement/turn/action spending and map constructor startup behavior.
- Cable/socket/power concepts. PR-RF-11 preserves the old Mission 7 implementation behind `BipobLegacyCableFlowService`; PR-RF-20 defines the planned generic runtime replacement contract in `docs/bipob_generic_cable_socket_power_contract.md`; PR-RF-22 adds a generic data-state helper without behavior integration; PR-RF-23 adds a data-only service skeleton; PR-RF-24 adds non-gameplay checks. Future implementation must move the reusable mechanic to generic runtime world-object services before deleting the old Mission 7 state.
- Fan/platform/airflow/cooling concepts. PR-RF-12 preserves the old Mission 8 implementation behind `BipobLegacyAirflowFlowService`; PR-RF-21 defines the planned generic runtime replacement contract in `docs/bipob_generic_airflow_cooling_contract.md`. Future implementation must move the reusable mechanic to generic runtime world-object services before deleting the old Mission 8 state.
- Hidden route-node discovery/revealed state, Scan Device / X-Ray visibility, WorldObjectCatalog, InteractionSystem, PowerSystem, and MissionManager generic runtime APIs.

## Branches that can be deleted after extraction/proof

- Mission 7 hardcoded cable reel/socket/gate setup, status text, and `cable_a` power event now isolated in `BipobLegacyCableFlowService`; do not delete yet. PR-RF-22 adds a data-state helper only, PR-RF-23 adds a data-only service skeleton only, and PR-RF-24 adds non-gameplay checks only, so Mission 7 remains blocked and not ready for deletion. Delete only after the PR-RF-20 generic contract is implemented by gameplay-wired runtime services and TASK TEST cable/socket/power smoke passes.
- Mission 8 hardcoded fan/platform/airflow/terminal setup, status text, controls, airflow tile updates, cooling state, terminal hack state, and door unlock now isolated in `BipobLegacyAirflowFlowService`; do not delete yet. Delete only after the PR-RF-21 generic contract is implemented by runtime services and TASK TEST fan/platform/airflow/cooling smoke passes.
- Mission-specific completion messages/progression now live in `complete_legacy_story_mission()`; delete after old story mission callers/resources are retired and TASK TEST sandbox completion smoke passes.

## TASK TEST safety notes

- PR-RF-08 does not delete resources, scenes, setup data, cable/socket/power behavior, fan/platform/airflow behavior, scan/hack, inventory, or MissionManager.
- PR-RF-10 removes legacy mission completion from generic scan/hack/read-terminal flows while preserving TASK TEST startup, Map Constructor, scan/hack mechanics, Info-Key storage, digital doors, hot nodes, airflow terminal unlock, cable/socket/power, inventory, and movement behavior.
- PR-RF-11 moves legacy Mission 7 cable/socket/powered-gate flow behind `BipobLegacyCableFlowService` while preserving TASK TEST, Map Constructor, scan/hack, inventory, movement, and old Mission 7 behavior.
- PR-RF-12 moves legacy Mission 8 fan/platform/airflow/terminal flow behind `BipobLegacyAirflowFlowService` while preserving TASK TEST, Map Constructor, scan/hack, inventory, movement, and old Mission 8 behavior.
- PR-RF-13 removes the retired Mission 2 terminal tutorial hack/read branches, `is_legacy_mission2_terminal_tutorial_active()`, and `complete_legacy_mission_from_story_glue()` while preserving generic scan/hack, terminal, Info-Key, digital record, digital door, TASK TEST, and Map Constructor behavior.
- PR-RF-14 removes retired Mission 4 hidden route-node story gating, recovered-module hints, Mission 4 hidden-route completion gating, and Mission 4-specific hidden-route discovery feedback while preserving generic hidden/reveal/Scan/X-Ray mechanics, Route Data digital records, TASK TEST, Map Constructor, Mission 7 cable boundaries, and Mission 8 airflow boundaries.
- PR-RF-15 isolates TASK TEST exit completion behind `complete_sandbox_run()` while preserving the existing TASK TEST completion hint, `sector_completed`, `status_changed`, and `mission_completed` behavior. Legacy story completion/progression remains available through `complete_legacy_story_mission()` and the `complete_mission()` compatibility wrapper.
- PR-RF-16 isolates TASK TEST startup/session calls behind `start_task_test_session()` and `reset_task_test_session()` while preserving `start_mission(10)` compatibility; PR-RF-18 adds the `task_test` catalog/layout alias and preserves `mission_10` fallback compatibility; PR-RF-25 adds `restart_task_test_session()` and routes sandbox restart/reset through the explicit TASK TEST boundary while preserving legacy restart compatibility; PR-RF-26 extends that isolation to the GameUI mission-result restart path and keeps raw mission-id restart handling legacy-only; PR-RF-27 centralizes remaining GameUI TASK TEST mission-index fallback inside `_is_task_test_runtime_active()` and uses controller helpers for TASK TEST compatibility ids.
- PR-RF-20 adds cable/socket/power contract planning only; PR-RF-22 adds generic cable data/state helpers only; PR-RF-23 adds a generic cable service skeleton only; PR-RF-24 adds non-gameplay state/service checks only. Mission 7 is not ready for deletion until the planned generic runtime replacement is wired into gameplay and passes TASK TEST smoke.
- PR-RF-21 adds fan/platform/airflow/cooling contract planning only; Mission 8 is not ready for deletion until the planned generic runtime replacement exists and passes TASK TEST smoke. Future removal PRs should first prove TASK TEST startup, sandbox exit completion, Map Constructor entry/exit, runtime Action / Connect / Heavy Claw, scan/hack, pickup/drop, generic cable/socket/power paths, and generic fan/platform/airflow/cooling paths no longer require old mission-index branches, then replace the `mission_10` compatibility layout id with a non-story sandbox layout id.

## PR-RF-31 update — TASK TEST objective text boundary

TASK TEST objective text is now separated from the legacy story mission hint dependency through a thin helper chain:

1. `MissionContentCatalog` keeps canonical `task_test` `goal_text` and `objective_hint` data, with `mission_10` accepted as an alias.
2. `MissionManager.get_task_test_goal_text()` and `MissionManager.get_task_test_objective_hint()` read that catalog data directly.
3. `BipobController.get_task_test_goal_text()` and `BipobController.get_task_test_objective_hint()` provide UI-safe wrappers.
4. `GameUI` chooses this TASK TEST boundary via `_is_task_test_runtime_active()` before falling back to legacy objective view-model / story hint behavior.

This removes TASK TEST objective UI from the old numeric mission hint table without deleting the table, `current_mission_index`, or `mission_10` compatibility. Remaining legacy mission retirement work should keep old story hints available until story mission resources and selection/progression UI are removed in later focused PRs.
