# BIPOB PR-RF-28 — TASK TEST mission-index usage audit

## Purpose

This docs-only audit records the remaining `current_mission_index`, `TASK_TEST_MISSION_INDEX`, `mission_10`, and `task_test` usage after PR-RF-27.

The goal is not to delete old missions yet. The goal is to separate which references are now safe compatibility boundaries from the references that still block removing legacy story mission resources.

Project direction remains:

- TASK TEST / Map Constructor / runtime sandbox is the active product surface.
- Old story missions 1-9 are deprecated and will be replaced later from scratch.
- Useful mechanics from old missions must survive if they are reusable.
- Mission resources/scenes/layouts should be removed only after TASK TEST startup, restart, completion, Map Constructor, runtime actions, scan/hack, inventory, and movement pass smoke without depending on legacy mission-index paths.

## Current high-level state

### TASK TEST is no longer only mission index 10

The main TASK TEST runtime boundaries now exist:

- `active_runtime_mode_id`
- `get_runtime_mode_id()`
- `is_task_test_mode_active()`
- `is_sandbox_mode_active()`
- `start_task_test_session()`
- `restart_task_test_session()`
- `reset_task_test_session()`
- `complete_sandbox_run()`
- GameUI `_is_task_test_runtime_active()`
- GameUI `_restart_task_test_from_result_screen()`

`current_mission_index == 10` and `mission_10` remain compatibility state/ids. They should not be used as new semantic TASK TEST checks outside helper boundaries.

### TASK TEST still has compatibility anchors

The following compatibility anchors still exist and should remain until the next isolation steps are done:

- `BipobController.TASK_TEST_MISSION_INDEX == 10`
- `BipobController.current_mission_index` still becomes `10` during TASK TEST session startup.
- `MissionManager.TASK_TEST_MISSION_ID == "mission_10"`
- `MissionManager.TASK_TEST_LAYOUT_ID == "task_test"`
- `MissionContentCatalog` currently resolves `task_test` to `mission_10`.
- `GridManager.get_mission10_layout()` and `reset_mission_layout(10)` remain fallback layout compatibility.

## Usage classification

### 1. GameUI

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `_is_task_test_runtime_active()` uses `bipob.is_task_test_mode_active()` first and falls back to `current_mission_index == 10`. | Safe compatibility boundary. | Keep as the only raw index fallback in GameUI until every runtime has the controller helper. |
| `_toggle_map_constructor_mode()` gates through `_is_task_test_runtime_active()`. | TASK TEST boundary isolated. | Correct; do not reintroduce raw mission index checks here. |
| Dev TASK TEST card resolves mission/layout id through controller helpers. | TASK TEST boundary isolated. | Correct; the UI no longer embeds `mission_10` directly for the dev card. |
| Dev start button calls `start_task_test_session()`. | TASK TEST boundary isolated. | Correct. |
| Restart button uses `reset_task_test_session()` when `_is_task_test_runtime_active()` is true. | TASK TEST boundary isolated. | Correct. |
| Mission-result restart calls `_restart_task_test_from_result_screen()` before legacy mission-id restart. | TASK TEST boundary isolated. | Correct; raw `current_mission_index` mutation remains legacy-only fallback. |

Conclusion: GameUI is mostly clean for the current stage. The raw TASK TEST mission-index fallback is centralized inside `_is_task_test_runtime_active()`.

## 2. BipobController

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `TASK_TEST_MISSION_INDEX := 10`. | Compatibility boundary. | Keep until `task_test` session can start without exposing index 10 even internally. |
| `current_mission_index`. | Legacy compatibility state, still blocking final mission-index removal. | TASK TEST identity no longer depends only on it, but old story progression, hints, and setup still do. |
| `active_runtime_mode_id`. | TASK TEST boundary isolated. | Primary runtime identity when a runtime session is active. |
| `get_runtime_mode_id()` falls back from `active_runtime_mode_id` to `current_mission_index`. | Safe compatibility boundary. | Later remove fallback after all startup/restart/completion/UI paths use explicit runtime mode. |
| `get_task_test_mission_id()` / `get_task_test_layout_id()`. | Safe compatibility boundary. | Good API surface. Next step should make `task_test` canonical in catalog while keeping `mission_10` alias. |
| `start_task_test_session()`. | TASK TEST boundary isolated. | Starts sandbox through shared runtime session helper. |
| `start_mission(10)` delegates to `start_task_test_session()`. | Safe compatibility boundary. | Keep until no external caller uses `start_mission(10)`. |
| `_start_runtime_session()` still sets `current_mission_index = mission_index`. | Compatibility state, still blocking final removal. | Acceptable for now; future step should store sandbox session id/layout id separately from story mission index. |
| `_start_runtime_session()` uses `grid_manager.reset_mission_layout(current_mission_index)` as fallback. | Compatibility fallback. | For TASK TEST primary path catalog layout is attempted first; fallback can remain until GridManager mission10 layout is retired. |
| Mission 7/8/9 setup branches by legacy predicates/index. | Legacy story glue / reusable mechanic boundary. | Keep until generic cable and generic airflow runtime services are wired and smoke-tested. |
| `restart_current_mission()` dispatches sandbox restart before legacy restart. | TASK TEST boundary isolated. | Correct. |
| `return_to_box()` still releases Mission 7 drag and emits Mission 9 hint. | Legacy story glue. | Keep until Mission 7/9 legacy flows are retired. |
| `start_next_mission()`. | Legacy story progression. | Not used for TASK TEST path once GameUI is routed correctly; remove with story progression. |
| `complete_sandbox_run()`. | TASK TEST boundary isolated. | Correct. |
| `complete_legacy_story_mission()`. | Legacy story progression. | Keep until old story completion/progression is removed. |

Conclusion: BipobController still carries mission-index compatibility, but TASK TEST startup/restart/completion identity is isolated enough to proceed to catalog/session cleanup.

## 3. MissionManager

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `current_mission_id`. | Runtime/session id boundary. | Better than numeric mission index; keep. |
| `active_runtime_mode_id`. | TASK TEST boundary isolated. | Correct. |
| `TASK_TEST_LAYOUT_ID := "task_test"`. | Desired semantic id. | Should become the canonical catalog id. |
| `TASK_TEST_MISSION_ID := "mission_10"`. | Compatibility id. | Keep as alias/fallback for now. |
| `get_task_test_layout_id()` tries `task_test`, falls back to `mission_10`. | Safe compatibility boundary. | Good transition helper. |
| `is_task_test_mission_id()` accepts both `task_test` and `mission_10`. | Safe compatibility boundary. | Keep. |
| `resolve_task_test_catalog_id()` resolves `task_test` to `mission_10` if catalog does not have `task_test`. | Compatibility fallback. | Next step should invert this once `task_test` is canonical. |
| `setup_world_objects_for_mission()` dispatches TASK TEST by `is_task_test_mission_id()`. | TASK TEST boundary isolated. | Good. |
| `_setup_task_test_mission_world()` remains in MissionManager as the runtime setup wrapper. | TASK TEST runtime setup compatibility boundary. | The wrapper now pulls seed data through `TaskTestWorldBuilder`; keep it until external callers no longer need the MissionManager method. |
| `build_task_test_mission_world_objects_for_validation()`. | TASK TEST validation compatibility wrapper. | Delegates to `TaskTestWorldBuilder.build_validation_world_objects()` while preserving the existing MissionManager API. |
| Map Constructor APIs gate through `_is_task_test_constructor_context()`. | TASK TEST boundary isolated. | Correct. |
| Preset/patch export defaults `source_mission_id` to `mission_10`. | Compatibility leak. | Later default to canonical `task_test`, while still accepting `mission_10` on import. |

Conclusion: MissionManager is now mode-aware, and TASK TEST seed object construction is delegated to `TaskTestWorldBuilder`. Constructor persistence still keeps `mission_10` compatibility in several places.

## 4. MissionContentCatalog

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `TASK_TEST_LAYOUT_ID := "task_test"`. | Desired semantic id. | Should become canonical. |
| `TASK_TEST_MISSION_ID := "mission_10"`. | Compatibility id. | Keep as alias/fallback. |
| `_MISSION_ALIASES = {"task_test": "mission_10"}`. | Compatibility direction still points semantic id to legacy id. | Next step should make `task_test` canonical and `mission_10` an alias to it. |
| `mission_10` definition contains TASK TEST layout and metadata. | Compatibility anchor still blocking final removal. | Move or mirror this definition under `task_test` in a behavior-preserving PR. |
| Validation hard-checks `mission_10` display name, role, migration status, layout source, and `world_content_source == legacy_mission_manager`. | Blocker. | Update validation to check canonical `task_test` and accept `mission_10` only as compatibility alias. |

Conclusion: MissionContentCatalog is the next best target. It still makes `mission_10` the canonical data owner for TASK TEST.

## 5. GridManager

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `get_mission10_layout()`. | Compatibility fallback. | Keep until catalog layout is proven and no TASK TEST start path falls back to GridManager layout. |
| `reset_mission_layout(10)`. | Compatibility fallback. | Keep for `start_mission(10)`/legacy fallback only. Later move behind explicit compatibility helper or delete after smoke. |
| Mission 7/8/9 layout helpers. | Legacy story resources. | Keep until reusable cable/airflow/terrain mechanics are generic and old mission resources are retired. |

Conclusion: GridManager still owns old hardcoded layouts. TASK TEST currently prefers catalog layout, but the mission10 fallback remains.

## Remaining blockers before old mission deletion

1. **Canonical TASK TEST id is still `mission_10` inside MissionContentCatalog.**
   - `task_test` exists, but currently aliases to `mission_10`.
   - Validation still requires `mission_10`.

2. **TASK TEST world content builder is extracted behind MissionManager wrappers.**
   - `TaskTestWorldBuilder` owns the behavior-equivalent TASK TEST seed object and item construction.
   - `_setup_task_test_mission_world()` and `build_task_test_mission_world_objects_for_validation()` remain MissionManager compatibility wrappers for runtime setup and validation callers.

3. **`current_mission_index` still exists in BipobController.**
   - TASK TEST no longer depends on it as the only identity source.
   - It still supports legacy story progression, hint table, and setup branches.

4. **GridManager still has `get_mission10_layout()` and `reset_mission_layout(10)`.**
   - These are now fallback, not primary TASK TEST path.
   - Do not remove until catalog-only TASK TEST layout has local smoke coverage.

5. **Mission 7 and Mission 8 reusable mechanics are still legacy-owned.**
   - Cable has contract/state/service/checks but no gameplay wiring.
   - Airflow has contract only.
   - Old Mission 7/8 resources must remain until generic implementations exist and pass TASK TEST smoke.

## Recommended next PR sequence

### PR-RF-29 — Make `task_test` the canonical catalog id while keeping `mission_10` alias

Goal: invert the current catalog relationship so `task_test` is the canonical TASK TEST definition and `mission_10` is compatibility.

Scope suggestion:

- Move the current TASK TEST catalog definition from `mission_10` to `task_test`, or introduce a canonical `task_test` definition that reuses the same layout data safely.
- Change alias direction so `mission_10` resolves to `task_test`.
- Keep `MissionManager.is_task_test_mission_id()` accepting both ids.
- Update catalog validation to validate canonical `task_test`, while accepting `mission_10` as alias.
- Preserve `mission_10` fallback compatibility for external callers.
- No gameplay behavior changes.
- No resource deletion.

### PR-RF-30 — Extract TASK TEST world-object builder from MissionManager

Status: completed. `TaskTestWorldBuilder` now owns behavior-equivalent TASK TEST world-object and item seed construction, while MissionManager keeps `_setup_task_test_mission_world()` and `build_task_test_mission_world_objects_for_validation()` as compatibility wrappers. Map Constructor validation/build paths continue to use the same wrapper output, and no mission resources were removed.

### PR-RF-31 — Add TASK TEST objective/view-model boundary independent of legacy hint table

Goal: make TASK TEST objective UI use MissionManager/catalog runtime objective data instead of `get_mission_goal_hint(10)` / legacy mission hint table.

Scope suggestion:

- Route TASK TEST goal/hint through catalog/runtime objective view model.
- Keep story mission hints unchanged for legacy missions.

### PR-RF-32 — Retire GridManager mission10 fallback only after catalog smoke

Goal: remove or quarantine `get_mission10_layout()` and `reset_mission_layout(10)` after catalog-only TASK TEST layout has been proven.

Scope suggestion:

- Only after local Godot parser/startup and TASK TEST smoke pass.
- Keep old Mission 7/8/9 layouts until their reusable mechanics are generic.

## Do-not-change in this audit

This audit is documentation only. It does not change:

- TASK TEST mechanics.
- Map Constructor behavior.
- Mission 7 cable behavior.
- Mission 8 airflow behavior.
- scan/hack.
- inventory.
- movement.
- mission resources/scenes.
- `project.godot`.

## Required smoke before continuing deletion work

Before any deletion of mission resources or removal of mission-index compatibility:

1. Run Godot parser gate.
2. Start TASK TEST from UI.
3. Enter Map Constructor.
4. Place/edit/delete an object.
5. Exit Map Constructor.
6. Restart/reset TASK TEST.
7. Complete/reach result screen if available.
8. Restart TASK TEST from result screen.
9. Move/turn Bipob.
10. Check Runtime Action / Connect / Heavy Claw.
11. Scan/hack runtime device if available.
12. Pick up/drop item if available.
13. Confirm no old story mission progression runs for TASK TEST.
