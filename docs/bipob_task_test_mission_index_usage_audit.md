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
- `MissionContentCatalog` owns canonical `task_test` layout data and resolves `mission_10` as a compatibility alias to it.
- `GridManager.get_mission10_layout()` and `reset_mission_layout(10)` remain emergency/legacy fallback layout compatibility only; normal TASK TEST startup does not use them when the catalog layout is present.

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
| `get_task_test_mission_id()` / `get_task_test_layout_id()` / `has_task_test_catalog_layout()`. | Safe compatibility boundary. | `get_task_test_layout_id()` now returns canonical `task_test`; `mission_10` remains only the compatibility mission id/alias. |
| `start_task_test_session()`. | TASK TEST boundary isolated. | Starts sandbox through shared runtime session helper. |
| `start_mission(10)` delegates to `start_task_test_session()`. | Safe compatibility boundary. | Keep until no external caller uses `start_mission(10)`. |
| `_start_runtime_session()` still sets `current_mission_index = mission_index`. | Compatibility state, still blocking final removal. | Acceptable for now; future step should store sandbox session id/layout id separately from story mission index. |
| `_start_runtime_session()` applies the catalog layout first for sandbox sessions and skips `reset_mission_layout(10)` when the TASK TEST catalog layout exists. | TASK TEST catalog boundary with quarantined compatibility fallback. | GridManager Mission 10 fallback is only for missing-catalog emergency/legacy compatibility; normal TASK TEST startup uses `task_test` catalog layout. |
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
| `TASK_TEST_LAYOUT_ID := "task_test"`. | Canonical semantic id. | Normal TASK TEST runtime layout loading uses this id. |
| `TASK_TEST_MISSION_ID := "mission_10"`. | Compatibility id. | Keep as alias/fallback for now; do not use as the normal runtime layout id. |
| `get_task_test_layout_id()` returns `task_test`. | Canonical TASK TEST layout boundary. | Normal startup requests the catalog layout by canonical id. |
| `get_task_test_source_id()` returns `task_test`; `get_task_test_sandbox_source_id()` mirrors it. | Canonical sandbox persistence/export boundary. | Use for new Map Constructor source metadata; the sandbox-named wrapper is the preferred TASK TEST boundary. |
| `is_task_test_mission_id()` accepts both `task_test` and `mission_10`. | Safe compatibility boundary. | Keep. |
| `resolve_task_test_catalog_id()` resolves both `task_test` and `mission_10` to canonical `task_test`. | Compatibility alias boundary. | Keeps old `mission_10` callers accepted without making them the normal layout source. |
| `setup_world_objects_for_mission()` dispatches TASK TEST by `is_task_test_mission_id()`. | Legacy compatibility boundary. | Still accepts `task_test` / `mission_10`, but now delegates TASK TEST setup to `setup_task_test_sandbox_world()`. |
| `setup_task_test_sandbox_world()` is the preferred runtime setup API; `_setup_task_test_mission_world()` remains as a compatibility wrapper. | Sandbox runtime setup boundary. | The sandbox wrapper pulls seed data through `TaskTestWorldBuilder`; keep the mission-named wrapper until external compatibility callers are retired. |
| `build_task_test_sandbox_world_objects_for_validation()` is the preferred validation API; `build_task_test_mission_world_objects_for_validation()` remains as a compatibility wrapper. | Sandbox validation boundary. | Both preserve behavior-equivalent Map Constructor validation/build data through `TaskTestWorldBuilder.build_validation_world_objects()`. |
| Map Constructor APIs gate through `_is_task_test_constructor_context()`. | TASK TEST boundary isolated. | Correct. |
| Preset/patch export defaults `source_mission_id` / source metadata to `task_test`. | Canonicalized. | New Map Constructor presets, runtime patches, mission patch exports, and design notes use `task_test`; `mission_10` remains accepted only for old imports/loads. |

Conclusion: MissionManager is now mode-aware, TASK TEST setup/validation has sandbox-named API boundaries backed by `TaskTestWorldBuilder`, and mission-named methods remain compatibility wrappers. New Constructor persistence/export source metadata uses canonical `task_test` while keeping `mission_10` import compatibility.

## 4. MissionContentCatalog

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `TASK_TEST_LAYOUT_ID := "task_test"`. | Canonical semantic id. | Normal TASK TEST runtime layout loading uses this id. |
| `TASK_TEST_MISSION_ID := "mission_10"`. | Compatibility id. | Keep as alias/fallback. |
| `_MISSION_ALIASES = {"mission_10": "task_test"}`. | Compatibility alias. | Correct direction: `task_test` is canonical and `mission_10` remains accepted. |
| `task_test` definition contains TASK TEST layout and metadata. | Canonical catalog source. | Keep `mission_10` alias until old callers/imports are retired. |
| Validation checks canonical `task_test` metadata/layout and verifies `mission_10` aliases to it. | Compatibility check. | Keep alias validation until old callers/imports are retired. |

Conclusion: MissionContentCatalog now makes `task_test` the canonical data owner for TASK TEST while preserving `mission_10` as an alias.

## 5. GridManager

| Usage | Classification | Retirement note |
| --- | --- | --- |
| `get_mission10_layout()`. | Emergency/legacy compatibility fallback. | Normal TASK TEST startup uses the `task_test` catalog layout; keep this only until compatibility callers are retired and smoke proves removal safe. |
| `reset_mission_layout(10)`. | Emergency/legacy compatibility fallback. | `start_mission(10)` delegates to TASK TEST startup; normal successful TASK TEST layout loading does not call this when catalog layout exists. |
| Mission 7/8/9 layout helpers. | Legacy story resources. | Keep until reusable cable/airflow/terrain mechanics are generic and old mission resources are retired. |

Conclusion: GridManager still owns old hardcoded layouts. TASK TEST normal startup uses the canonical catalog layout, and the mission10 fallback remains quarantined as compatibility-only.

## Remaining blockers before old mission deletion

1. **GridManager Mission 10 fallback still exists for compatibility.**
   - Normal TASK TEST startup is catalog-only through `task_test` when the catalog layout is present.
   - `mission_10` and `reset_mission_layout(10)` remain compatibility fallbacks until old callers/resources can be removed safely.

2. **TASK TEST world content builder is exposed through sandbox-named MissionManager wrappers.**
   - `TaskTestWorldBuilder` owns the behavior-equivalent TASK TEST seed object and item construction.
   - `setup_task_test_sandbox_world()` and `build_task_test_sandbox_world_objects_for_validation()` are the preferred runtime setup and validation boundaries.
   - `_setup_task_test_mission_world()` and `build_task_test_mission_world_objects_for_validation()` remain MissionManager compatibility wrappers for old callers.

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

Status: completed. `TaskTestWorldBuilder` now owns behavior-equivalent TASK TEST world-object and item seed construction. MissionManager now exposes sandbox-named setup/validation wrappers and keeps `_setup_task_test_mission_world()` and `build_task_test_mission_world_objects_for_validation()` as compatibility wrappers. Map Constructor validation/build paths continue to use the same builder output, and no mission resources were removed.

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

### PR-RF-31 completion note — TASK TEST objective/helper boundary

Status: completed. TASK TEST objective/goal text now has explicit helper boundaries before legacy mission hint lookup:

- `MissionManager.get_task_test_goal_text()` and `MissionManager.get_task_test_objective_hint()` read the canonical `task_test` catalog definition first and keep `mission_10` as compatibility fallback.
- `BipobController.get_task_test_goal_text()` and `BipobController.get_task_test_objective_hint()` delegate to MissionManager helpers and avoid adding a new UI-facing mission-index `10` path.
- `GameUI` uses `_is_task_test_runtime_active()` before selecting objective text, then asks BipobController for TASK TEST goal/hint values. Legacy story objective/hint display continues to use the existing view-model and `get_mission_goal_hint()` compatibility flow.

No TASK TEST mechanics, Map Constructor behavior, Mission 7 cable behavior, Mission 8 airflow behavior, scan/hack, inventory, movement, mission resources, scenes, or `project.godot` changed.

## PR-RF-34 update — TASK TEST session state source of truth

`current_mission_index = 10` is now classified as a compatibility mirror only during TASK TEST startup. TASK TEST runtime/session decisions should use explicit session state instead:

- `active_runtime_mode_id` wins when set.
- `current_mission_id` / canonical `task_test` layout id are the session/layout identity.
- `get_runtime_mode_id()`, `is_task_test_mode_active()`, and `is_sandbox_mode_active()` are the runtime gates.
- `get_task_test_layout_id()` and `get_task_test_source_id()` are the canonical layout/source id boundaries.

### PR-RF-34 usage classification

| Usage | Classification | Status |
| --- | --- | --- |
| `current_mission_index = TASK_TEST_MISSION_INDEX` in `BipobController._start_runtime_session()` | TASK TEST compatibility mirror. | Kept with an inline comment; explicit runtime mode/current mission id are authoritative. |
| `BipobController.get_runtime_mode_id()` fallback from `current_mission_index == TASK_TEST_MISSION_INDEX` | Legacy/compatibility fallback. | Kept only after `active_runtime_mode_id` and `current_mission_id` checks. |
| `BipobController.start_mission(10)` | Compatibility entry point. | Kept; delegates to `start_task_test_session()`. |
| `BipobController.get_mission_layout_id(10)` / `get_mission_goal_hint(10)` | Compatibility helper/story-hint fallback. | Kept; active TASK TEST layout/objective paths use TASK TEST helpers first. |
| Sandbox layout reset fallback to `reset_mission_layout(current_mission_index)` | Quarantined GridManager compatibility fallback. | Kept only for missing TASK TEST catalog layout emergency compatibility. |
| GameUI raw `current_mission_index == 10` | UI fallback helper only. | Remains centralized inside `_is_task_test_runtime_active()` and should not spread. |

Old story missions are still not ready for deletion; Mission 7 cable behavior, Mission 8 airflow behavior, legacy progression/hints, and compatibility resources remain deliberately retained.

## PR-RF-35 update — sandbox-named setup/validation boundaries

Status: completed for code-side decoupling. TASK TEST runtime setup now prefers `MissionManager.setup_task_test_sandbox_world()`, and validation paths use `build_task_test_sandbox_world_objects_for_validation()` internally. The old mission-named methods remain present as compatibility wrappers, `setup_world_objects_for_mission()` still supports legacy story setup and routes `task_test` / `mission_10` to the sandbox wrapper, and `TaskTestWorldBuilder` remains the only TASK TEST seed-data source.

This is the final code decoupling step before the final audit. It does not mean old mission resources, GridManager Mission 10 fallback, `mission_10`, or `current_mission_index` are ready for deletion.
