# BIPOB legacy mission retirement dependency map

PR-RF-08 through PR-RF-10 prepare legacy story missions for future removal without deleting shared mechanics or mission resources. The active product surface remains TASK TEST / Map Constructor / runtime sandbox.

## Classification key

- **Reusable mechanic, must keep** — behavior that can remain useful for TASK TEST, Map Constructor, runtime sandbox, or future missions, but may need a better runtime service home later.
- **Story glue, safe to remove later** — behavior tied only to old story/career missions and not required by TASK TEST once old missions are retired.
- **Story glue still blocking TASK TEST safety, needs extraction first** — old story branch touches generic paths or shared mechanics strongly enough that it should be extracted or replaced by runtime world-object contracts before deletion.
- **Unknown, keep for now** — insufficient proof to delete safely in this PR.

## Boundary wrappers added in PR-RF-08 and PR-RF-09

`scripts/bipob/bipob_controller.gd` now exposes explicit runtime and legacy wrappers so external reusable services do not need direct story mission checks:

- `get_runtime_mode_id()` returns the explicit runtime mode identity.
- `is_task_test_mode_active()` and `is_sandbox_mode_active()` identify the active TASK TEST / runtime sandbox surface while mission `10` remains the compatibility source.
- `is_legacy_story_mission_active()` separates missions `1..9` from TASK TEST sandbox mode.
- `is_legacy_mission2_terminal_tutorial_active()` names the old terminal calibration branch.
- `is_legacy_mission4_hidden_route_flow_active()` names the hidden route-node branch.
- `is_legacy_mission7_cable_flow_active()` and `is_legacy_mission7_cable_drag_active()` name the cable path branch.
- `is_legacy_mission8_airflow_flow_active()` names the fan/platform/airflow branch.
- `complete_legacy_mission_from_story_glue()` is now a compatibility no-op so deprecated story tutorial callers cannot complete missions from generic runtime flows.
- `unlock_airflow_terminal_path()` preserves the reusable airflow-terminal unlock effect; `complete_legacy_mission8_airflow_terminal_hack()` remains as a compatibility wrapper and does not complete a mission.

These wrappers are compatibility boundaries only. PR-RF-10 neutralizes legacy completion side effects in generic scan/hack/read-terminal flows while preserving shared mechanics for later extraction.

## Remaining usage map

### `scripts/bipob/bipob_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `117` | `current_mission_index` mission selector state. | Story glue still blocking TASK TEST safety, needs extraction first. | Keep until TASK TEST no longer boots through legacy mission numbering and mission selection is separated from runtime sandbox state. |
| `175-188` | `mission8_*` fan speed/direction, terminal/door positions, and airflow cells. | Story glue still blocking TASK TEST safety, needs extraction first. | Fan/platform/airflow is reusable, but this state is hardcoded to Mission 8 positions. Extract to runtime cooling/airflow world-object state before deleting. |
| `189-195` | `mission7_*` cable drag/connect positions, path, and length. | Story glue still blocking TASK TEST safety, needs extraction first. | Cable/socket/power is reusable, but this state is hardcoded to Mission 7 positions and object IDs. Extract to runtime cable/power state before deleting. |
| `1243-1259` | Legacy wrapper predicates read `current_mission_index`, `mission7_is_dragging_cable`, and Mission 8 activation. | Story glue, safe to remove later. | These wrappers intentionally isolate direct checks. Remove with old missions after callers move to runtime contracts. |
| `1281-1285` | `complete_legacy_mission_from_story_glue()` is a no-op compatibility wrapper. | Retired/neutralized story completion side effect. | Mission completion is no longer triggered from old terminal tutorial scan/hack/read-terminal branches. Remove the wrapper after legacy callers are gone. |
| `1287-1297` | `unlock_airflow_terminal_path()` sets `mission8_terminal_hacked` and opens `mission8_door_position`; `complete_legacy_mission8_airflow_terminal_hack()` delegates to it without mission completion. | Story glue still blocking TASK TEST safety, needs extraction first. | The generic hack flow now calls the reusable unlock helper directly. Replace the hardcoded Mission 8 tile mutation with a runtime Action/Hack result that mutates a world object or connection target. |
| `1273` | Current goal hint delegates to legacy mission hint table. | Story glue, safe to remove later. | TASK TEST should eventually use runtime objective/help text independent of story missions. |
| `1277`, `1301`, `1306`, `1383`, `1386`, `1449-1450` | Mission start/restart/progression uses `current_mission_index`. | Story glue still blocking TASK TEST safety, needs extraction first. | TASK TEST currently depends on mission `10` compatibility. Replace with sandbox session startup before removing. |
| `1294-1299` | Mission 7 cable state reset on mission start. | Story glue, safe to remove later. | Safe after Mission 7 cable flow is removed or extracted to runtime cable state. |
| `1314-1318` | Mission-specific setup dispatch for Missions 7, 8, and 9. | Story glue, safe to remove later. | Remove with old mission layouts after TASK TEST startup no longer depends on this switch. |
| `1395-1396` | Return-to-box releases active Mission 7 cable drag through wrapper. | Story glue, safe to remove later. | Keep until cable drag is extracted or old mission return flow is removed. |
| `1408` | Mission 9 return-to-box context hint. | Story glue, safe to remove later. | Old story hint only. |
| `6605`, `6607`, `6627-6649` | Exit completion and `complete_mission()` message/progression logic. | Story glue still blocking TASK TEST safety, needs extraction first. | TASK TEST uses completion compatibility. Isolate runtime sandbox completion before deleting mission-completion flow. |
| `7075` | Scan diagnostic checks `mission8_terminal_cooled`. | Story glue still blocking TASK TEST safety, needs extraction first. | Airflow cooled/hot state is reusable; read from runtime cooling state instead of Mission 8 variable. |
| `7777-7802` | Legacy tile interaction dispatches Mission 8 controls and Mission 7 cable/socket/gate branches. | Story glue still blocking TASK TEST safety, needs extraction first. | The mechanics are reusable, but dispatch should be driven by world-object actions/contracts. |
| `8286-8300` | `setup_mission8()` hardcodes fan/platform/terminal/door positions and resets Mission 8 airflow state. | Story glue still blocking TASK TEST safety, needs extraction first. | Extract fan/platform/airflow setup to data-driven world objects before deleting. |
| `8327-8336` | Mission 8 airflow status text uses wrapper and Mission 8 state. | Story glue, safe to remove later. | Status text is old mission UI glue. Runtime devices should present status through generic panels. |
| `8339-8346` | Mission 7 cable status text uses wrapper and Mission 7 state. | Story glue, safe to remove later. | Status text is old mission UI glue. Runtime cable status should come from generic runtime state. |
| `8349-8425` | Mission 7 setup, cable reel/socket interactions, path drawing/clearing, and release. | Story glue still blocking TASK TEST safety, needs extraction first. | Cable dragging/path/socket/power event is reusable, but hardcoded positions and `cable_a` must be extracted before removal. |
| `8429-8567` | Mission 8 terminal state text, fan rotation/speed controls, airflow range, and airflow tile updates. | Story glue still blocking TASK TEST safety, needs extraction first. | Fan/platform/airflow is reusable, but must move to runtime cooling/airflow service and world-object contracts. |
| `8857-8883` | `read_terminal()` switches on `current_mission_index`; Mission 2 now emits tutorial feedback only and no longer completes a mission. | Retired/neutralized story completion side effect. | Old terminal tutorial/info-key branch remains for compatibility. Scan/Hack and digital record mechanics must remain. |

### `scripts/game/bipob_scan_hack_service.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `213-218` | Uses `is_legacy_mission2_terminal_tutorial_active()` for the old terminal tutorial branch, but only emits feedback/status. | Retired/neutralized story completion side effect. | Generic scan/hack no longer calls `complete_legacy_mission_from_story_glue()`. The reusable `download_info_key` action and Info-Key digital record storage remain below this branch. |
| `239` | Calls `unlock_airflow_terminal_path()` for the airflow-terminal hack effect. | Reusable mechanic with legacy hardcoded state still needing extraction. | `unlock_airflow_terminal` remains available and does not call `complete_mission()`. Replace the hardcoded Mission 8 door state with runtime world-object contracts later. |

### `scripts/bipob/bipob_inventory_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `123-124` | Drop action checks `is_legacy_mission7_cable_drag_active()` and releases the cable. | Story glue, safe to remove later. | Generic inventory pickup/drop remains. Cable-drop behavior should move to runtime cable service before Mission 7 removal if cable survives. |

### `scripts/bipob/bipob_movement_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `147-148` | Movement checks `is_legacy_mission7_cable_drag_active()` and appends cable path. | Story glue still blocking TASK TEST safety, needs extraction first. | Generic movement remains. Cable path tracking is reusable but should be extracted from movement into a runtime cable-follow service. |

### `scripts/game/bipob_legacy_tile_interaction_service.gd`

No remaining `current_mission_index`, `mission7_*`, `mission8_*`, or `complete_mission()` usage. This service still contains legacy tile handling, but its current branches are generic digital-device guardrails and not old mission-index glue.

### `scripts/game/mission_manager.gd`

No remaining `current_mission_index`, `mission7_*`, `mission8_*`, or `complete_mission()` usage found in this file. MissionManager still owns runtime world-object APIs and mission layout compatibility, so it should not be broadly deleted in the legacy mission retirement work.

## Reusable mechanics that must survive

- Runtime scan/hack command flow and digital record storage. Generic scan/hack no longer completes legacy story missions.
- Inventory pickup/drop, manipulator hand, and pocket logic.
- Runtime movement/turn/action spending and map constructor startup behavior.
- Cable/socket/power concepts, after extraction from Mission 7 hardcoded positions/object IDs.
- Fan/platform/airflow/cooling concepts, after extraction from Mission 8 hardcoded positions/state.
- WorldObjectCatalog, InteractionSystem, PowerSystem, and MissionManager generic runtime APIs.

## Branches that can be deleted after extraction/proof

- Mission 2 terminal calibration completion side effect is retired/neutralized; remaining compatibility feedback can be deleted with the old terminal tutorial branch.
- Mission 4 hidden route-node story gating and recovered-module hints.
- Mission 7 hardcoded cable reel/socket/gate setup and status text, after cable mechanics are represented by runtime services.
- Mission 8 hardcoded fan/platform/airflow/terminal setup and status text, after airflow mechanics are represented by runtime services.
- Mission-specific completion messages/progression after TASK TEST has standalone sandbox objective handling.

## TASK TEST safety notes

- PR-RF-08 does not delete resources, scenes, setup data, cable/socket/power behavior, fan/platform/airflow behavior, scan/hack, inventory, or MissionManager.
- PR-RF-10 removes legacy mission completion from generic scan/hack/read-terminal flows while preserving TASK TEST startup, Map Constructor, scan/hack mechanics, Info-Key storage, digital doors, hot nodes, airflow terminal unlock, cable/socket/power, inventory, and movement behavior.
- Future removal PRs should first prove TASK TEST startup, runtime Action / Connect / Heavy Claw, scan/hack, and pickup/drop paths no longer require old mission-index branches.
