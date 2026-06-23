# Codex prompt — issue #1152 object primitive renderer

Implement issue #1152 from the latest `main` after merged PR #1151.

Use branch:

`codex/bip-architecture-coordinators-02f5a-object-primitives`

PR title:

`BIP-Architecture-Coordinators-02F5A: Extract procedural object primitive policy`

Read the issue body first and preserve every scope boundary.

## Required audit before editing

Inspect these exact areas in `scripts/field/room_visual_renderer.gd`:

- `get_iso_object_visual_profiles()` and `get_iso_object_profile()`;
- `draw_iso_object_slab()`;
- `draw_iso_object_door_panel()`;
- `draw_iso_object_pillar()`;
- `draw_iso_object_terminal_console()`;
- `draw_iso_object_small_marker()`;
- `draw_iso_object_line()`;
- `draw_iso_object_heat_marker()`;
- wall-mounted procedural fallback helpers and `draw_wall_mounted_object_shape()`;
- the post-texture accent dot/line inside `draw_iso_object_marker()`;
- generic object footprint/shadow drawing before texture dispatch;
- the shared command dispatcher and renderer component boundary checker.

Also inspect `scripts/visual/renderer/object_renderer.gd` so the new component does not duplicate descriptor, asset-key, layer or draw-entry policy already owned there.

## Architecture target

Create `scripts/visual/renderer/object_primitive_renderer.gd` as a stateless `RefCounted` component.

It receives already projected positions/polygons, normalized profile dictionaries, tile half-size/marker-height scalars and flags. It returns deterministic ordered primitive commands only.

Recommended API shape:

```gdscript
static func get_visual_profiles() -> Dictionary
static func get_profile(profile_key: String) -> Dictionary
static func build_floor_base_commands(context: Dictionary) -> Array[Dictionary]
static func build_shape_commands(shape: String, context: Dictionary) -> Array[Dictionary]
static func build_wall_mounted_commands(profile_key: String, context: Dictionary) -> Array[Dictionary]
static func build_texture_accent_commands(context: Dictionary) -> Array[Dictionary]
```

Equivalent focused names are acceptable.

Supported command kinds may include `polygon`, `line`, `circle`, `rect`, `arc` and `text` only when required by current behavior. Extend the coordinator command dispatcher with `arc` only if needed, keeping execution policy-free.

## Move in this PR

- the procedural object visual profile catalog;
- geometry/color/width/order policy for non-cable object fallback shapes;
- wall-mounted device fallback shape policy;
- object footprint and shadow primitive policy;
- texture-success accent dot/line policy;
- shape dispatch policy for non-route object primitives.

Delete migrated implementations from `RoomVisualRenderer` in the same PR. Keep no duplicate fallback implementation.

## Coordinator retains

- GridManager and MissionManager lookup;
- runtime object metadata and door/terminal state lookup;
- profile-key and asset-key resolution through `ObjectRenderer`;
- projection, visual-center and wall-center assembly;
- PNG/SVG/resource loading and caches;
- render-contract descriptor assembly already delegated to `ObjectRenderer`;
- texture draw execution;
- Canvas execution of returned primitive commands;
- object draw-entry collection, sorting, invalidation and draw-pass placement.

## Explicit exclusions

Do not change or extract:

- `draw_iso_object_png_texture_asset()` and texture caches/loaders;
- object render-contract routing or authored wall/floor canvas descriptor behavior;
- PNG → optional texture → legacy texture fallback order;
- `draw_iso_door_insert()` and door-opening policy;
- cable, duct, pipe or bridge rendering owned by `RouteRenderer`;
- floor or wall Canvas rendering;
- gameplay, collision, placement, mission, scene or `project.godot` behavior.

## Behavior preservation

Preserve exact current geometry, colors, alpha, widths, outline behavior and command order for:

- slab;
- door panel fallback shape used outside the dedicated door-insert path;
- pillar;
- terminal console;
- small marker;
- line;
- heat marker;
- wall terminal/platform/cooling panels;
- firewall, breaker, fuse box, switch, socket, light and wall cable-reel fallback shapes;
- generic footprint/shadow;
- texture-success accent marker.

`draw_iso_object_marker()` must remain the scene-facing orchestrator and retain the current texture-first/fallback flow. Its final procedural branch should only assemble context, delegate command generation and execute commands.

## Permanent contract

Add `tools/ci/check_object_primitive_renderer_contract.gd` and wire it as a dedicated step into `.github/workflows/renderer-component-gate.yml`.

Cover at minimum:

- representative profile catalog parity and safe generic fallback;
- every supported primitive shape;
- outlines disabled and enabled;
- valid and malformed/partial contexts;
- wall-mounted profile dispatch for every currently supported key;
- footprint/shadow on/off and invalid polygons;
- texture accent enabled/disabled;
- exact command schema and monotonically increasing `order`;
- repeated identical input stability;
- no commands for unsupported/empty shape when the existing renderer would draw nothing.

## Boundary enforcement

Extend `tools/check_room_visual_renderer_component_boundary.py` to require:

- preload and focused API of `ObjectPrimitiveRenderer`;
- no Node, manager, projection, resource, texture, time, font, Canvas or queue_redraw access in the component;
- `get_iso_object_visual_profiles()` / profile access delegate to the component;
- procedural shape helpers in `RoomVisualRenderer` become thin context/delegation wrappers or are removed;
- no migrated geometry/color/draw policy remains in the final procedural branch of `draw_iso_object_marker()`;
- texture loading/cache/fallback calls remain in `RoomVisualRenderer`;
- door insert and route/cable functions remain owned by their current paths;
- object draw ordering and fog-final ordering remain unchanged;
- the coordinator cap is renamed for this stage and lowered below 6153 to the exact final line count.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_object_primitive_renderer_contract.gd
```

Confirm Renderer Component, Godot Parser, Bipob Module Catalog and Surface Catalog gates are green.

## Stop boundary

Stop after procedural object primitive policy extraction. Do not start texture dispatch cleanup, door Canvas extraction, route cleanup or final coordinator cleanup in the same PR.
