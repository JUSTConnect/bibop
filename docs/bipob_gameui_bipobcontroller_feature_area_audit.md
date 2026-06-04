# BIPOB UICTRL-RF-01 — GameUI / BipobController feature-area ownership audit

## Purpose

This docs-only audit starts the next refactor phase after the TASK TEST / `mission_10` decoupling track.

The goal is to unload `scripts/ui/game_ui.gd` and `scripts/bipob/bipob_controller.gd` by feature area, not by random line-count cleanup.

This audit does not change gameplay, UI behavior, TASK TEST, Map Constructor, movement, scan/hack, inventory, cable, airflow, mission resources, scenes, or `project.godot`.

## Current context

The current active product surface is:

- TASK TEST runtime sandbox;
- Map Constructor;
- runtime object/action mechanics;
- editor/runtime smoke checks.

The previous TASK TEST decoupling phase reached a useful stopping point:

- `task_test` is the canonical TASK TEST id;
- `mission_10` is compatibility only;
- TASK TEST startup/restart/result/objective/layout/world setup are behind explicit sandbox boundaries;
- old missions are not ready for deletion because Mission 7 cable/socket/power and Mission 8 airflow/cooling still need generic gameplay replacements.

Now the main technical debt is file ownership:

- `GameUI` still owns too many UI screens, state machines, callbacks, refresh flows, and runtime/editor bridges.
- `BipobController` still owns too many runtime/session, movement, inventory, action, scan/hack, constructor, and legacy compatibility responsibilities.

## Existing extraction already present

This audit should not ignore existing progress.

### GameUI already uses several extracted UI helpers

`GameUI` already uses several extracted helpers/controllers:

- `RuntimeMissionMenu`
- `CenterScreen`
- `RuntimeStoragePanel`
- `RuntimeActionPanelBridge`
- runtime action bridge dependencies `RuntimeControlPanel` and `RuntimeInteractionPresenter`
- `RuntimeBipobSwitcher`
- `RuntimeObjectHud`
- `MapConstructorScreen`
- `MapConstructorInspector`
- `MapConstructorPropertyControls`
- `MapConstructorLinkControls`
- `MapConstructorSessionState`
- `MapConstructorRefreshCoordinator`

This means the next UI refactor should not create duplicate replacements. It should finish moving orchestration and state that still remains inside `GameUI` into these existing modules or small adjacent modules.

### BipobController already uses several extracted services/controllers

`BipobController` already preloads multiple service/controller classes:

- `BipobTargetingService`
- `BipobActionViewModelService`
- `BipobCapabilityService`
- `BipobRuntimeActionActorService`
- `BipobTerminalControlExecutionService`
- `BipobHeavyClawExecutionService`
- `BipobWorldObjectExecutionService`
- `BipobItemPickupExecutionService`
- `BipobLegacyTileInteractionService`
- `BipobLegacyCableFlowService`
- `BipobLegacyAirflowFlowService`
- `BipobScanHackService`
- `BipobMovementController`
- `BipobInventoryController`

The next controller refactor should continue converting `BipobController` into a thin owner/coordinator around these services, not create parallel systems.

## GameUI feature-area ownership map

### 1. Runtime boot / scene wiring / signal binding

Current owner: `scripts/ui/game_ui.gd`

Observed responsibilities:

- creates/owns runtime `Field`, `MissionManager`, and `Bipob` references;
- binds Bipob signals such as status, hint, world-action panel, mission completed/failed, returned-to-box;
- maintains `bipob`, `field_runtime`, `mission_manager_runtime`, runtime root nodes, and screen mode state;
- handles app screen transitions.

Important state/calls:

- `bipob`
- `field_runtime`
- `mission_manager_runtime`
- `_ensure_gameplay_runtime_created()`
- `_connect_bipob_runtime_signals_once()`
- `_has_gameplay_runtime()`
- `app_screen_mode`
- `previous_app_screen_mode`

Risk: medium.

Recommended target:

- keep in `GameUI` for now;
- later extract to `scripts/ui/runtime/runtime_bootstrap_controller.gd` only after Map Constructor and runtime panels are extracted further.

Can extract now: no.

Reason: boot/signal wiring touches every other UI area. It should be one of the last GameUI extractions.

### 2. Map Constructor UI bridge

Current owner: mostly `GameUI`, partially extracted to map-constructor UI classes.

Observed responsibilities still inside `GameUI`:

- owns `MapConstructorSessionState` instance through `_get` / `_set` dynamic session property forwarding;
- owns runtime map-constructor panel references;
- owns constructor validation overlay control inner class;
- owns readiness/warning presentation helpers for constructor warnings;
- owns constructor palette/filter constants and state;
- coordinates constructor screen, inspector, overview HUD, validation overlay, place-confirm panel, recent prefabs, history/overview filters;
- calls into Bipob/MissionManager for constructor warnings and readiness.

Important state/calls:

- `map_constructor_state`
- `runtime_map_constructor_palette_panel`
- `runtime_map_constructor_inspector_panel`
- `runtime_map_constructor_overview_hud_panel`
- `runtime_map_constructor_validation_overlay_control`
- `runtime_map_constructor_place_confirm_panel`
- `MAP_CONSTRUCTOR_*` constants
- `_get_constructor_warning_items()`
- `_get_constructor_readiness_state()`
- `_create_constructor_warning_readiness_panel()`

Risk: medium.

Recommended target:

- `scripts/ui/map_constructor/map_constructor_ui_bridge.gd`
- or extend existing `MapConstructorScreen` + `MapConstructorRefreshCoordinator` rather than creating a large new owner.

Can extract now: yes, first code PR candidate.

Why first:

- Map Constructor already has extracted classes;
- the state object already exists;
- many methods are UI presentation/coordination, not core gameplay;
- extraction can be done as behavior-equivalent delegation.

Acceptance for first extraction:

- GameUI keeps only top-level creation and one or two bridge calls;
- bridge owns constructor panel references, overlay refresh, readiness/warning card building, palette/overview refresh routing;
- existing `MapConstructorScreen`, `MapConstructorInspector`, `MapConstructorPropertyControls`, `MapConstructorLinkControls`, and `MapConstructorRefreshCoordinator` stay the specialized subcomponents;
- no Map Constructor behavior changes.

### 3. Runtime action/control panel bridge

Current owner: `GameUI`, partially extracted to runtime classes.

Observed responsibilities:

- owns runtime action/connect/heavy-claw/end-turn buttons;
- owns base controls grid and interaction action rows;
- refreshes runtime action availability and labels;
- forwards button presses to Bipob runtime methods;
- owns runtime notification state and panel;
- owns selected world-action target UI state.

Important state/calls:

- `runtime_action_button`
- `runtime_connect_button`
- `runtime_heavy_claw_button`
- `runtime_end_turn_button`
- `runtime_interaction_actions_row`
- `runtime_base_controls_grid`
- `runtime_world_actions_panel`
- `last_world_action_target_id`
- `last_world_action_selected`
- `RuntimeControlPanelRef`
- `RuntimeInteractionPresenterRef`
- `RuntimeObjectHudRef`

Risk: medium.

Recommended target:

- extend existing `scripts/ui/runtime/runtime_control_panel.gd`;
- add a thin `scripts/ui/runtime/runtime_action_panel_bridge.gd` only if needed.

Can extract now: yes, second code PR candidate.

Notes:

- This should be after Map Constructor UI bridge because Action/Connect/Heavy Claw are active runtime smoke surface.
- Keep GameUI as event router only.
- Do not change action availability logic in the same PR; only move existing UI orchestration.

UICTRL-RF-03 status:

- Added `scripts/ui/runtime/runtime_action_panel_bridge.gd` as the runtime action/control orchestration owner.
- `GameUI` now keeps compatibility wrapper methods and delegates action target lookup, action mode transitions, Action/Connect/Heavy Claw/End Turn callbacks, world-action target id derivation, and per-frame action feedback to the bridge.
- `RuntimeControlPanel` still builds the existing control panel view, but runtime button callbacks can now be wired directly to the bridge so no parallel runtime UI system is introduced.

UICTRL-RF-04 status:

- `RuntimeStoragePanel` now owns runtime storage action routing for drop, rotate, pocket take/swap, manipulator store, digital load/swap, and buffer store while continuing to call existing Bipob inventory APIs.
- `RuntimeStoragePanel` now owns runtime key id/display derivation used by the mini HUD; `GameUI` keeps compatibility wrappers that delegate to the panel.
- `GameUI` keeps the storage panel build/refresh bridge and existing callback method names, but the runtime storage UI callbacks are no longer implemented directly in `GameUI`.

### 4. Runtime storage / inventory UI

Current owner: `GameUI`, partially extracted to `RuntimeStoragePanel`.

Observed responsibilities:

- owns pocket/manipulator/digital slots;
- owns key summary/energy/actions labels;
- owns take/load/drop/rotate actions;
- owns runtime storage panel collapsed state;
- pulls inventory state from Bipob/MissionManager.

Important state/calls:

- `runtime_storage_panel`
- `runtime_pocket_slots`
- `runtime_digital_slots`
- `runtime_pocket_take_buttons`
- `runtime_digital_load_buttons`
- `runtime_key_summary_label`
- `drop_item_button`
- `rotate_storage_button`
- `RuntimeStoragePanelRef`

Risk: medium.

Recommended target:

- finish moving all runtime storage rendering/callback ownership into `scripts/ui/runtime/runtime_storage_panel.gd`.

Can extract now: yes, but after runtime action panel.

Notes:

- Inventory behavior itself should remain in Bipob/MissionManager services.
- UI extraction should not move storage gameplay data or mutate item semantics.

### 5. TASK TEST / dev task card / mission result / objective UI

Current owner: `GameUI`.

Observed responsibilities:

- dev card/task screens and TASK TEST launch;
- mission/result screen state;
- restart from result screen;
- objective/goal label selection;
- compatibility fallback via `_is_task_test_runtime_active()`.

Important state/calls:

- `tasks_*` state;
- `mission_result_root`;
- `last_mission_success`;
- `mission_goal_value_label`;
- `_is_task_test_runtime_active()`;
- `_restart_task_test_from_result_screen()`.

Risk: low-to-medium.

Recommended target:

- `scripts/ui/runtime/runtime_objective_panel.gd`
- `scripts/ui/tasks/task_test_dev_card.gd` if task/dev UI continues to grow.

Can extract now: not first.

Reason:

- TASK TEST decoupling just stabilized this path;
- avoid moving it immediately unless needed by a runtime HUD extraction.

### 6. Box constructor / module inventory / robot profile UI

Current owner: `GameUI`.

Observed responsibilities:

- body profile selection;
- module constructor filters;
- external/internal slot selection;
- selected module preview controls;
- internal overlay path planning UI;
- box storage/module tabs.

Important state/calls:

- `constructor_profiles`
- `active_bipob_profile_id`
- `CONSTRUCTOR_FILTERS`
- `selected_constructor_module`
- `selected_external_side_index`
- `selected_external_slot_position`
- `internal_view_mode`
- `SelectedModuleMiniPreviewControl`
- `InternalIsoPreviewControl`

Risk: high.

Recommended target:

- later split into `scripts/ui/box/box_constructor_screen.gd` and `scripts/ui/box/module_inventory_panel.gd`.

Can extract now: no.

Reason:

- It touches module placement, preview heat/cooling warnings, profile sizes, internal/external grids, and runtime readiness.
- Do after Map Constructor/runtime UI extraction.

### 7. Programmer / charging / repair / placeholder menus

Current owner: `GameUI`.

Observed responsibilities:

- programmer pending/completed files;
- programmer Bipob records;
- file recovery/decryption UI;
- charging tab UI;
- repair menu root.

Important state/calls:

- `programmer_pending_files`
- `programmer_completed_files`
- `programmer_pending_bipobs`
- `programmer_reprogrammed_bipobs`
- `charging_active_tab`
- `_get_programmer_source_files()`
- `_append_programmer_file_if_relevant()`
- `_on_programmer_file_action_pressed()`
- `_on_programmer_bipob_action_pressed()`

Risk: medium.

Recommended target:

- `scripts/ui/screens/programmer_screen.gd`
- `scripts/ui/screens/charging_screen.gd`
- `scripts/ui/screens/repair_screen.gd`

Can extract now: yes, but not urgent.

Reason:

- These are less central than TASK TEST/Map Constructor smoke. Extract after active gameplay/editor UI.

### 8. Generic UI styling/helpers

Current owner: `GameUI`, partially extracted to `GameUITextHelpers`.

Observed responsibilities:

- button creation helpers;
- panel styles;
- labels;
- colors/constants;
- responsive/small viewport helpers.

Risk: low.

Recommended target:

- continue using `GameUITextHelpers`;
- move purely generic style/button factories there only when touched by a feature extraction.

Can extract now: yes, opportunistically.

Do not make a standalone styling-only PR unless it removes significant duplication.

## BipobController feature-area ownership map

### 1. Runtime session / sandbox / legacy mission compatibility

Current owner: `BipobController`.

Observed responsibilities:

- runtime mode state;
- current mission id/index compatibility mirror;
- start/restart/reset TASK TEST;
- legacy story mission start/restart;
- mission completion/result routing;
- layout application and world setup dispatch;
- setup hooks for legacy Mission 7/8/9.

Important state/calls:

- `active_runtime_mode_id`
- `current_mission_id`
- `current_mission_index`
- `TASK_TEST_MISSION_INDEX`
- `TASK_TEST_LAYOUT_ID`
- `get_runtime_mode_id()`
- `is_task_test_mode_active()`
- `start_task_test_session()`
- `_start_runtime_session()`
- `restart_current_mission()`
- `return_to_box()`

Risk: high.

Recommended target:

- keep in `BipobController` for now;
- later extract to `scripts/bipob/bipob_runtime_session_controller.gd` only after UI/Action/Inventory surfaces are smaller.

Can extract now: no.

Reason:

- Recently refactored and core to all smoke paths.
- It also still hosts legacy compatibility boundaries.

### 2. Movement / facing / turn/action budget

Current owner: `BipobController`, partially extracted to `BipobMovementController` and `BipobTargetingService`.

Observed responsibilities:

- direction/facing;
- grid position;
- movement methods and action costs;
- action budget reset/spend;
- fog/visual updates;
- terrain compatibility checks;
- movement modules.

Important state/calls:

- `grid_position`
- `direction`
- `actions_left`
- `actions_per_turn`
- `turns_used`
- `BipobMovementControllerRef`
- `BipobTargetingServiceRef`

Risk: high.

Recommended target:

- keep existing `BipobMovementController` as target;
- only move remaining movement helpers after runtime action and inventory extraction.

Can extract now: no.

Reason:

- Movement is core smoke and interacts with collision, object blocking, doors, fog, and action budget.

### 3. Runtime action dispatch / Action / Connect / Heavy Claw

Current owner: `BipobActionController`, with `BipobController` keeping compatibility wrappers and legacy tile fallbacks.

Extracted responsibilities:

- action view model and actor wrapper delegation;
- facing action target/object/item lookup;
- selected action mutation, cycling, invalidation, and world-action panel emission;
- runtime item pickup orchestration;
- runtime world-object action dispatch;
- terminal door-control, Heavy Claw, and generic world-object execution refresh/signal handling.

Important services reused by the coordinator:

- `BipobActionViewModelService`
- `BipobRuntimeActionActorService`
- `BipobTerminalControlExecutionService`
- `BipobHeavyClawExecutionService`
- `BipobWorldObjectExecutionService`
- `BipobItemPickupExecutionService`
- `BipobTargetingService`
- `InteractionSystem`

Risk: medium.

Recommended target:

- Continue shrinking `BipobController` around remaining action-adjacent data helpers only when behavior-preserving seams are obvious.

Can extract now: completed in UICTRL-RF-05.

Reason:

- Runtime Action / Connect / Heavy Claw orchestration now has a focused code-side owner while preserving existing execution services and UI-facing wrappers.

### 4. Inventory / storage / digital records

Current owner: `BipobController`, partially extracted to `BipobInventoryController`.

Observed responsibilities:

- digital records;
- held/stored physical modules;
- storage text;
- pickup/drop/use wrappers;
- return-to-box storage cleanup.

Important state/calls:

- `held_module`
- `stored_physical_module`
- `store_digital_record()`
- `has_digital_record()`
- `use_digital_record()`
- `get_digital_storage_text()`
- `BipobInventoryControllerRef`

Risk: medium.

Recommended target:

- continue moving wrappers/state mutations into `scripts/bipob/bipob_inventory_controller.gd`.

Can extract now: yes, after runtime storage UI extraction.

Notes:

- This is a good second or third controller-side code extraction because a service already exists.

### 5. Scan / hack / terminal / digital interaction

Current owner: `BipobController`, partially extracted to `BipobScanHackService` and terminal execution service.

Observed responsibilities:

- scan/hack availability;
- terminal read/hack behavior;
- digital record creation/use;
- connector-dependent actions;
- Mission 2/4 story glue already removed from generic paths.

Risk: medium-to-high.

Recommended target:

- strengthen `scripts/game/bipob_scan_hack_service.gd` as the single scan/hack/read-terminal service;
- keep `BipobController` as wrapper/signal emitter.

Can extract now: not before Action/Inventory.

Reason:

- scan/hack touches digital storage, terminal/object runtime, and mission compatibility.

### 6. Map Constructor runtime bridge

Current owner: `BipobController` + `MissionManager` + `GameUI`.

Observed responsibilities:

- constructor readiness queries from UI;
- constructor default modules;
- module/capability readiness;
- layout/source id helpers;
- calls to MissionManager Map Constructor APIs.

Risk: medium.

Recommended target:

- `scripts/bipob/bipob_constructor_runtime_bridge.gd`
- or keep in `BipobController` until GameUI Map Constructor UI bridge is extracted.

Can extract now: not first.

Reason:

- Start from GameUI Map Constructor bridge. After UI surface is smaller, decide what controller-side bridge remains.

### 7. Legacy Mission 7 cable adapter

Current owner: `BipobController` delegates to `BipobLegacyCableFlowService`, but still exposes state and legacy predicate.

Important state/calls:

- `is_legacy_mission7_cable_flow_active()`
- `is_legacy_mission7_cable_drag_active()`
- `release_mission7_cable_end()`
- Mission 7 hardcoded state/positions remain legacy.

Risk: high.

Recommended target:

- do not refactor further inside GameUI/BipobController phase except documenting ownership;
- next real work should be generic cable/socket/power gameplay integration, not moving legacy hardcoding around.

Can extract now: no.

### 8. Legacy Mission 8 airflow adapter

Current owner: `BipobController` delegates to `BipobLegacyAirflowFlowService`, but still exposes state and legacy predicate.

Important state/calls:

- `is_legacy_mission8_airflow_flow_active()`
- `unlock_airflow_terminal_path()`
- `complete_legacy_mission8_airflow_terminal_hack()`
- Mission 8 hardcoded state/positions remain legacy.

Risk: high.

Recommended target:

- do not refactor further in this phase except documenting ownership;
- next real work should be generic airflow/cooling implementation and TASK TEST smoke.

Can extract now: no.

### 9. Constructor body/module model

Current owner: `BipobController`.

Observed responsibilities:

- external/internal module catalog/state;
- body profile sizes;
- internal grid and overlay path planning;
- thermal/cooling/damage preview helpers;
- constructor consistency/readiness helpers.

Risk: high.

Recommended target:

- `scripts/bipob/bipob_constructor_model.gd`
- `scripts/bipob/bipob_thermal_preview_service.gd`
- but only after UI constructor bridge is extracted.

Can extract now: no.

Reason:

- This is large and entangled with UI previews. Extracting it before UI cleanup will be risky.

## Recommended extraction sequence

### UICTRL-RF-02 — Extract GameUI Map Constructor UI bridge

Target:

- `scripts/ui/map_constructor/map_constructor_ui_bridge.gd`
- `scripts/ui/game_ui.gd`

Goal:

- move Map Constructor panel references, warning/readiness UI creation, overlay/overview refresh routing, and constructor screen coordination out of GameUI;
- keep existing specialized map-constructor components;
- no behavior changes.

Risk: medium.

Status after UICTRL-RF-02:

- `scripts/ui/map_constructor/map_constructor_ui_bridge.gd` now owns the moved Map Constructor readiness/warning card construction and validation overlay routing helpers.
- `scripts/ui/game_ui.gd` keeps compatibility wrappers for existing callback/callable surfaces and delegates bridge-safe orchestration to `MapConstructorUIBridge`.
- `ConstructorValidationOverlayControl` remains in GameUI as a draw-callback shim; moving that inner control is a follow-up only if the callback surface is made explicit.

Why first:

- active surface;
- existing extracted classes make this feasible;
- high line-count reduction potential.

Next recommended extraction:

- UICTRL-RF-03 should extract the runtime action/control panel bridge while preserving Runtime Action / Connect / Heavy Claw smoke behavior.

### UICTRL-RF-03 — Extract GameUI runtime action/control panel bridge

Target:

- `scripts/ui/runtime/runtime_control_panel.gd`
- optional `scripts/ui/runtime/runtime_action_panel_bridge.gd`
- `scripts/ui/game_ui.gd`

Goal:

- GameUI no longer owns detailed Action / Connect / Heavy Claw / End Turn button refresh and callback glue;
- keep behavior and action ids unchanged.

Risk: medium.

### UICTRL-RF-04 — Finish RuntimeStoragePanel ownership

Target:

- `scripts/ui/runtime/runtime_storage_panel.gd`
- `scripts/ui/game_ui.gd`

Goal:

- move runtime pocket/digital/manipulator slot rendering and storage callbacks out of GameUI;
- GameUI passes state and receives selected action callbacks only.

Risk: medium.

Status after UICTRL-RF-04:

- `scripts/ui/runtime/runtime_storage_panel.gd` owns the runtime storage callback routing and key-display helpers.
- `scripts/ui/game_ui.gd` keeps compatibility wrappers for existing callable names and delegates them to `RuntimeStoragePanel`.
- Inventory mutation rules remain in Bipob/MissionManager; the panel only invokes existing guarded public methods and refreshes host status.

Next recommended extraction:

- UICTRL-RF-05 should extract/strengthen the Bipob runtime action coordinator after the runtime action and storage UI surfaces are stable.

### UICTRL-RF-05 — Extract Bipob runtime action coordinator

Target:

- `scripts/bipob/bipob_action_controller.gd` or strengthened `scripts/game/bipob_runtime_action_actor_service.gd`
- `scripts/bipob/bipob_controller.gd`

Goal:

- BipobController stops coordinating detailed action execution branches;
- existing execution services remain implementation owners.

Risk: medium-to-high.

Dependency:

- do after UI action panel is stable.

### UICTRL-RF-06 — Finish Bipob inventory/storage controller boundary

Target:

- `scripts/bipob/bipob_inventory_controller.gd`
- `scripts/bipob/bipob_controller.gd`

Goal:

- move remaining digital/physical storage wrapper logic and state mutations into the inventory controller;
- keep public methods on BipobController as compatibility wrappers.

Risk: medium.

### UICTRL-RF-07 — Scan/hack/terminal boundary audit or extraction

Target:

- `scripts/game/bipob_scan_hack_service.gd`
- `scripts/game/bipob_terminal_control_execution_service.gd`
- `scripts/bipob/bipob_controller.gd`

Goal:

- ensure scan/hack/read-terminal has one owner and BipobController mostly wraps it.

Risk: medium-to-high.

### UICTRL-RF-08 — Final file-size and dependency audit

Goal:

- measure what remains in `GameUI` and `BipobController`;
- decide whether runtime session/movement/constructor model are ready for extraction;
- confirm TASK TEST/Map Constructor smoke is still the active verification path.

## Do not extract first

Do not start with:

- movement/action budget;
- runtime session startup;
- legacy Mission 7 cable adapter;
- legacy Mission 8 airflow adapter;
- constructor body/internal/external module model;
- old story mission compatibility.

These are high-risk and should wait until UI/runtime action/storage surfaces are smaller.

## Immediate next prompt recommendation

The next code PR should be:

**UICTRL-RF-05 — Extract Bipob runtime action coordinator**

Reason:

- UICTRL-RF-02, UICTRL-RF-03, and UICTRL-RF-04 have reduced the Map Constructor, runtime action, and runtime storage UI surfaces in `GameUI`;
- the remaining pressure is now on `BipobController` action coordination rather than introducing more runtime UI bridges;
- this should preserve TASK TEST / Map Constructor smoke behavior while continuing the feature-owner boundary work.

## Acceptance for this audit

This audit is complete when:

- GameUI feature areas are mapped;
- BipobController feature areas are mapped;
- extraction order is explicit;
- high-risk areas are marked not-first;
- TASK TEST / Map Constructor remain the active smoke surface;
- no gameplay files are changed.
