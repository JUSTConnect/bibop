# Bipob Breachable Wall Mechanic

`Breachable Wall` / `проламываемая стена` is a dedicated wall archetype, not a generic `damaged`, `broken`, or `destroyed` state.

## Runtime rule

- Code archetype: `wall_archetype = "breachable"`.
- Current breach tool: `heavy_claw`.
- Action label: `Heavy Claw Break`.
- Canonical internal action id: `break_breachable_wall`.
- Legacy/parser alias: `breach` normalizes to `break_breachable_wall` before validation or execution.
- A Breachable Wall blocks movement and vision while present.
- When Bipob faces an adjacent Breachable Wall from the selected breach side and has Heavy Claw capability, `Heavy Claw Break` removes the wall tile and converts that cell to floor, clearing a passage visually and in gameplay.

## Allowed constructor materials

- `breachable_concrete` — displayed as **Breachable Concrete**.
- `breachable_brick` — displayed as **Breachable Brick**.

## Allowed heights

Breachable Wall supports only:

- `mid`
- `halfmid`
- `tall`

`low` and `halflow` normalize to `mid` for Breachable Wall overrides.

## Breach side mapping

Breach side ids are visual isometric sides, not damaged states:

- `sw` maps to the gameplay `south` adjacent cell.
- `se` maps to the gameplay `east` adjacent cell.
- `nw` maps to the gameplay `west` adjacent cell.
- `ne` maps to the gameplay `north` adjacent cell.

This follows the project grid projection where grid `+x` appears visually southeast and grid `+y` appears visually southwest. Heavy Claw Break is enabled only when Bipob is in the mapped adjacent cell, and execution re-checks the same gate before clearing the wall.

## Non-goals

- This does not add generic damaged/broken wall assets.
- This does not add sledgehammer breach support.
- This does not make every damaged wall breachable.
