# RoomVisualRenderer component map

## Baseline

Before the first extraction stage, `scripts/field/room_visual_renderer.gd` contained:

- 7,811 lines;
- 435 functions;
- 106 constants;
- 82 exported properties.

The renderer currently combines scene coordination with floor, wall, object, route, overlay, fog, asset-resolution, projection, depth sorting and debug responsibilities.

## Dependency direction

```text
RoomVisualRenderer
    -> focused renderer components
    -> visual/domain services
    -> read-only GridManager / mission runtime inputs
```

Focused renderer components must not call each other. Shared geometry and draw-entry data flow through explicit arguments and dictionaries.

## Stage 1 owners

### `IsoProjectionService`

Owns reusable projection primitives:

- projection mode normalization;
- standard/classic/custom tile sizes;
- pitch-corrected half-tile geometry;
- grid-to-screen and screen-to-grid conversion;
- diamond and inset-diamond point generation;
- screen-space depth keys;
- deterministic cell depth comparison.

It has no gameplay, scene-tree or draw API dependency.

### `IsoDrawEntryContract`

Owns the stable queue-entry schema and ordering metadata:

```text
cell
layer
layer_bias (optional)
kind
depth_key
sub_order
payload
```

It also owns layer biases, sub-order constants, validation and deterministic entry comparison.

## Remaining extraction clusters

| Component | Main current responsibilities | Representative current functions |
|---|---|---|
| Floor renderer | floor profiles, material/height asset lookup, atlas layers, floor entry generation | `draw_iso_floor_cell`, `draw_floor_atlas_layer`, `build_iso_floor_draw_entries` |
| Wall renderer | topology, height/material profiles, wall geometry, breach overlays, wall entry generation | `get_wall_render_topology`, `draw_iso_wall_block`, `build_iso_wall_draw_entries` |
| Object renderer | object descriptors, asset resolution, grounding, object markers and entries | `build_iso_object_visual_descriptor`, `draw_iso_object_marker`, `build_iso_object_draw_entries` |
| Route renderer | cable/pipe/airflow paths, wall routes, cable bridges | `draw_iso_cable_segment_shape`, `draw_inner_wall_route_asset`, `build_iso_cable_object_bridge_draw_entries` |
| Overlay renderer | selection, constructor preview, debug overlays and reports | `draw_map_constructor_visual_overlay_passes`, `draw_iso_mouse_selection_overlay` |
| Fog renderer | visibility colors, floor/wall fog passes | `draw_iso_fog_overlay`, `draw_iso_fog_wall_overlay` |

## Coordinator target

`RoomVisualRenderer` should ultimately retain only:

- scene/runtime dependency binding;
- invalidation and redraw coordination;
- component context construction;
- requesting component draw entries;
- final queue composition and sorting;
- draw-entry dispatch during the migration period.

Every later extraction must delete the migrated implementation from the coordinator in the same change. No fallback implementation should remain.
