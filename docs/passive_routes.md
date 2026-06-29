# Passive Air-Duct and Water-Pipe Routes

Air ducts and water pipes are passive physical route segments. They are not devices and do not own operational state, power, control, access, durability, health, manual links, or runtime test overrides.

## Canonical authoring fields

A segment stores only its placement and physical geometry:

```gdscript
{
    "object_type": "air_duct|water_pipe",
    "route_mode": "inner|outer",
    "mount_side": "NE|SE|SW|NW",
    "route_side_1": "NE|SE|SW|NW",
    "route_side_2": "NE|SE|SW|NW"
}
```

Map Constructor exposes `mount_side`, `route_side_1`, and `route_side_2`. Existing external duct and pipe prefabs use a fixed `outer` route mode. Legacy inner/outer data is still normalized, but route mode is not a second editor-owned topology system.

The two route sides must be present and different. Opposite sides produce a straight segment; adjacent sides produce a turn. T-junctions and crossings are invalid for one segment.

## Connectivity

`PassiveRouteService` is the only topology resolver. Two neighboring segments connect only when all of these match:

- routing kind;
- inner or outer route mode;
- mount side;
- one segment has a physical port toward the neighbor;
- the neighbor has the opposite physical port.

Cell adjacency alone never creates a connection. This rule is identical for inner and outer routes.

## Computed components

Component IDs and member lists are derived from physical topology. They are deterministic for the same geometry and do not depend on object iteration order.

The following legacy fields are migration input only and are removed from canonical runtime data:

- `cooling_contour_id`;
- `cooling_contour_mode`;
- `cooling_contour_member_ids`;
- generic connection arrays;
- authored airflow cells and network IDs.

`CoolingRoutingContourService` remains only as a compatibility facade over computed passive-route components.

## Editor and validation

Map Constructor shows a read-only preview containing:

- normalized route pair;
- straight or turn shape;
- compatible neighbor IDs;
- computed component ID;
- stable machine-readable issue codes.

Invalid route geometry can still be saved as a draft and loaded in TASK TEST. It blocks promotion through the existing readiness contract rather than mutating or auto-correcting the map.

Validation and preview are read-only.

## Rendering and runtime use

The renderer consumes `PassiveRouteService.get_render_snapshot()` and does not infer or mutate topology. Airflow runtime recognizes canonical air-duct segments directly; passive segments do not need stored generic airflow roles.

Editing or validating a passive route does not trigger a global power or cooling recalculation and does not change passability.
