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

These wrappers are compatibility boundaries only. PR-RF-10 neutralizes legacy completion side effects in generic scan/hack/read-terminal flows while preserving shared mechanics for later extraction. PR-RF-11 isolates the old Mission 7 cable reel/socket/powered-gate implementation behind `scripts/game/bipob_legacy_cable_flow_service.gd`; the hardcoded Mission 7 state remains legacy, but the reusable cable/socket/power concept is preserved for a future generic runtime world-object contract. PR-RF-12 isolates the old Mission 8 fan/platform/airflow/terminal implementation behind `scripts/game/bipob_legacy_airflow_flow_service.gd`; the hardcoded Mission 8 state remains legacy, but the reusable fan/platform/airflow/cooling concept is preserved for a future generic runtime world-object contract.

## Remaining usage map

### `scripts/bipob/bipob_controller.gd`

| Location | Usage | Classification | Retirement note |
| --- | --- | --- | --- |
| `117` | `current_mission_index` mission selector state. | Story glue still blocking TASK TEST safety, needs extraction first. | Keep until TASK TEST no longer boots through legacy mission numbering and mission selection is separated from runtime sandbox state. |
| `175-188` | `mission8_*` fan speed/direction, terminal/door positions, and airflow cells. | Story glue still blocking TASK TEST safety, needs extraction first. | Fan/platform/airflow is reusable, but this state is hardcoded to Mission 8 positions. Extract to runtime cooling/airflow world-object state before deleting. |
| `189-195` | `mission7_*` cable drag/connect positions, path, and length. | Story glue still blocking TASK TEST safety, needs extraction first. | Cable/socket/power is reusable, but this state is hardcoded to Mission 7 positions and object IDs. Extract to runtime cable/power state before deleting. |
| `1243-1259` | Legacy wrapper predicates read `current_mission_index`, `mission7_is_dragging_cable`, and Mission 8 activation. | Story glue, safe to remove later. | These wrappers intentionally isolate direct checks. Remove with old missions after callers move to runtime contracts. |
| `1281-1285` | `complete_legacy_mission_from_story_glue()` is a no-op compatibility wrapper. | Retired/neutralized story completion side effect. | Mission completion is no longer triggered from old terminal tutorial scan/hack/read-terminal branches. Remove the wrapper after legacy callers are gone. |
| `1287-1291` | `unlock_airflow_terminal_path()` and `complete_legacy_mission8_airflow_terminal_hack()` are compatibility wrappers that delegate through `BipobLegacyAirflowFlowService`. | Isolated legacy boundary, safe to remove after replacement. | The generic hack flow still calls the controller wrapper. Replace the service's hardcoded Mission 8 tile mutation with a runtime Action/Hack result that mutates a world object or connection target before deleting the old Mission 8 state. |
| `1273` | Current goal hint delegates to legacy mission hint table. | Story glue, safe to remove later. | TASK TEST should eventually use runtime objective/help text independent of story missions. |
| `1277`, `1301`, `1306`, `1383`, `1386`, `1449-1450` | Mission start/restart/progression uses `current_mission_index`. | Story glue still blocking TASK TEST safety, needs extraction first. | TASK TEST currently depends on mission `10` compatibility. Replace with sandbox session startup before removing. |
| `1323` | Mission 7 cable state reset on mission start now delegates to `BipobLegacyCableFlowService.reset_state()`. | Isolated legacy boundary, safe to remove later. | Hardcoded Mission 7 state is still legacy and removable after generic cable runtime exists; reset behavior is no longer inline in the controller. |
| `1314-1318` | Mission-specific setup dispatch for Missions 7, 8, and 9. | Story glue, safe to remove later. | Remove with old mission layouts after TASK TEST startup no longer depends on this switch. |
| `1395-1396` | Return-to-box releases active Mission 7 cable drag through wrapper. | Story glue, safe to remove later. | Keep until cable drag is extracted or old mission return flow is removed. |
| `1408` | Mission 9 return-to-box context hint. | Story glue, safe to remove later. | Old story hint only. |
| `6605`, `6607`, `6627-6649` | Exit completion and `complete_mission()` message/progression logic. | Story glue still blocking TASK TEST safety, needs extraction first. | TASK TEST uses completion compatibility. Isolate runtime sandbox completion before deleting mission-completion flow. |
| `7075` | Scan diagnostic checks `mission8_terminal_cooled`. | Story glue still blocking TASK TEST safety, needs extraction first. | Airflow cooled/hot state is reusable; read from runtime cooling state instead of Mission 8 variable. |
| `7800-7824` | Legacy tile interaction dispatches Mission 8 control tiles through controller wrappers, then delegates Mission 7 cable/socket/gate branches to `BipobLegacyCableFlowService.handle_interact_tile()`. | Isolated legacy boundaries, safe to remove after replacement. | Mission 8 fan/platform/airflow and Mission 7 cable/socket/power behavior are preserved behind legacy boundaries. Later work should replace both with data-driven world-object actions/contracts before old missions are deleted. |
| `8299-8341` | Mission 8 setup, fan/platform control, airflow, terminal state, and unlock helpers are compatibility wrappers that delegate through `BipobLegacyAirflowFlowService`; Mission 8 tile branches still call those wrappers. | Isolated legacy boundary, safe to remove after replacement. | Fan/platform/airflow/cooling is reusable and must later move to generic runtime world-object contracts. The hardcoded old Mission 8 state is still legacy and removable after that generic airflow runtime exists. |
| `8358-8359` | Mission 7 cable status text wrapper delegates to `BipobLegacyCableFlowService.get_status_text()`. | Isolated legacy boundary, safe to remove later. | Status text is old mission UI glue. Runtime cable status should come from generic runtime cable state. |
| `8361-8380` | Mission 7 setup, cable reel/socket interactions, path drawing/clearing, and release are compatibility wrappers that delegate to `BipobLegacyCableFlowService`. | Isolated legacy boundary, safe to remove later. | The old implementation still uses hardcoded Mission 7 positions and `cable_a`, but it is no longer inline in `BipobController`. Keep until a generic runtime cable/socket/power contract replaces it. |
| `8857-8883` | `read_terminal()` switches on `current_mission_index`; Mission 2 now emits tutorial feedback only and no longer completes a mission. | Retired/neutralized story completion side effect. | Old terminal tutorial/info-key branch remains for compatibility. Scan/Hack and digital record mechanics must remain. |

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
| `213-218` | Uses `is_legacy_mission2_terminal_tutorial_active()` for the old terminal tutorial branch, but only emits feedback/status. | Retired/neutralized story completion side effect. | Generic scan/hack no longer calls `complete_legacy_mission_from_story_glue()`. The reusable `download_info_key` action and Info-Key digital record storage remain below this branch. |
| `239` | Calls `controller.unlock_airflow_terminal_path()` for the airflow-terminal hack effect; the controller wrapper delegates to `BipobLegacyAirflowFlowService`. | Isolated legacy boundary, safe to remove after replacement. | `unlock_airflow_terminal` remains available and does not call `complete_mission()`. Replace the service's hardcoded Mission 8 door state with runtime world-object contracts later. |

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

No remaining `current_mission_index`, `mission7_*`, `mission8_*`, or `complete_mission()` usage found in this file. MissionManager still owns runtime world-object APIs and mission layout compatibility, so it should not be broadly deleted in the legacy mission retirement work.

## Reusable mechanics that must survive

- Runtime scan/hack command flow and digital record storage. Generic scan/hack no longer completes legacy story missions.
- Inventory pickup/drop, manipulator hand, and pocket logic.
- Runtime movement/turn/action spending and map constructor startup behavior.
- Cable/socket/power concepts. PR-RF-11 preserves the old Mission 7 implementation behind `BipobLegacyCableFlowService`; future work must move the reusable mechanic to generic runtime world-object contracts before deleting the old Mission 7 state.
- Fan/platform/airflow/cooling concepts. PR-RF-12 preserves the old Mission 8 implementation behind `BipobLegacyAirflowFlowService`; future work must move the reusable mechanic to generic runtime world-object contracts before deleting the old Mission 8 state.
- WorldObjectCatalog, InteractionSystem, PowerSystem, and MissionManager generic runtime APIs.

## Branches that can be deleted after extraction/proof

- Mission 2 terminal calibration completion side effect is retired/neutralized; remaining compatibility feedback can be deleted with the old terminal tutorial branch.
- Mission 4 hidden route-node story gating and recovered-module hints.
- Mission 7 hardcoded cable reel/socket/gate setup, status text, and `cable_a` power event now isolated in `BipobLegacyCableFlowService`; delete after cable mechanics are represented by generic runtime services.
- Mission 8 hardcoded fan/platform/airflow/terminal setup, status text, controls, airflow tile updates, cooling state, and door unlock now isolated in `BipobLegacyAirflowFlowService`; delete after airflow mechanics are represented by generic runtime services.
- Mission-specific completion messages/progression after TASK TEST has standalone sandbox objective handling.

## TASK TEST safety notes

- PR-RF-08 does not delete resources, scenes, setup data, cable/socket/power behavior, fan/platform/airflow behavior, scan/hack, inventory, or MissionManager.
- PR-RF-10 removes legacy mission completion from generic scan/hack/read-terminal flows while preserving TASK TEST startup, Map Constructor, scan/hack mechanics, Info-Key storage, digital doors, hot nodes, airflow terminal unlock, cable/socket/power, inventory, and movement behavior.
- PR-RF-11 moves legacy Mission 7 cable/socket/powered-gate flow behind `BipobLegacyCableFlowService` while preserving TASK TEST, Map Constructor, scan/hack, inventory, movement, and old Mission 7 behavior.
- PR-RF-12 moves legacy Mission 8 fan/platform/airflow/terminal flow behind `BipobLegacyAirflowFlowService` while preserving TASK TEST, Map Constructor, scan/hack, inventory, movement, and old Mission 8 behavior.
- Future removal PRs should first prove TASK TEST startup, runtime Action / Connect / Heavy Claw, scan/hack, and pickup/drop paths no longer require old mission-index branches.
