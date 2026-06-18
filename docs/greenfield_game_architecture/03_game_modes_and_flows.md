# Game Modes And Flows

Этот документ описывает режимы игры, переходы между ними, экраны, состояния, кто владеет логикой режима и какие меню должны отображаться.

---

## AppMode

Главное состояние приложения.

```gdscript
enum AppMode {
    BOOT,
    MAIN_MENU,
    MISSION_SELECT,
    GAMEPLAY,
    MAP_CONSTRUCTOR,
    PAUSE_MENU,
    SETTINGS,
    DEBUG_TOOLS,
    GAME_OVER
}
```

Описание: `AppMode` определяет, какая сцена активна, какой input router используется и какие global panels доступны.

---

## Mode Ownership

Каждый режим должен иметь свой controller.

```text
BootModeController
MainMenuController
MissionSelectController
GameplayModeController
MapConstructorModeController
PauseModeController
SettingsModeController
GameOverModeController
```

Правило: `GameUI` не должен быть владельцем всех режимов сразу. Он может быть shell для UI, но mode logic должна быть выделена.

---

## BOOT

### Purpose

Загружает настройки, каталоги, ресурсы, schema definitions и начальное состояние.

### Visible UI

```text
LoadingScreen
BootProgressLabel
BootErrorPanel
```

### Flow

```text
AppRoot._ready()
  -> SettingsService.load()
  -> ObjectDefinitionCatalog.load_all()
  -> ItemDefinitionCatalog.load_all()
  -> SchemaRegistry.load_all()
  -> SaveLoadService.load_profile()
  -> AppStateMachine.set_mode(MAIN_MENU)
```

---

## MAIN_MENU

### Purpose

Главное меню игры.

### Visible UI

```text
MainMenuPanel
  ├─ New Game
  ├─ Continue
  ├─ Mission Select
  ├─ Map Constructor
  ├─ Settings
  └─ Exit
```

### Menu Structure

Все кнопочные меню используют общий `MenuPanelDefinition`:

```gdscript
class_name MenuPanelDefinition

var title: String
var actions: Array[MenuActionDefinition]
```

```gdscript
class_name MenuActionDefinition

var id: String
var label: String
var icon_id: String
var enabled: bool
var disabled_reason: String
var command: AppCommand
```

Описание: главное меню не должно собирать кнопки вручную. Оно отдаёт definition в `CommonMenuBuilder`.

---

## MISSION_SELECT

### Purpose

Выбор миссии или тестового уровня.

### Visible UI

```text
MissionSelectPanel
  ├─ MissionList
  ├─ MissionPreview
  ├─ DifficultySelector
  ├─ StartMissionButton
  └─ BackButton
```

### Flow

```text
MissionSelectController.select_mission(id)
  -> MissionCatalog.get_mission(id)
  -> MissionPreviewViewModel.from_mission(mission)
  -> MissionSelectPresenter.refresh(view_model)
```

```text
StartMissionButton.pressed
  -> AppStateMachine.set_mode(GAMEPLAY)
  -> MissionRuntime.start_mission(selected_mission_id)
```

---

## GAMEPLAY

### Purpose

Основной runtime режим.

### Visible UI

```text
RuntimeHudRoot
  ├─ RuntimeNotificationPanel
  ├─ RuntimeObjectivePanel
  ├─ RuntimeBottomLeft
  │    ├─ RuntimeStatsStrip
  │    └─ RuntimeControlsPanel
  ├─ RuntimeStoragePanel
  ├─ RuntimeWorldActionPanel
  └─ RuntimeTooltipLayer
```

### Gameplay State

```gdscript
class_name GameplayState

var active_actor_id: String
var selected_cell: Vector2i
var selected_object_id: String
var selected_item_id: String
var interaction_mode: String
var turn_index: int
var mission_status: String
```

### Input Routing

```text
InputRouter
  -> GameplayModeController.handle_input(input_event)
  -> MissionRuntime.apply_actor_command(command)
```

### Runtime Controls

`RuntimeControlsPanel` строится из `RuntimeHudViewModel`, а не вручную.

```text
Forward
Backward
Turn Left
Turn Right
Action
Connect
Claw
Cut
End Turn
```

Каждая кнопка имеет:

```text
action_id
label
icon_id
enabled
disabled_reason
shortcut
command
```

---

## MAP_CONSTRUCTOR

### Purpose

Редактор карты, объектов, links, rooms, prefabs и tests.

### Visible UI

```text
MapConstructorRoot
  ├─ ConstructorToolbar
  ├─ ConstructorPalettePanel
  ├─ ConstructorInspectorPanel
  ├─ ConstructorValidationPanel
  ├─ ConstructorOverlayControls
  └─ ConstructorPreviewLayer
```

### Constructor Modes

```gdscript
enum ConstructorToolMode {
    SELECT,
    PLACE_OBJECT,
    PLACE_ITEM,
    PLACE_FLOOR,
    PLACE_WALL,
    PAINT_ZONE,
    LINK_OBJECTS,
    MULTI_SELECT,
    PREVIEW_ROUTE,
    VALIDATE
}
```

### Inspector Flow

```text
User selects object
  -> ObjectSelectionSystem.select(entity_id)
  -> ObjectInspectorViewModelFactory.create(entity_id)
  -> ObjectInspectorBuilder.build(view_model)
```

Запрещено: выбрать объект, собрать inspector в одном месте, а затем autoload-слой переставляет блоки.

---

## PAUSE_MENU

### Purpose

Пауза в gameplay.

### Visible UI

```text
PauseMenuPanel
  ├─ Resume
  ├─ Restart Mission
  ├─ Save
  ├─ Load
  ├─ Settings
  └─ Exit To Main Menu
```

### Rules

- Runtime systems ставятся на pause.
- UI overlays остаются видимыми, но gameplay input отключён.
- Map constructor не должен активироваться через pause без явного перехода режима.

---

## SETTINGS

### Purpose

Настройки графики, звука, управления, accessibility, debug flags.

### Visible UI

```text
SettingsPanel
  ├─ VideoTab
  ├─ AudioTab
  ├─ ControlsTab
  ├─ GameplayTab
  ├─ AccessibilityTab
  └─ DebugTab
```

### Rules

Все настройки описываются через `SettingsSchema`.

```gdscript
class_name SettingsOptionDefinition

var id: String
var label: String
var type: String
var default_value: Variant
var allowed_values: Array
var category: String
```

UI настроек строится по schema, а не вручную.

---

## DEBUG_TOOLS

### Purpose

Внутренние инструменты разработки.

### Visible UI

```text
DebugToolsPanel
  ├─ RuntimeStateTab
  ├─ PowerDebugTab
  ├─ CoolingDebugTab
  ├─ LinksDebugTab
  ├─ ValidationDebugTab
  └─ PerformanceTab
```

### Rules

Debug tools не должны быть частью обычного gameplay UI.

Debug tools могут читать runtime snapshots, но mutation должна идти через те же services, что и gameplay.

---

## GAME_OVER

### Purpose

Результат миссии.

### Visible UI

```text
MissionResultPanel
  ├─ ResultTitle
  ├─ ObjectiveSummary
  ├─ Statistics
  ├─ Retry
  ├─ Next Mission
  └─ Main Menu
```

---

## Transition Rules

Все переходы должны идти через `AppStateMachine`.

```gdscript
func set_mode(mode: AppMode, payload: Dictionary = {}) -> void
func can_transition(from_mode: AppMode, to_mode: AppMode) -> bool
func get_current_mode() -> AppMode
```

Запрещено:

```gdscript
runtime_hud.visible = false
map_constructor_panel.visible = true
app_screen_mode = 12
```

Правильно:

```gdscript
AppStateMachine.set_mode(AppMode.MAP_CONSTRUCTOR, {"mission_id": current_mission_id})
```

---

## Mode Menu Matrix

| Mode | Main Menu | Runtime HUD | Constructor UI | Pause | Settings | Debug |
|---|---:|---:|---:|---:|---:|---:|
| BOOT | no | no | no | no | no | no |
| MAIN_MENU | yes | no | no | no | optional | optional |
| MISSION_SELECT | yes | no | no | no | optional | optional |
| GAMEPLAY | no | yes | no | yes | overlay | optional |
| MAP_CONSTRUCTOR | no | optional preview | yes | optional | overlay | optional |
| PAUSE_MENU | overlay | frozen | no | yes | optional | optional |
| SETTINGS | overlay | frozen/hidden | frozen/hidden | optional | yes | no |
| DEBUG_TOOLS | overlay | optional | optional | optional | no | yes |
| GAME_OVER | yes | no | no | no | optional | optional |

---

## Acceptance Criteria

Режим считается правильно реализованным, если:

- у него есть controller;
- input идёт через router;
- UI строится через builder/view model;
- переходы идут через `AppStateMachine`;
- не используются legacy visible toggles в разных местах;
- нет autoload, который чинит mode UI после перехода;
- есть понятная таблица, какие панели видимы в этом режиме.
