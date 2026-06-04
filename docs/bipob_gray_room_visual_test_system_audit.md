# BIPOB VIS-TEST-01 — Gray room visual test system audit

## Purpose

This audit documents the current gray room visual test system that is already working and should be treated as the active visual test contract while floor, wall, and broken-wall assets are being prepared.

This is not a proposal to replace the system with a new asset pipeline. The current system is accepted as the baseline because it already gives a controlled way to test isometric floor footprint, wall height, wall base anchoring, and Map Constructor / TASK TEST visual readability before final art polish.

This audit is docs-only. It does not change rendering, gameplay, TASK TEST, Map Constructor, asset files, scenes, or `project.godot`.

## Current owner

The system is owned by:

```text
scripts/field/room_visual_renderer.gd
```

`RoomVisualRenderer` remains a visual projection layer over `GridManager`. Gameplay cells remain `Vector2i` in grid/runtime logic; visual projection helpers should not mutate gameplay state.

## Active test mode

The current test mode is controlled by:

```gdscript
@export var use_gray_room_visual_test_assets: bool = true
```

This flag is currently the important visual-test switch. When enabled, floor-like tiles resolve to the gray floor asset and walls can resolve to the gray wall height test set.

Do not replace this mode while asset preparation is ongoing. Extend or document it instead.

## Asset directory

The gray test asset pack is expected under:

```text
res://assets/visual/isometric/test/
```

Current required files:

```text
floor_gray_01.png
wall_gray_tallest_01.png
wall_gray_tall_01.png
wall_gray_mid_01.png
wall_gray_halfmid_01.png
wall_gray_low_01.png
```

These are validated by `get_gray_room_visual_test_asset_validation()`.

## Floor contract

The active gray floor asset key is:

```gdscript
const ISO_FLOOR_TEST_ASSET_KEY: String = "floor_gray_test"
```

It maps to:

```text
res://assets/visual/isometric/test/floor_gray_01.png
```

Placement contract:

```gdscript
"floor_gray_test": {
  "visible_bounds": Rect2i(0, 162, 512, 286),
  "target_footprint": ISO_STANDARD_TILE_SIZE,
  "overlap": Vector2(1.5, 1.5),
  "offset": Vector2.ZERO
}
```

Interpretation:

- the PNG can live on a larger transparent canvas;
- renderer uses measured visible bounds, not the full canvas, as the floor shape;
- the visible floor shape is normalized into the active `128x71` isometric footprint;
- small overlap is intentional to reduce seam/gap visibility between neighboring floor tiles;
- the floor contract is about footprint alignment, not final material polish.

Do not judge final material quality from this floor. Use it to judge geometry, footprint fit, gaps, and projection.

## Wall height contract

Gray wall test heights are ordered from visually highest to lowest:

```text
tallest
tall
mid
halfmid
low
```

Current mapping:

```text
wall_gray_tallest -> wall_gray_tallest_01.png
wall_gray_tall    -> wall_gray_tall_01.png
wall_gray_mid     -> wall_gray_mid_01.png
wall_gray_halfmid -> wall_gray_halfmid_01.png
wall_gray_low     -> wall_gray_low_01.png
```

The system supports explicit and automatic height selection.

### Explicit height fields

`get_test_wall_height_asset_key()` checks these possible fields:

```text
material.wall_height
material.wall_visual_height
override.wall_height
override.wall_visual_height
wall_data.wall_height
wall_data.wall_visual_height
```

Accepted normalized values include:

```text
tallest / highest
tall / high
mid / medium / middle
halfmid / halfmedium / half
low / short / lowest
auto / default / empty
```

Empty/default/auto uses automatic depth-based height.

### Automatic wall height

`resolve_auto_test_wall_height(cell)` computes a depth value from:

```text
cell.x + cell.y
```

It finds min/max wall depth in the current map and assigns a wall height band across the wall depth span.

This gives a fast readability test for 2.5D rooms:

- nearer/deeper wall rows should not visually collapse into one uniform slab;
- depth separation becomes visible even with simple gray assets;
- asset authoring can be checked against multiple height silhouettes before final materials exist.

## Wall visible bounds and base anchoring

Gray wall assets use explicit visible bounds:

```text
wall_gray_tallest: Rect2(0, 0,   512, 768)
wall_gray_tall:    Rect2(0, 63,  512, 705)
wall_gray_mid:     Rect2(0, 150, 512, 618)
wall_gray_halfmid: Rect2(0, 238, 512, 532)
wall_gray_low:     Rect2(0, 353, 512, 415)
```

The draw rect is computed from the visible bottom-center of the wall image and anchored to the isometric cell base:

```text
base_anchor = grid_to_iso(cell) + Vector2(0, tile_half_height)
```

Interpretation:

- wall PNG transparent padding is allowed;
- the visible bottom-center of the wall, not the full canvas center, is the important anchor;
- the wall base must sit on the blocked wall cell base in the 128x71 footprint;
- bad wall fit should be debugged through visible bounds / base anchor before changing renderer math.

This is the core reason the current system is valuable: it separates asset canvas padding from actual visual geometry.

## Renderer behavior that should be preserved

Do not casually change:

- `use_gray_room_visual_test_assets` default behavior;
- `ISO_STANDARD_TILE_SIZE = Vector2(128.0, 71.0)`;
- floor visible-bounds normalization;
- floor overlap normalization;
- wall visible bottom-center anchoring;
- auto wall-height depth banding;
- the existing fallback to procedural rendering when a test asset is missing;
- existing Map Constructor and TASK TEST runtime behavior.

The current system is a test harness, not final art polish.

## What this system is good for

Use it to answer:

- Do floor tiles fit the 128x71 diamond footprint?
- Are there visible gaps between floors?
- Does wall base align to the floor cell?
- Do transparent canvas margins break placement?
- Are different wall heights readable?
- Does depth order produce a readable 2.5D room?
- Does Map Constructor placement show the same result as TASK TEST runtime?
- Is the issue in the asset bounds or in renderer placement?

## What this system is not for

Do not use it to finalize:

- concrete material style;
- color palette;
- final wall damage art;
- object silhouettes;
- character animation;
- gameplay collision;
- mission design.

Those should come after geometry/placement is stable.

## Current validation hook

`get_gray_room_visual_test_asset_validation()` reports:

```text
ok
enabled
required_assets
missing_assets
fallback
```

This is enough for the current phase. It confirms whether the expected test assets are loadable and whether the renderer will fall back to procedural visuals.

## Recommended next work

### VIS-TEST-02 — Add current system docs to Map Constructor / TASK TEST smoke notes

Goal:

- record how to run the gray room visual test in editor/TASK TEST;
- list expected visual checks;
- avoid changing renderer behavior.

### VIS-TEST-03 — Add optional debug overlay for asset alignment

Only if needed after asset authoring begins.

Useful overlay toggles:

```text
floor target footprint
floor visible bounds mapped rect
wall base anchor
wall visible bottom-center
wall draw rect
wall height band label
```

This should extend existing debug overlays instead of replacing the renderer.

### VIS-TEST-04 — Add real asset replacement slots using the same contract

When real floor/wall PNGs are ready, add them as new asset keys using the same visible-bounds / footprint / base-anchor contract.

Do not remove the gray test pack. Keep it as regression baseline.

## Suggested asset authoring guidance based on current system

For floor PNGs:

- transparent canvas is allowed;
- visible alpha bounds must contain the full diamond floor surface;
- the visible diamond should be cleanly normalizable to `128x71`;
- avoid painted shadows that extend too far outside the footprint unless they are intentionally part of overlap;
- keep seams testable with repeated tiles.

For wall PNGs:

- transparent canvas is allowed;
- the visible bottom-center of the wall must be the anchor point;
- the bottom visual base should line up with the target tile base;
- height variants should preserve the same base anchor;
- broken/damaged variants should keep the same visible base contract even if the center is destroyed;
- do not rotate or skew the base independently from the isometric footprint.

## Acceptance for this audit

This audit is complete when:

- the current gray room visual test system is documented as the active baseline;
- the floor contract is recorded;
- the wall height contract is recorded;
- visible-bounds/base-anchor behavior is recorded;
- future work is framed as extending the existing system, not replacing it;
- no code or asset files are changed.
