# PR-GEN-04 — Legacy Mission 7/8 removal-readiness audit

Status: legacy Mission 7 and Mission 8 are **not ready for deletion** in this PR.

This audit records deletion readiness after PR-GEN-02 generic cable runtime, PR-GEN-03 generic airflow runtime, and PR-GEN-04 Map Constructor validation. It is an audit only; no mission resources, scenes, story missions, or `project.godot` entries are deleted.

## Mission 7 — cable/socket/power legacy flow

### Legacy files/services still present

- `scripts/game/bipob_legacy_cable_flow_service.gd` still implements the Mission 7 cable route interaction adapter.
- `scripts/game/bipob_legacy_tile_interaction_service.gd` still participates in legacy tile interaction routing.
- `scripts/bipob/bipob_controller.gd` still preloads the legacy cable service and owns Mission 7 cable state.
- `scripts/field/grid_manager.gd` still contains `get_mission7_layout()` and Mission 7 map selection.
- `scripts/ui/game_ui.gd` still displays Mission 7 cable drag/status affordances.

### Generic replacements now available

- PR-GEN-02 introduced `BipobCableRuntimeState` and `BipobCableRuntimeService` for generic cable/socket/power state and propagation.
- `MissionManager.refresh_generic_cable_runtime_state()`, `get_generic_cable_runtime_report()`, `is_world_object_powered()`, and `get_world_object_power_state()` expose the generic runtime to TASK TEST/read-only callers.
- TASK TEST includes the valid `task_test_generic_power_smoke` chain plus `task_test_generic_unpowered_device` as an intentionally incomplete case.
- PR-GEN-04 adds Map Constructor warnings for missing power networks, missing/invalid sources, missing/invalid sockets, dangling endpoints, incomplete chains, and unpowered generic sinks.

### Callers still referencing Mission 7-specific methods/state

Observed references include:

- `BipobController.is_legacy_mission7_cable_flow_active()`;
- `BipobController.is_legacy_mission7_cable_drag_active()`;
- `BipobController.setup_mission7()`;
- `BipobController.release_mission7_cable_end()`;
- `BipobController.add_current_cell_to_mission7_cable_path()`;
- `BipobController.get_mission7_cable_status_text()`;
- `mission7_is_dragging_cable`;
- `mission7_cable_connected`;
- `mission7_cable_reel_position`;
- `mission7_socket_position`;
- `mission7_powered_gate_position`;
- `mission7_cable_path`;
- `mission7_cable_max_length`;
- `GameUI` Mission 7 cable status/HUD branches.

### Remaining blockers

- Story Mission 7 still has hardcoded controller/grid/UI wiring.
- There is no Mission 7 resource migration proving the story mission can be expressed entirely as generic world-object cable metadata.
- Existing player-facing Mission 7 status text and cable drag behavior still depend on legacy controller state.
- Generic cable runtime is TASK TEST-first and intentionally simple; it has not been promoted as a full replacement for the legacy story mission flow.
- Full local Godot smoke for old Mission 7 was not completed in this audit environment.

### Deletion safety

Deletion safe now: **No**.

Recommended next step: create a separate migration PR that either ports Mission 7 content to generic cable/socket/power metadata and updates caller routing, or formally quarantines Mission 7 as a legacy-only mission while leaving old files in place.

## Mission 8 — fan/airflow/cooling legacy flow

### Legacy files/services still present

- `scripts/game/bipob_legacy_airflow_flow_service.gd` still implements Mission 8 fan/platform/terminal flow.
- `scripts/game/bipob_legacy_tile_interaction_service.gd` still participates in legacy tile interaction routing.
- `scripts/bipob/bipob_controller.gd` still preloads the legacy airflow service and owns Mission 8 airflow state.
- `scripts/field/grid_manager.gd` still contains `get_mission8_layout()` and Mission 8 map selection.
- `scripts/ui/game_ui.gd` still displays Mission 8 airflow status text.
- `scripts/field/room_visual_renderer.gd` still includes `airflow_terminal` visual classification/support.

### Generic replacements now available

- PR-GEN-03 introduced `BipobAirflowRuntimeState` and `BipobAirflowRuntimeService` for generic fan/airflow/cooling propagation.
- `MissionManager.refresh_generic_airflow_runtime_state()`, `get_generic_airflow_runtime_report()`, `is_world_object_cooled()`, and `get_world_object_cooling_state()` expose generic cooling state to TASK TEST/read-only callers.
- TASK TEST includes the generic fan/path/target/blocker/uncooled-target smoke chain.
- PR-GEN-04 adds Map Constructor warnings for missing airflow networks, missing fan direction, disabled fan with cooling-required targets, uncooled targets, blocked paths, out-of-range targets, and invalid declared linked target ids.

### Callers still referencing Mission 8-specific methods/state

Observed references include:

- `BipobController.is_legacy_mission8_airflow_flow_active()`;
- `BipobController.setup_mission8()`;
- `BipobController.unlock_airflow_terminal_path()`;
- `BipobController.complete_legacy_mission8_airflow_terminal_hack()`;
- `BipobController.interact_mission8_platform_control_left()`;
- `BipobController.interact_mission8_platform_control_right()`;
- `BipobController.increase_mission8_fan_speed()`;
- `BipobController.decrease_mission8_fan_speed()`;
- `BipobController.get_mission8_airflow_status_text()`;
- `mission8_fan_direction`;
- `mission8_fan_speed`;
- `mission8_terminal_cooled`;
- `mission8_terminal_hacked`;
- `mission8_fan_platform_position`;
- `mission8_platform_control_position` and side-specific platform controls;
- `mission8_fan_control_position` and speed controls;
- `mission8_terminal_position`;
- `mission8_door_position`;
- `mission8_airflow_cells`;
- `GameUI` Mission 8 airflow status/HUD branches.

### Remaining blockers

- Story Mission 8 still has hardcoded controller/grid/UI wiring.
- There is no Mission 8 resource migration proving the story mission can be expressed entirely as generic fan/path/blocker/target metadata.
- Existing Mission 8 terminal hack and door unlock sequence still depends on legacy controller state.
- Generic airflow runtime is TASK TEST-first and line-of-sight/range based; it has not been promoted as a full replacement for the legacy story mission flow.
- Full local Godot smoke for old Mission 8 was not completed in this audit environment.

### Deletion safety

Deletion safe now: **No**.

Recommended next step: create a separate migration PR that ports Mission 8 content and terminal unlock conditions to generic airflow/cooling metadata, then runs a full old Mission 8 smoke before deleting legacy adapters.

## Overall removal-readiness result

Legacy Mission 7/8 removal should remain blocked until both old story missions are either migrated to generic data or explicitly retired through a separate deletion PR with full runtime smoke coverage.
