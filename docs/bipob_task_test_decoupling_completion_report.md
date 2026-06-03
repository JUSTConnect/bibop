# BIPOB PR-RF-36 — TASK TEST decoupling completion report

## Purpose

This docs-only report closes the current code-side effort to separate TASK TEST / Map Constructor / runtime sandbox from the legacy `mission_10` story-mission identity.

This report does **not** approve deletion of old story mission resources. It records that the TASK TEST decoupling track is complete enough to stop doing mission-index cleanup PRs and move to the next product/technical phase.

## Completion summary

The code-side TASK TEST / legacy mission-flow decoupling is complete for the current target scope.

TASK TEST is now treated as a sandbox/runtime surface through explicit boundaries instead of as normal story Mission 10.

The canonical TASK TEST identity is:

- runtime mode: `task_test`
- catalog/layout/source id: `task_test`
- compatibility id: `mission_10`
- compatibility numeric index: `10`

`mission_10` and `current_mission_index = 10` remain compatibility mirrors only. They should not be used for new TASK TEST logic.

## What is now decoupled

### Runtime identity

TASK TEST runtime identity is explicit:

- `active_runtime_mode_id`
- `current_mission_id`
- `get_runtime_mode_id()`
- `is_task_test_mode_active()`
- `is_sandbox_mode_active()`

`current_mission_index == 10` is now only a fallback after explicit runtime/session ids.

### Startup / restart / reset

TASK TEST has explicit session entry points:

- `start_task_test_session()`
- `restart_task_test_session()`
- `reset_task_test_session()`

`start_mission(10)` still exists, but only as a compatibility wrapper that delegates into TASK TEST startup.

`restart_current_mission()` dispatches to TASK TEST restart when sandbox mode is active and otherwise uses legacy story restart.

### Mission result restart

GameUI mission-result restart checks the TASK TEST runtime boundary first and calls the TASK TEST restart/reset helper before any legacy mission-id restart fallback.

The legacy result-screen path still exists for old story missions.

### GameUI TASK TEST detection

GameUI TASK TEST detection is centralized through `_is_task_test_runtime_active()`.

Raw numeric fallback, if still present, belongs only inside that helper boundary. New GameUI code should not add direct `current_mission_index == 10` checks.

### Catalog/layout identity

`task_test` is now the canonical MissionContentCatalog id.

`mission_10` is an alias/compatibility id that resolves to `task_test`.

Normal TASK TEST startup uses canonical `task_test` catalog layout data. GridManager Mission 10 layout remains only an emergency/legacy fallback.

### Map Constructor persistence

New Map Constructor exports/presets/patches/design-note metadata use canonical `task_test` source ids.

Old data that contains `mission_10` remains accepted and normalized to `task_test` on import/load paths.

### TASK TEST objective text

TASK TEST objective/goal/hint text is routed through catalog/runtime helper boundaries.

Legacy story mission hint tables remain available for old story missions, but TASK TEST objective UI does not need `get_mission_goal_hint(10)` as the normal path.

### TASK TEST world seed/setup

TASK TEST seed data is owned by `TaskTestWorldBuilder`.

MissionManager now exposes sandbox-named APIs:

- `setup_task_test_sandbox_world()`
- `build_task_test_sandbox_world_objects_for_validation()`
- `get_task_test_sandbox_layout_id()`
- `get_task_test_sandbox_source_id()`

Mission-named methods remain as compatibility wrappers:

- `setup_world_objects_for_mission()`
- `_setup_task_test_mission_world()`
- `build_task_test_mission_world_objects_for_validation()`

TASK TEST runtime setup prefers the sandbox-named wrapper.

## Compatibility-only items that remain

These are expected to remain after this phase:

| Item | Current role | Removal status |
| --- | --- | --- |
| `mission_10` | Compatibility alias/import/start wrapper id. | Keep for now. |
| `TASK_TEST_MISSION_INDEX == 10` | Numeric compatibility mirror for old callers/UI fallback. | Keep for now. |
| `current_mission_index = 10` during TASK TEST | Compatibility mirror only. | Keep for now. |
| `start_mission(10)` | Compatibility entry point that delegates to TASK TEST startup. | Keep until external callers are retired. |
| `GridManager.get_mission10_layout()` | Emergency/legacy fallback layout. | Keep until smoke proves no fallback callers remain. |
| `GridManager.reset_mission_layout(10)` | Emergency/legacy fallback layout reset. | Keep until safe removal PR. |
| Mission-named MissionManager methods | Backward-compatible wrappers. | Keep until external callers are retired. |

## What is not ready for deletion

Old mission deletion is **not** approved by this report.

### Mission 7 cable/socket/power

Mission 7 reusable mechanics are preserved but not fully generic yet.

Current state:

- legacy behavior isolated behind `BipobLegacyCableFlowService`;
- generic cable/socket/power contract exists;
- `BipobCableRuntimeState` exists;
- `BipobCableRuntimeService` skeleton exists;
- non-gameplay checks exist;
- generic cable gameplay is **not wired into TASK TEST/runtime gameplay yet**.

Do not delete old Mission 7 resources/state until generic cable/socket/power gameplay exists and passes TASK TEST smoke.

### Mission 8 fan/platform/airflow/cooling

Mission 8 reusable mechanics are preserved but not generic yet.

Current state:

- legacy behavior isolated behind `BipobLegacyAirflowFlowService`;
- generic airflow/cooling contract exists;
- generic runtime implementation is not complete;
- generic airflow gameplay is not TASK TEST-smoked yet.

Do not delete old Mission 8 resources/state until generic airflow/cooling gameplay exists and passes TASK TEST smoke.

### Legacy story progression / selection

Old story mission progression and compatibility APIs still exist.

They should be removed only when the project intentionally removes old story missions and after reusable mechanics have generic replacements.

## Definition of done for this phase

This phase is complete when the following statement is true:

> TASK TEST normal startup/restart/reset/result restart/layout/objective/world setup/Map Constructor persistence no longer require `mission_10` or numeric mission index 10 as their semantic source of truth.

That statement is now true for the code-side PR-RF chain.

Remaining `mission_10` / index 10 references are compatibility wrappers/fallbacks, not normal TASK TEST architecture.

## Required verification before moving on

Run locally because the Codex environment repeatedly lacked Godot CLI:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Manual smoke:

1. Start TASK TEST from UI.
2. Confirm runtime mode reports TASK TEST / sandbox.
3. Confirm TASK TEST layout/start/exit unchanged.
4. Confirm expected TASK TEST world objects appear.
5. Enter Map Constructor.
6. Place/edit/delete an object.
7. Save/export a preset or patch if available and confirm new metadata uses `task_test`.
8. Load/import legacy `mission_10` preset/patch if available and confirm compatibility.
9. Exit Map Constructor.
10. Restart/reset TASK TEST.
11. Reach result/completion screen if available.
12. Restart TASK TEST from result screen.
13. Confirm `start_mission(10)` compatibility still starts TASK TEST if reachable.
14. Move/turn Bipob.
15. Check Runtime Action / Connect / Heavy Claw.
16. Scan/hack runtime device if available.
17. Pick up/drop item if available.

## Recommended next phase

Stop doing further mission-index cleanup PRs unless a real bug appears.

Recommended choices:

1. Return to TASK TEST / Map Constructor / runtime mechanics work.
2. Start generic cable/socket/power gameplay integration for TASK TEST, replacing dependence on old Mission 7 behavior.
3. Start generic fan/platform/airflow/cooling implementation for TASK TEST, replacing dependence on old Mission 8 behavior.
4. Audit and reduce `GameUI` / `BipobController` by feature area now that TASK TEST boundaries are clearer.

Preferred next practical step:

**Return to TASK TEST mechanics/editor/runtime work**, because the decoupling target has reached a useful stopping point.

## Do not do next

Do not immediately delete old missions 1-9.

Do not delete Mission 7 or Mission 8 resources yet.

Do not remove `mission_10`, `current_mission_index`, or GridManager Mission 10 fallback in the next PR unless a full local Godot smoke pass confirms no compatibility use remains and reusable mechanics are accounted for.
