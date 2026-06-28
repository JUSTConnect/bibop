# Entity Definition Contract

`WorldObjectCatalog` owns canonical world-object definitions. `EntityDefinitionContract.validate_definition(definition_id, definition)` is the single public entry point for completeness and semantic validation.

`EntityDefinitionContract` owns validation behavior and contract vocabulary. `scripts/world/entity_contract_fixtures.gd` is its private data module for profile descriptors and independent fixture records. It is not a second public validator or gameplay registry. `MapConstructorPrefabCatalog` remains presentation-only and must not define capabilities, profiles, entity types, field families, or semantic rules.

## Profiles and fixtures

Profiles are descriptor records under `PROFILE_REGISTRIES`. Use `has_profile`, `get_profile_descriptor`, and `get_profile_ids` instead of indexing the registry as a string list.

Every registered profile ID has an independent machine-readable fixture. Each fixture contains a minimal valid sample, invalid mutations, expected stable diagnostic codes, and allowed stored, editable, and computed field families. `validate_fixture_registry()` verifies fixture structure, profile identity, expected codes, and full profile coverage. The generic `default` fixture exists only for definition compatibility and does not count as profile coverage.

## Field semantics

Known fields are listed exactly in `FIELD_SEMANTICS`; families are never inferred from substrings. Every field declares its family, capability owner where applicable, storage role (`stored`, `computed`, or `legacy`), and editability.

Computed fields cannot be authored in `property_schema` or stored as canonical truth. Legacy fields require an exact migration exception even when their former capability is enabled. Legacy and computed fields are never editable.

Physical topology records such as cable endpoints, socket IDs, runtime reel ends, connection state, and path cells are classified separately from logical bindings. Their presence does not enable or imply the generic `bindings` capability.

## Legacy exceptions

Temporary contradictions use exact `legacy_semantic_exceptions` entries with `field`, `reason`, and `migration_issue`. Wildcards, duplicate entries, unknown fields, unknown issue IDs, and exceptions for absent or non-contradictory fields are rejected. Valid exceptions create visible warnings and never authorize editable fields.

Four existing authoring-reachable fallback records (`power_cable`, `power_socket`, `turret`, and `debris`) use a closed compatibility allowlist inside `EntityDefinitionContract`. This bridge only describes audited historic fields and approved migration issues. New definitions cannot enter it implicitly and must declare their own exact inline exceptions.

## Diagnostic contract

Every error and warning contains `code`, `severity`, `field`, `message_key`, `message`, `fallback`, `fix_hint`, and structured `details`. Consumers must branch on codes and details, never parse fallback text. Diagnostic traversal order is deterministic.

Validation reports preserve `valid`, `palette_eligible`, `definition_id`, `scope`, `entity_type`, `entity_subtype`, `capabilities`, `contract`, `errors`, and `warnings`. Reports also include `semantic_valid`, `resolved_profiles`, `applied_fixture_ids`, `validation_fixture`, `legacy_exceptions`, and `field_semantics`.

`palette_eligible` is true only when errors are empty. Allowed migration warnings remain visible but do not remove a prefab from the palette.

Future authoring entities must provide a complete explicit `entity_contract` before they can enter the Map Constructor palette or be placed directly. Unsupported profiles must be declared as `none`. Definitions using `property_profile = "definition_schema"` must provide a non-empty canonical `property_schema`.
