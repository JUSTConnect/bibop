# BIPOB PR-GEN-02 — Generic cable runtime smoke

## Purpose

This smoke note records the TASK TEST generic cable/socket/power object set added for PR-GEN-02. The runtime path is additive and does not replace the legacy Mission 7 cable flow.

## Object roles

| Object id | Role | Expected startup state |
| --- | --- | --- |
| `task_test_generic_power_source` | `power_source` | powered/source on |
| `task_test_generic_socket_input` | `socket_input` | powered when source is available |
| `task_test_generic_cable_link` | `cable_link` | powered when connected between sockets |
| `task_test_generic_socket_output` | `socket_output` | powered when cable link is valid |
| `task_test_generic_powered_device` | `powered_device` | powered through the valid chain |
| `task_test_generic_unpowered_device` | `powered_device` | unpowered because its source/socket ids are incomplete |

## Expected runtime states

Valid chain:

```text
task_test_generic_power_source
  -> task_test_generic_socket_input
  -> task_test_generic_cable_link
  -> task_test_generic_socket_output
  -> task_test_generic_powered_device
```

Expected result: `task_test_generic_powered_device` has `is_powered == true`, `power_state == "powered"`, and `power_received == 1`.

Incomplete chain:

```text
task_test_generic_unpowered_device
  -> task_test_generic_missing_source / task_test_generic_missing_socket
```

Expected result: `task_test_generic_unpowered_device` has `is_powered == false`, `power_state == "unpowered"`, and `power_received == 0`.

## Manual smoke steps

1. Start TASK TEST.
2. Inspect the generic smoke objects around row 9 of the TASK TEST sandbox.
3. Confirm `task_test_generic_powered_device` reports powered state through object debug/status, hint, or `MissionManager.get_world_object_power_state("task_test_generic_powered_device")`.
4. Confirm `task_test_generic_unpowered_device` remains unpowered through `MissionManager.get_world_object_power_state("task_test_generic_unpowered_device")`.
5. Confirm Runtime Action / Connect / Heavy Claw still behaves as before.
6. Enter Map Constructor and inspect the generic source/socket/cable/device metadata if visible.
7. Exit Map Constructor and restart/reset TASK TEST; the same startup states should return.
8. Historical note: Mission 7 is no longer reachable after PR-LEGACY-RM-02, and the legacy cable service has been deleted.

## Known limitations

- The propagation pass is intentionally simple and metadata-driven.
- PR-GEN-02 does not implement Map Constructor cable validation.
- PR-GEN-02 does not implement airflow/cooling.
- Complex multi-source, branching, load, and compatibility graph behavior remains future work.
