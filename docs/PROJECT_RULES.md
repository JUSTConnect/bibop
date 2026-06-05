# BIPOB Project Rules

This file defines mandatory rules for all development work in the BIPOB project.

> RU note: этот файл нужен как общий контракт проекта. Любой человек, Codex или другая LLM-модель должна сначала сверяться с этими правилами.

---

## 1. Project Status

BIPOB is currently a prototype.

Current confirmed decisions:

- Godot: project opens in Godot 4.6.
- Final isometric floor diamond standard: `128x71`.
- Early legacy missions may be removed after their useful mechanics are moved into reusable systems or rewritten.
- TASK TEST is currently a development sandbox.
- TASK TEST may later be used to build 2–3 vertical slice tutorial missions.
- Challenge/combat-style systems are planned, but full implementation starts only after base mechanics are stable.
- Power Block is a module port distribution concept, not a battery and not a full electrical load simulation.

---

## 2. Most Important Rule

Do not keep growing overloaded files.

New mechanics, logic and systems should be implemented in dedicated files whenever possible.

Avoid adding new large systems directly into:

- `scripts/game/mission_manager.gd`
- `scripts/ui/game_ui.gd`
- `scripts/bipob/bipob_controller.gd`
- `scripts/field/room_visual_renderer.gd`
- `scripts/field/grid_manager.gd`

These files may coordinate, delegate or expose compatibility wrappers, but they should not become the final home for new mechanics.

---

## 3. Ownership Rules

### GridManager

`GridManager` owns gameplay grid truth:

- map cells;
- tile ids;
- bounds;
- walkability;
- visibility/fog state;
- gameplay cell coordinates.

It must not become a visual asset manager or mission scripting system.

### RoomVisualRenderer

`RoomVisualRenderer` owns visual projection and draw order.

It must not own gameplay rules.

Visual changes must not change pathfinding, passability, mission state, inventory state or runtime interaction logic.

### MissionManager

`MissionManager` is currently overloaded and should be reduced over time.

It may coordinate mission runtime, but new systems should be extracted into services:

- inventory runtime service;
- map constructor services;
- validation services;
- power/cooling/cable services;
- platform services;
- future challenge/runtime services.

### GameUI

`GameUI` should become a UI shell/coordinator.

New UI areas should live in dedicated controllers/screens, for example:

- runtime HUD;
- Box screen;
- Map Constructor screen;
- action panel;
- inventory/storage panel;
- object HUD.

### BipobController

`BipobController` should represent Bipob runtime state and delegate specialized logic.

New systems should not be embedded directly into it unless the change is very small and temporary.

---

## 4. TASK TEST Rules

TASK TEST is the main sandbox for validating mechanics.

Allowed in TASK TEST:

- experimental mechanics;
- debug validation;
- Map Constructor tools;
- temporary diagnostic UI;
- sandbox-only objects;
- vertical slice preparation.

Forbidden unless explicitly requested:

- mutating normal campaign mission resources;
- writing normal mission content from validation tools;
- making TASK TEST-only assumptions leak into normal runtime;
- using validation that permanently changes active mission state.

Validation must be read-only or snapshot/restore.

---

## 5. Documentation Rules

Codex and implementation agents should not perform documentation work unless explicitly requested.

Documentation and audit updates should be handled by the project owner or ChatGPT planning/audit pass.

After a milestone is completed, update `docs/ROADMAP.md` manually:

- completion percentage;
- completed milestone notes;
- next milestone;
- known blockers.

Codex tasks should focus on code implementation and smoke checklist results.

---

## 6. File Growth Rule

If a change adds more than about 150 lines to an already large file, stop and consider extracting a new service.

Preferred pattern:

```text
scripts/<domain>/<feature>_service.gd
scripts/<domain>/<feature>_types.gd
scripts/<domain>/<feature>_validation.gd
scripts/<domain>/<feature>_runtime.gd
```

Large existing files may keep compatibility wrappers, but the new logic should live elsewhere.

---

## 7. Visual Rules

- Final projection target is `128x71`.
- Visual assets must align to the final projection.
- Visual PRs must not change gameplay passability.
- Wall/floor geometry is visual representation, not gameplay truth.
- Wall-mounted objects use wall mount zones but interact through adjacent gameplay cells.
- Door visuals should remain renderer-controlled and should not bake gameplay state into art.

---

## 8. Power / Cooling / Cable Rules

- Power recalculation must happen after explicit power events.
- Do not globally recalculate power on every frame, movement or action.
- Cooling application must be scoped.
- Cable cut/repair/reconnect are separate actions.
- Repair does not automatically reconnect a cut cable.
- Preview functions must not mutate runtime state.

---

## 9. Module Rules

Power Block is a port distribution concept.

It should manage port availability and module activation rules, not simulate full electrical load/capacity/overload.

Battery stores energy.

Power Block distributes module connections and creates configuration pressure.

The goal is module management:

- limited space;
- limited ports;
- mission-specific configuration;
- active/inactive module state;
- clear inactive reasons.

---

## 10. Future Challenge Systems

Future advanced encounter systems should be implemented only after base mechanics are stable.

Before adding them, create dedicated files for:

- challenge runtime;
- targeting;
- damage and recovery calculation;
- status effects;
- NPC or automated object behavior;
- equipment behavior.

Do not place these systems directly inside `MissionManager`, `BipobController` or `GameUI`.

---

## 11. PR / Task Checklist

Every implementation task should define:

```text
[ ] Goal
[ ] Scope
[ ] Target files
[ ] Files that must not be touched
[ ] Acceptance criteria
[ ] Manual smoke checklist
[ ] Risk notes
```

Review checklist:

```text
[ ] Scope matches the task
[ ] No unrelated mission content changes
[ ] No unnecessary project.godot changes
[ ] No validation resource writes
[ ] No gameplay mutation in visual-only work
[ ] New mechanics are extracted into dedicated files where possible
[ ] TASK TEST remains safe
[ ] README/docs updated only if explicitly requested
```
