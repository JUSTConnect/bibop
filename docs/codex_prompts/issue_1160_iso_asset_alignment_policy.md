# Codex prompt — extract renderer asset alignment policy

Implement GitHub issue #1160 from the latest `main` after merged PR #1159.

## Goal

Extract deterministic isometric asset alignment, expected-size and authored utility-layout policy from `RoomVisualRenderer` into focused stateless visual owners, while preserving all current visual values, serialized exports, public compatibility APIs, resource-loading ownership and rendered behavior.

This is roadmap stage 2 from #1144. Stop before texture/resource runtime extraction.

## Required audit before editing

Inspect current `main` and map every reference to the following symbols in `scripts/field/room_visual_renderer.gd`:

- `ISO_ASSET_ALIGNMENT_RULES`;
- `ISO_OBJECT_CANONICAL_VISUAL_IDS`;
- `OUTER_UTILITY_WIDTH_SCALE`;
- `OUTER_UTILITY_HEIGHT_SCALE`;
- `OUTER_UTILITY_VERTICAL_OFFSET_SCALE`;
- `ISO_COOLING_WALL_CANVAS_FACE_REGIONS`;
- all expected-size, anchor, scale, offset and wall-mounted alignment helpers;
- all authored cooling/outer-utility layout helpers;
- all coordinator aliases to `FloorRenderer` and `WallRenderer` constants;
- `show_asset_alignment_overlay` and alignment diagnostics;
- all functions that read `ISO_ASSET_ALIGNMENT_RULES` or derive placement from its fields.

Also inspect:

- `scripts/visual/visual_asset_catalog.gd`;
- `scripts/visual/visual_asset_render_contract_service.gd`;
- `scripts/visual/renderer/floor_renderer.gd`;
- `scripts/visual/renderer/wall_renderer.gd`;
- `scripts/visual/renderer/object_renderer.gd`;
- `tools/check_room_visual_renderer_component_boundary.py`;
- `.github/workflows/renderer-component-gate.yml`.

Before moving code, classify every reference as one of:

1. public/serialized compatibility API;
2. coordinator runtime/resource/Canvas execution;
3. deterministic alignment/catalog policy.

Do not move categories 1 or 2 blindly. Keep thin aliases/delegates where compatibility requires them.

## Architecture target

Create:

`res://scripts/visual/renderer/iso_asset_alignment_policy.gd`

The component must be stateless:

```gdscript
extends RefCounted
class_name IsoAssetAlignmentPolicy
```

It may own immutable visual metadata and pure normalization/layout calculations only.

It must not access:

- Node, Node2D or scene tree;
- GridManager or MissionManager;
- ResourceLoader, `load()`, FileAccess or ResourceSaver;
- Texture2D or texture caches;
- Canvas methods such as `draw_*`;
- time, fonts or theme services;
- gameplay/domain mutation.

Return duplicated dictionaries/arrays from public getters so callers cannot mutate shared constants.

## Exact metadata to preserve

Move the complete current `ISO_ASSET_ALIGNMENT_RULES` dataset without changing any value, key or note.

Representative values that must remain exact include:

### Floor

`floor_default`:

```text
anchor = center
scale = 1.0
offset = Vector2.ZERO
expected_size = IsoProjectionService.STANDARD_TILE_SIZE
layer_hint = floor
```

The other existing floor and ground rules must remain byte-for-byte equivalent in their effective values.

### Wall

`wall_default`:

```text
anchor = wall_cell_base
scale = 1.0
offset = Vector2(0, -32)
expected_size = Vector2(128, 120)
layer_hint = wall
```

Preserve all wall material/damaged variants exactly.

### Wall-mounted object

`object_terminal`:

```text
anchor = wall_mount_center
scale = 0.8
offset = Vector2(0, -18)
expected_size = Vector2(96, 96)
layer_hint = object
```

Preserve equivalent socket/button/switch wall-mounted rules.

### Floor object

`object_key`:

```text
anchor = bottom_center
scale = 0.55
offset = Vector2(0, -6)
expected_size = Vector2(96, 96)
layer_hint = object
```

Preserve component/cable/generic/fuse/repair-kit/keycard/access-code/cable-reel rules exactly.

### Authored cooling/outer utility layout

Preserve exactly:

```text
OUTER_UTILITY_WIDTH_SCALE = 5.0
OUTER_UTILITY_HEIGHT_SCALE = 2.0
OUTER_UTILITY_VERTICAL_OFFSET_SCALE = 2.0
```

Preserve face regions:

```text
sw = Rect2(0.0, 0.0, 0.5, 1.0)
se = Rect2(0.5, 0.0, 0.5, 1.0)
```

Move any pure formulas that derive authored utility destination/source rectangles into the policy only after recording and contract-testing the exact current behavior.

## Recommended focused API

Equivalent focused names are acceptable, but keep the surface small and typed where practical:

```gdscript
const ALIGNMENT_RULES: Dictionary
const OUTER_UTILITY_WIDTH_SCALE: float
const OUTER_UTILITY_HEIGHT_SCALE: float
const OUTER_UTILITY_VERTICAL_OFFSET_SCALE: float
const COOLING_WALL_CANVAS_FACE_REGIONS: Dictionary

static func has_alignment_rule(asset_key: String) -> bool
static func get_alignment_rule(asset_key: String) -> Dictionary
static func get_alignment_rule_ids() -> Array[String]
static func get_expected_size(asset_key: String, fallback: Vector2) -> Vector2
static func get_anchor(asset_key: String, fallback: String = "center") -> String
static func get_scale(asset_key: String, fallback: float = 1.0) -> float
static func get_offset(asset_key: String, fallback: Vector2 = Vector2.ZERO) -> Vector2
static func get_layer_hint(asset_key: String, fallback: String = "object") -> String
static func get_cooling_wall_face_region(side: String) -> Rect2
static func build_outer_utility_layout(context: Dictionary) -> Dictionary
```

Do not add speculative APIs that have no current caller.

Malformed keys/context must return documented fallbacks and must never throw unsafe casts.

## Visual catalog ownership

`VisualAssetCatalog` remains the visual path and visual-ID catalog.

Audit `ISO_OBJECT_CANONICAL_VISUAL_IDS`:

- if it is path/visual-ID catalog metadata, move it to `VisualAssetCatalog`;
- expose a duplicated typed getter if mutation safety is needed;
- do not copy the same list into `IsoAssetAlignmentPolicy`;
- do not add gameplay/domain metadata to `VisualAssetCatalog`.

Do not move texture loading, caches or fallback execution into `VisualAssetCatalog`.

## Floor/Wall compatibility aliases

Audit coordinator constants that are direct aliases to `FloorRenderer` and `WallRenderer`.

For each alias:

- remove it from `RoomVisualRenderer` when it is only used internally and replace internal usage with the real owner;
- keep a thin compatibility alias only when an external caller or serialized/public contract requires it;
- do not copy catalog dictionaries back into a new component;
- do not change floor/wall renderer ownership.

Add static enforcement so removed internal aliases cannot return to the coordinator.

## Coordinator ownership to preserve

`RoomVisualRenderer` must retain:

- all current `@export` fields, especially exported `Texture2D` references and authored canvas source/anchor settings;
- runtime scene dependencies;
- projection/context assembly;
- asset path/texture resolution calls;
- all resource loading and texture cache ownership;
- actual texture drawing and Canvas execution;
- draw-entry composition, ordering and sorting;
- debug overlay execution and logging;
- invalidation and redraw behavior.

`RoomVisualRenderer` should call the new policy and remain a scene-facing executor.

## Explicit exclusions

Do not change:

- any asset path or visual ID except moving it to the correct owner;
- any anchor, scale, offset, expected size, face region or authored layout formula;
- object texture attempt ordering;
- resource loading/cache/fallback behavior;
- optional texture resolution;
- placeholder loading;
- wall/breach overlay texture execution;
- floor/wall/object/door/cable/route/overlay/fog rendering behavior;
- gameplay, collision, placement, missions or scenes;
- `project.godot`;
- final coordinator cleanup;
- roadmap stage 3 texture/resource runtime ownership.

No temporary workflows, worklogs, generated `.uid`/`.import` files or checked-in transformation scripts.

## Permanent contract

Add:

`tools/ci/check_iso_asset_alignment_policy_contract.gd`

The contract must use one final success/failure exit path and must assert exact values, not only key presence.

Cover at minimum:

1. `floor_default` exact anchor/scale/offset/expected size/layer;
2. `wall_default` exact values;
3. `object_key` exact values;
4. `object_terminal` exact wall-mounted values;
5. another wall-mounted rule such as socket/button/switch;
6. both cooling wall face regions;
7. all three outer-utility scales;
8. unknown asset-key fallbacks;
9. duplicate safety: mutating a returned dictionary/array does not mutate the policy constant;
10. canonical visual-ID ownership/getter after the audit;
11. current pure authored utility layout formulas using representative exact inputs.

Print:

```text
IsoAssetAlignmentPolicy contract OK
```

only on success and exit non-zero on any failure.

## Boundary enforcement

Add a focused checker or extend the existing renderer checker to enforce:

- `IsoAssetAlignmentPolicy` is `RefCounted` and stateless;
- forbidden scene/resource/texture/Canvas tokens are absent;
- `RoomVisualRenderer` does not contain the literal `ISO_ASSET_ALIGNMENT_RULES` body;
- authored utility scale/face-region tables are absent from the coordinator;
- retained public compatibility APIs are thin aliases/delegates;
- removed internal floor/wall aliases do not return;
- resource loading/cache/Canvas methods remain in the coordinator/runtime owners;
- the policy contract is present in Renderer Component Gate;
- `RoomVisualRenderer` decreases by at least 80 lines from the current `main` baseline and the permanent exact cap is lowered accordingly.

Do not use a weak checker that only looks for the new preload.

## Validation commands

Run and report:

```text
python tools/check_room_visual_renderer_component_boundary.py
python tools/check_gdscript_safety_patterns.py
python <new focused alignment boundary checker>
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_iso_asset_alignment_policy_contract.gd
```

Keep all permanent gates green:

- Renderer Component Gate;
- Godot Parser Gate;
- Bipob Module Catalog Gate;
- Surface Catalog Gate.

## Acceptance criteria

- deterministic alignment/layout metadata has one explicit owner;
- visual path/ID catalog ownership is explicit and separate from alignment policy;
- all effective metadata values and authored utility formulas are unchanged;
- `RoomVisualRenderer` contains no copied alignment table or authored utility layout table;
- texture/resource/Canvas ownership remains scene-facing;
- public compatibility and serialized exports remain intact;
- exact representative contracts pass;
- final PR contains only expected source/test/workflow changes;
- coordinator line cap is lowered by at least 80 lines.

## Stop boundary

Stop after deterministic asset alignment/catalog ownership extraction. Do not begin texture/resource runtime extraction or final coordinator cleanup in this PR.
