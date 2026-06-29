# Entity status ownership

`EntityStatusEvaluator` is the single owner of shared entity status semantics. It is a stateless `RefCounted` utility that reads an entity dictionary plus optional evaluation context and returns a normalized result without writing to mission objects, the scene tree, power graph, bindings, UI, or save data.

Stored authoring axes are limited to the explicit status axes allowed by the canonical catalog `status_profile` plus the entity capabilities:

- `object_standard`: `intent_state`, `operational_state`, and `health_state` when `capabilities.health=true`
- `item_standard`: `operational_state` only
- `cable_standard`: `operational_state` only
- `cooling_passive`: no status axes
- `light_standard`: `intent_state` and `operational_state`
- `movable_standard`: `health_state` and lifecycle `operational_state`, never per-action movement availability

Every catalog entity profile must be registered in the evaluator axis policy. Unknown catalog profiles fail the evaluator CI gate rather than silently receiving an empty status model. Intent and operational axes additionally require `capabilities.state=true`; health and thermal require their matching capabilities.

`operational_state` remains subtype-specific, such as door `open`/`closed`/`locked`, fuse box `installed`/`empty`, item `available`/`collected`/`disabled`, or cable `connected`/`disconnected`/`broken`/`invalid_path`. Movable destination, actor, manipulator, and power-class availability remain per-action results owned by `MovableActionService`, not stored status fields.

`effective_state`, `is_operational`, `blocking_reason`, `reason_code`, `sections`, `real_values`, and `forced_values` are computed read-only result fields. They must not become an authoring source of truth and are stripped by `serializable_source()`.

Legacy status layer nodes are thin adapters. They may call the evaluator for display compatibility, and the Map Constructor status section remains visible as read-only presentation until the #1179 inspector replacement. These adapters must not scene-tree scan to infer domain state and must not normalize-write status fields back into mission objects.

Power loss is an external computed blocker (`power.unpowered`) only for contracts with `capabilities.power=true`. It returns `effective_state=unavailable` and never rewrites `intent_state`, `health_state`, `thermal_state`, or `operational_state`; legacy `unpowered` is ignored for no-power contracts. Persisted `object_data.external_blocker` is not authoritative. Trusted computed blockers are passed through evaluation context, while narrowly scoped legacy state mapping remains read-only compatibility.

Production evaluation resolves contracts, subtypes, profiles, and allowed axes exclusively from `WorldObjectCatalog`; `object_data.entity_contract` and context attempts to replace contract/profile/axes are ignored. Isolated evaluator fixtures use the explicit `evaluate_synthetic_for_test()` helper instead of changing production authority.

Test overrides are read only when all three are true: `entity_contract.capabilities.test_override`, source/context `supports_test_override`, and Map Constructor or TASK TEST context. Instance fields cannot enable overrides forbidden by the contract. Override values are returned beside real values and are removed by `serializable_source()` before ordinary save data is produced.

Operational blocker codes are profile/subtype-specific; for example `fuse_box.empty` produces `operational.empty`, while `power_cable.disconnected`, `power_cable.broken`, and `power_cable.invalid_path` produce matching `operational.*` codes.

Legacy stationary cables derive connection lifecycle from the real legacy fields: explicit canonical/connection state first, broken or cut health next, invalid path next, and then connected/disconnected booleans. The legacy health-oriented `state=ok` field is not treated as the cable connection state.

Legacy state values are profile/subtype-aware: door open/closed/locked/jammed, item available/collected/disabled, fuse installed/empty, and cable connected/disconnected/broken/invalid_path map to `operational_state`; broken/damaged/destroyed map to `health_state` for non-cable entities that support health; overheat/overheated maps to `thermal_state` when overheat is supported; off maps to `intent_state`.

Deferred acceptance: runtime action availability, diagnostic presenters, and the full schema-driven Map Constructor inspector still need to consume the same evaluator `reason_code` values in #1178/#1179. This PR keeps the current inspector as a read-only adapter and does not claim final closure of #1174 until those consumers are migrated.
