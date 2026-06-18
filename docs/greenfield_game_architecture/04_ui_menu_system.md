# UI Menu System

Этот документ описывает единую архитектуру всех меню игры: main menu, runtime HUD, object inspector, map constructor, settings, storage, action menu и notifications. Цель — чтобы однотипные меню не собирались отдельно и не имели разную структуру.

---

## UI Architecture Rule

Любое меню строится по общей модели:

```text
MenuDefinition
  -> CommonMenuBuilder
  -> MenuPresenter
  -> User command
  -> Runtime/App service
```

UI не должен сам решать game rules. UI только отображает view model и отправляет command.

---

## Common Menu Building Blocks

### CommonPanel

Базовый контейнер для любого меню.

```gdscript
class_name CommonPanelDefinition

var id: String
var title: String
var subtitle: String
var icon_id: String
var sections: Array[CommonSectionDefinition]
var actions: Array[CommonActionDefinition]
```

Описание: любой panel строится одинаково: header, sections, footer actions.

### CommonSection

```gdscript
class_name CommonSectionDefinition

var id: String
var title: String
var description: String
var rows: Array[CommonRowDefinition]
var collapsed: bool
var visible: bool
```

Описание: section — это блок, например `Identity`, `Status`, `Configurable Parameters`, `Links`, `Validation`.

### CommonPropertyRow

```gdscript
class_name CommonPropertyRowDefinition

var id: String
var label: String
var value: Variant
var control_type: String
var readonly: bool
var enabled: bool
var disabled_reason: String
var options: Array[CommonOptionDefinition]
var apply_mode: String
var command: UICommand
```

Описание: все строки property UI строятся через один builder. Если у строки есть `Apply`, кнопка всегда справа от поля.

### CommonSeparator

Разделительная полоса между sections.

```gdscript
func create_section_separator() -> Control
```

Описание: separator добавляется самим `CommonPanelBuilder`, а не каждым отдельным меню вручную.

---

## Common Control Types

Каждый control type должен строиться одним builder-ом.

```text
readonly_text
line_edit
text_edit
number_spin
checkbox
dropdown
multi_select
object_reference
object_reference_list
button_row
action_list
warning_list
status_badge
progress_bar
icon_grid
```

Если новый UI требует похожий контрол, сначала расширяется `CommonPropertyRowBuilder`, а не создаётся уникальный control в конкретном меню.

---

## Apply Button Rules

### Inline Apply

Для `LineEdit`, `TextEdit`, `SpinBox` и других редактируемых строк кнопка `Apply` находится справа.

```text
Label | Input Control | Apply Button
```

### Auto Apply

Для dropdown/checkbox можно применять изменения сразу, если это безопасно.

```text
Label | Dropdown
```

### Preview/Apply

Для опасных действий используется две стадии.

```text
Preview Button | Apply Button
```

---

## Runtime HUD

### Structure

```text
RuntimeHudRoot
  ├─ NotificationArea
  ├─ ObjectiveArea
  ├─ RuntimeBottomLeft
  │    ├─ RuntimeStatsStrip
  │    └─ RuntimeControlsPanel
  ├─ StoragePanel
  ├─ ActionMenuPanel
  └─ TooltipLayer
```

### RuntimeStatsStrip

Показывает:

```text
Energy
Actions
Health
Turn
```

### RuntimeControlsPanel

Показывает действия активного actor.

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

Каждая кнопка строится из:

```gdscript
class_name RuntimeControlButtonDefinition

var id: String
var label: String
var icon_id: String
var command: ActorCommand
var enabled: bool
var disabled_reason: String
var highlight: bool
```

Правило: legacy `CommandPanel` не существует в runtime HUD. Если он нужен для debug, он должен быть в `DebugToolsPanel`, не в gameplay.

---

## Object Inspector

### Standard Structure

```text
ObjectInspectorPanel
  ├─ TabBar
  └─ ActiveTabContent
       ├─ 1. Identity
       ├─ Separator
       ├─ 2. Status
       ├─ Separator
       ├─ 3. Configurable Parameters
       ├─ Separator
       ├─ 4. Links
       ├─ Separator
       ├─ 5. Validation
       └─ 6. Debug / Advanced
```

### Identity Section

Всегда первый блок.

Rows:

```text
Name
Description
```

Правила:

- `Name` редактируется через `line_edit` с inline Apply.
- `Description` редактируется через `text_edit` с inline Apply справа.
- Identity не содержит object type, object class, status, links.

### Status Section

Read-only.

Rows:

```text
Object type
Total state
Power state
```

Расширение допускается, но только read-only:

```text
Health state
Overheat state
Access state
Control state
```

### Configurable Parameters Section

Редактируемые параметры объекта.

Rows создаются из `ObjectConfigSchema`.

Примеры:

```text
Object class
Power mode
Control mode
Access mode
Mount
Side
Routing mode
Capacity
Overheat threshold
Required tool level
```

### Links Section

Связи объекта.

Rows создаются из `ObjectLinkSchema`.

```text
Power source
Power circuit
Control terminal
Access terminal
Stored key
Target door
Target platform
```

### Validation Section

Warnings/errors/quick fixes.

```text
Missing power source
Invalid access terminal
Broken backlink
Object is not reachable
```

### Debug Section

Скрываемый advanced блок.

```text
Object id
Prefab id
Raw data
Runtime flags
```

---

## Inspector Tabs

Tabs не должны менять базовый порядок блоков. Каждая вкладка всё равно начинается с Identity и Status.

```text
Objects Tab
Floor Tab
Walls Tab
Items Tab
Links Tab
Validation Tab
Debug Tab
```

Описание: если объект отображается на другой вкладке, структура блока остаётся одинаковой.

---

## Storage Menu

### Structure

```text
StoragePanel
  ├─ Identity
  ├─ Status
  ├─ Stored Items
  ├─ Compatible Actions
  └─ Validation
```

### Stored Items

Список items строится через `ItemListDefinition`.

```gdscript
class_name ItemListDefinition

var items: Array[ItemRowDefinition]
var actions: Array[CommonActionDefinition]
```

### Item Row

```text
Icon | Name | Count | Status | Actions
```

---

## Action Menu

### Structure

```text
ActionMenuPanel
  ├─ Target Summary
  ├─ Primary Actions
  ├─ Tool Actions
  ├─ Link Actions
  └─ Disabled Actions
```

Действия приходят из `ObjectInteractionSystem`, а не создаются в UI вручную.

```gdscript
class_name ActionDefinition

var id: String
var label: String
var icon_id: String
var enabled: bool
var disabled_reason: String
var cost_energy: int
var cost_actions: int
var command: ObjectActionCommand
```

---

## Map Constructor Toolbar

```text
ConstructorToolbar
  ├─ Select
  ├─ Place Object
  ├─ Place Item
  ├─ Floor
  ├─ Wall
  ├─ Links
  ├─ Multi Select
  ├─ Validate
  └─ Test Play
```

Toolbar строится из `ConstructorToolDefinition`.

```gdscript
class_name ConstructorToolDefinition

var id: String
var label: String
var icon_id: String
var mode: ConstructorToolMode
var enabled: bool
var disabled_reason: String
```

---

## Palette Menu

```text
PalettePanel
  ├─ Search
  ├─ Category Tabs
  ├─ Object Grid
  ├─ Item Grid
  └─ Preview
```

Категории:

```text
Power
Control
Access
Cooling
Doors
Terminals
Platforms
Storage
Hazards
Items
Decor
Debug
```

Правило: palette читает `ObjectDefinitionCatalog` и `ItemDefinitionCatalog`, а не содержит hardcoded список кнопок.

---

## Settings Menu

Все настройки строятся из `SettingsSchema`.

```text
Video
Audio
Controls
Gameplay
Accessibility
Debug
```

Каждая строка — `CommonPropertyRowDefinition`.

---

## Notification System

### Notification Types

```text
system
system_negative
positive
negative
hint
warning
error
```

### Notification Rule

Есть один `NotificationBus` и один `NotificationPresenter`.

Запрещено:

- отдельный floating notification layer;
- отдельный HUD hint system;
- прямое создание labels из gameplay systems.

Runtime отправляет событие:

```gdscript
NotificationBus.push(NotificationMessage.new(...))
```

UI отображает.

---

## UI Builder Rules

- Builder создаёт UI только из definition/view model.
- Presenter обновляет значения, но не перестраивает дерево без причины.
- Все repeated controls идут через common builders.
- Ни одно меню не должно сканировать всё дерево сцены.
- Ни одно меню не должно создавать fallback UI для другой системы.

---

## Acceptance Criteria

Меню считается правильным, если:

- использует common panel/section/property row;
- имеет view model;
- не содержит бизнес-правил;
- не дублирует другое меню;
- не требует external patch layer;
- элементы редактирования имеют одинаковое поведение Apply;
- readonly и configurable разделены;
- добавление нового объекта автоматически использует ту же структуру inspector.
