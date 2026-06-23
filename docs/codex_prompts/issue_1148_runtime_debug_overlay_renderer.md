# Codex Prompt — Issue #1148

Implement GitHub issue #1148, **BIP-Architecture-Coordinators-02F3: Extract runtime and debug overlay policy**, from the latest `main` of `JUSTConnect/bibop`.

## First: audit the exact current code

Before editing, inspect and map all callers and pass ordering in:

- `scripts/field/room_visual_renderer.gd`
- `scripts/visual/renderer/overlay_renderer.gd`
- `scripts/visual/renderer/map_constructor_overlay_renderer.gd`
- `tools/check_room_visual_renderer_component_boundary.py`
- `.github/workflows/renderer-component-gate.yml`
- existing renderer contract tests under `tools/ci/`

Current verified baseline after merged PR #1147:

- `RoomVisualRenderer` is approximately 6149 source lines; verify the exact count;
- permanent cap is 6162;
- normal selection and interaction overlays are already owned by `OverlayRenderer`;
- Map Constructor overlays are already owned by `MapConstructorOverlayRenderer`;
- `_draw_overlay_commands()` already executes `polygon`, `polyline`, `line`, and `circle` commands;
- `RoomVisualRenderer._draw()` currently places wall-mount/wall-run/floor-join diagnostics after the geometry pass, then cable-reel drag trail, selection, Map Constructor, interaction target, world/fan markers, and finally fog.

Inspect the exact current implementations and every call site controlled by these flags/functions:

- `show_wall_mount_zones_overlay` / `draw_wall_mount_zones_overlay()`;
- `show_wall_run_overlay` / `draw_wall_run_overlay()`;
- `show_floor_join_overlay` / `draw_floor_join_overlay()`;
- `show_object_grounding_overlay` and its drawing helper/call sites;
- `show_asset_alignment_overlay` / `draw_iso_asset_alignment_overlay()` and its call sites;
- `show_door_opening_overlay` and its drawing helper/call sites;
- `show_wall_topology_overlay` if it still owns a separate deterministic overlay path;
- `draw_world_overlay_markers()`;
- `draw_fan_platform_marker()`;
- `debug_draw_marker` and `debug_draw_iso_helper_preview` handling in `_draw()`.

Build a caller/dependency map before editing. Do not infer ownership only from export flag names.

## Goal

Create a focused stateless component:

```text
scripts/visual/renderer/runtime_debug_overlay_renderer.gd
```

with:

```gdscript
extends RefCounted
class_name RuntimeDebugOverlayRenderer
```

The component owns deterministic runtime/debug overlay geometry, style, labels, and stable primitive-command ordering from explicit screen-space inputs.

`RoomVisualRenderer` remains responsible for:

- all grid, mission, world, visibility, topology, object, and runtime lookup;
- all feature/debug flags;
- cell validity and projection through `grid_to_iso()` and existing geometry helpers;
- font selection and actual Canvas execution;
- draw-pass placement and invalidation;
- cable-reel drag-trail runtime lookup and rendering in this slice;
- fog;
- primary wall/floor/object rendering and textures.

## Exact extraction scope

Extract deterministic policy for these overlay families only:

1. wall-mount zone circles and side labels;
2. wall-run diagnostic labels and edge colors/widths;
3. floor-join edge colors/widths;
4. world overlay marker label placement/style;
5. fan-platform direction triangle/line geometry and style;
6. object-grounding diagnostic primitives;
7. asset-alignment diagnostic primitives and labels;
8. door-opening diagnostic primitives;
9. origin marker and helper-preview diamond primitives;
10. wall-topology diagnostics only if the audit confirms a distinct current overlay path controlled by `show_wall_topology_overlay`.

Preserve each overlay at its current draw-pass location. Inline diagnostics called from floor/wall/object draw paths must remain inline relative to the owning primary asset draw; only their deterministic command generation moves.

## Strict exclusions

Do not move or modify:

- normal selection/interaction overlays;
- Map Constructor overlays;
- cable-reel drag trail;
- fog or fog outlines;
- primary wall/floor/object procedural drawing;
- textures, resource loading, asset resolution, caches, descriptors, or authored-canvas drawing;
- gameplay, collision, mission, visibility, placement, topology, or selection behavior;
- `project.godot`.

Do not add a second fallback path. Delete migrated deterministic drawing bodies from `RoomVisualRenderer` in the same PR.

## Context boundary

The coordinator must pass explicit projected data only. Recommended context families:

```gdscript
{
    "origin_marker": Dictionary,
    "helper_preview": Dictionary,
    "wall_mount_zones": Array[Dictionary],
    "wall_runs": Array[Dictionary],
    "floor_join_edges": Array[Dictionary],
    "world_markers": Array[Dictionary],
    "fan_marker": Dictionary,
    "grounding_diagnostics": Array[Dictionary],
    "asset_alignment_diagnostics": Array[Dictionary],
    "door_opening_diagnostics": Array[Dictionary]
}
```

Exact shapes may differ, but inputs must already contain screen-space points, centers, rects, labels, state flags, and current ordering. Do not pass nodes, managers, cells requiring projection, callables, textures, resources, fonts, or the coordinator itself.

## Command contract

Use deterministic dictionaries with monotonically increasing `order` metadata. Reuse existing primitive kinds where possible:

```gdscript
{"kind": "polygon", "points": PackedVector2Array, "color": Color, "order": int}
{"kind": "polyline", "points": PackedVector2Array, "color": Color, "width": float, "antialiased": bool, "order": int}
{"kind": "line", "start": Vector2, "end": Vector2, "color": Color, "width": float, "antialiased": bool, "order": int}
{"kind": "circle", "center": Vector2, "radius": float, "color": Color, "order": int}
{"kind": "text", "position": Vector2, "text": String, "width": float, "font_size": int, "alignment": int, "color": Color, "order": int}
```

Add `rect` or `arc` command kinds only if the exact current grounding/alignment/door diagnostics require them. If added, define complete deterministic schema and permanent tests.

Extend the common `_draw_overlay_commands()` dispatcher for `text` and any proven missing primitive. The dispatcher must remain policy-free. Font selection remains in the coordinator, normally using `ThemeDB.fallback_font` during text execution.

## Preserve current behavior exactly

Do not redesign colors, offsets, widths, radii, labels, marker sizes, or pass ordering. In particular preserve current verified behavior for:

- wall-mount zones: mountable-only filtering remains coordinator-owned; circle center is the projected mount-zone center; side label remains first uppercase character with current offset, font size, width, and colors;
- wall-run overlay: label content remains current shape plus `RX`, `RY`, and `cap` suffix rules; neighbor-connected and disconnected edge colors/width remain exact;
- floor-join overlay: shown/hidden border colors and widths remain exact;
- world markers: visibility filtering and marker lookup remain coordinator-owned; current projected offset, text width, font size, and color remain exact;
- fan marker: active/runtime lookup and projected direction remain coordinator-owned; current center/base/tip/perpendicular geometry and colors remain exact;
- debug origin marker and helper preview: current enable flags, geometry, colors, widths, and final pass placement remain exact;
- grounding, asset-alignment, door-opening, and optional wall-topology diagnostics: preserve all current conditionals and call-site ordering exactly.

Do not merge diagnostic families into one visual style.

## Coordinator migration

In `RoomVisualRenderer`:

1. preload `RuntimeDebugOverlayRenderer`;
2. keep all runtime lookup, visibility checks, topology queries, projection, and feature flags;
3. build narrow screen-space context helpers per overlay family;
4. delegate deterministic command generation to the new component;
5. execute commands through the common policy-free dispatcher;
6. keep inline diagnostic calls at the same points relative to primary texture/procedural draws;
7. preserve `_draw()` ordering exactly;
8. remove migrated colors, widths, radii, label composition, offsets, direction-triangle math, and direct Canvas calls from migrated overlay functions.

Avoid one giant coordinator context builder. Prefer small explicit helpers per family so runtime lookup boundaries stay readable.

## Contract test

Add:

```text
tools/ci/check_runtime_debug_overlay_renderer_contract.gd
```

Follow existing headless `SceneTree` contract-test style. Assert exact geometry, style, labels, schema, and ordering.

Cover at least:

1. origin marker enabled/absent;
2. helper-preview polygon plus closing outline edges;
3. wall-mount zone marker and one-character label;
4. multiple wall-mount zones preserving input order;
5. wall-run label composition for shape, RX, RY, and cap;
6. connected versus disconnected wall-run edge style;
7. shown versus hidden floor-join edge style;
8. world marker projected text command;
9. multiple world markers preserving input order;
10. fan marker triangle and center-to-tip line geometry for at least two directions;
11. grounding diagnostic representative command set;
12. asset-alignment representative command set;
13. door-opening representative command set;
14. optional wall-topology representative command set if included by audit;
15. omitted or invalid projected input emits no command;
16. all command kinds have complete required fields;
17. `order` is monotonically increasing for a full mixed-family context;
18. identical input produces stable output.

Wire the test into the existing Renderer Component Gate. Do not create another workflow.

## Architecture enforcement

Extend `tools/check_room_visual_renderer_component_boundary.py` so that:

- the new component file is required and preloaded;
- its public stateless contract is required;
- runtime/debug overlay functions delegate deterministic policy;
- `_draw()` preserves existing relative pass order;
- inline grounding/alignment/door diagnostics retain their current call-site placement;
- migrated colors, widths, radii, offsets, label composition, direction geometry, and direct Canvas calls cannot return to migrated coordinator functions;
- the component is forbidden from `Node`, `Node2D`, managers, `get_node`, `get_tree`, `ThemeDB`, fonts, `ResourceLoader`, `load`, textures, `Time`, `queue_redraw`, projection helpers, and all Canvas methods;
- `draw_cable_reel_drag_trail`, fog functions, normal overlay delegation, Map Constructor delegation, and primary object/floor/wall drawing remain coordinator-owned in this stage;
- the permanent line cap is lowered from 6162 based on the final actual `RoomVisualRenderer` line count.

The new cap must be below the pre-change source count and should equal final line count plus only a small explicit maintenance margin.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_runtime_debug_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_map_constructor_overlay_renderer_contract.gd
```

Also require permanent Renderer Component, Godot Parser, Surface Catalog, and Bipob Module Catalog gates to pass.

## Branch and PR

Branch:

```text
codex/bip-architecture-coordinators-02f3-runtime-debug-overlays
```

PR title:

```text
BIP-Architecture-Coordinators-02F3: Extract runtime and debug overlay policy
```

PR body must include:

- `Implements #1148`;
- exact audited overlay families and functions moved;
- old/new `RoomVisualRenderer` line counts;
- new permanent cap;
- responsibilities retained in the coordinator;
- explicit exclusions respected;
- actual validation and CI results.

Stop after this focused extraction. Do not begin fog or remaining primary object Canvas/texture extraction in the same PR.
