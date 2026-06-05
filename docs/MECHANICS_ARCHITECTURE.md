# BIPOB Mechanics Architecture

This document maps BIPOB mechanics to their intended architecture location.

> RU note: это не список задач для немедленной реализации. Это карта, чтобы будущие механики не складывались в один большой файл.

---

## 1. Mechanics Development Rule

Every new mechanic should have a clear owner before implementation.

Do not add full new mechanics directly into:

- `MissionManager`
- `GameUI`
- `BipobController`
- `RoomVisualRenderer`
- `GridManager`

Use these files as coordinators only when necessary.

---

## 2. Base Mechanics

| Mechanic | Status | Target owner |
|---|---:|---|
| Grid movement | Partial / implemented | `scripts/bipob/bipob_movement_controller.gd`, `GridManager` |
| Turn/action economy | Partial / implemented | `scripts/bipob/bipob_action_controller.gd` |
| Inventory | Partial / implemented | future `scripts/game/mission_inventory_runtime_service.gd` |
| Door access | Partial / implemented | `WorldObjectCatalog`, interaction services |
| Terminal interaction | Partial / implemented | scan/action services + world object runtime |
| Power graph | Partial / implemented | `scripts/world/power_system.gd` |
| Cable/socket/reel | Partial / implemented | cable runtime/topology services |
| Cooling | Partial / implemented | world cooling services / future internal cooling |
| Platforms | Partial / implemented | `scripts/game/platform/*` |
| Scan/diagnostic/X-Ray | Partial / implemented | scan services + future sensor domain |
| TASK TEST | Implemented sandbox | `MissionContentCatalog`, `MissionManager`, constructor services |

---

## 3. Module Management

Module management should prevent the player from installing everything at once.

The player should think about:

- internal space;
- external slots;
- Power Block ports;
- Internal Interface ports;
- External Interface ports;
- Processor requirements;
- Connector requirements;
- heat/cooling;
- mission-specific configuration.

Target files:

```text
scripts/bipob/bipob_module_port_types.gd
scripts/bipob/bipob_module_port_controller.gd
scripts/bipob/bipob_module_activation_service.gd
scripts/bipob/bipob_module_diagnostics.gd
scripts/ui/box/module_port_panel.gd
```

Required functions:

```text
get_installed_module_port_state()
preview_module_port_activity()
recalculate_module_port_activity()
get_module_inactive_reasons(module_id)
```

Power Block distributes module ports.
Battery stores energy.

---

## 4. Sensor Mechanics

Planned sensor systems:

- basic vision;
- radar;
- thermal vision;
- X-Ray;
- diagnostic scan;
- hidden object reveal;
- approximate position reveal;
- scan accuracy / scan range modifiers.

Target domain:

```text
scripts/game/sensors/sensor_types.gd
scripts/game/sensors/sensor_runtime_service.gd
scripts/game/sensors/scan_result_service.gd
scripts/game/sensors/xray_reveal_service.gd
scripts/game/sensors/radar_reveal_service.gd
scripts/game/sensors/thermal_reveal_service.gd
```

Rules:

- Sensor logic should not live inside `GameUI`.
- Sensor visuals should read sensor results, not compute gameplay truth.
- Hidden object reveal should mutate only explicit reveal/discovery state.

---

## 5. Connectivity Mechanics

Planned connectivity systems:

- wired connectors;
- wireless connectors;
- direct device links;
- connector range;
- connector requirements;
- device link diagnostics;
- future connectivity modifiers.

Target domain:

```text
scripts/game/connectivity/connectivity_types.gd
scripts/game/connectivity/connectivity_service.gd
scripts/game/connectivity/wireless_link_service.gd
scripts/game/connectivity/device_link_validation.gd
```

Rules:

- Connectivity should not be mixed with room power graph.
- Connector requirements should connect to module port activity.
- Terminal/device actions should ask connectivity service for availability.

---

## 6. Lighting Mechanics

Planned lighting systems:

- powered lights;
- dark areas;
- visibility modifiers;
- light switches;
- emergency lighting;
- visual light state.

Target domain:

```text
scripts/game/lighting/lighting_types.gd
scripts/game/lighting/lighting_runtime_service.gd
scripts/game/lighting/light_visibility_service.gd
scripts/visual/lighting_visual_service.gd
```

Rules:

- Lighting can affect visibility, but visual light rendering should not be gameplay truth.
- Power state should be read from power/runtime systems.

---

## 7. Runtime State and Recovery

Planned runtime state systems:

- movement modifiers;
- terrain effects;
- overheating;
- disabled states;
- temporary module malfunction states;
- recovery and repair states.

Target domain:

```text
scripts/game/runtime_state/runtime_state_types.gd
scripts/game/runtime_state/runtime_state_service.gd
scripts/game/runtime_state/runtime_state_validation.gd
scripts/game/repair/repair_action_service.gd
```

Rules:

- Runtime states should be data-driven.
- Runtime states should have duration/source/reason fields where relevant.
- UI should display summaries through view models.
- Runtime state logic must not be hardcoded into unrelated movement or UI code.

---

## 8. Mobility / Chassis Mechanics

Planned mobility systems:

- wheels;
- legs;
- tracks;
- hover / air cushion;
- jump-like movement modules;
- terrain compatibility;
- terrain movement modifiers.

Target domain:

```text
scripts/bipob/mobility/mobility_types.gd
scripts/bipob/mobility/mobility_profile_service.gd
scripts/bipob/mobility/terrain_modifier_service.gd
```

Rules:

- Terrain compatibility should be calculated through mobility services.
- GridManager can expose terrain/floor data but should not know all chassis rules.
- Module port activity should affect which mobility modules are active.

---

## 9. Visual Mechanics

Visual systems:

- seamless floor surfaces;
- connected wall runs;
- wall mount zones;
- door openings;
- object grounding;
- asset pivots;
- visual overlays;
- fog/visibility overlay;
- cable visuals;
- platform visual states.

Target domain:

```text
scripts/visual/visual_asset_catalog.gd
scripts/visual/iso_projection.gd
scripts/visual/floor_join_visual_service.gd
scripts/visual/wall_run_visual_service.gd
scripts/visual/object_grounding_visual_service.gd
scripts/visual/cable_visual_service.gd
```

Rules:

- Visual services read gameplay state.
- Visual services do not mutate gameplay state.
- Final projection is `128x71`.

---

## 10. Vertical Slice Mechanics

Before building the first vertical slice, the following should be stable enough:

```text
[ ] movement / action economy
[ ] door access
[ ] terminal action
[ ] power source / power graph
[ ] cable / socket / reel
[ ] scan / diagnostic
[ ] inventory item pickup/use
[ ] basic module configuration
[ ] floor/wall visual stability
[ ] mission start/exit flow
```

The first vertical slice should be built from sandbox-proven systems, not custom one-off mission hacks.
