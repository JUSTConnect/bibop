# RoomVisualRenderer component map

## Baseline

Before the first extraction stage, `scripts/field/room_visual_renderer.gd` contained:

- 7,811 lines;
- 435 functions;
- 106 constants;
- 82 exported properties.

The renderer combines scene coordination with floor, wall, object, route, overlay, fog, asset-resolution, projection, depth sorting and debug responsibilities.

## Dependency direction

```text
RoomVisualRenderer
    -> focused renderer components
    -> visual/domain services
    -> read-only GridManager / mission runtime inputs
```

Focused renderer components must not call each other. Shared geometry and draw-entry data flow through explicit arguments and dictionaries.

## Extracted owners

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

### `FloorRenderer`

Owns floor data and pure rendering decisions:

- floor and raised-ground asset catalogs and placement metadata;
- floor visual profiles and passage/interactive classification;
- material and height normalization through the focused domain catalogs;
- atlas layout, variants, seam-safe policy and UV geometry;
- floor draw-entry generation through `IsoDrawEntryContract`.

`FloorRenderer` does not call CanvasItem drawing APIs. `RoomVisualRenderer` temporarily retains `draw_iso_floor_cell`, texture drawing and atlas draw dispatch until the dedicated Canvas floor-rendering stage.

### `WallRenderer`

Owns wall data and pure rendering decisions:

- production/test wall asset catalogs and placement metadata;
- material and wall-height normalization through focused catalogs;
- procedural wall visual profiles and metadata-to-profile resolution;
- connected-wall topology, end caps, corners, T-junctions and crosses;
- visible wall sides and wall-mounted anchor zones;
- connected base geometry and depth keys;
- wall draw-entry generation through `IsoDrawEntryContract`.

`WallRenderer` has no CanvasItem drawing dependency. `RoomVisualRenderer` temporarily retains wall texture/procedural drawing, breach overlays and draw-entry dispatch until a later Canvas wall-rendering stage.

## Remaining extraction clusters

| Component | Main current responsibilities | Representative current functions |
|---|---|---|
| Floor Canvas renderer | texture/atlas drawing and procedural floor geometry | `draw_iso_floor_cell`, `draw_floor_atlas_layer`, `draw_iso_floor_texture_asset` |
| Wall Canvas renderer | wall texture/procedural drawing and breach overlays | `draw_iso_wall_block`, `draw_iso_wall_asset`, `draw_iso_breachable_wall_overlay` |
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
