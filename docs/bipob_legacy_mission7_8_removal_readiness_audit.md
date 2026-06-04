# PR-LEGACY-RM-01 — Mission 7/8 quarantine and removal-readiness audit

Status: legacy Mission 7 and Mission 8 are **retired/quarantined but not physically deleted**.

This audit supersedes the PR-GEN-04 deletion-readiness note for Mission 7/8. Product decision: old Mission 7/8 story flows will not be used in the future. PR-LEGACY-RM-01 disconnects them from active selectable/runtime paths while keeping files, services, metadata stubs, and parser-safe compatibility methods in place for a later physical deletion PR.

## Active replacements

- **TASK TEST** remains the active smoke surface for reusable mechanics.
- **Generic cable/socket/power runtime** remains active through TASK TEST, MissionManager generic cable reports, and Map Constructor validation.
- **Generic fan/airflow/cooling runtime** remains active through TASK TEST, MissionManager generic airflow reports, and Map Constructor validation.
- **Map Constructor validation** remains active and continues reporting generic cable/power and generic airflow/cooling readiness issues.

## Runtime quarantine applied in PR-LEGACY-RM-01

- Mission 7/8 are no longer included in the active Tasks mission list.
- `BipobController.start_mission(7)` and `start_mission(8)` now stop with a retired-mission hint instead of launching legacy runtime setup.
- Legacy story progression skips from Mission 6 to Mission 9.
- Runtime-mode classification no longer treats `mission_7` or `mission_8` as active legacy story missions.
- `GridManager.reset_mission_layout(7/8)` no longer selects the retired Mission 7/8 layouts; those layout functions remain in the file only for compatibility until deletion.
- Mission 7 cable HUD/status branches and Mission 8 airflow HUD/status branches are gated behind legacy-active checks, which are now false for retired missions.
- Legacy Mission 7 cable tile handling and Mission 8 fan/platform control tile handling are gated behind legacy-active checks, which prevents those flows from being reached through active runtime interaction.
- Mission catalog entries for `mission_7` and `mission_8` are retained as `retired_quarantined` metadata stubs.

## Mission 7 — cable/socket/power legacy flow

### Current state

Mission 7 is retired and disconnected from active mission launch/selection paths. Its legacy files are still present for parser safety and staged cleanup only.

### Files/services still intentionally present

- `scripts/game/bipob_legacy_cable_flow_service.gd`
- `scripts/bipob/bipob_controller.gd` Mission 7 compatibility state and method stubs
- `scripts/field/grid_manager.gd` `get_mission7_layout()` compatibility layout data
- parser/CI checks that snapshot legacy Mission 7 dictionaries while validating generic cable service behavior

### Replacement surface

Use TASK TEST generic cable/socket/power smoke and Map Constructor validation. Do not add new dependencies to `mission7_*` state.

### Deletion safety

Deletion safe now: **No**. The mission is runtime-quarantined, but physical deletion is intentionally deferred to the next PR so remaining parser-safe references can be removed in one focused cleanup.

## Mission 8 — fan/airflow/cooling legacy flow

### Current state

Mission 8 is retired and disconnected from active mission launch/selection paths. Its legacy files are still present for parser safety and staged cleanup only.

### Files/services still intentionally present

- `scripts/game/bipob_legacy_airflow_flow_service.gd`
- `scripts/bipob/bipob_controller.gd` Mission 8 compatibility state and method stubs
- `scripts/field/grid_manager.gd` `get_mission8_layout()` compatibility layout data
- legacy tile/device constants used by parser-safe compatibility code

### Replacement surface

Use TASK TEST generic fan/airflow/cooling smoke and Map Constructor validation. Do not add new dependencies to `mission8_*` state.

### Deletion safety

Deletion safe now: **No**. The mission is runtime-quarantined, but physical deletion is intentionally deferred to the next PR so remaining parser-safe references can be removed in one focused cleanup.

## Next PR: physical deletion

The next PR should delete the retired Mission 7/8 compatibility files and stubs after verifying no parser/runtime entry point depends on them. Expected cleanup targets include legacy services, Mission 7/8 layout helpers, Mission 7/8 controller state/method stubs, legacy tile routing helpers that only served Mission 7/8, and docs references that described pre-quarantine blockers.
