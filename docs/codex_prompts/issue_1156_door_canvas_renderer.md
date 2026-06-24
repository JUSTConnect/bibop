# Codex prompt — issue #1156 door Canvas command policy

Implement issue #1156 from the latest `main` after merged PR #1155.

Use branch:

`codex/bip-architecture-coordinators-02f5c-door-canvas`

PR title:

`BIP-Architecture-Coordinators-02F5C: Extract door Canvas command policy`

PR body must include:

`Closes #1156`

Read the issue body first. Preserve every ownership and stop boundary below.

## Required audit before editing

Inspect these exact functions in `scripts/field/room_visual_renderer.gd`:

- `is_door_like_tile()`;
- `_get_door_opening_polygon()`;
- `get_door_opening_context()`;
- `_get_door_kind_for_tile()`;
- `get_iso_door_opening_visual_profile()`;
- `_get_door_axis_vectors()`;
- `draw_iso_door_insert()`;
- `draw_door_opening_overlay_for_context()`;
- `_draw_object_primitive_commands()`;
- `draw_iso_texture_asset()`;
- `draw_iso_object_png_texture_asset()`.

Also inspect:

- `scripts/visual/renderer/object_primitive_renderer.gd` command schema;
- `tools/check_room_visual_renderer_component_boundary.py`;
- `.github/workflows/renderer-component-gate.yml`.

Do not start implementation until you have compared all current door branches and recorded exact command order, coordinates, colors, widths and flags.

## Architecture target

Create:

`scripts/visual/renderer/door_canvas_renderer.gd`

The component must:

```gdscript
extends RefCounted
class_name DoorCanvasRenderer
```

It is a stateless deterministic command-policy component. It must not access scene/runtime objects, load resources or call Canvas APIs.

Recommended focused API:

```gdscript
static func normalize_state(raw_state: String) -> String
static func build_visual_profile(door_kind: String, door_state: String) -> Dictionary
static func build_threshold_commands(context: Dictionary) -> Array[Dictionary]
static func build_frame_commands(context: Dictionary) -> Array[Dictionary]
static func build_body_commands(context: Dictionary) -> Array[Dictionary]
static func build_state_overlay_commands(context: Dictionary) -> Array[Dictionary]
```

Equivalent names are acceptable only if the ownership remains equally narrow.

Use the existing object primitive command schema consumed by `_draw_object_primitive_commands()`:

- `polygon` with `points`, `color`, `order`;
- `line` with `start`, `end`, `color`, `width`, `antialiased`, `order`;
- `circle` with `center`, `radius`, `color`, `order`.

Do not introduce a second Canvas executor.

## Runtime/profile split

`get_iso_door_opening_visual_profile()` must retain:

- tile lookup through `_grid_manager`;
- `_get_door_kind_for_tile()`;
- raw state lookup from object data;
- MissionManager lookup;
- `get_map_constructor_door_visual_state` call;
- object flags `is_open/open`, `is_locked/locked`, `damaged/broken`.

After resolving the raw state, normalize it through `DoorCanvasRenderer.normalize_state()` and delegate all deterministic palette/flag construction to `DoorCanvasRenderer.build_visual_profile()`.

Do not move MissionManager or GridManager access into the new component.

## Exact state normalization

Preserve current semantics:

- `broken`, `jammed`, `destroyed` → `damaged`;
- accepted states: `open`, `closed`, `locked`, `powered`, `unpowered`, `damaged`;
- empty or unknown state → `closed`.

Use safe typed readers where context values may be malformed. Wrong Variant types must not cause runtime errors or accidentally activate boolean branches.

## Exact visual profile parity

Base defaults:

```gdscript
base_color = Color(0.27, 0.24, 0.22, 0.96)
frame_color = Color(0.12, 0.14, 0.16, 0.98)
accent_color = Color(0.88, 0.72, 0.36, 0.98)
warning_color = Color(1.0, 0.3, 0.22, 0.98)
threshold_color = Color(0.16, 0.18, 0.2, 0.82)
alpha = 0.96
```

Door-kind overrides:

```gdscript
digital_door:
    base_color = Color(0.13, 0.2, 0.28, 0.96)
    accent_color = Color(0.38, 0.88, 1.0, 0.98)

powered_gate:
    base_color = Color(0.09, 0.14, 0.2, 0.9)
    accent_color = Color(0.48, 0.96, 1.0, 0.98)
```

State overrides:

```gdscript
open:
    alpha = 0.38
    base_color = base_color.darkened(0.18)
    accent_color = Color(0.58, 0.9, 0.98, 0.92)

locked:
    accent_color = Color(1.0, 0.72, 0.22, 0.99)
    warning_color = Color(1.0, 0.86, 0.24, 0.99)

powered:
    accent_color = Color(0.32, 0.92, 1.0, 0.99)

unpowered:
    base_color = Color(0.18, 0.19, 0.21, 0.86)
    accent_color = Color(0.48, 0.54, 0.58, 0.86)
    alpha = 0.72

damaged:
    accent_color = Color(1.0, 0.34, 0.22, 0.99)
    warning_color = Color(1.0, 0.18, 0.12, 0.99)
```

Flags:

```gdscript
frame_enabled = true
threshold_enabled = true
state_badge_enabled = door_state != "closed"
damage_overlay_enabled = door_state == "damaged"
```

Preserve the current draw-time alpha behavior exactly:

```gdscript
base_color.a *= alpha
accent_color.a *= maxf(alpha, 0.55)
```

Do not silently “simplify” this into replacing alpha. The contract must verify the final command colors resulting from the current multiplication.

## Coordinator phase order

Refactor `draw_iso_door_insert()` into a thin coordinator with this exact order:

1. `get_door_opening_context(cell)` and early return when invalid;
2. `get_iso_door_opening_visual_profile(cell, object_data)`;
3. threshold texture attempt through `draw_iso_texture_asset(cell, "floor_door_underlay")` when threshold is enabled;
4. execute `DoorCanvasRenderer.build_threshold_commands(...)` only as policy output; the builder must emit no fallback commands when threshold texture succeeded or threshold is disabled;
5. validate jamb cells in the coordinator and build `valid_jamb_centers` using bounds, wall-tile checks, `grid_to_iso()` and `iso_wall_height`;
6. execute `DoorCanvasRenderer.build_frame_commands(...)`;
7. prepare `door_visual_data` in the coordinator;
8. door PNG attempt through `draw_iso_object_png_texture_asset(cell, "door", door_insert_center, door_visual_data)`;
9. execute `DoorCanvasRenderer.build_body_commands(...)`, passing `door_texture_succeeded` and `debug_outlines`;
10. execute `DoorCanvasRenderer.build_state_overlay_commands(...)`;
11. optional `draw_door_opening_overlay_for_context(context)`.

Use `_draw_object_primitive_commands()` for all command arrays.

`draw_iso_door_insert()` must contain no direct calls to:

```text
draw_line
draw_circle
draw_colored_polygon
draw_rect
draw_arc
draw_polyline
```

## Exact threshold commands

When `threshold_enabled` is false or `threshold_texture_succeeded` is true, return `[]`.

When fallback is required and polygon has at least 3 points:

1. polygon fill with exact `threshold_color`;
2. one line for every polygon edge in source order;
3. edge color is final `accent_color.darkened(0.25)`;
4. width `1.0`;
5. preserve current antialias behavior explicitly in command schema.

Malformed or short polygons return `[]` safely.

## Exact frame commands

When `frame_enabled` is false or frame polygon has fewer than 4 points, emit no frame polygon/outline commands.

Otherwise preserve:

1. frame polygon fill `Color(frame_color.r, frame_color.g, frame_color.b, 0.72)`;
2. one edge line per frame polygon edge;
3. edge color `frame_color.lightened(0.18)`;
4. width `2.0`;
5. for each coordinator-validated jamb center, line from `center + Vector2(0, -10)` to `center + Vector2(0, 13)`;
6. jamb color `frame_color.lightened(0.24)`;
7. jamb width `3.0`.

The component must not validate cells or call projection.

## Exact body geometry

Context includes:

```text
orientation
door_insert_center
tile_half_size
wall_height
profile
door_texture_succeeded
debug_outlines
```

Move `_get_door_axis_vectors()` into the component or implement equivalent private pure logic there.

Current axes:

```gdscript
axis_y: along = Vector2(0.78, 0.39).normalized()
other:  along = Vector2(0.78, -0.39).normalized()
up = Vector2(0, -1)
```

Current dimensions:

```gdscript
half_width = tile_half_size.x * 0.24
panel_height = wall_height * 0.58
panel_bottom = door_insert_center + Vector2(0, 12)
panel_top = panel_bottom + up_axis * panel_height
```

Panel points order must remain:

```text
panel_top - along * half_width
panel_top + along * half_width
panel_bottom + along * half_width
panel_bottom - along * half_width
```

### Procedural fallback (`door_texture_succeeded == false`)

Open state:

- split offset `along_axis * half_width * 0.58`;
- exact left/right panel polygons and order from current code;
- two polygon commands with final base color.

Other states:

- one panel polygon with final base color.

Digital door:

- strip from `panel_top + along * half_width * 0.58` to `panel_bottom + along * half_width * 0.58`;
- line width `3.2`, final accent color;
- circle at lerp `0.35`, radius `2.8`, `accent_color.lightened(0.2)`.

Powered gate:

- four bars;
- `bar_t = 0.2 + index * 0.2`;
- endpoints `bar_center ± along * half_width * 0.84`;
- line width `1.8`;
- center circle radius `1.6`, `accent_color.lightened(0.18)`.

Mechanical door:

- center line from panel left edge midpoint to right edge midpoint;
- width `1.6`.

Debug outlines:

- only when enabled;
- one line per full panel edge in source order;
- `frame_color.lightened(0.28)`;
- width `1.0`.

Preserve current behavior: even for open split panels, debug outline uses the original full `panel_points` edges.

### Texture-success path (`door_texture_succeeded == true`)

Do not emit procedural panel polygons.

Digital door:

- line `(10, -43)` → `(10, -13)` relative to insert center, width `2.6`;
- circle at `(10, -28)`, radius `2.4`, lightened accent.

Powered gate:

- three horizontal bars;
- y values `-38`, `-28`, `-18`;
- x from `-13` to `13`;
- line width `1.8`.

Mechanical door:

- line `(-9, -24)` → `(9, -24)`, width `2.0`.

All texture-success kinds then emit the center circle at `(0, -31)`, radius `2.5`, final accent color.

## Exact state overlays

Badge center:

```gdscript
door_insert_center + Vector2(18, -22)
```

When `state_badge_enabled` is false, emit no badge commands.

Badge circle:

- radius `4.2`;
- accent color by default;
- warning color for `locked` and `damaged`.

Locked line:

- `(-2, -1)` → `(2, -1)` relative to badge center;
- frame color;
- width `1.2`.

Unpowered line:

- `(-2.8, 2)` → `(2.8, -2)`;
- frame color;
- width `1.4`.

Damage overlay when enabled:

- insert `(-12, -36)` → `(-2, -23)`, warning color, width `1.8`;
- insert `(-2, -23)` → `(-8, -14)`, warning color, width `1.4`.

Badge commands must precede damage commands exactly as today.

## Safe context readers

The component must safely read at least:

```text
String
bool
float
Vector2
Color
Dictionary
PackedVector2Array
Array[Vector2]
```

Wrong types return safe fallbacks and never throw.

Do not use permissive `bool(value)` on arbitrary Variant values.

## Permanent contract

Add:

`tools/ci/check_door_canvas_renderer_contract.gd`

Wire a dedicated permanent step into `.github/workflows/renderer-component-gate.yml`.

The contract must accumulate failures and call `quit()` exactly once at the end.

Test exact values for:

1. normalization of every supported state plus broken/jammed/destroyed/unknown/empty;
2. all 3 door kinds × all 6 supported states visual profiles;
3. final alpha-multiplied base/accent colors used by commands;
4. threshold disabled, texture success, malformed polygon and exact fallback polygon/edges;
5. frame disabled, malformed polygon, exact frame fill/edges and two jamb centers;
6. mechanical closed procedural body for both orientations;
7. mechanical open split panels;
8. digital procedural commands;
9. powered-gate procedural commands;
10. all three texture-success accent variants;
11. debug outlines off/on;
12. closed state no badge;
13. locked, unpowered and damaged badge commands;
14. damage overlay exact commands and ordering;
15. malformed/wrong-type contexts;
16. exact command schema and monotonic order;
17. repeated identical input stability using `var_to_str` or direct deep equality.

Do not accept only `not empty` assertions. Check exact command count, kinds, coordinates, colors, widths, radii, antialias flags and order.

## Boundary checker

Extend `tools/check_room_visual_renderer_component_boundary.py`.

Require:

- `DOOR_CANVAS_RENDERER` source path and component read;
- preload in `RoomVisualRenderer`;
- focused APIs listed above;
- class name `DoorCanvasRenderer`;
- component has no direct Canvas/runtime/resource ownership.

Forbidden component tokens should be specific and avoid false positives. Do **not** forbid the raw substring `Canvas`, because it is part of `DoorCanvasRenderer`.

Forbid at minimum:

```text
extends Node
extends Node2D
GridManager
MissionManager
get_node(
get_tree(
grid_to_iso(
ResourceLoader
load(
Texture2D
Time
ThemeDB
queue_redraw(
draw_line(
draw_circle(
draw_colored_polygon(
draw_rect(
draw_arc(
draw_polyline(
draw_texture
draw_set_transform
```

Require `get_iso_door_opening_visual_profile()` to retain runtime tokens:

```text
_get_door_kind_for_tile
get_mission_manager_ref
get_map_constructor_door_visual_state
DoorCanvasRendererRef.normalize_state
DoorCanvasRendererRef.build_visual_profile
```

Require `get_door_opening_context()` to retain:

```text
_grid_manager
is_cell_in_bounds
is_door_like_tile
is_wall_tile
grid_to_iso
_get_door_opening_polygon
```

Require `draw_iso_door_insert()` to retain exact coordinator tokens and source order:

```text
get_door_opening_context
get_iso_door_opening_visual_profile
draw_iso_texture_asset
DoorCanvasRendererRef.build_threshold_commands
valid_jamb_centers
DoorCanvasRendererRef.build_frame_commands
draw_iso_object_png_texture_asset
DoorCanvasRendererRef.build_body_commands
DoorCanvasRendererRef.build_state_overlay_commands
draw_door_opening_overlay_for_context
```

Require `_draw_object_primitive_commands` execution for every command phase.

Reject direct Canvas draw calls inside `draw_iso_door_insert()`.

Require `_get_door_axis_vectors()` to be absent from `RoomVisualRenderer` after migration.

Rename the stage cap and lower it below current `5852` to the exact final line count.

## Explicit exclusions

Do not modify:

- `ObjectTextureDispatchPolicy` behavior from #1154;
- object texture cache/loading/descriptor architecture;
- `get_door_opening_context()` behavior or wall-support rules;
- tile constants or door gameplay state;
- route/cable/duct/pipe rendering;
- floor/wall/object primitive ownership outside command-schema reuse;
- visual-state overlay animation;
- Map Constructor gameplay logic;
- scenes;
- `project.godot`;
- final coordinator cleanup.

Do not add temporary workflows, worklogs or transformation scripts.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_door_canvas_renderer_contract.gd
```

Confirm all four permanent gates are green:

- Renderer Component Gate;
- Godot Parser Gate;
- Bipob Module Catalog Gate;
- Surface Catalog Gate.

## Stop boundary

Stop after door profile/palette and Canvas command extraction. Do not begin final `RoomVisualRenderer` cleanup, smoke fixtures or closure of #1115/#1101 in this PR.
