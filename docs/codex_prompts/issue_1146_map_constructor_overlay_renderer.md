# Codex Prompt — Issue #1146

Implement GitHub issue #1146, **BIP-Architecture-Coordinators-02F2: Extract Map Constructor overlay policy**, from the latest `main` of `JUSTConnect/bibop`.

## First: inspect actual current code

Before editing, inspect and map callers/dependencies in:

- `scripts/field/room_visual_renderer.gd`
- `scripts/visual/renderer/overlay_renderer.gd`
- `tools/check_room_visual_renderer_component_boundary.py`
- `.github/workflows/renderer-component-gate.yml`
- existing renderer contract tests under `tools/ci/`

Current verified baseline after merged PR #1145:

- `RoomVisualRenderer` is 6190 lines;
- permanent cap is 6205;
- `draw_map_constructor_visual_overlay_passes()` is still direct policy + Canvas execution;
- `_draw_overlay_commands()` supports `polygon`, `polyline`, and `line`;
- `_draw()` order is:
  1. cable reel trail;
  2. normal mouse selection;
  3. Map Constructor overlays;
  4. selected interaction target;
  5. world/fan markers;
  6. fog.

Verify these facts against the latest branch before editing.

## Goal

Create a stateless component:

```text
scripts/visual/renderer/map_constructor_overlay_renderer.gd
```

with:

```gdscript
extends RefCounted
class_name MapConstructorOverlayRenderer
```

The component owns deterministic Map Constructor overlay style, primitive geometry derived from already projected inputs, and stable primitive ordering.

`RoomVisualRenderer` remains responsible for:

- overlay preference/state dictionaries;
- preview cell and blocked state;
- all current guard conditions;
- cell validation;
- `grid_to_iso()` and inset-diamond projection;
- Canvas execution and `queue_redraw()`;
- normal `OverlayRenderer` paths;
- runtime/debug overlays outside this function;
- fog, textures, resources, and runtime managers.

## Exact scope

Extract deterministic policy only from:

- `_draw_wall_side_arrow()`;
- `draw_map_constructor_visual_overlay_passes()`.

Cover these passes in their current order:

1. selected cell;
2. hover cell;
3. placement preview;
4. room visual preview walls;
5. room visual preview doors;
6. room visual preview terminals;
7. room visual preview floors;
8. multi-select;
9. validation markers;
10. links;
11. power;
12. preview wall-side arrow;
13. selected wall-side arrow.

Do not move setters, state fields, projection, normal selection/interaction overlays, unrelated debug overlays, fog, texture caches, or object rendering.

## Recommended context boundary

The coordinator should prepare explicit screen-space data, for example:

```gdscript
{
    "selected_points": PackedVector2Array,
    "hover_points": PackedVector2Array,
    "preview_points": PackedVector2Array,
    "preview_mode": String, # normal / blocked / destructive / none
    "room_walls": Array[Dictionary], # {points, center}
    "room_door_centers": Array[Vector2],
    "room_terminal_centers": Array[Vector2],
    "room_floor_point_sets": Array[PackedVector2Array],
    "multi_select_point_sets": Array[PackedVector2Array],
    "validation_markers": Array[Dictionary], # {center, severity, expected_invalid}
    "links": Array[Dictionary], # {start, end, broken}
    "power_links": Array[Dictionary], # {start, end}
    "wall_side_arrows": Array[Dictionary] # {center, wall_side, color}
}
```

The exact shape may differ, but do not pass nodes, managers, cells requiring projection, callables, resources, or the coordinator itself.

Preferences remain coordinator-owned. Prefer omitting disabled pass inputs rather than passing the full preference dictionary into the component.

## Preserve current guards exactly

Do not “clean up” or broaden current validity conditions during this extraction:

- selected/hover/preview/room-preview/multi-select/validation rows currently require both x and y to be non-negative;
- links currently skip only when `from_cell.x < 0` or `to_cell.x < 0`;
- power rows currently skip only when `f.x < 0` or `t.x < 0`;
- preview wall-side arrow currently requires non-empty side and `map_constructor_preview_cell.x >= 0` only;
- selected wall-side arrow currently requires only a non-empty side before projecting its selected cell.

Keep these observable semantics unless a separate bug issue explicitly changes them.

## Exact visual contract

### Selected

- fill: `Color(1.0, 0.92, 0.24, 0.11)`;
- outline: `Color(1.0, 0.92, 0.24, 0.95)`;
- width: `2.4`;
- fill first, then four ordered `line` edges including the closing edge.

### Hover

- outline: `Color(0.72, 0.92, 1.0, 0.45)`;
- width: `1.2`;
- four ordered `line` edges.

### Placement preview

Normal:

- fill `Color(0.35, 1.0, 0.85, 0.16)`;
- stroke `Color(0.45, 1.0, 0.92, 1.0)`.

Blocked:

- fill `Color(1.0, 0.35, 0.25, 0.2)`;
- stroke `Color(1.0, 0.55, 0.3, 1.0)`.

Destructive:

- fill `Color(1.0, 0.62, 0.22, 0.17)`;
- stroke `Color(1.0, 0.7, 0.3, 1.0)`.

Stroke width is `2.2`. Blocked takes precedence over destructive, matching current code.

### Room visual preview

Walls:

- outline `Color(0.95, 0.74, 0.28, 0.42)`, width `1.5`;
- center marker at `center + Vector2(0.0, -8.0)`;
- radius `2.1`;
- marker color `Color(0.45, 0.9, 1.0, 0.76)`.

Doors:

- marker at projected center `+ Vector2(-5.0, -9.0)`;
- radius `2.8`;
- color `Color(1.0, 0.76, 0.28, 0.88)`.

Terminals:

- marker at projected center `+ Vector2(5.0, -9.0)`;
- radius `2.8`;
- color `Color(0.44, 0.9, 1.0, 0.88)`.

Floors:

- outline `Color(0.56, 0.78, 0.96, 0.48)`;
- width `1.15`.

### Multi-select

- outline `Color(0.75, 0.85, 1.0, 0.8)`;
- width `1.4`.

### Validation

Radius is `6.0`.

- default/info: `Color(0.62, 0.8, 1.0, 0.95)`;
- expected invalid: `Color(0.74, 0.66, 0.86, 0.95)`;
- error: `Color(1.0, 0.3, 0.3, 0.95)`;
- warning: `Color(1.0, 0.74, 0.3, 0.95)`.

Preserve current precedence:

1. explicit `expected_invalid` or severity lowercased equals `expected_invalid`;
2. exact severity `error`;
3. exact severity `warning`;
4. default/info.

Do not silently make all severity comparisons case-insensitive.

### Links and power

Links:

- normal `Color(0.9, 0.58, 1.0, 0.85)`;
- broken `Color(1.0, 0.3, 0.3, 0.9)`;
- width `1.8`.

Power:

- `Color(0.45, 0.9, 1.0, 0.65)`;
- width `1.2`.

### Wall-side arrows

Direction mapping:

- north/default: `Vector2(0.0, -1.0)`;
- east: `Vector2(1.0, 0.0)`;
- south: `Vector2(0.0, 1.0)`;
- west: `Vector2(-1.0, 0.0)`.

Geometry:

- tip = center + direction * `16.0`;
- line width `2.0`;
- tip circle radius `3.0`;
- line then circle.

Colors:

- preview: `Color(0.82, 0.95, 1.0, 1.0)`;
- selected: `Color(1.0, 0.88, 0.35, 1.0)`.

## Primitive command contract

Use stable append order and monotonically increasing `order` metadata.

Supported commands should include:

```gdscript
{"kind": "polygon", "points": PackedVector2Array, "color": Color, "order": int}
{"kind": "line", "start": Vector2, "end": Vector2, "color": Color, "width": float, "antialiased": bool, "order": int}
{"kind": "circle", "center": Vector2, "radius": float, "color": Color, "order": int}
```

Use individual `line` commands for diamond outlines to preserve current closing-edge and join behavior exactly.

Extend `_draw_overlay_commands()` with `circle` execution. The dispatcher must remain policy-free. Do not add a second Map Constructor dispatcher or retain old direct drawing as fallback.

## Coordinator migration

In `RoomVisualRenderer`:

1. preload the new component alongside `OverlayRenderer`;
2. keep all setters and state fields behaviorally unchanged;
3. build a narrow helper that resolves current preferences, guards, cells, projection, inset points, centers, and endpoints;
4. make `draw_map_constructor_visual_overlay_passes()` call the component and `_draw_overlay_commands()`;
5. remove `_draw_wall_side_arrow()` or reduce it to a pure delegate with no direction/style policy;
6. delete all migrated colors, widths, radii, offsets, direction mapping, and direct Canvas calls from the Map Constructor function;
7. preserve `_draw()` ordering exactly.

## Contract test

Add:

```text
tools/ci/check_map_constructor_overlay_renderer_contract.gd
```

Follow the existing headless `SceneTree` contract-test style. Assert exact geometry/style/order, not only command kinds.

Required cases:

1. selected fill and four closing outline edges;
2. hover outline;
3. normal preview;
4. blocked preview;
5. destructive preview;
6. blocked precedence over destructive;
7. room wall outline + marker;
8. door marker offset/radius/color;
9. terminal marker offset/radius/color;
10. floor outline;
11. multiple multi-select rows preserve input order;
12. validation info/expected-invalid/error/warning colors and precedence;
13. normal and broken links;
14. power line;
15. north/east/south/west/default wall-side arrows;
16. absent or invalid projected input emits no command;
17. complete command fields and monotonically increasing `order`;
18. identical input produces stable output.

Wire it into `.github/workflows/renderer-component-gate.yml` after the existing overlay contract. Do not create another workflow.

## Architecture enforcement

Extend `tools/check_room_visual_renderer_component_boundary.py`:

- add/read the new component;
- require its preload and public contract;
- require `draw_map_constructor_visual_overlay_passes()` to delegate;
- ensure the function remains present and remains in the same `_draw()` order;
- forbid migrated Map Constructor colors, widths, radii, offsets, direction mapping, and direct `draw_*` calls from returning to the coordinator function;
- forbid the component from `Node`, `Node2D`, managers, `get_node`, `get_tree`, `ResourceLoader`, `load`, `Time`, `queue_redraw`, projection helpers, and all Canvas calls;
- keep normal `OverlayRenderer` delegation checks;
- keep runtime/debug overlay and fog ownership in the coordinator for this stage;
- lower the line cap from 6205 based on the final actual `RoomVisualRenderer` line count.

The final cap must be below the pre-change baseline of 6190 and should equal final line count plus only a small explicit maintenance margin (normally no more than 10–15 lines). Do not increase or leave it at 6205.

## Strict exclusions

Do not change:

- gameplay, collision, placement, mission, editor-state, or selection behavior;
- normal selection/interaction overlays already owned by `OverlayRenderer`;
- runtime/debug overlays outside `draw_map_constructor_visual_overlay_passes()`;
- fog;
- textures, caches, resource loading, object rendering, or projection services;
- `project.godot`.

Do not add temporary workflows, worklogs, transformation scripts, duplicate render paths, or broad formatting cleanup.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_map_constructor_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
```

Also require permanent Renderer Component, Godot Parser, Surface Catalog, and Bipob Module Catalog gates to pass.

## Branch and PR

Branch:

```text
codex/bip-architecture-coordinators-02f2-map-constructor-overlays
```

PR title:

```text
BIP-Architecture-Coordinators-02F2: Extract Map Constructor overlay policy
```

PR body must include:

- `Implements #1146`;
- old/new `RoomVisualRenderer` line counts;
- new permanent cap;
- responsibilities retained in the coordinator;
- explicit exclusions respected;
- actual validation and CI results.

Stop after this focused extraction. Do not begin runtime/debug overlays or fog in the same PR.
