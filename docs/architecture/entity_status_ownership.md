# Entity status ownership

`EntityStatusEvaluator` is the single owner of shared entity status semantics. It is a stateless `RefCounted` utility that reads an entity dictionary plus optional evaluation context and returns a normalized result without writing to mission objects, the scene tree, power graph, bindings, UI, or save data.

Stored authoring axes are limited to the capabilities allowed by the entity contract:

- `intent_state`: `on` or `off`
- `health_state`: `healthy`, `damaged`, or `broken`
- `thermal_state`: `normal` or `overheated`
- `operational_state`: subtype-specific state such as door `open`/`closed`/`locked`, fuse `installed`/`empty`, item `available`/`collected`/`disabled`, or cable `connected`/`disconnected`/`broken`/`invalid_path`

`effective_state`, `is_operational`, `blocking_reason`, `reason_code`, `sections`, `real_values`, and `forced_values` are computed read-only result fields. They must not become an authoring source of truth and are stripped by `serializable_source()`.

Legacy status layer nodes are thin adapters. They may call the evaluator for display compatibility, and the Map Constructor status section remains visible as read-only presentation until the #1179 inspector replacement. These adapters must not scene-tree scan to infer domain state and must not normalize-write status fields back into mission objects.

Power loss is an external computed blocker (`power.unpowered`) only for contracts with `capabilities.power=true`. It never rewrites `intent_state`, `health_state`, `thermal_state`, or `operational_state`; legacy `unpowered` is ignored for no-power contracts.

Test overrides are read only when all three are true: `entity_contract.capabilities.test_override`, source/context `supports_test_override`, and Map Constructor or TASK TEST context. Instance fields cannot enable overrides forbidden by the contract. Override values are returned beside real values and are removed by `serializable_source()` before ordinary save data is produced.

Legacy state values are profile/subtype-aware: door open/closed/locked/jammed, item available/collected/disabled, fuse installed/empty, and cable connected/disconnected/broken/invalid_path map to `operational_state`; broken/damaged/destroyed map to `health_state` for non-cable entities that support health; overheat/overheated maps to `thermal_state` when overheat is supported; off maps to `intent_state`.

Deferred acceptance: runtime action availability, diagnostic presenters, and the full schema-driven Map Constructor inspector still need to consume the same evaluator `reason_code` values in #1178/#1179. This PR keeps the current inspector as a read-only adapter and does not claim final closure of #1174 until those consumers are migrated.
