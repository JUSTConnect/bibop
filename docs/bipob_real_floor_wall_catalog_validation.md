# BIPOB VIS-ASSET-REAL-02 — real floor/wall catalog validation

## Purpose

This docs-only validation records a full repository-side check of the production floor/wall asset catalog introduced by VIS-ASSET-REAL-01.

Scope:

- validate the real floor PNG paths used by `RoomVisualRenderer`;
- validate the real wall PNG paths used by `RoomVisualRenderer`;
- confirm the production material/height vocabulary matches the checked-in files;
- do not change rendering, gameplay, TASK TEST, Map Constructor, assets, scenes, or `project.godot`.

## Result

Status: **catalog paths validated**.

All production floor/wall PNG paths referenced by the VIS-ASSET-REAL-01 catalog were checked through GitHub file fetches and resolved to PNG blobs.

Godot parser/runtime smoke was not run in this docs-only validation environment.

## Production floor catalog

Expected runtime directory:

```text
res://assets/visual/isometric/floor/
```

Validated floor assets:

| Material | Catalog key | File | Status |
| --- | --- | --- | --- |
| concrete | `floor_concrete` | `assets/visual/isometric/floor/floor_concrete_01.png` | ok |
| steel | `floor_steel` | `assets/visual/isometric/floor/floor_steel_01.png` | ok |
| titan | `floor_titan` | `assets/visual/isometric/floor/floor_titan_01.png` | ok |

## Production wall catalog

Expected runtime directory:

```text
res://assets/visual/isometric/wall/
```

Production wall height vocabulary:

```text
low
halflow
mid
halfmid
tall
```

### Concrete

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_concrete_low` | `concrete/wall_concrete_low_01.png` | ok |
| halflow | `wall_concrete_halflow` | `concrete/wall_concrete_halflow_01.png` | ok |
| mid | `wall_concrete_mid` | `concrete/wall_concrete_mid_01.png` | ok |
| halfmid | `wall_concrete_halfmid` | `concrete/wall_concrete_halfmid_01.png` | ok |
| tall | `wall_concrete_tall` | `concrete/wall_concrete_tall_01.png` | ok |

### Steel

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_steel_low` | `steel/wall_steel_low_01.png` | ok |
| halflow | `wall_steel_halflow` | `steel/wall_steel_halflow_01.png` | ok |
| mid | `wall_steel_mid` | `steel/wall_steel_mid_01.png` | ok |
| halfmid | `wall_steel_halfmid` | `steel/wall_steel_halfmid_01.png` | ok |
| tall | `wall_steel_tall` | `steel/wall_steel_tall_01.png` | ok |

### Titan

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_titan_low` | `titan/wall_titan_low_01.png` | ok |
| halflow | `wall_titan_halflow` | `titan/wall_titan_halflow_01.png` | ok |
| mid | `wall_titan_mid` | `titan/wall_titan_mid_01.png` | ok |
| halfmid | `wall_titan_halfmid` | `titan/wall_titan_halfmid_01.png` | ok |
| tall | `wall_titan_tall` | `titan/wall_titan_tall_01.png` | ok |

### Reinforced steel

Runtime folder spelling is intentionally:

```text
reinforce_steel/
```

Runtime filename stem spelling is intentionally:

```text
wall_reinforcesteel_*
```

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_reinforced_steel_low` | `reinforce_steel/wall_reinforcesteel_low_01.png` | ok |
| halflow | `wall_reinforced_steel_halflow` | `reinforce_steel/wall_reinforcesteel_halflow_01.png` | ok |
| mid | `wall_reinforced_steel_mid` | `reinforce_steel/wall_reinforcesteel_mid_01.png` | ok |
| halfmid | `wall_reinforced_steel_halfmid` | `reinforce_steel/wall_reinforcesteel_halfmid_01.png` | ok |
| tall | `wall_reinforced_steel_tall` | `reinforce_steel/wall_reinforcesteel_tall_01.png` | ok |

### Brick

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_brick_low` | `brick/wall_brick_low_01.png` | ok |
| halflow | `wall_brick_halflow` | `brick/wall_brick_halflow_01.png` | ok |
| mid | `wall_brick_mid` | `brick/wall_brick_mid_01.png` | ok |
| halfmid | `wall_brick_halfmid` | `brick/wall_brick_halfmid_01.png` | ok |
| tall | `wall_brick_tall` | `brick/wall_brick_tall_01.png` | ok |

### Outer wall

Outer wall keeps the production depth-gradient resolver:

```text
tall -> halfmid -> mid -> halflow -> low
```

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| low | `wall_outer_low` | `outerwall/wall_outerwall_low_01.png` | ok |
| halflow | `wall_outer_halflow` | `outerwall/wall_outerwall_halflow_01.png` | ok |
| mid | `wall_outer_mid` | `outerwall/wall_outerwall_mid_01.png` | ok |
| halfmid | `wall_outer_halfmid` | `outerwall/wall_outerwall_halfmid_01.png` | ok |
| tall | `wall_outer_tall` | `outerwall/wall_outerwall_tall_01.png` | ok |

### Grate

Grate intentionally supports only:

```text
mid
halfmid
tall
```

Lower requests should normalize to `mid` in renderer logic.

| Height | Catalog key | File | Status |
| --- | --- | --- | --- |
| mid | `wall_grate_mid` | `grate/wall_grate_mid_01.png` | ok |
| halfmid | `wall_grate_halfmid` | `grate/wall_grate_halfmid_01.png` | ok |
| tall | `wall_grate_tall` | `grate/wall_grate_tall_01.png` | ok |

## Validation notes

- The checked files resolve as PNG blobs through GitHub contents fetch.
- The production wall catalog uses nested material folders, not the old flat `wall_01_*` naming.
- The reinforced steel spelling mismatch is intentional in the current asset folder/file names and must stay mirrored by catalog mapping unless files are renamed in a future PR.
- Gray room visual test PNGs remain a debug/fallback baseline, not the production default.

## Remaining required local smoke

This validation proves path existence, not visual correctness in Godot.

Still required locally:

```bash
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Manual visual smoke:

1. Start TASK TEST.
2. Confirm floor materials render: concrete, steel, titan.
3. Confirm wall materials render: concrete, steel, titan, reinforced steel, grate, brick, outer wall.
4. Confirm heights render: low, halflow, mid, halfmid, tall.
5. Confirm grate lower-height requests normalize to mid.
6. Confirm outer wall gradient still goes from taller top/perimeter to lower bottom/perimeter.
7. Open Map Constructor.
8. Place/edit/delete floors and walls.
9. Confirm Map Constructor preview matches runtime placement.
10. Confirm no missing resource warnings for floor/wall production assets.

## Recommendation

Next technical step should be a small runtime/debug report PR, not another asset remap:

```text
VIS-ASSET-REAL-03 — Add in-game real floor/wall catalog debug report + missing-path warnings
```

Goal:

- expose the production floor/wall catalog validation through existing `IsoVisualDebugReport` / debug text;
- report missing floor/wall texture paths in-game if a file is renamed later;
- keep validation read-only;
- do not change placement/rendering logic.
