# Map Constructor architecture

## Facade and service split

After PR13 and PR14, `scripts/game/mission_manager.gd` remains the public facade for Map Constructor APIs. Existing UI and gameplay callers should continue calling `MissionManager` methods.

The extracted services have focused ownership:

| Layer | File | Responsibility |
| --- | --- | --- |
| Public facade | `scripts/game/mission_manager.gd` | Stable Map Constructor API surface for UI and other callers; delegates extracted operations and retains APIs not moved into a service. |
| Mutation service | `scripts/game/map_constructor_service.gd` | Core placement, remove, move, duplicate, entity lookup, and property-update mutation logic extracted in PR13. |
| Validation service | `scripts/game/map_constructor_validation_service.gd` | Entity-link validation, dependency status, overlays, issues, door-opening summaries, readiness reports, and audit summaries extracted in PR14. |

The services are implementation details behind `MissionManager`. Do not bypass the facade from UI helpers.

## Mutation flow

For extracted mutations, the expected flow is:

```text
Map Constructor UI helper
  -> MissionManager facade method
    -> MapConstructorService
      -> mutation result Dictionary
```

Use `scripts/game/map_constructor_service.gd` for placement, move, duplicate, delete/remove, entity lookup, and core property-update mutation logic. Keep the corresponding method on `MissionManager` as the public entry point.

Some Map Constructor behavior remains on the facade. In particular, do not assume every editor action was moved into `MapConstructorService`: inspect `MissionManager` before changing floor/wall material APIs, batch tools, cleanup/autofix behavior, templates, or catalog helpers.

## Validation flow

For extracted validation and readiness logic, the expected flow is:

```text
Map Constructor UI helper
  -> MissionManager facade method
    -> MapConstructorValidationService
      -> validation/readiness/audit result
```

Use `scripts/game/map_constructor_validation_service.gd` for entity-link validation, missing-link/dependency issues, validation overlays, readiness reports, and audit summaries. Keep warning presentation in `scripts/ui/map_constructor/map_constructor_validation_view.gd`.

## UI integration rule

UI helpers must call the `MissionManager` facade instead of accessing `MapConstructorService` or `MapConstructorValidationService` directly. This keeps service extraction internal, preserves a stable caller contract, and avoids coupling UI files to implementation details.

## Compatibility and return-shape rules

- Do not casually rename public Map Constructor facade methods on `MissionManager`.
- Do not change result `Dictionary` shapes unless every caller is reviewed and updated in the same focused PR.
- Preserve keys consumed by UI helpers, including status, message, entity, warning, and summary fields.
- Old maps must keep loading without migration unless a save/load migration PR is explicitly planned.
- Treat catalog defaults and serialized schema values as compatibility-sensitive.

## Where to make common changes

| Change | Start in | Notes |
| --- | --- | --- |
| Placement, move, duplicate, or delete mutation logic | `scripts/game/map_constructor_service.gd` | Preserve the matching `MissionManager` facade methods. |
| Property-update mutation logic | `scripts/game/map_constructor_service.gd` | UI control changes belong in `scripts/ui/map_constructor/map_constructor_property_controls.gd`. |
| Entity-link validation | `scripts/game/map_constructor_validation_service.gd` | Link-control presentation belongs in `scripts/ui/map_constructor/map_constructor_link_controls.gd`. |
| Missing-link warnings | `scripts/game/map_constructor_validation_service.gd` for data; `scripts/ui/map_constructor/map_constructor_validation_view.gd` for presentation | Keep validation logic out of the UI view. |
| Readiness or audit summaries | `scripts/game/map_constructor_validation_service.gd` | Preserve facade return shapes. |
| Floor/wall material actions | `scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd` and the relevant `MissionManager` facade methods | Inspect current facade ownership before moving logic. Do not expand service scope incidentally. |
| Object prefab palette behavior | `scripts/ui/map_constructor/map_constructor_object_palette.gd` | If placement mutation changes are also required, use the facade and `MapConstructorService`. |

## Review checklist

- Is the caller still using the `MissionManager` facade?
- Is mutation logic in `MapConstructorService` only when the task is about extracted mutations?
- Is validation/readiness/audit logic in `MapConstructorValidationService` only when the task is about those concerns?
- Are return dictionary shapes compatible with all callers?
- Do old maps continue loading without an unplanned migration?
- Are UI presentation changes isolated from runtime behavior?
- Do the local static checks pass?

## Configurable object archetype contract

Map Constructor authoring follows a global catalog contract: the palette exposes a base archetype, the inspector renders the archetype property schema, and runtime creation normalizes defaults plus overrides into canonical object data. Door is the first migrated consumer: the palette exposes one `door` row and legacy material/type ids remain load-only compatibility aliases.

Door state uses `state` and `allowed_states` as its source of truth. Compatibility flags such as `is_open`, `is_locked`, and `blocks_movement` are derived by the catalog state synchronizer. Canonical ids remain English runtime values; generated display names are presentation-only labels.

Next archetypes to migrate through the same registry, without variant palette rows: `terminal`, `platform`, `power_source`, `power_cable`, `switch`, `item`, `wall`, `floor_tile`, `cooling_device`, and `data_device`.
