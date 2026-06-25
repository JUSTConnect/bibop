# RoomVisualRenderer component map

## Final coordinator baseline

The decomposition started from a 7,811-line `scripts/field/room_visual_renderer.gd` that mixed scene coordination, visual catalogs, deterministic geometry/style policy, resource loading, caches, debug reports and Canvas execution.

After the controlled extraction sequence through issues #1141–#1162, the final coordinator is capped at **4,288 lines**. The remaining size is dominated by scene-facing context assembly and Canvas execution that depends on live `GridManager`, mission runtime and serialized scene configuration.

## Dependency direction

```text
RoomVisualRenderer
    -> focused renderer components
    -> visual/domain services
    -> read-only GridManager / mission runtime inputs
```

Focused policy components never call `RoomVisualRenderer`, never access the scene tree and never execute Canvas commands. They receive explicit contexts and return draw entries, command arrays or normalized values.

## Focused owners

| Owner | Responsibility |
|---|---|
| `IsoProjectionService` | Projection mode normalization, tile geometry, grid/screen conversion and depth keys. |
| `IsoDrawEntryContract` | Canonical draw-entry schema, sub-order/layer constants, validation and deterministic comparison. |
| `FloorRenderer` | Floor/ground catalogs, classification, material/height normalization, atlas policy and floor draw entries. |
| `WallRenderer` | Wall catalogs, material/height policy, topology, visible sides, mount zones and wall draw entries. |
| `ObjectRenderer` | Object classification, visual profile/asset selection, mount policy, descriptor policy and object draw entries. |
| `ObjectPrimitiveRenderer` | Deterministic procedural object command plans. |
| `ObjectTextureDispatchPolicy` | Texture-attempt ordering, authored descriptor route and success-accent policy. |
| `DoorCanvasRenderer` | Door profile, threshold, frame, body and state-overlay command plans. |
| `RouteRenderer` | Route normalization, wall route geometry and procedural cable/duct/pipe command plans. |
| `CableCanvasRenderer` | Floor cable, hidden/wall cable, endpoint, damage, object-link and bridge command plans. |
| `OverlayRenderer` | Selection and interaction-target overlay command plans. |
| `MapConstructorOverlayRenderer` | Map Constructor preview, validation, links, power and side-arrow command plans. |
| `RuntimeDebugOverlayRenderer` | Origin/helper, wall, join, marker, grounding and diagnostic overlay command plans. |
| `FogRenderer` | Fog color and floor/wall fog command plans. |
| `IsoAssetAlignmentPolicy` | Stateless expected-size, anchor, scale, offset and authored utility-layout policy. |
| `VisualAssetResourceRuntime` | The single scene-facing texture/path/cache/fallback runtime. |
| `VisualAssetCatalog` | Canonical visual IDs and resource paths. |

## Responsibilities retained by RoomVisualRenderer

`RoomVisualRenderer` is the scene-facing coordinator and Canvas executor. It retains only responsibilities that require one or more of the following:

- serialized `@export` configuration and texture overrides;
- binding to the live `GridManager` and mission/runtime services;
- assembling component request contexts from live scene data;
- requesting and composing floor, wall, platform, object and bridge draw entries;
- sorting the unified geometry queue through `IsoDrawEntryContract`;
- dispatching draw entries and executing Canvas/texture commands;
- coordinating selection, constructor, runtime/debug and fog passes;
- explicit cache invalidation and redraw requests;
- externally used compatibility methods for UI/controller integration.

It no longer owns:

- visual path or ID catalogs;
- floor/wall/object/route/door/overlay/fog deterministic policy;
- texture loading or cache dictionaries;
- asset-alignment datasets;
- duplicate overlay, route and object command executors;
- internal debug-report APIs with no runtime consumer;
- coordinator-only aliases to focused component APIs.

## Canonical command execution

All component command arrays are executed by one policy-free coordinator method:

```text
_draw_canvas_commands(commands, fallback_profile)
```

Supported command kinds are:

```text
polygon
polyline
line
circle
rect
arc
text
wall_cable_segment
```

The dispatcher validates primitive input and performs Canvas calls only. Geometry, colors, widths, ordering and fallback decisions remain in focused components.

## Frame order

The representative frame order is permanently guarded:

1. unified floor/ground/platform/cable/object/door/wall/wall-mounted queue;
2. wall diagnostics and editor overlays;
3. cable-reel transient trail;
4. selection and Map Constructor overlays;
5. interaction/world/debug markers;
6. fog as the final visual pass.

`tools/ci/check_room_visual_renderer_smoke_contract.gd` covers representative TASK TEST floor/wall topology, wall-mounted occlusion, door phases, cable/route/bridge ordering, selection/constructor/debug overlays, fog and asset fallback/alignment.

## Architecture enforcement

Permanent checks prevent responsibilities from returning to the coordinator:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_cable_canvas_renderer_boundary.py
python tools/check_iso_asset_alignment_policy_boundary.py
python tools/check_visual_asset_resource_runtime_boundary.py
godot --headless --path . --script res://tools/ci/check_room_visual_renderer_smoke_contract.gd
```

Every future visual feature must extend the focused owner responsible for its deterministic policy. `RoomVisualRenderer` may only receive the resulting command/entry contract and execute it against the live scene.
