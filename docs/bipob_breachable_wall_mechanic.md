# Bipob Breachable Wall Mechanic

`Breachable Wall` / `проламываемая стена` is a dedicated wall archetype, not a generic `damaged`, `broken`, or `destroyed` state.

## Runtime rule

- Code archetype: `wall_archetype = "breachable"`.
- Current breach tool: `heavy_claw`.
- Action label: `Break`.
- Internal action id: `break_breachable_wall`.
- A Breachable Wall blocks movement and vision while present.
- When Bipob faces an adjacent Breachable Wall and has Heavy Claw capability, `Break` removes the wall tile and converts that cell to floor, clearing a passage visually and in gameplay.

## Allowed constructor materials

- `breachable_concrete` — displayed as **Breachable Concrete**.
- `breachable_brick` — displayed as **Breachable Brick**.

## Allowed heights

Breachable Wall supports only:

- `mid`
- `halfmid`
- `tall`

`low` and `halflow` are rejected for breachable wall material overrides.

## Non-goals

- This does not add generic damaged/broken wall assets.
- This does not add sledgehammer breach support.
- This does not make every damaged wall breachable.
