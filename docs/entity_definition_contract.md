# Entity Definition Contract

`WorldObjectCatalog` owns canonical world-object definitions. `EntityDefinitionContract.validate_definition(definition_id, definition)` is the single public validation entry point for entity-definition contract completeness and machine-readable semantic checks.

`EntityDefinitionContract` owns the contract vocabulary: entity types, capabilities, profile descriptors, exact field semantics, validation fixtures, stable diagnostic codes, legacy migration exceptions, and palette eligibility. `MapConstructorPrefabCatalog` remains presentation-only. It consumes canonical reports from `WorldObjectCatalog` and may expose derived metadata such as `entity_contract_valid`, scope, type/subtype, capabilities, error codes, and warning codes. It must not define gameplay capabilities, profile registries, entity type tables, field families, or contract rules.

## Profiles and fixtures

Profiles are registered as descriptors under `PROFILE_REGISTRIES`. Use `has_profile(profile_field, profile_id)`, `get_profile_descriptor(profile_field, profile_id)`, and `get_profile_ids(profile_field)` instead of indexing the registry as a string list. Descriptors can declare allowed entity types, required capabilities, forbidden capabilities, and fixture IDs. `validate_fixture_registry()` asserts that every registered profile has machine-readable fixture coverage and that fixture IDs resolve.

## Field semantics

Known entity-contract fields are listed exactly in `FIELD_SEMANTICS`; families are not inferred from substrings. Each known field identifies its family, capability owner, and storage role (`stored`, `computed`, or `legacy`). Computed/read-only fields such as `effective_state`, `is_operational`, `blocking_reason`, `power_state`, `resolved_source_id`, `resolved_circuit_id`, `physical_connection_source_id`, `editor_readiness`, and `editor_issues` cannot be editable in `property_schema` or stored as new canonical truth.

## Legacy exceptions

Temporary contradictions from pre-migration raw fields must be declared with exact `legacy_semantic_exceptions` entries containing `field`, `reason`, and positive integer `migration_issue`. Exceptions are visible warnings, not silent passes, and do not authorize editable `property_schema` fields.

## Report contract

Validation reports keep the existing consumer fields: `valid`, `palette_eligible`, `definition_id`, `scope`, `entity_type`, `entity_subtype`, `capabilities`, `contract`, `errors`, and `warnings`. Reports also include semantic metadata such as `semantic_valid`, `resolved_profiles`, `applied_fixture_ids`, `legacy_exceptions`, and `field_semantics`. `palette_eligible` is true only when there are no errors; allowed migration warnings do not remove a prefab from the palette.

Future authoring entities must add a complete explicit `entity_contract` to their canonical definition before they can appear in the Map Constructor palette or be placed directly. Unsupported profiles should be declared as `none`, and definitions using `property_profile = "definition_schema"` must provide a non-empty canonical `property_schema`.
