# BIPOB VIS-GROUND-01 — raised floor ground visuals

## Purpose

Raised floor height is now a visual-only property for TASK TEST / Map Constructor floor cells. It is independent from the floor material covering, so a raised cell still draws one of the normal top materials:

- `concrete`
- `steel`
- `titan`

## Height vocabulary

The canonical floor height field is `floor_height`.

Supported values are:

- `default` — normal flat floor, no raised ground base.
- `step_1` — draw `res://assets/visual/isometric/ground/ground_low_01.png` below the floor covering.
- `step_2` — draw `res://assets/visual/isometric/ground/ground_halflow_01.png` below the floor covering.

Accepted aliases normalize into the same values:

- `empty`, `default`, `flat`, `normal` → `default`
- `1`, `step1`, `step_1`, `low`, `ground_low` → `step_1`
- `2`, `step2`, `step_2`, `halflow`, `ground_halflow` → `step_2`

## Render layering

For floor-like cells, the isometric renderer keeps the existing floor material path and adds an optional ground base layer first:

1. Existing room/floor background or procedural fallback when needed.
2. Raised ground asset when `floor_height` is `step_1` or `step_2`.
3. Top floor material asset / covering (`concrete`, `steel`, or `titan`).
4. Existing objects, walls, fog, and overlays.

The first pass anchors the ground asset to the same cell base / 128x71 footprint contract used by the production wall-height assets. The floor material tile remains centered on the normal floor cell footprint so material coverage is preserved on top of the raised visual base.

## Map Constructor behavior

The Floor Coverage inspector now exposes a **Height** dropdown with:

- Default
- 1 Step
- 2 Step

Applying floor coverage stores both:

- `material_id`
- `floor_height`

Clearing floor coverage removes the override and returns the cell to the default flat visual behavior.

## Current limitation

Raised floors are visual metadata only in this PR. They do not change gameplay movement, pathfinding, collision, passability, action costs, combat, object placement rules, or wall behavior.

Future work may add stairs, platform transfers, movement constraints, or other gameplay rules between floor heights.
