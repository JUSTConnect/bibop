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
