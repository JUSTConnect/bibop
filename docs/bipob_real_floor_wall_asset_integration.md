# BIPOB VIS-ASSET-REAL-01 — real floor/wall PNG integration

## Runtime source of truth

`RoomVisualRenderer` now uses production PNG assets as the default floor/wall render path.
The gray room visual test PNGs remain checked in and can still be enabled with
`use_gray_room_visual_test_assets`, but that export is now a debug/fallback mode rather than
the normal runtime source.

## Floor assets

Production floor assets are loaded from `res://assets/visual/isometric/floor/` with explicit
catalog keys:

- `floor_concrete` → `floor_concrete_01.png`
- `floor_steel` → `floor_steel_01.png`
- `floor_titan` → `floor_titan_01.png`

The renderer keeps the existing 128x71 normalized footprint placement contract for all floor
materials.

## Wall assets

Production wall assets are loaded from `res://assets/visual/isometric/wall/` with explicit
material + height catalog keys. Supported production heights are:

- `low`
- `halflow`
- `mid`
- `halfmid`
- `tall`

Supported wall materials are:

- `concrete`
- `steel`
- `titan`
- `reinforced_steel`
- `grate`
- `brick`
- `outerwall` / `outer_wall`

`grate` intentionally has only `mid`, `halfmid`, and `tall` assets. Requests for lower grate
heights are normalized to `mid` so runtime rendering does not spam missing asset warnings.

## Height resolution

Wall height can be supplied from these fields, in priority order already available to the
renderer:

- `material.wall_height`
- `material.wall_visual_height`
- `override.wall_height`
- `override.wall_visual_height`
- `wall_data.wall_height`
- `wall_data.wall_visual_height`

Accepted aliases include `low`, `half_low`/`half-low`/`halflow`, `mid`/`medium`,
`half_mid`/`half-mid`/`uppermid`, and `tall`/`high`/`tallest`.

## Outer wall gradient

Outer walls keep the previous depth-based behavior, but the production resolver maps the
gradient to the new five-level vocabulary:

`top/depth start → tall → halfmid → mid → halflow → low → bottom/depth end`

This keeps perimeter walls visually tall near the top of the map and progressively lower
toward the lower/deeper border.

## Raised ground floor visuals

Raised floor visuals are documented separately in `docs/bipob_raised_floor_ground_visuals.md`.
Floor height is visual-only metadata: `default`, `step_1`, and `step_2` select whether a raised ground base is drawn beneath the existing concrete/steel/titan top floor material. Movement, pathfinding, collision, and stair/platform transfer gameplay are intentionally unchanged.
