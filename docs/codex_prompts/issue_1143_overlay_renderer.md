# Codex Prompt — Issue #1143

Implement GitHub issue #1143, **BIP-Architecture-Coordinators-02F1: Extract selection and interaction overlay policy**, directly from the latest `main` of `JUSTConnect/bibop`.

## First: inspect current code, do not rely only on the issue text

Before editing, build a caller/dependency map for the exact current implementations in:

- `scripts/field/room_visual_renderer.gd`
- `tools/check_room_visual_renderer_component_boundary.py`
- `.github/workflows/renderer-component-gate.yml`
- existing renderer components and contract tests under `scripts/visual/renderer/` and `tools/ci/`

The current `RoomVisualRenderer` baseline is approximately 6210 lines and the boundary checker still allows 6450. Verify the actual current values before changing anything.

Inspect all callers and state around:

- `set_iso_mouse_selection_visuals()`
- `clear_iso_mouse_selection_visuals()`
- `draw_iso_mouse_selection_overlay()`
- `set_selected_wall_mounted_object()` / `clear_selected_wall_mounted_object()`
- `set_selected_interaction_target()`
- `_get_selected_interaction_target_cell()`
- `_get_selected_interaction_overlay_rect()`
- `draw_selected_interaction_target_overlay()`
- the frame/update path that advances `selected_interaction_overlay_time`
- the renderer `_draw()` order for selection and interaction overlays

Also identify the immediately adjacent `draw_map_constructor_visual_overlay_passes()` block. That block is explicitly out of scope and must remain in `RoomVisualRenderer` unchanged in this PR.

## Goal

Create a stateless component:

```text
scripts/visual/renderer/overlay_renderer.gd
```

with:

```gdscript
extends RefCounted
class_name OverlayRenderer
```

`OverlayRenderer` must own only deterministic geometry, style, pulse math and primitive-command ordering for:

1. normal mouse selection overlays;
2. selected interaction-target overlays.

`RoomVisualRenderer` remains the scene-facing coordinator and owns:

- selected state fields and setters/clearers;
- runtime world-object lookup;
- parsing/validation of cells;
- projection and runtime-surface lookup;
- animation time state and redraw scheduling;
- all CanvasItem `draw_*` execution;
- Map Constructor overlays;
- fog;
- textures and resource loading.

## Exact current behavior that must remain unchanged

### Mouse selection overlay

Preserve current ordering and values:

1. every route cell, in current array order:
   - fill `Color(0.29, 0.75, 0.95, 0.14)`;
   - outline `Color(0.29, 0.75, 0.95, 0.45)`;
   - width `1.6`;
2. selected cell:
   - fill `Color(0.85, 0.93, 1.0, 0.09)`;
   - outline `Color(0.8, 0.97, 1.0, 1.0)`;
   - width `2.6`;
3. action cell:
   - fill `Color(0.98, 0.66, 0.35, 0.24)`;
   - outline `Color(0.99, 0.75, 0.45, 1.0)`;
   - width `2.8`;
4. wall-mounted anchor outline:
   - `Color(0.35, 0.92, 1.0, 1.0)`;
   - width `2.8`;
5. attached-wall outline:
   - `Color(1.0, 0.8, 0.35, 1.0)`;
   - width `2.8`;
6. selected wall-object diamond marker:
   - radius `9.0`;
   - color `Color(1.0, 0.96, 0.3, 1.0)`;
   - width `2.8`;
   - closed polyline;
   - only when the coordinator has resolved the requested object id and projected its visual center.

The component receives already projected point arrays and the already resolved wall-object center. It must not call projection helpers or query the mission/world.

### Interaction target overlay

Preserve the current rect policy exactly:

- base/default center is resolved in the coordinator with the existing object visual-center path;
- wall targets use the projected wall center and existing wall-height offset;
- default size: `Vector2(half.x * 0.72, half.y * 0.92 + object_marker_height * 0.45)`;
- wall size: `Vector2(half.x * 0.95, half.y * 1.2 + wall_height * 0.35)`;
- cable size: `Vector2(half.x * 0.86, half.y * 0.58)`;
- item size: `Vector2(half.x * 0.52, half.y * 0.62)`;
- retain the existing initial/default size semantics if the current implementation depends on them;
- grow the resulting rect by `6.0` before command generation.

Preserve pulse and style exactly:

```gdscript
pulse = 0.65 + 0.35 * sin(time_seconds * 5.0)
color = Color(0.2, 0.9, 1.0, 0.45 + 0.35 * pulse)
shadow = Color(0.02, 0.05, 0.07, color.a * 0.72)
corner = maxf(10.0, minf(rect.size.x, rect.size.y) * 0.24)
width = 2.0 + pulse
shadow_width = width + 2.0
```

For each corner preserve primitive ordering:

1. horizontal shadow;
2. vertical shadow;
3. horizontal color line;
4. vertical color line.

Preserve antialiasing and the current corner direction signs.

## Component API

Use a compact stateless API. Exact names may vary, but it should be equivalent to:

```gdscript
static func build_mouse_selection_commands(context: Dictionary) -> Array[Dictionary]
static func build_interaction_target_rect(context: Dictionary) -> Rect2
static func get_interaction_pulse(time_seconds: float) -> float
static func build_interaction_target_commands(context: Dictionary) -> Array[Dictionary]
```

Recommended mouse-selection context:

```gdscript
{
    "route_point_sets": Array[PackedVector2Array],
    "selected_points": PackedVector2Array,
    "action_points": PackedVector2Array,
    "wall_anchor_points": PackedVector2Array,
    "attached_wall_points": PackedVector2Array,
    "has_wall_object_center": bool,
    "wall_object_center": Vector2
}
```

Recommended interaction context:

```gdscript
{
    "kind": String,
    "object_type": String,
    "default_center": Vector2,
    "wall_center": Vector2,
    "tile_half_size": Vector2,
    "wall_height": float,
    "object_marker_height": float,
    "time_seconds": float
}
```

Do not pass the full `RoomVisualRenderer`, `GridManager`, mission manager, nodes, resources or callables into the component.

## Primitive command contract

Use explicit dictionaries with stable append order. Each command must contain a `kind` and all geometry/style required for execution.

Support only the primitives needed by this slice, for example:

```gdscript
{
    "kind": "polygon",
    "points": PackedVector2Array,
    "color": Color,
    "order": int
}

{
    "kind": "polyline",
    "points": PackedVector2Array,
    "color": Color,
    "width": float,
    "closed": bool,
    "antialiased": bool,
    "order": int
}

{
    "kind": "line",
    "start": Vector2,
    "end": Vector2,
    "color": Color,
    "width": float,
    "antialiased": bool,
    "order": int
}
```

A polygon outline may be emitted as one closed `polyline` command or as ordered `line` commands, but Canvas behavior must remain visually equivalent. Prefer the form that matches the current drawing semantics most exactly.

Add one small generic overlay-command dispatcher in `RoomVisualRenderer`, such as `_draw_overlay_commands(commands)`. It may call `draw_colored_polygon`, `draw_polyline` and `draw_line`. Do not put policy or fallback geometry in the dispatcher.

## Coordinator migration

In `RoomVisualRenderer`:

1. preload `OverlayRenderer` alongside the existing focused renderer components;
2. keep all state setter/clearer methods unchanged in behavior;
3. keep `_get_selected_interaction_target_cell()` as runtime/state parsing;
4. make `_get_selected_interaction_overlay_rect()` a thin context-preparation delegate or replace it with an equally narrow private delegate while preserving callers;
5. change `draw_iso_mouse_selection_overlay()` to:
   - resolve all selected projected point sets;
   - resolve selected wall object and visual center through the existing runtime path;
   - call `OverlayRenderer.build_mouse_selection_commands()`;
   - execute commands through the generic dispatcher;
6. change `draw_selected_interaction_target_overlay()` to:
   - resolve cell, kind/type and projected centers;
   - pass current `selected_interaction_overlay_time` explicitly;
   - call the component;
   - execute commands through the dispatcher;
7. delete the migrated color/width/pulse/corner/primitive-building bodies from the coordinator in the same change.

Do not create a fallback path that keeps the old direct drawing implementation.

Preserve the existing global `_draw()` ordering. Selection and interaction overlays must appear in the same relative order as before.

## Strict exclusions

Do not move or redesign:

- `draw_map_constructor_visual_overlay_passes()`;
- `_draw_wall_side_arrow()`;
- Map Constructor preview, hover, validation, multi-select, links or power overlays;
- fog functions or fog state;
- world-overlay markers or debug overlays;
- picking and gameplay selection logic such as `get_cell_at_iso_visual_position()`;
- projection services;
- texture caches, asset loading or object rendering;
- `project.godot`.

No unrelated cleanup, formatting sweep, visual redesign, new plugin, temporary workflow, worklog or transformation script.

## Contract test

Add:

```text
tools/ci/check_overlay_renderer_contract.gd
```

Follow the existing headless `SceneTree` contract-test style.

Required deterministic cases:

1. route fill then route outline ordering;
2. multiple route cells preserve input order;
3. selected-cell fill and outline values;
4. action-cell fill and outline values;
5. wall-anchor outline;
6. attached-wall outline;
7. selected wall-object diamond geometry and closed polyline;
8. no wall-object command when the coordinator context says no resolved center;
9. default interaction rect;
10. wall interaction rect and wall center selection;
11. cable interaction rect;
12. item interaction rect;
13. pulse at `t = 0.0` equals `0.65` approximately;
14. pulse at `t = PI / 10.0` equals `1.0` approximately;
15. pulse at `t = 3.0 * PI / 10.0` equals `0.30` approximately;
16. interaction command count, complete fields and corner ordering;
17. shadow/color alpha and width relationships;
18. stable output for identical input.

Assertions must check full geometry/style fields, not only command count or `kind`.

## Permanent architecture enforcement

Extend `tools/check_room_visual_renderer_component_boundary.py`:

- add `OVERLAY = ROOT / "scripts/visual/renderer/overlay_renderer.gd"`;
- read the component;
- require the preload in `RoomVisualRenderer`;
- require `class_name OverlayRenderer` and the selected public static APIs;
- require migrated coordinator helpers to delegate to `OverlayRenderer`;
- forbid direct selection/interaction style-policy tokens from returning to those coordinator bodies;
- forbid `OverlayRenderer` from containing runtime/Canvas dependencies, including at least:
  - `GridManager`;
  - `MissionManager`;
  - `Node` / `Node2D` ownership;
  - `get_node(`;
  - `get_tree(`;
  - `ResourceLoader` / `load(`;
  - `Time`;
  - `queue_redraw(`;
  - `grid_to_iso(`;
  - `draw_line(`;
  - `draw_polyline(`;
  - `draw_colored_polygon(`;
  - `draw_rect(`;
  - `draw_arc(`;
- ensure Map Constructor overlay ownership remains in the coordinator for this stage;
- ensure fog ownership remains in the coordinator for this stage.

The current coordinator baseline is about 6210 lines while the existing cap is 6450. After migration, measure the actual file and lower the cap to a value below the pre-change baseline. Do not leave the cap at 6450 and do not increase it. Choose a tight value based on the final coordinator line count, with only a small explicit maintenance margin.

## CI wiring

Add the contract to `.github/workflows/renderer-component-gate.yml` after the existing renderer component contracts:

```yaml
- name: Check OverlayRenderer contract
  run: godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
```

Do not create a separate workflow.

## Validation

Run all of these locally:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_renderer_projection_contract.gd
godot --headless --path . --script res://tools/ci/check_floor_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_wall_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_object_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd
```

Also ensure the permanent Godot Parser, Renderer Component, Surface Catalog and Bipob Module Catalog gates remain green.

## Deliverable

Create one focused PR from:

```text
codex/bip-architecture-coordinators-02f1-overlay-policy
```

PR title:

```text
BIP-Architecture-Coordinators-02F1: Extract selection and interaction overlay policy
```

PR body must include:

- `Implements #1143`;
- concise dependency map;
- list of migrated responsibilities;
- explicit list of responsibilities intentionally left in `RoomVisualRenderer`;
- old/new `RoomVisualRenderer` line counts and new cap;
- validation commands and results;
- statement that Map Constructor overlays, fog, gameplay selection and visual appearance were not intentionally changed.

Stop after this coherent extraction. Do not begin the later Map Constructor/debug-overlay, fog or object Canvas/texture stages from roadmap #1144.