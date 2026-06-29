# Entity status ownership

`EntityStatusEvaluator` is the single owner of shared entity status semantics. It is a stateless `RefCounted` utility that reads an entity dictionary plus optional evaluation context and returns a normalized result without writing to mission objects, the scene tree, power graph, bindings, UI, or save data.

Stored authoring axes are limited to the capabilities allowed by the entity contract:

- `intent_state`: `on` or `off`
- `health_state`: `healthy`, `damaged`, or `broken`
- `thermal_state`: `normal` or `overheated`
- `operational_state`: subtype-specific state such as door `open`/`closed`/`locked`, fuse `installed`/`empty`, or cable `connected`/`disconnected`

`effective_state`, `is_operational`, `blocking_reason`, `reason_code`, `sections`, `real_values`, and `forced_values` are computed read-only result fields. They must not become an authoring source of truth.

Legacy status layer nodes are thin adapters. They may call the evaluator for display compatibility, but they must not scan the scene tree to infer domain state and must not normalize-write status fields back into mission objects.

Power loss is an external computed blocker (`power.unpowered`). It never rewrites `intent_state`, `health_state`, `thermal_state`, or `operational_state`.

Test overrides are read only when `supports_test_override` is enabled and the evaluation context is Map Constructor or TASK TEST. Override values are returned beside real values and are removed by `serializable_source()` before ordinary save data is produced.
