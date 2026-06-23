# Codex prompt — issue #1154 object texture dispatch policy

Implement issue #1154 from the latest `main` after merged PR #1153.

Use branch:

`codex/bip-architecture-coordinators-02f5b-object-texture-dispatch`

PR title:

`BIP-Architecture-Coordinators-02F5B: Extract object texture dispatch and render-contract plan`

PR body must include `Closes #1154`.

Read the issue body first and preserve every ownership boundary.

## Required audit before editing

Inspect these exact paths and functions:

- `scripts/field/room_visual_renderer.gd`
  - `draw_iso_object_marker()`;
  - `draw_iso_object_png_texture_asset()`;
  - `draw_optional_visual_texture_asset()`;
  - `draw_iso_texture_asset()`;
  - `build_iso_object_visual_descriptor_for_contract()`;
  - `build_iso_object_visual_descriptor()`;
  - `build_authored_wall_canvas_descriptor()`;
  - `build_authored_floor_canvas_descriptor()`;
  - `draw_iso_object_png_texture_with_descriptor()`;
  - `draw_visual_state_overlays_for_descriptor()`.
- `scripts/visual/renderer/object_renderer.gd` descriptor APIs.
- `scripts/visual/renderer/object_primitive_renderer.gd` so primitive fallback ownership is not duplicated.
- `tools/check_room_visual_renderer_component_boundary.py`.
- `.github/workflows/renderer-component-gate.yml`.

## Architecture target

Create:

`scripts/visual/renderer/object_texture_dispatch_policy.gd`

It must be a stateless `RefCounted` policy component. It receives already normalized booleans and asset IDs and returns deterministic plans only.

Recommended API:

```gdscript
static func build_attempt_plan(context: Dictionary) -> Array[Dictionary]
static func get_descriptor_route(render_contract: String, wall_contract: String, floor_contract: String) -> String
static func should_draw_success_accent(context: Dictionary) -> bool
```

Equivalent focused names are acceptable.

Each texture attempt must have stable explicit fields:

```text
order
kind            # png | optional | legacy
asset_id
source          # case | primary | door_state | terminal_state
stop_on_success
```

The policy must not call drawing methods or inspect resources.

## Exact current texture semantics to preserve

### Loot case

- one primary `png` attempt;
- use the already resolved visual-state asset ID supplied in context;
- stop on success;
- suppress texture-success accent.

### Primary PNG object

- one primary `png` attempt;
- do not add optional or legacy attempts for the same primary key;
- door and terminal state fallbacks may still follow.

### Primary non-PNG object

- primary `optional` attempt first;
- primary `legacy` attempt second;
- preserve identical asset ID for both;
- door and terminal state fallbacks follow.

### Cable

- when `profile_key == "cable"`, do not build the normal primary texture attempts;
- do not alter the existing procedural cable branch.

### State fallbacks

- door state optional attempt follows the primary chain;
- terminal state optional attempt follows door fallback;
- preserve attempts even when supplied fallback ID is empty, unless exact current behavior is demonstrably unchanged by filtering it;
- first successful attempt stops execution;
- if every attempt fails, procedural fallback continues.

### Success accent

- successful non-case texture keeps current `ObjectPrimitiveRenderer.build_texture_accent_commands()` path;
- successful case texture returns without accent.

The direct door-floor-object texture branch at the start of `draw_iso_object_marker()` is not part of this plan and must remain unchanged.

## Coordinator execution

Add a thin coordinator helper, for example:

```gdscript
func _execute_object_texture_attempt_plan(
    attempts: Array[Dictionary],
    cell: Vector2i,
    visual_center: Vector2,
    object_data: Dictionary
) -> bool
```

It may dispatch only to the existing coordinator-owned methods:

- `draw_iso_object_png_texture_asset()`;
- `draw_optional_visual_texture_asset()`;
- `draw_iso_texture_asset()`.

It must stop at the first success and return whether any attempt succeeded.

Do not move actual texture drawing or loading into the policy.

## Render-contract routing

Move only deterministic route selection into the policy:

- wall authored contract → `wall_authored`;
- floor authored contract → `floor_authored`;
- object sprite or unknown contract → `object`.

`build_iso_object_visual_descriptor_for_contract()` must become a thin wrapper that asks the policy for the route, then calls the existing descriptor builders.

Do not duplicate descriptor math already owned by `ObjectRenderer`.

## Coordinator must retain

- MissionManager/GridManager lookup;
- door and terminal visual-state lookup;
- `VisualStateAssetService` calls;
- `VisualAssetRenderContractService` constants and path classification;
- `is_iso_object_png_asset_key()`;
- path resolution and texture caches;
- `load()`, `Texture2D`, atlas handling;
- missing-asset debug fallback and warnings;
- actual Canvas texture drawing and transforms;
- alignment overlays and logging;
- visual-state overlay textures, glow animation and `Time`;
- descriptor context values from tile size, facing, alignment and surface state;
- draw-entry sorting and invalidation.

## Explicit exclusions

Do not modify or extract:

- `draw_iso_door_insert()`;
- door geometry, threshold, frame, badges or damage overlays;
- route/cable/duct/pipe rendering;
- `ObjectPrimitiveRenderer` geometry/style policy;
- texture caches or resource loading architecture;
- authored wall/floor descriptor geometry constants;
- visual-state overlay animation;
- floor/wall rendering;
- gameplay, collision, placement, mission, scenes or `project.godot`;
- final coordinator cleanup.

## Contract

Add:

`tools/ci/check_object_texture_dispatch_policy_contract.gd`

Wire a dedicated permanent step into Renderer Component Gate.

Test exact plans for:

1. loot case;
2. PNG primary;
3. non-PNG optional → legacy;
4. cable empty primary plan;
5. door fallback only;
6. terminal fallback only;
7. both state fallbacks after primary attempts;
8. empty asset IDs;
9. malformed/partial context;
10. repeated identical input stability.

For every attempt verify exact:

- `order`;
- `kind`;
- `asset_id`;
- `source`;
- `stop_on_success`.

Also test:

- accent enabled for successful non-case;
- accent disabled for successful case;
- exact descriptor routes for object, wall-authored, floor-authored and unknown contracts;
- first-success execution semantics through a deterministic plan-consumption simulation that does not use resources or Canvas.

The contract must accumulate failures and exit once at the end.

## Boundary checker

Extend `tools/check_room_visual_renderer_component_boundary.py` to require:

- preload and focused API of `ObjectTextureDispatchPolicy`;
- no Node, manager, projection, texture, resource, load, time, font, Canvas or invalidation dependencies in the policy;
- `draw_iso_object_marker()` calls `build_attempt_plan()` and a thin coordinator executor;
- the previous hard-coded `is_case_visual` / PNG / optional / legacy / door fallback / terminal fallback chain is removed from the marker body;
- the direct door-floor-object branch remains before the normal policy plan;
- texture-success accent remains after successful plan execution and is controlled by policy;
- procedural wall-mounted and generic primitive fallback remain after failed texture execution;
- `draw_iso_object_png_texture_asset()` retains path resolution, texture lookup, missing fallback, descriptor execution and visual-state overlays;
- the three actual draw methods remain absent from the policy and present in the coordinator;
- `build_iso_object_visual_descriptor_for_contract()` delegates route selection to policy;
- descriptor builders remain in `RoomVisualRenderer`/`ObjectRenderer` as currently owned;
- cable/route and door functions remain unchanged;
- the cap is renamed for this stage and lowered below 5854 to exact final line count.

## Validation

Run:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_object_texture_dispatch_policy_contract.gd
```

Confirm all four permanent gates are green:

- Renderer Component Gate;
- Godot Parser Gate;
- Bipob Module Catalog Gate;
- Surface Catalog Gate.

## Stop boundary

Stop after texture-attempt planning and render-contract route extraction. Do not begin door Canvas extraction or final coordinator cleanup in this PR.
