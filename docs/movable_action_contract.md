# Movable Action Contract

All object movement availability and execution is resolved per player action by `MovableActionService`.

## Canonical actor types

Runtime actor types are `scout`, `engineer`, and `heavy`. Historic or display value `Juggernaut` normalizes to `heavy` and is never stored as a canonical requirement value.

Exactly one Bipob participates in an object movement action. Actor strength is not combined.

## Movement requirements

Movable subtypes declare a structured profile:

```gdscript
{
    "required_actor_types": ["engineer", "heavy"],
    "required_manipulator": "heavy_claw",
    "required_manipulator_level": 1,
    "required_power_class": "engineer",
    "movement_mode": "drag"
}
```

Profiles are evaluated together with target relation, facing, destination bounds, passability, occupancy, and surface compatibility. Preview is read-only and execution commits only after the same preview succeeds.

## Crates

Only canonical crates store editable `weight_class`, with values `normal` or `heavy`.

A normal crate requires one Bipob and an available regular manipulator. A heavy crate requires an `engineer` or `heavy` Bipob, an active Heavy Claw, and the required power class.

Heavy Claw is a separate channel. An item held by the regular manipulator does not block Heavy Claw movement. Regular-manipulator movement does require that manipulator to be free.

## Non-crate movables

Barrels, disabled Bipobs, cooling equipment, platform blocks, and other movable subtypes use `movement_requirement`. They do not store `weight_class`.

Legacy fields such as `movable`, `heavy_claw_movable`, `heavy_claw_mode`, and `required_bipob_power_class` are migration inputs only and are stripped from canonical runtime data.

## Runtime flow

`InteractionSystem`, action view models, direct push execution, Heavy Claw drag, and `MissionManager` all use the same resolver and reason codes.

Movement is scoped to the affected object. It does not globally recalculate power or cooling. A failed action does not change object position, actor state, or unrelated systems.

Stable reasons include missing/inactive objects, incompatible actor, missing or occupied manipulator, missing Heavy Claw, insufficient power class, unsupported action, target relation errors, and blocked, occupied, out-of-bounds, or incompatible destinations.
