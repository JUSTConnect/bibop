# Greenfield Game Architecture Pack

Этот пакет документов описывает правильную архитектуру игры BIPOB с нуля. Он не является описанием текущего кода и не пытается оправдать существующие наслоения. Это целевая структура, по которой можно пересобрать проект системно: без дублей, без post-process UI слоёв, без скрытых fallback-меню и без разрозненной логики.

Все заголовки, имена модулей, имена функций и названия систем даны на английском. Объяснение — на русском.

---

## Document Map

- `01_project_structure.md` — структура файлов и папок для новой версии игры.
- `02_core_runtime_architecture.md` — главные runtime-системы, владельцы данных, поток обновлений.
- `03_game_modes_and_flows.md` — режимы игры, переходы между ними, экраны и состояния.
- `04_ui_menu_system.md` — единая архитектура всех меню, HUD, inspector, tabs, panels.
- `05_objects_and_items_model.md` — единая модель объектов и items, базовые параметры, подключение новых типов.
- `06_world_systems.md` — power, cooling, access, control, links, status, validation.
- `07_implementation_rules.md` — правила разработки, запреты, acceptance criteria, checklist для новых features.

---

## Goal

Цель — получить игру, где каждая система имеет один источник правды:

```text
Object definition -> Runtime data -> ViewModel -> UI Builder -> UI Presenter
```

А не:

```text
Old UI -> Patch layer -> Recovery layer -> Another autoload -> Manual fallback -> Hidden legacy panel
```

---

## Core Principles

### Single Source Of Truth

У каждой логики есть один владелец. Если объект имеет статус, статус считается в `ObjectStatusSystem`, а не в inspector, renderer, mission manager и HUD одновременно.

### Schema Driven UI

Все однотипные меню строятся по общей схеме. Если добавляется новый объект, его inspector не пишется вручную заново. Объект подключается через `ObjectDefinition`, получает базовые параметры и автоматически попадает в общие блоки:

```text
Identity
Status
Configurable Parameters
Links
Validation
Debug
```

### No UI Patch Layers

UI не чинится autoload-слоями после сборки. Если меню собрано неправильно, исправляется `Builder`, а не добавляется внешний слой, который переставляет nodes.

### Data First, UI Second

Сначала описывается модель данных и view model, потом UI. UI не должен сам угадывать правила игры.

### Explicit System Boundaries

Power, Cooling, Access, Control, Status, Inventory, Runtime HUD и Map Constructor не должны дублировать друг друга. Каждая система имеет чёткий вход, выход и владельца.

---

## Target High Level Architecture

```text
GameApp
  ├─ AppStateMachine
  ├─ SceneRouter
  ├─ SaveLoadService
  ├─ InputRouter
  ├─ MissionRuntime
  │   ├─ WorldStateRepository
  │   ├─ ActorSystem
  │   ├─ ObjectInteractionSystem
  │   ├─ ItemSystem
  │   ├─ InventorySystem
  │   ├─ PowerSystem
  │   ├─ CoolingSystem
  │   ├─ AccessSystem
  │   ├─ ControlSystem
  │   ├─ LinkSystem
  │   ├─ StatusSystem
  │   └─ ValidationSystem
  ├─ MapConstructorRuntime
  │   ├─ MapEditState
  │   ├─ ObjectPlacementSystem
  │   ├─ InspectorViewModelFactory
  │   └─ ConstructorValidationSystem
  ├─ Presentation
  │   ├─ RuntimeHudViewModel
  │   ├─ ObjectInspectorViewModel
  │   ├─ StorageViewModel
  │   ├─ ActionMenuViewModel
  │   └─ NotificationViewModel
  └─ UI
      ├─ RuntimeHudBuilder
      ├─ RuntimeHudPresenter
      ├─ ObjectInspectorBuilder
      ├─ ObjectInspectorPresenter
      ├─ CommonPanelBuilder
      ├─ CommonPropertyRowBuilder
      └─ NotificationPresenter
```

---

## What This Pack Should Prevent

- Два активных меню управления одновременно.
- Inspector, который собирается в одном месте, а затем переставляется другим autoload-слоем.
- Объекты, у которых базовые параметры живут в разных форматах.
- Items, которые не используют общую модель identity/status/configuration.
- Power links, control links и access links, которые синхронизируются вручную в UI.
- Renderer, который меняет gameplay данные.
- MissionManager, который становится единственным огромным файлом для всего.
- Runtime `_process`, который сканирует всё дерево сцены.

---

## Recommended Branches

Для реализации этой архитектуры лучше использовать отдельные ветки:

```text
greenfield/architecture-docs
refactor/single-source-runtime-hud
refactor/single-source-object-inspector
refactor/object-definition-catalog
refactor/domain-systems-power-cooling-access
refactor/mission-runtime-split
```

---

## First Implementation Milestone

Первый практический milestone должен быть маленьким:

```text
ObjectDefinitionCatalog
ObjectInspectorViewModel
ObjectInspectorBuilder
CommonPropertyRowBuilder
```

После этого любой объект должен отображаться через одну структуру inspector:

```text
1. Identity
2. Status
3. Configurable Parameters
4. Links
5. Validation
6. Debug
```

Только после этого стоит переносить HUD, power/cooling/access и остальные системы.
