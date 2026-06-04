# PR-GEN-03 Generic Airflow Runtime Smoke

PR-GEN-03 originally added an additive TASK TEST-first generic fan / airflow / cooling runtime. As of PR-LEGACY-RM-02, retired legacy Mission 8 code has been physically deleted; this document is retained as historical generic runtime smoke context.

## Runtime roles

The smoke objects use `generic_airflow_runtime = true`, a stable `airflow_network_id`, and these roles:

- `fan` / `airflow_source` — emits directed airflow when enabled.
- `airflow_path_cell` — documents the valid airflow path.
- `airflow_blocker` — stops propagation.
- `cooling_target` / `heat_sensitive_terminal` — receives generic cooled state.

## TASK TEST smoke objects

- `task_test_generic_airflow_fan` at `(9, 9)` emits rightward airflow on `task_test_generic_airflow_smoke`.
- `task_test_generic_airflow_path_cell` at `(10, 9)` marks the valid path.
- `task_test_generic_airflow_target` at `(11, 9)` requires cooling and should become cooled.
- `task_test_generic_airflow_blocker` at `(12, 9)` blocks airflow propagation.
- `task_test_generic_uncooled_target` at `(13, 9)` requires cooling and should remain uncooled behind the blocker.

## Expected runtime state

After TASK TEST setup or runtime refresh:

- `is_world_object_cooled("task_test_generic_airflow_target")` returns `true`.
- `get_world_object_cooling_state("task_test_generic_airflow_target")` reports `cooling_state = "cooled"` and `cooling_received > 0`.
- `is_world_object_cooled("task_test_generic_uncooled_target")` returns `false`.
- `get_world_object_cooling_state("task_test_generic_uncooled_target")` reports `cooling_state = "uncooled"` and `cooling_received = 0`.
- Disabling the fan, changing its direction away from the target, or placing an airflow blocker before the target should leave the target uncooled.

## Manual smoke steps

1. Start TASK TEST.
2. Confirm the generic airflow smoke objects listed above are present.
3. Inspect or debug-read `task_test_generic_airflow_target`; it should be cooled.
4. Inspect or debug-read `task_test_generic_uncooled_target`; it should be uncooled because the blocker stops propagation.
5. Temporarily disable the fan or rotate it away from the target in object state and refresh; both targets should be uncooled.
6. Confirm the PR-GEN-02 cable smoke remains unchanged:
   - `task_test_generic_powered_device` is powered.
   - `task_test_generic_unpowered_device` is unpowered.
7. Confirm Runtime Action / Connect / Heavy Claw and TASK TEST restart/reset still work.
8. Historical note: legacy Mission 8 is no longer reachable after PR-LEGACY-RM-02.

## Known limitations

- The first generic implementation is intentionally simple: one-direction line propagation from enabled fans.
- It does not implement a broad graph solver or fluid simulation.
- Map Constructor airflow validation is intentionally deferred to PR-GEN-04.
- Legacy Mission 8 no longer remains backed by a legacy service after PR-LEGACY-RM-02; use TASK TEST generic airflow/cooling smoke instead.
