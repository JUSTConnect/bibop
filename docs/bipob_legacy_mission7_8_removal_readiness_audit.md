# PR-LEGACY-RM-02 — Mission 7/8 physical deletion completion

Status: retired legacy Mission 7 and Mission 8 runtime code/resources are **physically deleted from active code paths**.

Product decision remains unchanged: the old Mission 7/8 story flows will not be used in the future. PR-LEGACY-RM-01 quarantined them from active runtime paths; PR-LEGACY-RM-02 removes the remaining retired compatibility services, controller state/methods, layout helpers, HUD/status branches, and legacy-dependency readiness warnings.

## What was removed

- Deleted `scripts/game/bipob_legacy_cable_flow_service.gd` and its Godot UID file.
- Deleted `scripts/game/bipob_legacy_airflow_flow_service.gd` and its Godot UID file.
- Removed Mission 7 `mission7_*` state, cable drag/setup/release/status methods, legacy cable predicates, and service preload from `BipobController`.
- Removed Mission 8 `mission8_*` state, fan/platform/terminal/setup/status methods, airflow predicates, terminal-unlock wrapper, and service preload from `BipobController`.
- Removed `GridManager.get_mission7_layout()` and `GridManager.get_mission8_layout()`.
- Removed Mission 7/8 catalog stubs from `MissionContentCatalog`.
- Removed Mission 7/8 HUD/status and selection-guard branches from `GameUI`.
- Removed legacy Mission 7 snapshot helpers/checks from the generic cable runtime state/service CI coverage.
- Removed Map Constructor legacy Mission 7/8 dependency warnings that only existed to block physical deletion.

## Preserved active surfaces

- TASK TEST remains the active smoke surface for reusable mechanics.
- Generic cable/socket/power runtime remains active and independent from old Mission 7 state.
- Generic fan/airflow/cooling runtime remains active and independent from old Mission 8 state.
- Map Constructor validation still reports generic cable/power and generic airflow/cooling readiness issues.
- Mission 1-6 and Mission 9 remain the only active legacy story mission ids in Tasks career selection.
- Mission progression still skips from Mission 6 to Mission 9.

## Remaining historical references

Some historical design/audit documents still mention Mission 7/8, legacy service names, or migration-era blocker states. Those references are documentation history only and are not runtime preloads, parser dependencies, selection paths, layout helpers, or active TASK TEST dependencies.

Generic tile constants and visual labels for cable/socket/powered-gate and fan/airflow/cooling concepts remain because TASK TEST, Map Constructor, room rendering, and generic runtime validation still use those reusable concepts.

## Recommendation

Treat Mission 7/8 legacy deletion as complete. Future cleanup should update or archive older historical docs opportunistically, but should not remove generic cable/socket/power or generic fan/airflow/cooling systems.

## Post-deletion gate status — 2026-06-04

BIPOB POST-LEGACY-RM-GATE static verification was run after the Mission 7/8 physical deletion.

### Gates

- `git diff --check` passed.
- `python tools/check_gdscript_safety_patterns.py` passed with existing heuristic callback-guard warnings only; it reported no hard safety-pattern issues.
- `python tools/check_map_constructor_sections.py` passed.
- `godot --headless --path . --script res://tools/ci/parse_all_gd.gd` was not run because `godot` was unavailable in this environment (`command not found`).

### Active mission surface

- Active catalog mission keys remain `mission_1` through `mission_6`, `mission_9`, and `task_test`.
- `mission_7` and `mission_8` remain absent from active catalog keys.
- `mission_10` remains a compatibility alias for `task_test`.
- `BipobController` still treats mission indexes 7 and 8 as retired, skips them when advancing missions, and keeps Mission 6 completion messaging pointed at Mission 9.

### Deleted-reference search

No active `scripts/`, `tools/`, `scenes/`, or `project.godot` references were found for the deleted Mission 7/8 service names, deleted service script paths, legacy Mission 7/8 state prefixes, retired layout helper names, or the old Mission 8 terminal cooled flag. Historical references remain in older documentation only.

### Runtime smoke status from static verification

- TASK TEST generic cable objects remain declared, including `task_test_generic_powered_device` and `task_test_generic_unpowered_device`.
- The generic cable runtime service and state remain present and are still preloaded/refreshed by `MissionManager`.
- TASK TEST generic airflow objects remain declared, including `task_test_generic_airflow_target`, `task_test_generic_airflow_blocker`, and `task_test_generic_uncooled_target`.
- The generic airflow runtime service and state remain present and are still preloaded/refreshed by `MissionManager`.
- Scan/hack airflow terminal readiness no longer reads `mission8_terminal_cooled`; it reads world-object `cooling_required` and `is_cooled` fields.
- Map Constructor validation still preloads the generic cable and generic airflow runtime services and still emits generic cable/airflow validation warnings.

### Manual follow-up still required

Because the Godot CLI was unavailable here, in-editor/manual smoke should still confirm that TASK TEST starts/restarts, the Map Constructor opens, generic cable/airflow warnings are visible, Runtime Action / Connect / Heavy Claw remain operational, and cooled/uncooled scan-hack terminal cases behave as expected at runtime.
