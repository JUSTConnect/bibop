# BIPOB PR-RF-21 — Generic airflow/cooling runtime contract

## Purpose

This document defines the planned generic runtime contract for fan, platform, airflow, and cooling mechanics before old Mission 8 resources or `BipobLegacyAirflowFlowService` are retired.

PR-RF-21 is documentation-first planning only. It does **not** implement `BipobAirflowRuntimeService`, change TASK TEST, change Map Constructor behavior, change Mission 8 gameplay, delete mission resources, or remove the legacy airflow service.

The reusable mechanic should move to TASK TEST / Map Constructor / runtime sandbox data in a future implementation PR. Old Mission 8 story glue should remain isolated until that generic implementation exists and passes smoke.

## Reusable mechanic versus old Mission 8 glue

The future runtime service must treat fan/platform/airflow/cooling behavior as data-driven world-object state, not as Mission 8-specific variables or tile mutations.

Reusable mechanics to keep:

- A fan has a direction and speed.
- Fan speed determines airflow range.
- Airflow projects through map cells until blocked by bounds or blockers.
- A platform or mount may determine the fan source position.
- Airflow visuals can appear and clear as runtime state changes.
- Cooling targets become cooled/stable when valid airflow reaches them.
- Scan/hack and action UI can query cooled/hot/hacked state through a generic contract.
- A hacked/cooled airflow terminal can unlock a linked door/path/target.

Old Mission 8 story glue to replace later:

- Hardcoded `mission8_*` positions and state on the controller.
- Hardcoded airflow ranges, blocker tile checks, and terminal/door positions inside the legacy service.
- Direct mutation of Mission 8 door tiles.
- Scan/hack branches that need Mission 8-specific variables instead of generic runtime object state.
- Mission 8 layout resources that exist only to host the old story setup.

## Runtime object roles

| Role | Purpose | Notes |
| --- | --- | --- |
| `fan` | Emits airflow from a source position in a direction at a configured speed. | Owns `direction`, `speed`, `min_speed`, `max_speed`, and optional `airflow_range`. |
| `fan_control` | Interactable control that rotates a fan or changes fan speed. | May expose separate actions for left/right rotation, speed up/down, or explicit speed setting. |
| `platform` / `movable_platform` / `fan_platform` | A runtime object that can hold, move, or visually represent a fan source. | `fan_platform` should be a generic object/visual role, not `GridManager.TILE_FAN_PLATFORM` logic hardcoded to Mission 8. |
| `platform_control` | Interactable control that moves or rotates a linked platform/fan mount. | May link to a platform by `linked_platform_id`. |
| `airflow_zone` / `airflow_path` | Runtime projection of cells affected by one fan or airflow source. | Stores calculated `airflow_cells` / `cells` and visual state. |
| `cooling_target` / `heat_target` / `hot_node` | Object whose cooled/overheated/stable state is affected by airflow. | A terminal can also be a cooling target if cooling gates hacking. |
| `airflow_terminal` | Interactable terminal whose scan/hack state depends on cooling state. | Should expose `cooled`, `hacked`, and linked target state without Mission 8 variables. |
| `powered_door` / `linked_door` / `linked_target` | Door, path, or target unlocked by a cooled/hacked terminal. | Uses generic linked target updates instead of direct Mission 8 door tile mutation. |
| Optional `cooling_network` | Groups fans, airflow paths, terminals, and targets when multiple sources affect shared targets. | Useful for future layouts with more than one fan or cooling target. |
| Optional `airflow_event` | Data-driven event emitted when airflow/cooling state changes. | Useful for action panel status, UI refresh, linked target unlocks, and smoke testing. |

## Required object fields and properties

Future runtime world objects do not need every field for every role. The service should read the fields relevant to each role and use safe defaults when optional fields are absent.

| Field/property | Applies to | Contract |
| --- | --- | --- |
| `id` | All runtime objects | Stable object id used for service lookups, links, status text, and persistence. |
| `type` / `family` | All runtime objects | Object role/type classification, such as `fan`, `fan_control`, `airflow_terminal`, or `linked_door`. |
| `position` | Physical objects and visual objects | Grid position for fan source, controls, terminals, targets, doors, and blockers. |
| `state` | All runtime objects | Generic state string/dictionary, such as `idle`, `active`, `cooled`, `hot`, `hacked`, `unlocked`, or `blocked`. |
| `direction` | `fan`, `fan_platform`, airflow source | Direction used to calculate airflow cells. Should map to existing runtime direction conventions. |
| `speed` | `fan` | Current fan speed. |
| `min_speed` / `max_speed` | `fan`, controls | Bounds for speed changes. Mission 8 currently behaves like `0..3`. |
| `airflow_range` | `fan`, `airflow_zone`, `airflow_path` | Effective range derived from speed or explicitly configured by data. |
| `airflow_cells` | `airflow_zone`, `airflow_path`, service state | Calculated cells currently affected by airflow. |
| `platform_position` / `linked_platform_id` | `fan`, `fan_platform`, `platform_control` | Identifies the movable platform or fan mount that determines source position. |
| `target_id` / `linked_target_id` | Controls, terminals, events | Id of the object affected by a control, cooling result, or hack result. |
| `terminal_id` / `linked_terminal_id` | Cooling target, network, linked target | Id of the terminal whose cooled/hacked state participates in the flow. |
| `cooled` / `overheated` / `stable` | `cooling_target`, `heat_target`, `hot_node`, `airflow_terminal` | Cooling-state booleans or equivalent state values used by scan/hack and UI. |
| `hacked` / `unlocked` | `airflow_terminal`, `linked_target`, `linked_door` | Hack and unlock state exposed through generic runtime data. |
| `blocks_airflow` | Map objects, doors, walls, blockers | Whether this object stops airflow projection. |
| `airflow_filter` / `cooling_filter` | Fans, blockers, targets, networks | Optional compatibility filter for airflow type, cooling type, required direction, required speed, or network membership. |
| `visual_tile` / `visual_state` | Visual objects and runtime path overlays | Optional renderer/catalog mapping for fan platform, airflow path, terminal, cooled/hot state, and unlocked/locked state. |

## Required actions

These action ids are the planned generic contract names. Future implementation can expose them through the existing parser/action system when the object role and runtime state allow the action.

| Action | Contract |
| --- | --- |
| `rotate_fan_left` | Rotate the linked fan/platform direction counter-clockwise, then update airflow and cooling effects. |
| `rotate_fan_right` | Rotate the linked fan/platform direction clockwise, then update airflow and cooling effects. |
| `increase_fan_speed` | Increase fan speed within `max_speed`, then update airflow and cooling effects. |
| `decrease_fan_speed` | Decrease fan speed within `min_speed`, then update airflow and cooling effects. |
| `set_fan_speed` | Set fan speed to an explicit valid value, then update airflow and cooling effects. |
| `move_platform_left` | Move a linked platform/fan mount left if allowed by bounds/collision rules, then update airflow. |
| `move_platform_right` | Move a linked platform/fan mount right if allowed by bounds/collision rules, then update airflow. |
| `update_airflow` | Recalculate airflow ranges/cells and refresh visual path state. |
| `apply_airflow_effects` | Apply current airflow cells to cooling targets, terminals, and linked state. |
| `cool_target` | Mark a cooling target or terminal cooled/stable when airflow reaches it and filters pass. |
| `hack_airflow_terminal` | Hack a cooled/eligible airflow terminal through scan/hack runtime rules. |
| `unlock_linked_target` / `open_linked_door` | Apply the terminal hack/unlock result to a linked target through generic object state and visual/collision updates. |

## Runtime service responsibilities

A future `BipobAirflowRuntimeService` should own generic behavior currently trapped behind old Mission 8 state.

Required responsibilities:

1. Track fan direction and speed through world-object state by `id` and `position`.
2. Calculate airflow range from speed, using object data such as `min_speed`, `max_speed`, speed-to-range tables, or explicit `airflow_range`.
3. Calculate airflow cells from direction, range, blockers, and map bounds.
4. Respect `blocks_airflow`, `airflow_filter`, `cooling_filter`, and map/object collision rules without hardcoded Mission 8 tile branches.
5. Move a platform/fan mount when a platform object controls fan position, then recalculate airflow from the new source position.
6. Update visual airflow path state without depending on Mission 8 hardcoded tiles or positions.
7. Apply cooling effects to linked targets when airflow reaches them.
8. Expose terminal cooled/hot/hacked state through generic runtime object data.
9. Let hack/scan services query cooled/hot state without reading `mission8_*` variables.
10. Unlock linked door/path/target when an airflow terminal is hacked and eligible.
11. Expose concise status text for UI/action panel, including direction, speed, range, cooled/hot state, and hack/unlock results.
12. Clean up airflow visuals on reset, layout reload, object deletion, or service shutdown.
13. Keep object/world state data-driven by ids/positions rather than story mission indexes.
14. Preserve parser safety by keeping action ids/data contracts explicit and avoiding broad dynamic method calls.

## Current legacy Mission 8 mapping

The table below names how the existing Mission 8 implementation should translate into future generic runtime data. These are migration mappings only; new TASK TEST/runtime layouts should use the generic fields directly.

| Current legacy Mission 8 field/constant | Future generic contract field/role |
| --- | --- |
| `mission8_fan_speed` | `fan.speed` |
| `mission8_fan_direction` | `fan.direction` |
| `mission8_terminal_cooled` | `cooling_target.cooled` / `airflow_terminal.cooled` |
| `mission8_terminal_hacked` | `airflow_terminal.hacked` |
| `mission8_terminal_position` | `airflow_terminal.position` / `cooling_target.position` |
| `mission8_door_position` | `linked_target.position` / `linked_door.position` |
| `mission8_fan_position` | `fan.position` |
| `mission8_fan_platform_position` | `platform.position` / `linked_platform_id` |
| `mission8_airflow_cells` | `airflow_zone.airflow_cells` / `airflow_path.cells` |
| `GridManager.TILE_FAN_PLATFORM` | `platform` / `fan_mount` visual/object type through `visual_tile` / catalog mapping. |
| `GridManager.TILE_AIRFLOW` | Airflow visual path state through `visual_state` / runtime overlay data. |
| `GridManager.TILE_AIRFLOW_TERMINAL` | `airflow_terminal` visual/object type through `visual_tile` / catalog mapping. |
| Direct door tile mutation | Generic `linked_target` / `linked_door` state update, followed by renderer/collision refresh. |

## Migration plan

### Stage A — PR-RF-21 contract only

- Keep `BipobLegacyAirflowFlowService` in place.
- Add this generic contract document.
- Update legacy mission readiness/dependency docs.
- Make no gameplay, TASK TEST, Map Constructor, runtime action, scan/hack, movement, inventory, cable/socket/power, airflow/cooling, terminal hack, door/path unlock, or mission resource behavior changes.

### Stage B — Generic runtime service

- Add `BipobAirflowRuntimeService` as the non-story home for fan/platform/airflow/cooling behavior.
- Make it operate on world objects by `id`, `position`, and explicit object fields instead of Mission 8 state names.
- Allow TASK TEST / Map Constructor layouts to place fans, fan controls, platforms, platform controls, airflow terminals, cooling targets, and linked doors/targets.
- Keep legacy Mission 8 behavior unchanged while the new service is developed and smoke-tested separately.

### Stage C — Legacy adapter

- Make the legacy Mission 8 adapter call the generic airflow service with generated object data based on existing hardcoded positions/state.
- Preserve old Mission 8 behavior, status text, airflow cells, cooling state, terminal hack behavior, and door/path unlock behavior during adapter migration.
- Keep Mission 8 resources until both old behavior and TASK TEST generic behavior are proven.

### Stage D — Scan/hack contract migration

- Update `BipobScanHackService` to query cooled/hacked state through the generic airflow/cooling runtime contract instead of Mission 8 variables.
- Preserve legacy wrapper compatibility until old Mission 8 resources are deleted.
- Keep scan/hack action ids explicit and parser-safe.

### Stage E — Legacy retirement

- Remove `BipobLegacyAirflowFlowService` only after old Mission 8 resources are retired and TASK TEST generic airflow smoke passes.
- Delete Mission 8-specific state, hardcoded positions, airflow tile mutation, terminal cooling variables, and direct door mutation only after no runtime path depends on them.
- Keep reusable fan/platform/airflow/cooling world-object support in TASK TEST and future missions.

## Acceptance smoke for future implementation

A future implementation PR should pass at least this smoke flow before Mission 8 deletion continues:

1. Place a fan, platform/fan mount, airflow terminal, and cooling target in TASK TEST / Map Constructor.
2. Rotate the fan left and right.
3. Increase and decrease fan speed.
4. Confirm airflow cells update from direction, range, blockers, and bounds.
5. Confirm airflow visuals appear and clear correctly on update/reset/layout reload.
6. Confirm platform movement changes the fan or airflow source if configured.
7. Confirm the cooling target becomes cooled/stable when airflow reaches it.
8. Confirm scan/hack sees cooled terminal state through the generic contract.
9. Hack the airflow terminal.
10. Confirm the linked door/path/target opens or unlocks.
11. Confirm no old Mission 8 state, positions, `current_mission_index` branch, or legacy tile mutation is required.

## Non-goals for PR-RF-21

- Do not implement full generic airflow runtime behavior.
- Do not delete Mission 8 resources.
- Do not remove `BipobLegacyAirflowFlowService`.
- Do not convert old Mission 8 layout data.
- Do not change TASK TEST or Map Constructor behavior.
- Do not touch Mission 7 cable runtime.
- Do not change movement, inventory, scan/hack, terminal hack, cooling, door/path unlock, cable/socket/power, or parser behavior.
- Do not add new story content, UI labels/text, scenes, or project settings.
