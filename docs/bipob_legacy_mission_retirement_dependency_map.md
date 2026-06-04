# Mission retirement dependency map

## PR-LEGACY-RM-02 status

Mission 7 and Mission 8 are retired and physically removed from active runtime code paths.

## Deleted legacy dependencies

- Mission 7 cable/socket/powered-gate service file and UID were deleted.
- Mission 8 fan/platform/airflow/cooling service file and UID were deleted.
- BipobController no longer owns Mission 7/8 compatibility state or methods.
- GridManager no longer carries Mission 7/8 layout helper functions.
- GameUI no longer has Mission 7/8 HUD/status/runtime branches.
- MissionContentCatalog no longer carries Mission 7/8 runtime/catalog stubs.
- Map Constructor no longer reports legacy Mission 7/8 adapter-present deletion blockers.

## Preserved non-legacy dependencies

The following are active generic/MVP systems and are intentionally preserved:

- TASK TEST sandbox startup/reset/restart.
- Generic cable/socket/power runtime services and state.
- Generic fan/airflow/cooling runtime services and state.
- Map Constructor object placement/edit/delete and validation for generic cable/airflow readiness.
- Mission 1-6 and Mission 9 legacy story flow.
- Movement/action budget, inventory, runtime action, scan/hack, and room visual rendering.

## Historical references

Historical documentation may still mention removed Mission 7/8 services or `mission7_*` / `mission8_*` fields as part of earlier migration notes. Those references do not represent active dependencies after PR-LEGACY-RM-02.

## Next recommendation

Keep future cleanup focused on generic system improvements. Do not restore old Mission 7/8 story flows, and do not remove generic cable/socket/power or generic fan/airflow/cooling behavior while cleaning historical docs.
