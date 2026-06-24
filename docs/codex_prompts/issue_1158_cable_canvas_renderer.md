# Codex prompt — complete floor cable and bridge Canvas extraction

Issue number is assigned after creation. Work from latest `main` after merged PR #1157.

## Goal

Extract the remaining deterministic floor-cable and cable-bridge Canvas geometry/style policy from `RoomVisualRenderer` into a focused stateless `CableCanvasRenderer`, while keeping topology/world lookup, projection context assembly, draw-entry composition and actual Canvas execution in the coordinator.

## Required audit before editing

Inspect these exact functions in `scripts/field/room_visual_renderer.gd`:

- `draw_iso_cable_topology_line()`;
- `draw_iso_cable_segment_shape()`;
- `draw_iso_cable_mode_polyline()`;
- `draw_iso_cable_mode_segment()`;
- `draw_iso_cable_hidden_segment()`;
- `draw_iso_cable_wall_segment()`;
- `draw_iso_cable_damage_marker()`;
- `draw_iso_cable_object_links()`;
- `_draw_iso_cable_polyline()`;
- `draw_iso_cable_endpoint_cap()`;
- `draw_iso_cable_elbow()`;
- `draw_iso_cable_invalid_marker()`;
- `get_cable_bridge_network_id()`;
- `is_power_cable_bridge_connectable_object()`;
- `should_draw_object_cable_bridge()`;
- `get_cell_edge_bridge_points()`;
- `draw_object_cable_bridge()`;
- `build_iso_cable_object_bridge_draw_entries()`;
- `_draw_route_commands()`.

Also inspect:

- `scripts/visual/renderer/route_renderer.gd`;
- `tools/ci/check_route_renderer_contract.gd`;
- `tools/check_room_visual_renderer_component_boundary.py`;
- `.github/workflows/renderer-component-gate.yml`.

Record the exact existing command order, colors, widths, radii, dash/gap values, projected endpoints and early-return behavior before editing.

## Architecture target

Create:

`scripts/visual/renderer/cable_canvas_renderer.gd`

The component must be stateless:

```gdscript
extends RefCounted
class_name CableCanvasRenderer
```

It may build deterministic commands and pure visual plans only. It must not access GridManager, MissionManager, CableTopologyService, scene tree, resources, textures, time, fonts, projection services or Canvas methods.

Recommended focused API:

```gdscript
static func build_floor_cable_commands(context: Dictionary) -> Array[Dictionary]
static func build_layered_segment_commands(context: Dictionary) -> Array[Dictionary]
static func build_layered_polyline_commands(context: Dictionary) -> Array[Dictionary]
static func build_object_link_commands(context: Dictionary) -> Array[Dictionary]
static func build_endpoint_cap_commands(context: Dictionary) -> Array[Dictionary]
static func build_elbow_commands(context: Dictionary) -> Array[Dictionary]
static func build_invalid_marker_commands(context: Dictionary) -> Array[Dictionary]
static func build_damage_marker_commands(context: Dictionary) -> Array[Dictionary]
static func build_bridge_commands(context: Dictionary) -> Array[Dictionary]
static func extract_bridge_network_id(object_data: Dictionary) -> String
static func should_emit_bridge(context: Dictionary) -> bool
```

Equivalent focused names are acceptable.

Use explicit command dictionaries with monotonically increasing `order`. Supported command kinds should remain narrow:

- `line`;
- `circle`;
- `arc`;
- `polyline`.

Every line command must contain `start`, `end`, `color`, `width`, `antialiased`, `order`.
Every circle command must contain `center`, `radius`, `color`, `order`.
Every arc command must contain `center`, `radius`, `start_angle`, `end_angle`, `point_count`, `color`, `width`, `antialiased`, `order`.
Every polyline command must contain `points`, `color`, `width`, `antialiased`, `order`.

Do not introduce a second Canvas executor.

## Coordinator ownership to preserve

`RoomVisualRenderer` must retain:

- `CableTopologyServiceRef.classify_cell()`;
- `_get_runtime_world_objects_for_iso_render()`;
- map-constructor/editor state;
- GridManager access and wall-cell checks;
- `grid_to_iso()` and all cell-to-screen projection;
- `_get_iso_cable_branch_endpoint_for_visual_center()` or equivalent projected endpoint preparation;
- wall-face visibility and occluder checks;
- draw-entry discovery/composition/sorting;
- actual Canvas execution through `_draw_route_commands()`;
- debug logging of emitted cable-object bridges;
- invalidation and scene/runtime dependencies.

`RouteRenderer` must remain the owner of:

- install/routing/health normalization;
- route family classification;
- wall-face segment geometry;
- wall procedural cable/air-duct/water-pipe commands;
- wall broken-route geometry;
- existing wall/floor segment primitives already exposed there.

Do not duplicate those APIs in `CableCanvasRenderer`.

## Floor cable coordinator split

Refactor `draw_iso_cable_segment_shape()` so it only:

1. resolves install mode and health state through `RouteRenderer` delegates;
2. reads editor mode;
3. handles the hidden/non-editor early return;
4. determines `cable_center` and wall-route early path;
5. obtains `route_plan` from `RouteRenderer.build_floor_topology_plan(topology)`;
6. prepares projected endpoints for active directions;
7. prepares normalized colors/profile and object-link endpoint rows;
8. calls `CableCanvasRenderer.build_floor_cable_commands(context)`;
9. executes commands through `_draw_route_commands()`.

The function must contain no direct calls to:

```text
draw_line
draw_circle
draw_arc
draw_polyline
draw_colored_polygon
draw_rect
```

Do not change topology classification or active-direction ordering.

## Exact current floor-cable behavior to preserve

### Profile preparation

Start from profile colors:

```text
base
accent
outline
```

Apply current `line_color_id` overrides exactly:

- red: `Color(1.0, 0.22, 0.18, fallback.a)`;
- blue: `Color(0.22, 0.48, 1.0, fallback.a)`;
- green: `Color(0.24, 0.92, 0.42, fallback.a)`;
- yellow: `Color(1.0, 0.88, 0.2, fallback.a)`;
- orange: `Color(1.0, 0.55, 0.18, fallback.a)`;
- purple: `Color(0.72, 0.38, 1.0, fallback.a)`;
- white: `Color(0.95, 0.95, 0.92, fallback.a)`.

Then preserve:

- hidden mode alpha adjustments;
- wall mode lightening;
- invalid route override colors;
- final `install_mode` in the normalized profile.

This color/style policy belongs in `CableCanvasRenderer`; the coordinator supplies raw profile, install mode, validity and line color ID.

### Isolated cable

When active directions are empty:

- half width `max(tile_half_size.x * 0.12, 7.0)`;
- layered mode segment between left/right points;
- center circle radius `4.5`, accent color;
- full ring radius `7.0`, angles `0..TAU`, 20 points, outline color, width `1.4`, antialiased true.

### Straight, elbow and branches

Preserve `RouteRenderer.build_floor_topology_plan()` interpretation:

- straight: one layered polyline between the two projected endpoints;
- elbow: layered polyline through endpoint A → center → endpoint B, followed by the two current center circles;
- branches/junctions: one layered polyline center → endpoint for every active direction in current order.

### Layered visible polyline

Preserve exact layers:

1. shadow points offset `(0, 2)`, `Color(0.03, 0.02, 0.02, 0.28)`, width `7.0`;
2. outline, width `6.0`;
3. base, width `4.0`;
4. accent, width `1.5`.

### Hidden segments

Preserve the current hidden dash/gap behavior used by the coordinator. Do not silently replace it with a different `RouteRenderer` dash profile unless the exact rendered commands are proven equivalent by contract.

### Wall segment shadow

Preserve the additional shadow line from `start + (0,2)` to `end + (0,2)`, `Color(0,0,0,0.18)`, width `2.0`, antialiased true. Keep wall-route topology/visibility in the coordinator.

### Object links

For each supplied object-link direction row:

- preserve link start/end distance formulas;
- hidden mode uses hidden segment commands;
- visible mode emits shadow width `4.0`, outline `3.0`, base `1.9`;
- link-end circle radius `2.3`, accent color;
- preserve direction iteration order supplied by coordinator.

### Endpoint cap

Preserve exact normal/tangent geometry and three lines:

- outline width `4.4`;
- color width `2.2`;
- forward highlight width `1.2`.

### Junction and invalid markers

Preserve current junction center circle radius `3.6`.
Move the complete current `draw_iso_cable_invalid_marker()` geometry/style without redesign.

### Damage marker

Preserve:

- accepted states `damaged`, `broken`, `cut`;
- dark center circle radius `4.0`;
- yellow marker for damaged;
- red marker for broken/cut;
- two diagonal lines width `1.8`, antialiased true.

### Debug outlines

Preserve one outline line from center to each active endpoint, width `1.0`, antialiased true, only when `debug_draw_iso_object_outlines` is enabled.

## Cable bridge split

Keep bridge draw-entry discovery in `RoomVisualRenderer`, including iteration over runtime world objects and cable cells.

Move only pure visual bridge policy:

- network ID extraction from the existing key precedence;
- cardinal adjacency check;
- normalized same-network decision from already supplied booleans/IDs;
- shared-edge point geometry from already projected object/cable centers;
- two layered half-segment command groups.

The coordinator must prepare:

```text
object_cell
cable_cell
object_center
cable_center
object_connectable
cable_present
object_network_id
cable_network_id
profile
debug metadata
```

`CableCanvasRenderer.should_emit_bridge(context)` must not call CableTopologyService.

`draw_object_cable_bridge()` becomes a thin command-builder/executor wrapper and retains only optional logging.

## Route command executor

Extend `_draw_route_commands()` only as needed to execute `polyline` and `arc` command kinds. Actual Canvas calls remain there.

Require safe typed reads and ignore malformed commands without throwing.

Do not move Canvas execution into `CableCanvasRenderer`.

## Remove migrated helpers

Delete migrated Canvas/style bodies from `RoomVisualRenderer` in the same PR. Compatibility wrappers may remain only when externally referenced and must be thin builder/executor delegates.

Expected removals or thin delegates include:

- `_get_line_color_from_id`;
- `draw_iso_cable_hidden_segment`;
- `draw_iso_cable_wall_segment`;
- `draw_iso_cable_damage_marker`;
- `draw_iso_cable_object_links`;
- `_draw_iso_cable_polyline`;
- `draw_iso_cable_endpoint_cap`;
- `draw_iso_cable_elbow`;
- `draw_iso_cable_invalid_marker`;
- `get_cable_bridge_network_id`;
- `get_cell_edge_bridge_points`.

Before deleting any public-looking function, search the repository. Preserve a thin compatibility delegate if external callers exist.

## Permanent contract

Add:

`tools/ci/check_cable_canvas_renderer_contract.gd`

Wire a dedicated permanent step into Renderer Component Gate after RouteRenderer contract.

Use approximate helpers for float/vector/color values. Accumulate failures and quit once.

Cover exact command outputs for:

1. every line color ID plus unknown fallback;
2. visible/hidden/wall/invalid profile normalization;
3. isolated cable exact layered segment, circle and arc;
4. straight cable for both axis directions;
5. elbow exact points and center circles;
6. branch and junction ordering;
7. endpoint cap exact geometry;
8. invalid marker exact geometry;
9. damage states and normal no-op;
10. visible and hidden object links;
11. debug outlines off/on;
12. wall segment shadow;
13. bridge network-key precedence;
14. bridge adjacency/same-network acceptance and rejection;
15. bridge exact shared-edge commands;
16. malformed/wrong-type context safety;
17. exact command schema/order;
18. repeated identical input stability.

Do not accept only command counts. Assert exact points, colors, widths, radii, arc fields, antialias flags and order.

## Boundary checker

Extend `tools/check_room_visual_renderer_component_boundary.py` to require:

- `CableCanvasRenderer` source and preload;
- focused API and class name;
- no Node/GridManager/MissionManager/CableTopologyService/projection/resource/texture/time/font/scene-tree/Canvas dependencies in the component;
- `draw_iso_cable_segment_shape()` retains topology/world/projection context but no direct Canvas calls;
- `_draw_route_commands()` remains the only owner of cable `draw_line`, `draw_circle`, `draw_arc`, `draw_polyline` execution;
- cable bridge draw-entry discovery remains in the coordinator;
- migrated helpers are absent or thin delegates;
- wall-route APIs remain owned by `RouteRenderer`;
- draw-entry order and cable-before-object layering remain unchanged;
- coordinator cap is renamed for this stage and reduced below 5723 to exact final line count.

Use specific forbidden tokens and avoid false positives from the class name `CableCanvasRenderer`.

## Explicit exclusions

Do not modify:

- wall-route geometry already owned by `RouteRenderer`, except command-executor compatibility;
- door, object, floor, wall, fog or overlay policies;
- texture/resource loading or asset alignment catalogs;
- CableTopologyService gameplay behavior;
- power-network gameplay rules;
- collision, placement, mission or map-constructor behavior;
- scenes or `project.godot`;
- final coordinator cleanup.

Do not add temporary workflows, worklogs or transformation scripts.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_cable_canvas_renderer_contract.gd
```

Keep Renderer Component, Godot Parser, Bipob Module Catalog and Surface Catalog gates green.

## Stop boundary

Stop after floor cable and cable-bridge Canvas extraction. Do not start asset alignment/catalog extraction, texture/resource runtime extraction or final coordinator cleanup in the same PR.
