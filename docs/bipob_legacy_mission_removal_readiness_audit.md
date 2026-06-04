# Legacy mission removal readiness audit

## Current status after PR-LEGACY-RM-02

Retired Mission 7 and Mission 8 story flows have completed the two-step retirement process:

1. PR-LEGACY-RM-01 quarantined Mission 7/8 from active selection, launch, progression, runtime predicates, and GridManager layout selection.
2. PR-LEGACY-RM-02 physically deleted the retired Mission 7/8 compatibility services and removed their remaining controller, UI, catalog, GridManager, validation, and CI snapshot references.

## Removal outcome

Mission 7/8 are no longer active runtime missions and no longer have dedicated legacy service files. `MissionContentCatalog.get_active_runtime_mission_ids()` exposes Mission 1-6, Mission 9, and TASK TEST compatibility ids; it does not expose Mission 7 or Mission 8.

Mission 6 progression continues to point to Mission 9. TASK TEST remains the active sandbox for generic cable/socket/power and fan/airflow/cooling smoke coverage.

## Preserved systems

- Generic cable/socket/power runtime and TASK TEST smoke objects remain in place.
- Generic fan/airflow/cooling runtime and TASK TEST smoke objects remain in place.
- Map Constructor validation remains in place for generic cable/power and generic airflow/cooling readiness warnings.
- Mission 1-6, Mission 9, movement/action budgets, inventory, scan/hack, and runtime action behavior are not intentionally changed by this deletion.

## Remaining historical material

Older audit and contract documents may still describe pre-deletion blockers, legacy adapter names, or migration plans. Those entries are historical context only. They should not be interpreted as current runtime dependencies unless a source file also contains an active preload/caller.

## Next recommendation

No additional Mission 7/8 runtime deletion is required. Continue future work on the generic systems directly through TASK TEST and Map Constructor, and update older historical documentation only when it becomes misleading for active implementation work.
