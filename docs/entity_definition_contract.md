# Entity definition contract

WorldObjectCatalog owns canonical gameplay/domain entity definitions. That includes `ARCHETYPE_REGISTRY`, authoring-reachable `OBJECT_LIBRARY` fallback definitions, property schemas, placement contracts, and legacy alias resolution.

`EntityDefinitionContract` owns only the contract vocabulary and completeness validator: scopes, supported top-level entity types, capability keys, profile ID registries, validation fixtures, stable error codes, and palette eligibility. The validator is stateless and does not depend on scenes, MissionManager, Map Constructor UI, or renderer classes.

`MapConstructorPrefabCatalog` remains presentation-only. It consumes canonical reports from WorldObjectCatalog and may expose derived metadata such as `entity_contract_valid`, scope, type/subtype, capabilities, and error codes. It must not define gameplay capabilities, profile registries, entity type tables, or contract rules.

`MapConstructorService` enforces authoring eligibility during placement. Incomplete code-level definitions fail closed with `incomplete_entity_contract` and contract errors instead of receiving a generic fallback object.

`MapConstructorValidationService` may consume contract reports and diagnostics for authoring/CI warnings, but the primary contract rules remain in `EntityDefinitionContract`.

Legacy runtime definitions and saved-map compatibility remain temporarily supported. Historic non-authoring `OBJECT_LIBRARY` data may still load through the legacy path; this contract is not a save/TASK TEST readiness gate for map instances with missing links or invalid configured values.

Future authoring entities must add a complete explicit `entity_contract` to their canonical definition before they can appear in the Map Constructor palette or be placed directly. Unsupported profiles should be declared as `none`, and definitions using `property_profile = "definition_schema"` must provide a non-empty canonical `property_schema`.

This gate is metadata-only. It does not migrate runtime status evaluation, power behavior, access behavior, bindings, notifications, inspector/UI behavior, renderer behavior, family migrations, legacy aliases, or legacy raw fields.
