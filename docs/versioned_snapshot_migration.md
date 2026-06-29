# Versioned Map and Save Migration

Persisted world documents use an explicit integer `format_version`. The current world/save format is version 2. Map Constructor preset documents use `schema_version = 2` and contain a canonical version-2 `world_state_snapshot`.

## Migration boundary

`VersionedSnapshotMigrationService` runs before `WorldStateStore.replace_serialized_snapshot()`. The service is pure: it duplicates the source document, returns a canonical result, and never writes files or mutates live state.

Only a successful migration may be committed. A technical or unsupported-version failure leaves the current mission state unchanged.

## Supported steps

The pipeline is sequential and deterministic:

1. `v0_to_v1_envelope_and_bindings`
   - converts legacy `objects` to `entities`;
   - separates explicit bindings from the entity array.
2. `v1_to_v2_canonical_entities_and_currency`
   - normalizes entity definitions and state contracts;
   - extracts logical relations into BindingStore before legacy fields are removed;
   - rejects physical topology as a BindingStore source of truth;
   - canonicalizes power-cable reel endpoints and path;
   - migrates normal items and Details currency;
   - migrates crate requirements and passive-route geometry;
   - removes legacy and runtime-derived source fields.

Migration never skips directly from one historic format to an unrelated current representation.

## Canonical version-2 document

```gdscript
{
    "format_version": 2,
    "entities": [],
    "bindings": [],
    "inventory_state": {},
    "center_storage": {},
    "details_currency": {}
}
```

The next save always writes this envelope. Legacy `objects`, `runtime_inventory_state`, authored physical-source fields, manual route contours, flat reel aliases, and logical-link fields embedded in entities are not written again.

## Binding migration

Explicit logical bindings and legacy entity link fields are merged by the canonical relation key: role, source ID, and target ID. Duplicate relations are removed deterministically.

Physical relation roles such as runtime reel feeds are removed with a stable warning because the related entities remain the source of truth. Unsupported logical roles are not guessed. Their raw data is preserved in the issue details, TASK TEST remains loadable, and promotion is blocked.

No proximity, display-name, or text matching is used to invent relations.

## Readiness and diagnostics

Migration returns stable issues and three readiness flags:

- `draft_save_allowed`: false only for a technical migration failure;
- `task_test_allowed`: true for every loadable migrated document;
- `promotion_allowed`: false while semantic error issues remain.

A current version-2 document is validated without applying migration steps. Repeating migration on a canonical document is idempotent.

## Map Constructor presets

Preset schema version 2 stores `world_state_snapshot` and constructor-only fields. Derived `cell_items`, `world_objects_by_cell`, and legacy `mission_world_objects` are not written.

Schema 0/1 presets are migrated in memory through the same world migration pipeline before they are applied. Saving the preset again writes schema 2 only.
