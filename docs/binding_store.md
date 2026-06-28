# Canonical BindingStore

`WorldStateStore` is the only owner of canonical logical relations. A binding is stored separately from entity dictionaries:

```gdscript
{
    "id": "binding_000001",
    "role": "control_terminal",
    "source_id": "terminal_a",
    "target_id": "door_a",
    "parameters": {},
    "format_version": 1
}
```

`WorldBindingStoreContract` is a stateless validator and deterministic index builder. It does not own runtime data.

## Supported roles

The initial canonical roles are:

- `control_terminal`
- `access_terminal`
- `access_item`
- `preferred_power_source`
- `light_controller`
- `platform_controller`

Role descriptors define allowed endpoint types or capabilities, cardinality, and cycle policy. New roles must be added to the central role registry with tests and stable diagnostics.

## Indexes and queries

`WorldStateStore` owns:

- `_bindings_by_id`
- `_binding_ids_by_source_id`
- `_binding_ids_by_target_id`
- `_binding_ids_by_role`

Indexes are derived from canonical records and rebuilt deterministically. Public getters return deep copies. Consumers query by ID, source, target, or role and do not scan entity raw fields.

## Validation results

Binding operations return machine-readable results containing:

```text
success
code
reason_code
binding_id
source_id
target_id
role
details
```

Stable codes distinguish missing endpoints, wrong type, inactive endpoints, capacity, duplicate relation or ID, cycle, unsupported role, invalid version, and forbidden physical relations. UI and gameplay code must not parse fallback text.

Direct CRUD rejects semantically invalid relations. Loading a broken authoring snapshot preserves records with missing, wrong, inactive, over-capacity, or cyclic endpoints and exposes diagnostics. Structurally invalid, duplicate, unsupported, physical, or version-invalid records fail the atomic load.

## Deletion policy

Entity deletion always chooses an explicit policy:

- `preserve`: keep relations and expose missing-endpoint diagnostics;
- `remove_related`: remove all source and target relations;
- `reject_if_bound`: reject deletion until the caller resolves relations.

Bindings are never silently retargeted to a nearby or similar entity.

## Serialization and migration

World snapshots use separate versioned collections:

```gdscript
{
    "format_version": 1,
    "entities": [],
    "bindings": []
}
```

Bindings serialize in stable ID order. Legacy logical link fields are converted once to binding records and stripped from canonical serialized entities. Re-running migration is idempotent.

## Physical topology exclusion

BindingStore contains logical relations only. The following remain physical topology and are never represented as bindings:

- authored `power_cable` segments;
- `power_cable_reel` ends, socket connection, and runtime path;
- passive air-duct and water-pipe adjacency;
- cable endpoint IDs and path cells.

Physical connectivity remains the source of truth for power, reel, and passive-route systems.
