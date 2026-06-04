# PR-GEN-04 — Generic cable/airflow Map Constructor validation

Status: implemented as read-only Map Constructor readiness validation.

## Scope

This validation extends the existing Map Constructor validation/readiness pipeline. It does not add a new UI panel, scene, gameplay propagation owner, or destructive runtime recalculation.

Primary implementation files:

- `scripts/game/map_constructor_validation_service.gd`
- `scripts/game/map_constructor_readiness_validation_service.gd`

Read-only runtime strategy:

- Validation duplicates `mission_world_objects` before invoking generic cable or generic airflow runtime services.
- Warnings are appended as normal Map Constructor validation issues.
- Existing readiness normalization and `MapConstructorUIBridge` warning cards consume the new issue rows without layout changes.
- Live mission object dictionaries are not intentionally mutated by validation.

## Generic cable/socket/power warnings

Validation category prefix: `generic_cable_`.

Implemented warning ids:

| Warning id | Meaning |
|---|---|
| `generic_cable_missing_network_*` | Generic cable/source/socket/sink metadata is missing `power_network_id`. |
| `generic_cable_missing_source_*` | A generic chain object is missing `source_object_id`, references a missing source, references a non-source, or a powered sink network has no source. |
| `generic_cable_missing_socket_*` | A generic powered sink/device is missing `socket_id`, references a missing socket, or references an incompatible non-socket object. |
| `generic_cable_incomplete_chain_*` | A generic chain is missing `connection_id`, a source has no sink on its network, or a cable link has dangling/missing/incompatible endpoints. |
| `generic_cable_sink_unpowered_*` | A generic powered sink/device still requires power after read-only validation propagation. |

Covered authoring cases:

- power source without sink;
- sink/powered device requiring power without valid source;
- dangling cable endpoint;
- cable endpoint connected to incompatible object;
- missing `connection_id`;
- missing `power_network_id`;
- missing/invalid `source_object_id`;
- missing/invalid `socket_id` on powered sink/device;
- incomplete chains warn rather than crash.

TASK TEST expected smoke behavior:

- `task_test_generic_powered_device` should not receive generic cable warnings from the PR-GEN-04 validator when the PR-GEN-02 smoke chain is intact.
- `task_test_generic_unpowered_device` should warn with `generic_cable_missing_source_*`, `generic_cable_missing_socket_*`, and `generic_cable_sink_unpowered_*` because it intentionally references missing source/socket ids.

## Generic fan/airflow/cooling warnings

Validation category prefix: `generic_airflow_`.

Implemented warning ids:

| Warning id | Meaning |
|---|---|
| `generic_airflow_missing_network_*` | Generic fan/path/blocker/target or cooling-required metadata is missing `airflow_network_id`. |
| `generic_airflow_fan_missing_direction_*` | A generic fan has no valid `fan_direction`/`facing_dir`. |
| `generic_airflow_target_uncooled_*` | A cooling-required generic target remains uncooled, a fan is disabled for the network, or a fan declares a bad linked target id. |
| `generic_airflow_path_blocked_*` | A cooling-required target is aligned to a matching fan but blocked by an airflow blocker before the target. |
| `generic_airflow_target_out_of_range_*` | A cooling-required target is aligned to a matching fan but beyond `airflow_range`. |

Covered authoring cases:

- fan without direction;
- fan disabled while target requires cooling;
- fan without `airflow_network_id`;
- cooling target requiring airflow without valid fan path;
- blocked airflow path;
- target outside fan range;
- missing `airflow_network_id`;
- missing/invalid declared linked target ids;
- cooling-required legacy-style metadata without generic airflow network is warned instead of accepted as TASK TEST generic source of truth.

TASK TEST expected smoke behavior:

- `task_test_generic_airflow_target` should validate as cooled/reachable in read-only validation.
- `task_test_generic_uncooled_target` should warn with `generic_airflow_path_blocked_*` because `task_test_generic_airflow_blocker` stops the path.

## Legacy removal-readiness warnings

PR-GEN-04 also exposes non-blocking removal-readiness dependency warnings while the old adapters remain present:

| Warning id | Meaning |
|---|---|
| `legacy_mission7_dependency_present` | Legacy Mission 7 cable/socket/power adapter still exists, so old Mission 7 deletion is not ready. |
| `legacy_mission8_dependency_present` | Legacy Mission 8 fan/airflow/cooling adapter still exists, so old Mission 8 deletion is not ready. |

These warnings document deletion readiness only; they do not delete or disable legacy flows.

## Readiness/UI integration

`MapConstructorReadinessValidationService` maps the new category prefixes to readable readiness labels:

- `Generic cable/power readiness`
- `Generic airflow/cooling readiness`
- `Legacy Mission 7 dependency`
- `Legacy Mission 8 dependency`

No Map Constructor UI layout changes are required. The existing readiness banner and warning panel consume `warning_issues` from the readiness report.

## Non-goals

PR-GEN-04 intentionally does not:

- delete legacy Mission 7 or Mission 8 assets/code;
- convert old story missions to generic metadata;
- redesign the Map Constructor UI;
- make Map Constructor own cable or airflow gameplay propagation;
- add a full electrical or airflow graph solver.
