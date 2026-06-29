# Canonical Runtime Ownership

Normal runtime accepts and writes only canonical version-2 world documents. Historic data is interpreted exclusively by `VersionedSnapshotMigrationService` before it reaches gameplay stores.

## WorldStateStore

`WorldStateStore` owns live entities, logical BindingStore records, and deterministic indexes. It accepts exactly the current `WORLD_SNAPSHOT_FORMAT_VERSION` with explicit `entities` and `bindings` arrays.

It does not:

- read legacy `objects` documents;
- extract embedded logical links;
- repair legacy data while saving;
- infer relations by proximity, names, or messages.

A rejected document does not mutate the current store.

## Logical relations

BindingStore owns logical relations only. Legacy entity link fields are read by the versioned migration service, converted before entity cleanup, and never consulted by normal runtime.

Physical topology is excluded from BindingStore. Cable segments, cable-reel endpoints and paths, and passive duct/pipe adjacency remain physical entity data.

## Power cable reel

The canonical reel state uses nested `end_1`, `end_2`, `path_cells`, and `connection_state` fields.

Flat endpoint and cable-path aliases are read only by `migrate_legacy_reel()` during versioned migration. `canonicalize_reel()` and all runtime actions never recreate those aliases.

## Power ownership

Physical power topology determines the active source. Normal power and reel runtime write computed fields:

- `resolved_source_id`;
- `resolved_circuit_id`;
- `power_state`.

They do not write authored `power_source_id` or `physical_connection_source_id`, and there is no virtual `main_power_net` fallback.

Optional source preference remains a logical BindingStore relation used only when physical topology is ambiguous.

## Validation and UI

Domain decisions consume machine-readable `code` and `reason_code` values. Human-readable messages are presentation only and must not be parsed to classify gameplay or validation state.

Renderer classes are presentation consumers and are not imported by gameplay truth layers.

## CI regression gate

`Canonical Runtime Ownership V2 Gate` verifies:

- strict current-format store loading;
- one versioned legacy-binding caller;
- no store-time migration or save-time cleanup;
- no flat reel alias writes;
- no legacy power-source writes or virtual main-network fallback;
- no physical runtime-feed BindingStore creation;
- no TASK TEST message inference;
- no renderer dependency in gameplay truth layers;
- behavior-level strict-store and one-time reel migration boundaries.
