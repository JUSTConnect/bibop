# Current Project Inventory

Этот документ фиксирует известные данные о текущем проекте BIPOB, чтобы greenfield/refactor архитектура не была абстрактной. Это не целевая архитектура, а карта того, что уже есть, где находятся дубли и какие решения нельзя повторять.

Документ нужно обновлять после каждого крупного изучения проекта.

---

## Project Basics

```text
Repository: JUSTConnect/bibop
Engine: Godot 4.6, GL Compatibility
Main scene uid: uid://diphyupq6cob4
Main scene path: scenes/main.tscn
Game UI script: scripts/ui/game_ui.gd
```

Текущее `project.godot` содержит main scene uid и режимы rendering/input. В autoload сейчас подключены runtime helper layers, что уже является architecture debt и должно быть очищено в refactor-ветках.

Current autoloads known from project:

```text
RuntimeNotifications
RuntimeHudRepair
MapConstructorInspectorStructure
```

Целевое состояние: оставить только настоящие global services, а `RuntimeHudRepair` и `MapConstructorInspectorStructure` удалить после переноса логики в builders.

---

## Main Scene Inventory

`scenes/main.tscn` содержит:

```text
Main Node2D
  └─ UI CanvasLayer with GameUI script
       ├─ MissionLabel
       ├─ StatusLabel
       ├─ HintLabel
       ├─ CommandPanel legacy menu
       └─ BoxScreen
```

Known issue:

`CommandPanel` — legacy control menu. Он содержит кнопки:

```text
Forward
Backward
Turn Left
Turn Right
Action [E]
End Turn [Space]
```

Целевая архитектура: gameplay должен использовать `RuntimeControlsPanel`, а не legacy `CommandPanel`. Legacy node должен быть удалён из scene или переведён в debug-only после переноса HUD.

---

## GameUI Inventory

`GameUI` сейчас является большим UI shell и одновременно содержит много разных responsibilities.

Known preloads:

```text
RuntimeMissionMenu
CenterScreen
RuntimeStoragePanel
RuntimeActionPanelBridge
RuntimeBipobSwitcher
RuntimeObjectHud
MapConstructorScreen
MapConstructorInspector
MapConstructorPropertyControls
MapConstructorPropertyUpdateService
MapConstructorLinkControls
MapConstructorInspectorVisibilityService
MapConstructorSessionState
MapConstructorRefreshCoordinator
MapConstructorUIBridge
MissionContentCatalog
```

Known state groups inside `GameUI`:

```text
bipob
field_runtime
mission_manager_runtime
legacy CommandPanel buttons
runtime_hud_root
runtime controls buttons
runtime notification panel
runtime storage panel
runtime world actions panel
map constructor palette panel
map constructor inspector panel
map constructor overview HUD
validation overlay
object info panel
map_constructor_state
map_constructor_ui_bridge
runtime_action_panel_bridge
```

Architecture debt:

- `GameUI` owns too many panels.
- It mixes screen coordination, HUD construction, map constructor, inspector, storage, notifications and runtime action routing.
- It still references legacy `CommandPanel` and current `RuntimeControlsPanel` at the same time.
- It should become shell/coordinator only.

Target split:

```text
GameUI
  -> RuntimeHudBuilder
  -> RuntimeHudPresenter
  -> RuntimeStoragePresenter
  -> RuntimeActionMenuPresenter
  -> MapConstructorScreenCoordinator
  -> ObjectInspectorBuilder
  -> ObjectInspectorPresenter
  -> NotificationPresenter
```

---

## Runtime HUD Known State

Current runtime HUD concepts known:

```text
runtime_hud_root
RuntimeBottomLeft
RuntimeStatsStrip
RuntimeControlsPanel
RuntimeBaseControlRow
RuntimeStoragePanel
RuntimeWorldActionsPanel
RuntimeNotificationPanel
```

Known problems encountered:

- Legacy `CommandPanel` exists in scene and can be accidentally enabled.
- `RuntimeControlsPanel` sometimes does not appear unless runtime HUD layout is rebuilt.
- `RuntimeHudRepair` was added as temporary helper; it should not become permanent architecture.
- HUD height growth happened when a repair layer recalculated `RuntimeBottomLeft` size every check.

Target fix:

```text
RuntimeHudBuilder builds RuntimeBottomLeft once.
RuntimeHudPresenter refreshes energy/actions/buttons.
No repair autoload.
No legacy CommandPanel.
```

---

## Map Constructor Inspector Inventory

Current central file:

```text
scripts/ui/map_constructor/map_constructor_inspector.gd
```

Known behavior:

- `MapConstructorInspector.build()` creates the inspector panel, scroll and content container.
- `_render_entity_tab()` builds world object/item inspector blocks.
- Identity currently includes Name, Description, Object type and Object class in the same section in current source.
- Current Status is built inside `_render_entity_tab()` and contains type-specific status rows.
- Placement and Configurable Parameters are built manually in the same function.
- Power, cable, lighting, terminal, cooling, wall routing and platform logic are partially hardcoded in inspector rendering.

Architecture debt:

- Inspector structure is not schema-driven.
- Identity, Status, Configurable Parameters are mixed with object-type-specific logic.
- Post-process structural autoload was added but is not the right long-term solution.
- Proper fix must be inside `ObjectInspectorBuilder` / `MapConstructorInspector` source builder.

Target split:

```text
MapConstructorInspector
  -> ObjectInspectorViewModelFactory
  -> ObjectInspectorBuilder
  -> IdentitySectionBuilder
  -> StatusSectionBuilder
  -> ConfigSectionBuilder
  -> LinksSectionBuilder
  -> ValidationSectionBuilder
```

---

## MapConstructorPropertyControls Inventory

Current central helper:

```text
scripts/ui/map_constructor/map_constructor_property_controls.gd
```

Known responsibilities:

```text
create_inspector_section
create_property_row
add_text_property
add_map_constructor_description_editor
add_bool_property
add_enum_property
add_enum_updates_property
add_int_property
add_enum_array_property
add_circuit_block
add_archetype_schema_properties
```

Known issue:

`add_map_constructor_description_editor()` currently creates Description row and then adds Apply button as a separate child below. Target UI requires Apply button inline on the right of the TextEdit.

Target role:

`MapConstructorPropertyControls` should be replaced or reduced into:

```text
CommonPropertyRowBuilder
CommonControlFactory
ObjectConfigControlBuilder
```

---

## MissionManager Inventory

Current central file:

```text
scripts/game/mission_manager.gd
```

Known preloads include:

```text
WorldObjectCatalog
ScanSystem
InteractionSystem
PowerSystem
MissionContentCatalog
MissionIds
TaskTestWorldBuilder
MapConstructorService
MapConstructorValidationService
MapConstructorPresetService
MapConstructorKeyDoorLinkService
MapConstructorTerminalLinkFilterService
MapConstructorInformationTerminalService
CableTopologyService
PlatformTypes
PlatformMechanismService
PlatformControlService
PlatformVisualService
PlatformMotionService
PlatformOccupancyService
PlatformRotationService
BipobCableRuntimeService
BipobAirflowRuntimeService
BreachableWallService
WallRoutingValidationService
CoolingRoutingContourService
BreachableWallRulesService
WallMountedPlacementRulesService
```

Known asset aliases inside MissionManager include floor, wall and object visual aliases. This indicates that MissionManager currently mixes mission logic with catalog/visual mapping.

Architecture debt:

- MissionManager has too many preloads and responsibilities.
- It acts as runtime manager, map constructor bridge, validation owner, asset alias holder, platform service coordinator and visual state helper.
- It should be split into repository + runtime systems + constructor services + catalog services.

Target split:

```text
MissionRuntime
WorldStateRepository
MissionContentCatalog
AssetAliasCatalog
MapConstructorRuntime
ConstructorMutationService
ConstructorValidationSystem
PowerSystem
CoolingSystem
AccessSystem
ControlSystem
LinkSystem
StatusSystem
PlatformSystem
WallSystem
```

---

## Known Domain Systems Already Present

Known systems/services by name from current code:

```text
WorldObjectCatalog
ScanSystem
InteractionSystem
PowerSystem
MapConstructorService
MapConstructorValidationService
MapConstructorPresetService
MapConstructorKeyDoorLinkService
MapConstructorTerminalLinkFilterService
MapConstructorInformationTerminalService
CableTopologyService
PlatformMechanismService
PlatformControlService
PlatformVisualService
PlatformMotionService
PlatformOccupancyService
PlatformRotationService
BipobCableRuntimeService
BipobAirflowRuntimeService
BreachableWallService
WallRoutingValidationService
CoolingRoutingContourService
BreachableWallRulesService
WallMountedPlacementRulesService
```

Target: сохранить полезные правила этих сервисов, но убрать дубли из UI/manager.

---

## Known Object And Item Types

Known object/item concepts from current code and assets:

```text
floor_concrete
floor_steel
floor_titan
floor_clean_lab
floor_dark_service
floor_hazard
floor_power
floor_damaged
floor_reinforced
floor_diagnostic
wall_default
wall_outer
wall_brick
wall_concrete
wall_grate
wall_damaged
wall_steel
wall_reinforced_steel
wall_titan
object_door
object_terminal
object_key
object_component
object_socket
object_cable
object_generic
object_fuse
object_repair_kit
object_keycard
object_access_code
object_cable_reel
cable_reel
fuse_box
wall_fuse_box
light
power_source
power_switcher
radiator
terminal
barrel
case
steel_box
fire_barrel
normal_crate
heavy_crate
button
switch
```

Known categories from inspector and services:

```text
power
door
terminal
control
lighting
cooling
platform
item
wall
floor
movable
routing
bipob
```

Target: each type must become `ObjectDefinition` or `ItemDefinition` with schema-driven inspector.

---

## Known Map Constructor Concepts

Known map constructor systems:

```text
palette
inspector
overview HUD
validation overlay
floor/wall coverage
entity tabs
object tabs
item tabs
wall tab
floor tab
placement
configuration
links
circuit management
terminal stored data
cooling routing controls
bipob constructor object controls
platform controls
```

Known selected state fields:

```text
selected_map_constructor_entity_kind
selected_map_constructor_entity_id
selected_map_constructor_entity_cell
map_constructor_active_inspector_tab_id
pending_map_constructor_cell
```

Target: constructor UI should be driven by `MapConstructorViewModel` and `ObjectInspectorViewModel`.

---

## Known Runtime Concepts

Known runtime concepts:

```text
BipobController
GridManager
MissionManager
RuntimeStoragePanel
RuntimeActionPanelBridge
RuntimeInteractionPresenter
RuntimeWorldActionsPanel
RuntimeObjectHud
RuntimeBipobSwitcher
RuntimeNotifications
RuntimeHudRepair
```

Known Bipob/HUD fields:

```text
energy
actions
actions_per_turn
max_energy
movement
turn left/right
interact
action
connect
claw
cut
end turn
```

Important signal names that should not be removed without migration:

```text
world_action_panel_requested
mission_failed
hint_requested
```

---

## Known Temporary / Risky Layers

Current or recent temporary layers:

```text
RuntimeHudRepair
MapConstructorInspectorStructure
RuntimeControlMenuRecovery
RuntimeCommandPanelRecovery
ObjectStatusLayer runtime/scanner variants
RuntimeWorldActionMenuSections
MapConstructorObjectLinkLayer variants
```

Target: temporary layers must be deleted after their logic is moved into the real builders/systems.

Never use these as architecture examples.

---

## Known Problems From Recent Work

### Runtime HUD

Problem:

`RuntimeControlsPanel` disappeared, legacy `CommandPanel` was accidentally enabled, and repair layers caused HUD height growth.

Lesson:

- Never enable legacy UI to fix current UI.
- Never recalculate layout every tick from current minimum size.
- Fix `RuntimeHudBuilder` and `RuntimeHudPresenter` directly.

### Object Inspector

Problem:

A post-process structure layer was added, but real UI was still built inside `MapConstructorInspector._render_entity_tab()`.

Lesson:

- Do not patch inspector after build.
- Move correct structure into the real inspector builder.

### Object Status

Problem:

A large editable status layer conflicted with desired read-only Status + editable Configurable Parameters split.

Lesson:

- StatusModel must be domain/view model.
- Configurable Parameters must be schema-driven.
- Do not mix status and configuration in one UI block.

---

## Current Architecture Debt Summary

Highest-risk files:

```text
scripts/ui/game_ui.gd
scripts/game/mission_manager.gd
scripts/ui/map_constructor/map_constructor_inspector.gd
scripts/ui/map_constructor/map_constructor_property_controls.gd
project.godot autoload list
scenes/main.tscn legacy CommandPanel
```

Why they are risky:

- too many responsibilities;
- duplicate UI systems;
- manual object-specific inspector code;
- temporary repair autoloads;
- legacy scene nodes still active/available;
- visual aliases mixed with mission runtime.

---

## Migration Notes

### Do Not Start By Editing Everything

Correct migration order:

```text
1. Freeze new patch layers.
2. Create ObjectDefinitionCatalog.
3. Create CommonPropertyRowBuilder.
4. Replace inspector section by section.
5. Remove MapConstructorInspectorStructure autoload.
6. Replace RuntimeHudBuilder/Presenter.
7. Remove RuntimeHudRepair and CommandPanel.
8. Split MissionManager responsibilities.
```

### First Clean Slice

Recommended first clean slice:

```text
Object Inspector Identity + Status
```

Files to create:

```text
scripts/presentation/object_inspector_view_model.gd
scripts/ui/object_inspector/object_inspector_builder.gd
scripts/ui/object_inspector/identity_section_builder.gd
scripts/ui/object_inspector/status_section_builder.gd
scripts/ui/common/common_property_row_builder.gd
```

Files to avoid patching further:

```text
MapConstructorInspectorStructure autoload
ObjectStatusLayer autoload
RuntimeHudRepair autoload
```

---

## Inventory Update Rule

Каждый раз, когда проект изучается повторно, этот файл нужно обновлять:

```text
new known files
new duplicate systems
new risky autoloads
new object types
new migration notes
```

Это нужно, чтобы LLM не работал по устаревшей картине проекта.
