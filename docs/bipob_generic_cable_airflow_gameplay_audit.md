# BIPOB PR-GEN-01 — Generic cable/socket/power + fan/airflow/cooling gameplay audit

## Purpose

This docs-only audit starts the combined generic gameplay phase for two legacy-backed systems:

- Mission 7 cable/socket/power;
- Mission 8 fan/airflow/cooling.

The goal is to fit both systems into a compact 4-PR plan without mixing responsibilities or deleting legacy missions too early.

This audit does not change gameplay, TASK TEST, Map Constructor, scan/hack, inventory, movement, GameUI, BipobController, mission resources, scenes, or `project.godot`.

## Current context

The broad GameUI/BipobController feature-area unloading phase has reached a useful stopping point.

The next useful code work should be product-motivated. The two strongest gameplay tracks are:

1. generic cable/socket/power gameplay, to retire dependency on legacy Mission 7 behavior later;
2. generic fan/airflow/cooling gameplay, to retire dependency on legacy Mission 8 behavior later.

Old Mission 7/8 resources are not approved for deletion yet. They remain compatibility and reference behavior until generic TASK TEST smoke passes.

## Combined 4-PR plan

### PR-GEN-01 — Generic cable + airflow ownership audit and contracts

Status: this document.

Scope:

- map ownership boundaries;
- define shared contracts;
- define TASK TEST smoke objects;
- define Map Constructor validation needs;
- define the next 3 code PRs.

### PR-GEN-02 — Generic cable/socket/power runtime + TASK TEST smoke

Scope:

- implement generic cable runtime state;
- support power source -> socket/cable -> sink propagation;
- add TASK TEST cable smoke objects/data;
- expose powered/unpowered status to runtime objects;
- keep Mission 7 legacy flow intact;
- no airflow work.

### PR-GEN-03 — Generic fan/airflow/cooling runtime + TASK TEST smoke

Scope:

- implement generic fan/airflow/cooling runtime;
- support fan direction/speed and airflow path evaluation;
- apply cooled/uncooled state to target terminal/device;
- add TASK TEST airflow smoke objects/data;
- keep Mission 8 legacy flow intact;
- no cable work except reading generic powered state if already available.

### PR-GEN-04 — Map Constructor validation + Mission 7/8 removal readiness

Scope:

- add Map Constructor readiness/warnings for generic cable links;
- add Map Constructor readiness/warnings for generic airflow links;
- update TASK TEST validation expectations;
- audit whether legacy Mission 7 and Mission 8 can be removed later;
- do not delete old missions unless a separate explicit removal PR is approved.

## Ownership boundaries

### Cable/socket/power system

Recommended owners:

| Responsibility | Owner |
| --- | --- |
| Legacy Mission 7 cable behavior | `BipobLegacyCableFlowService` |
| Generic cable runtime state | `BipobCableRuntimeState` or equivalent existing generic state class |
| Generic cable propagation/service logic | `BipobCableRuntimeService` or equivalent existing generic service |
| Runtime object metadata | `WorldObjectCatalog` + MissionManager world-object dictionaries |
| Runtime object instance state | `MissionManager` world-object runtime state |
| Player action dispatch | `BipobActionController` / existing execution services |
| UI display | existing runtime UI / status/hint signals |
| Map Constructor validation | Map Constructor validation/readiness layer, not gameplay service |

Boundary rule:

- legacy Mission 7 code may remain as compatibility;
- generic cable service must not call Mission 7 hardcoded positions;
- TASK TEST must use generic cable metadata/state, not Mission 7 flags.

### Fan/airflow/cooling system

Recommended owners:

| Responsibility | Owner |
| --- | --- |
| Legacy Mission 8 airflow behavior | `BipobLegacyAirflowFlowService` |
| Generic airflow runtime state | new/existing generic airflow state class |
| Generic airflow propagation/service logic | new/existing airflow runtime service |
| Fan/platform/terminal metadata | `WorldObjectCatalog` + MissionManager world-object dictionaries |
| Runtime object instance state | `MissionManager` world-object runtime state |
| Hack/terminal cooled checks | `BipobScanHackService` should read generic cooled state only after PR-GEN-03 |
| Terminal action execution | `BipobTerminalControlExecutionService` / `BipobActionController` |
| Map Constructor validation | Map Constructor validation/readiness layer |

Boundary rule:

- generic airflow must not depend on Mission 8-specific `mission8_terminal_cooled` as source of truth;
- legacy Mission 8 can mirror or continue using old flag until removal readiness;
- TASK TEST should verify generic cooled/uncooled state.

## Generic cable/socket/power contract

Minimum generic object roles:

- `power_source`
- `socket_input`
- `socket_output`
- `cable_endpoint`
- `cable_segment` or `cable_link`
- `power_sink`
- `powered_device`

Minimum generic runtime fields:

```text
power_network_id
connection_id
source_object_id
sink_object_id
socket_id
endpoint_a_id
endpoint_b_id
is_connected
is_powered
power_state
power_required
power_received
validation_errors
validation_warnings
```

Minimum propagation rule:

```text
powered source + valid connection path + compatible sink = sink is powered
otherwise sink is unpowered
```

Required behavior:

- failed/invalid cable connection must not mutate unrelated inventory or movement state;
- powered/unpowered must be readable by terminal/device/action checks;
- disconnecting or breaking a link must update dependent sinks;
- Map Constructor must be able to detect dangling or incomplete links.

## Generic airflow/cooling contract

Minimum generic object roles:

- `fan`
- `airflow_source`
- `airflow_path_cell`
- `airflow_blocker`
- `rotating_platform` if still needed as generic object;
- `cooling_target`
- `heat_sensitive_terminal`

Minimum generic runtime fields:

```text
airflow_network_id
fan_object_id
fan_enabled
fan_direction
fan_speed
airflow_range
airflow_cells
blocked_cells
cooled_target_ids
is_cooled
cooling_required
cooling_received
validation_errors
validation_warnings
```

Minimum propagation rule:

```text
enabled fan + valid direction/path + unobstructed target = target is cooled
otherwise target is uncooled
```

Required behavior:

- fan direction/speed changes update airflow preview/runtime state;
- blocked path prevents cooling;
- cooled/uncooled state must be readable by scan/hack/terminal logic;
- legacy Mission 8 behavior must remain intact until removal readiness.

## TASK TEST smoke requirements

### Cable smoke set

Minimum objects:

1. one generic power source;
2. one compatible socket/input;
3. one cable or cable endpoint pair;
4. one power sink/consumer;
5. one powered device that visibly reports powered/unpowered or changes action availability.

Expected smoke:

- start TASK TEST;
- source is powered;
- incomplete link leaves sink unpowered;
- valid link powers sink;
- powered device reports powered;
- disconnect or invalid state reports unpowered;
- legacy Mission 7 flow is not required for this result.

### Airflow smoke set

Minimum objects:

1. one generic fan;
2. one airflow path/space;
3. one target terminal/device requiring cooling;
4. optional blocker/platform if already supported generically;
5. one visible readout through scan/hack/status showing cooled/uncooled.

Expected smoke:

- start TASK TEST;
- fan disabled leaves target uncooled;
- fan enabled in correct direction cools target;
- blocked/wrong direction leaves target uncooled;
- target terminal/device reads generic cooled state;
- legacy Mission 8 flag is not the source of truth for TASK TEST.

## Map Constructor validation requirements

### Cable validation

Warnings/errors should cover:

- power source without sink;
- sink requiring power without valid source;
- dangling cable endpoint;
- cable endpoint connected to incompatible socket;
- duplicate/ambiguous connection if the model disallows it;
- missing `connection_id` / `network_id` metadata;
- powered device with no readable power source path.

### Airflow validation

Warnings/errors should cover:

- fan without direction;
- fan without target/path;
- cooling target requiring airflow without valid fan path;
- blocked airflow path;
- target outside fan range;
- missing `airflow_network_id` or link metadata;
- legacy Mission 8-only cooling flag used in TASK TEST objects.

## What not to do in this phase

Do not delete old missions in PR-GEN-02 or PR-GEN-03.

Do not combine cable and airflow implementation into the same service.

Do not make Map Constructor own gameplay propagation.

Do not move movement/action budget.

Do not rewrite scan/hack. It may read generic cooled/powered state only when the relevant runtime state exists.

Do not add broad GameUI/BipobController cleanup to these PRs.

## Risks

### Large PR risk

PR-GEN-02 and PR-GEN-03 are intentionally larger than prior cleanup PRs. They must stay tightly scoped:

- PR-GEN-02 only cable/socket/power;
- PR-GEN-03 only fan/airflow/cooling;
- PR-GEN-04 only validation/readiness.

### Parser gate risk

Recent Codex runs often could not run Godot CLI. Each code PR must state whether the parser gate ran:

```bash
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

### Legacy compatibility risk

Mission 7/8 legacy flows must keep working until removal readiness. Generic runtime should be additive and TASK TEST-first.

## Acceptance for PR-GEN-01

This audit is complete when:

- cable/socket/power ownership is defined;
- fan/airflow/cooling ownership is defined;
- generic contracts are documented;
- TASK TEST smoke sets are documented;
- Map Constructor validation needs are documented;
- 4-PR plan is explicit;
- no gameplay files changed.

## Next prompt

Recommended next PR:

**PR-GEN-02 — Generic cable/socket/power runtime + TASK TEST smoke**

Goal:

- implement generic cable/socket/power runtime state and propagation for TASK TEST;
- add/enable a small TASK TEST cable smoke object set;
- expose powered/unpowered state to runtime objects;
- keep legacy Mission 7 intact;
- do not touch airflow.

Required checks:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Manual smoke:

1. Start TASK TEST.
2. Confirm cable smoke objects exist or can be spawned.
3. Confirm incomplete cable chain leaves sink unpowered.
4. Confirm valid power source -> cable/socket -> sink powers the sink.
5. Confirm powered device/action reads powered state.
6. Enter Map Constructor.
7. Inspect cable/source/sink objects.
8. Exit Map Constructor.
9. Confirm Mission 7 legacy flow still does not crash if reachable.

## PR-GEN-02 status update

Status: implemented for the TASK TEST-first generic cable/socket/power runtime path.

Implemented cable runtime pieces:

- `BipobCableRuntimeState` now carries the generic cable/socket/power runtime fields from this audit in addition to the existing legacy Mission 7 snapshot fields.
- `BipobCableRuntimeService` remains independent from `BipobController` and Mission 7 legacy state, and now applies a small deterministic generic propagation pass over world-object dictionaries.
- `MissionManager` owns the runtime application point and exposes `is_world_object_powered(object_id)` plus `get_world_object_power_state(object_id)` read helpers for runtime object/action code.
- `WorldObjectCatalog` power source/socket/cable defaults now include the generic role and runtime field contract expected by future Map Constructor validation.
- TASK TEST includes a stable smoke chain under `task_test_generic_power_smoke` and a deliberately incomplete generic powered device.

TASK TEST smoke ids:

- Valid source: `task_test_generic_power_source`
- Input socket: `task_test_generic_socket_input`
- Cable link: `task_test_generic_cable_link`
- Output socket: `task_test_generic_socket_output`
- Powered sink/device: `task_test_generic_powered_device`
- Incomplete/unpowered device: `task_test_generic_unpowered_device`

Current limitations kept intentionally for PR-GEN-02:

- The generic propagation is deterministic metadata traversal, not a full electrical graph solver.
- It supports the first smoke shape: one source, one socket/cable chain, and a sink/device.
- Map Constructor validation/readiness warnings are still deferred to PR-GEN-04.
- Airflow/cooling remains untouched for PR-GEN-03.
- Legacy Mission 7 cable flow remains present and is not deleted or converted.

## PR-GEN-03 implementation status

Status: implemented for TASK TEST as an additive generic runtime path.

PR-GEN-03 adds:

- `BipobAirflowRuntimeState` as a parser-safe generic state holder for fan/cooling runtime fields.
- `BipobAirflowRuntimeService` as a Mission 8-independent propagation service.
- MissionManager generic cooling accessors:
  - `is_world_object_cooled(object_id)`;
  - `get_world_object_cooling_state(object_id)`;
  - `get_generic_airflow_runtime_report()`.
- TASK TEST smoke objects using stable ids:
  - `task_test_generic_airflow_fan`;
  - `task_test_generic_airflow_path_cell`;
  - `task_test_generic_airflow_target`;
  - `task_test_generic_airflow_blocker`;
  - `task_test_generic_uncooled_target`.
- `docs/bipob_generic_airflow_runtime_smoke.md` with expected states and manual smoke steps.

The generic runtime is intentionally simple and TASK TEST-first: enabled fan + direction/range + unobstructed line path cools linked targets; blockers stop propagation. It does not implement Map Constructor validation, a broad airflow graph solver, or legacy Mission 8 deletion.

Compatibility notes:

- `BipobLegacyAirflowFlowService` remains intact.
- Generic airflow does not read `mission8_terminal_cooled` as source of truth.
- PR-GEN-02 generic cable ids and propagation semantics are unchanged.
- PR-GEN-04 remains responsible for Map Constructor readiness/warnings.

## PR-GEN-04 validation/readiness status

Status: implemented for Map Constructor readiness validation and removal-readiness documentation.

PR-GEN-04 adds read-only validation warnings for the generic TASK TEST cable/socket/power and fan/airflow/cooling contracts. Validation duplicates world objects before invoking the generic runtime services, then emits normal Map Constructor validation issues consumed by the existing readiness/warning display.

Generic cable warning categories:

- `generic_cable_missing_network`
- `generic_cable_missing_source`
- `generic_cable_missing_socket`
- `generic_cable_incomplete_chain`
- `generic_cable_sink_unpowered`

Generic airflow warning categories:

- `generic_airflow_missing_network`
- `generic_airflow_fan_missing_direction`
- `generic_airflow_target_uncooled`
- `generic_airflow_path_blocked`
- `generic_airflow_target_out_of_range`

Legacy removal-readiness warning categories:

- `legacy_mission7_dependency_present`
- `legacy_mission8_dependency_present`

Removal-readiness result:

- Legacy Mission 7 deletion is **not safe yet**. Generic cable runtime and validation exist, but story Mission 7 still has legacy controller/grid/UI dependencies and needs a separate migration/smoke PR.
- Legacy Mission 8 deletion is **not safe yet**. Generic airflow runtime and validation exist, but story Mission 8 still has legacy controller/grid/UI dependencies and needs a separate migration/smoke PR.

New supporting docs:

- `docs/bipob_generic_cable_airflow_map_constructor_validation.md`
- `docs/bipob_legacy_mission7_8_removal_readiness_audit.md`

Next recommended step:

1. Run full local Godot smoke for TASK TEST Map Constructor warnings and old Mission 7/8 compatibility.
2. Create a follow-up Mission 7 migration PR that ports old cable/socket/power content to generic metadata without deleting legacy code first.
3. Create a follow-up Mission 8 migration PR that ports old fan/airflow/cooling terminal content to generic metadata without deleting legacy code first.
