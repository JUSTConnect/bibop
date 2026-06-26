# Entity definition contract

WorldObjectCatalog remains the owner of canonical gameplay/domain entity definitions, including `ARCHETYPE_REGISTRY`, compatible `OBJECT_LIBRARY` definitions, property schemas, and placement contracts.

`EntityDefinitionContract` owns the contract vocabulary and completeness validator: scopes, top-level entity types, capability keys, profile ID registries, stable error codes, and palette-eligibility reporting. It is stateless and does not depend on scenes, MissionManager, or UI classes.

`MapConstructorPrefabCatalog` owns palette presentation only. It consumes canonical contract reports from WorldObjectCatalog and adds derived diagnostic metadata such as validity, scope, type/subtype, capabilities, and error codes. It does not own gameplay capabilities, profile registries, or entity rules.

`MapConstructorService` enforces definition eligibility during placement. Incomplete code-level definitions fail closed with `incomplete_entity_contract` instead of receiving a generic fallback object.

Legacy runtime definitions and saved-map compatibility remain temporarily supported. Historic non-authoring OBJECT_LIBRARY data may still load through the legacy path, but new authoring definitions must provide a complete contract before appearing in the Map Constructor palette or being placeable directly.

This gate is metadata-only. It does not migrate status, power, access, binding, notification, UI, renderer, save, or TASK TEST behavior.
