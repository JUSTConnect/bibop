# BIPOB Architecture

This document describes the target architecture of the BIPOB project.

> RU note: цель архитектуры — сделать так, чтобы каждая новая механика имела понятное место в проекте и не раздувала старые перегруженные файлы.

---

## 1. Architecture Principles

1. Gameplay truth is separate from visual presentation.
2. New mechanics live in dedicated services/controllers/catalogs.
3. Large legacy files should become coordinators, not final homes for new logic.
4. TASK TEST validates systems before they become vertical slice content.
5. Preview and validation should be read-only unless explicitly applying a change.
6. Runtime state, catalog definitions, visual assets and UI state must not be mixed.

---

## 2. Confirmed Technical Decisions

- Godot: project opens in Godot 4.6.
- Final isometric projection standard: `128x71`.
- `128x64` is legacy/classic option only, not the target standard.
- TASK TEST is currently a development sandbox.
- Early legacy missions can be removed after useful mechanics are extracted or rewritten.
- Power Block distributes module ports, not stored energy.
- Battery stores energy.
- Full advanced encounter systems are deferred until base mechanics are stable.

---

## 3. Main Ownership Map

| Area | Current / Target Owner | Notes |
|---|---|---|
| Gameplay grid | `scripts/field/grid_manager.gd` | Source of truth for cells, bounds, walkability and visibility. |
| Visual room rendering | `scripts/field/room_visual_renderer.gd` | Visual-only isometric projection and draw order. |
| Mission runtime | `scripts/game/mission_manager.gd` | Currently overloaded. Should delegate more. |
| Mission definitions | `scripts/game/mission_content_catalog.gd` | TASK TEST is catalogued; old missions are mostly legacy metadata. |
| World object definitions | `scripts/world/world_object_catalog.gd` | Canonical object definitions and legacy aliases. |
| Robot runtime | `scripts/bipob/bipob_controller.gd` | Should delegate movement, interaction, inventory and modules. |
| UI shell | `scripts/ui/game_ui.gd` | Currently overloaded. Should delegate to UI controllers. |
| Power graph | `scripts/world/power_system.gd` | Scoped power graph calculation. |
| Map Constructor | `scripts/game/map_constructor_*`, `scripts/ui/map_constructor/*` | Should continue moving out of MissionManager/GameUI. |

---

## 4. Target Folder Ownership

```text
scripts/
  bipob/              Robot state, movement, modules, inventory bridge
  field/              Grid and room-level visual rendering
  game/               Mission runtime services and gameplay orchestration
  game/map_constructor/  Future home for constructor-specific services
  game/platform/      Platform-specific logic
  game/object/        Object-facing, grounding and object helpers
  ui/                 UI shell and runtime screens
  ui/runtime/         Runtime HUD and mission UI components
  ui/map_constructor/ Map Constructor UI
  world/              Catalogs and world systems
  visual/             Shared visual catalogs and asset resolution
```

New features should prefer a dedicated file in the right domain.

---

## 5. Overloaded Files and Reduction Plan

### MissionManager

Current issue: owns too much mission runtime, constructor state, inventory state, visual mappings and IO.

Reduction targets:

```text
scripts/game/map_constructor_preset_service.gd
scripts/game/map_constructor_wall_service.gd
scripts/game/map_constructor_floor_service.gd
scripts/game/mission_inventory_runtime_service.gd
scripts/visual/visual_asset_catalog.gd
scripts/game/mission_ids.gd
```

### GameUI

Current issue: runtime HUD, Box screen, Map Constructor, overlays and many panels are in one file.

Reduction targets:

```text
scripts/ui/runtime/runtime_hud_controller.gd
scripts/ui/box/box_screen_controller.gd
scripts/ui/runtime/runtime_action_panel_controller.gd
scripts/ui/runtime/runtime_object_hud_controller.gd
scripts/ui/map_constructor/map_constructor_overlay_controller.gd
```

### BipobController

Current issue: robot state plus many world/mission bridges.

Reduction targets:

```text
scripts/bipob/bipob_module_port_controller.gd
scripts/bipob/bipob_damage_controller.gd
scripts/bipob/bipob_sensor_controller.gd
scripts/bipob/bipob_status_effect_controller.gd
```

### RoomVisualRenderer

`RoomVisualRenderer` is the scene-facing isometric coordinator and Canvas executor. Deterministic floor, wall, object, door, route/cable, overlay, fog, alignment and resource-runtime responsibilities live under `scripts/visual/renderer/`. Canonical asset IDs and paths live in `scripts/visual/visual_asset_catalog.gd`.

The coordinator retains serialized scene configuration, live runtime context assembly, draw-entry composition/sorting, Canvas execution, invalidation and externally required UI/controller delegates. New deterministic visual policy must not be added to the coordinator.

The complete ownership map and permanent boundaries are documented in:

```text
docs/room_visual_renderer_component_map.md
```

---

## 6. Gameplay / Visual Separation

Gameplay grid:

```text
Vector2i cell
GridManager.map_data
walkability
visibility
runtime cell state
```

Visual projection:

```text
screen_x = (x - y) * tile_width / 2
screen_y = (x + y) * tile_height / 2
```

For final `128x71`:

```text
tile_width = 128
tile_height = 71
```

Visual wall mass, wall mount zones, floor joins and object pivots must not become gameplay rules.

---

## 7. Mission Architecture

Target direction:

- Mission definitions live in `MissionContentCatalog` or future mission resources.
- TASK TEST remains the sandbox.
- Vertical slice missions should be catalog-driven.
- Old missions can be removed after their mechanics are no longer needed as references.

A mission should define:

```text
id
title
role
layout
start_cell
exit_cells
world_objects
objective_text
required_mechanics
validation_suites
smoke_checklist
```

---

## 8. Module Architecture

Module system target:

- Bipob has internal and external modules.
- Modules consume space and ports.
- Power Block distributes module ports.
- Battery stores energy.
- Processor and Connector requirements control advanced actions.
- Modules can be installed but inactive.
- Inactive modules must explain why they are inactive.

Planned core files:

```text
scripts/bipob/bipob_module_port_controller.gd
scripts/bipob/bipob_module_port_types.gd
scripts/bipob/bipob_module_activation_service.gd
scripts/bipob/bipob_module_diagnostics.gd
```

---

## 9. Advanced Mechanics Architecture

Advanced systems should not be implemented directly inside existing overloaded files.

Planned domains:

```text
scripts/game/encounter/
scripts/game/status_effects/
scripts/game/damage/
scripts/game/sensors/
scripts/game/connectivity/
scripts/game/repair/
scripts/game/lighting/
scripts/game/npc/
scripts/game/automated_objects/
```

Each domain should have:

```text
*_types.gd
*_service.gd
*_runtime.gd
*_validation.gd
```

---

## 10. Data / Runtime / UI Separation

Do not mix these layers:

- catalog data;
- runtime state;
- visual state;
- UI state;
- validation reports.

Preferred pattern:

```text
Catalog creates normalized object definitions.
Runtime service mutates runtime state.
Visual service reads runtime state and emits draw data.
UI reads view models and emits commands.
Controller coordinates commands.
```

---

## 11. Milestone Update Rule

After a milestone is completed, update `docs/ROADMAP.md` manually.

Do not require Codex to update roadmap percentages unless explicitly requested.
