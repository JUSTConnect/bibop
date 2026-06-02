# BIPOB — следующий этап: корректная реализация, cleanup и разгрузка GameUI/BipobController

Документ фиксирует, что ещё нужно корректно реализовать после серии PR по Map Constructor, Door/Terminal/Power/Item contracts, Action/Connect UI и TASK TEST smoke.

Цель — не добавлять новые фичи хаотично, а стабилизировать runtime contracts, убрать дубли, зафиксировать границы ответственности и подготовить следующий этап рефакторинга: разгрузить `scripts/ui/game_ui.gd` и `scripts/bipob/bipob_controller.gd`.

---

## 1. Главный вывод

Архитектурный foundation уже в основном есть:

- `WorldObjectCatalog` стал источником правды для archetypes/objects.
- Map Constructor palette всё больше строится от archetype/catalog rows.
- Door/Terminal/Item/Utility contracts начали нормализоваться.
- Parser gate и Godot CI уже включены.
- Runtime smoke начал выявлять реальные несостыковки между UI, object data, movement, action availability и power graph.

Но сейчас проект вошёл в фазу, где дальнейшие точечные правки внутри `game_ui.gd` и `bipob_controller.gd` будут быстро накапливать технический долг. Нужен следующий этап: **сначала закрепить runtime contracts**, затем **выносить ответственность из больших файлов в небольшие сервисы/контроллеры**.

---

## 2. Что ещё нужно корректно реализовать

### 2.1 Door access/control semantics

Нужно окончательно развести два разных понятия.

#### `control_type`

Отвечает только за то, **где выполняется Open/Close**:

```text
internal — у двери есть собственный локальный интерфейс; Bipob может открыть/закрыть дверь напрямую, если доступ разрешён.
external — дверь открывается/закрывается только через связанный внешний Terminal.
```

Запрещено:

```text
control_type = terminal
```

Если старые данные содержат `control_type=terminal`, они должны нормализоваться в `external`.

#### `access_type`

Отвечает только за то, **как дверь отпирается**:

```text
no_key       — отпирание не нужно.
key_card     — физическая key card.
terminal     — отпирание через Terminal.
digital_key  — цифровой ключ, ввод через Connector.
access_code  — 4-значный код доступа, ввод через Connector/keypad UI.
```

Возможны смешанные случаи:

```text
access_type=terminal + control_type=internal
# Terminal отпирает дверь, но открывает/закрывает игрок уже у самой двери.

access_type=key_card + control_type=external
# Key card отпирает дверь, но открытие/закрытие делает внешний Terminal.

access_type=digital_key + control_type=external
# Digital key вводится через Connector, а Open/Close делается Terminal.
```

### 2.2 Digital Key и Access Code

Нужно добавить явное поведение:

- `digital_key` нельзя вводить через манипулятор/action.
- `digital_key` требует `Connect` и `has_connector_jack=true`.
- `access_code` требует `Connect` и явный keypad UI.
- Access Code — 4 цифры.
- Код можно получить в Terminal, но ввод выполняется рядом с Door через Connector.

Минимальный acceptable state:

```text
Connect к access_code Door открывает небольшой UI:
- display/tableau введённых цифр;
- кнопки 0–9;
- Input/Submit;
- clear/backspace, если легко добавить.
```

Если keypad не готов, нельзя фейково считать дверь открытой. Нужно показывать честное сообщение: `Access code entry is not implemented.`

### 2.3 Terminal и Power Source должны блокировать движение

Нужно закрепить правило:

```text
Terminal = world object, blocks_movement=true by default.
Power Source = world object, blocks_movement=true by default.
```

Проверить:

- catalog defaults;
- normalization;
- map constructor placement;
- save/load old data;
- runtime movement lookup;
- object info HUD target lookup.

Важно: если cell показывает Terminal, Bipob не должен проходить через него, а object info/action target должны ссылаться на тот же самый Terminal.

### 2.4 Power network и физическое подключение

Правило:

```text
Power Source создаёт свою source-owned сеть.
main_power_net остаётся единственной виртуальной глобальной сетью.
```

Нужно проверить и доработать:

- Power Source имеет stable `power_network_id` вида `<source_id>_net`.
- External-power object может выбрать `main_power_net` или source-owned сеть.
- Logical binding к source не должен сам по себе означать physical power, если выбран не `main_power_net`.
- Если проложен физический кабель от source к consumer, warning должен исчезать, объект должен получать питание.
- Если кабель не проложен, warning должен оставаться.

Нужно отдельно протестировать:

```text
Power Source -> Power Cable cells -> Door/Terminal/Consumer
```

### 2.5 Circuit Switch

Переключатель цепи имеет ровно 3 положения:

```text
Circuit 1
Circuit 2
Circuit 3
```

Runtime UI должен показывать три явные кнопки, а не только generic `Switch`.

Технически action ids могут остаться:

```text
circuit_1
circuit_2
circuit_3
```

Но game-facing labels:

```text
Circuit 1
Circuit 2
Circuit 3
```

### 2.6 TASK TEST default modules

В TASK TEST у Bipob по умолчанию должны быть:

```text
Manipulator V1+
Connector V1+
Heavy Claw
```

Это нужно зафиксировать в mission setup / default capability helper, чтобы не приходилось вручную добавлять модули для базового smoke.

### 2.7 Heavy Claw

Heavy Claw — отдельное действие в runtime menu.

Правила:

- В меню управления есть кнопка `Heavy Claw`.
- Она подсвечивается/активируется, если перед Bipob объект, который можно толкать или тащить.
- Первым этапом достаточно реализовать push.
- Drag/pull можно оставить follow-up, но не нужно фейково заявлять, что он работает.

Нужно добавить/проверить object flags:

```text
movable_by_heavy_claw=true
heavy_claw_mode=push | drag | push_and_drag
blocks_movement=true
```

Целевые объекты:

```text
Crate
Barrel
Box
другие тяжёлые moveable puzzle objects
```

### 2.8 Object visuals

Сейчас не все объекты читаемо видны на карте. Нужно дать всем важным объектам простые визуальные формы.

Минимальные формы:

```text
Door          — прямоугольная панель/рама.
Terminal      — небольшой console/upright box.
Power Source  — квадратный/коробочный блок.
Circuit Switch / Light Switch — маленький switch/node.
Crate         — квадрат/ящик.
Barrel        — цилиндрический proxy/круглая крышка.
Power Cable   — красная линия/полоса по полу или стене.
```

Cable visual:

```text
visible cable  -> red stripe/line.
hidden cable   -> no visible stripe.
```

Нужно проверить, что visuals соответствуют реальным runtime objects, а не рисуются как отдельные фейковые decorations.

---

## 3. Где нужен рефакторинг

### 3.1 `scripts/ui/game_ui.gd`

`game_ui.gd` сейчас выполняет слишком много ролей:

- screen switching;
- center menu;
- runtime HUD;
- bottom control panel;
- inventory/storage UI;
- map constructor UI;
- property inspector;
- object info HUD;
- notifications;
- action/connect/heavy-claw buttons;
- developer/debug UI;
- callbacks для mission manager и bipob controller.

Это главный кандидат на разгрузку.

#### Целевое разделение

```text
scripts/ui/game_ui.gd
  Тонкий root/coordinator. Создаёт экраны, держит ссылки, прокидывает события.

scripts/ui/screens/center_screen.gd
  Center screen: Box/Shop/Charge/Research/Repair/Programmer/Menu.

scripts/ui/runtime/runtime_hud_controller.gd
  Energy/actions/goal/object hint/menu root.

scripts/ui/runtime/runtime_control_panel.gd
  Turn Left / Turn Right / Action / Connect / Heavy Claw / End Turn.

scripts/ui/runtime/runtime_action_view_model.gd
  Только presentation data для доступных действий.

scripts/ui/runtime/runtime_object_hud.gd
  Object card near selected/facing object.

scripts/ui/runtime/runtime_storage_panel.gd
  Inventory/keychain/pocket/manipulator/digital storage.

scripts/ui/runtime/runtime_notifications.gd
  Success/warning/error notifications.

scripts/ui/map_constructor/map_constructor_screen.gd
  Root Map Constructor screen/panel orchestration.

scripts/ui/map_constructor/map_constructor_inspector.gd
  Object inspector layout only.

scripts/ui/map_constructor/map_constructor_property_controls.gd
  Schema-driven property widgets.

scripts/ui/map_constructor/map_constructor_link_controls.gd
  Door/Terminal/Power/Item link pickers.

scripts/ui/map_constructor/map_constructor_palette.gd
  Palette rendering/filtering.
```

#### Что убрать из `game_ui.gd`

- прямое построение большинства Map Constructor property widgets;
- прямую логику Action/Connect availability;
- ручные hardcoded UI labels для object types;
- дублирующие callbacks, которые просто прокидывают в сервис;
- stateful logic, которая должна жить в runtime/map-constructor controllers.

`game_ui.gd` должен остаться примерно таким:

```text
- boot UI;
- create root screens;
- bind signals;
- route events to controllers;
- call refresh on active screen.
```

### 3.2 `scripts/bipob/bipob_controller.gd`

`bipob_controller.gd` сейчас объединяет:

- movement;
- facing target lookup;
- runtime action selection;
- action execution;
- inventory pickup/drop/use;
- connector interaction;
- door interaction;
- switch/power action;
- turn processing;
- visual pulse/selection;
- UI-facing view model assembly.

#### Целевое разделение

```text
scripts/bipob/bipob_controller.gd
  Thin owner/coordinator for Bipob node state.

scripts/bipob/bipob_movement_controller.gd
  Movement, turn left/right, collision checks, grid position.

scripts/bipob/bipob_targeting_service.gd
  Facing cell, facing object, facing item, action target resolution.

scripts/bipob/bipob_capability_service.gd
  Manipulator/Connector/Processor/Heavy Claw capabilities and versions.

scripts/bipob/bipob_action_controller.gd
  Applies chosen action id to target through InteractionSystem/MissionManager.

scripts/bipob/bipob_inventory_controller.gd
  Pickup/drop/hold/keychain/digital storage operations.

scripts/bipob/bipob_heavy_claw_controller.gd
  Heavy Claw availability and push/drag behavior.

scripts/bipob/bipob_visual_feedback.gd
  Selection pulse, action pulse, route visuals, highlight cleanup.
```

#### Что убрать из `bipob_controller.gd`

- прямое знание всех object_type branches;
- прямое построение UI action view models;
- прямое управление inventory internals;
- прямое исполнение power/terminal/door-specific effects;
- hardcoded object logic, которая уже должна быть в `InteractionSystem`, `MissionManager` или catalog helpers.

`bipob_controller.gd` должен только координировать:

```text
input -> target service -> action controller -> mission manager -> UI refresh
```

### 3.3 `scripts/game/mission_manager.gd`

`mission_manager.gd` остаётся большим, но разгружать его нужно осторожно после `game_ui` и `bipob_controller`.

Кандидаты на вынос:

```text
scripts/game/map_constructor_runtime_service.gd
  Placement, selection, update, delete, duplicate, undo/snapshot.

scripts/game/map_constructor_link_service.gd
  Door/Terminal/Power/Item link sync and link target candidates.

scripts/game/runtime_inventory_service.gd
  cell_items, keychain, pocket, digital storage, world_item_runtime.

scripts/game/runtime_object_lookup_service.gd
  world_objects_by_cell, mission_world_objects indexing, conflict checks.

scripts/game/task_test_setup_service.gd
  TASK TEST object/module/default setup.
```

Но это лучше делать после стабилизации текущих smoke issues.

---

## 4. Где убрать ненужное или задвоения

### 4.1 Door link fields

Сейчас встречаются compatibility поля:

```text
linked_terminal_id
required_terminal_id
control_terminal_id
control_source_id
```

Нужно выбрать canonical field:

```text
control_terminal_id
```

Остальные оставить как compatibility aliases, но не плодить UI под каждое поле.

Правило:

```text
Door inspector показывает только Linked Terminal.
Runtime внутри может синхронизировать aliases.
```

### 4.2 Terminal door link fields

Поля:

```text
target_door_id
linked_door_ids
controls
controlled_object_ids
```

Предлагаемый canonical минимум:

```text
target_door_id          # primary selected Door for simple UI
linked_door_ids         # optional list if terminal can control several doors
```

На текущем этапе UI должен показывать одно понятное поле:

```text
Linked Door
```

### 4.3 Power source/network fields

Поля, которые сейчас могут смешиваться:

```text
power_network_id
power_source_id
connected_power_source_id
physical_connection_source_id
```

Предлагаемый смысл:

```text
power_network_id
  Логическая выбранная сеть: main_power_net или <source_id>_net.

power_source_id
  Выбранный/логически связанный источник питания.

physical_connection_source_id
  Источник, реально найденный power graph traversal через кабели/цепь.

connected_power_source_id
  Compatibility alias, постепенно убирать из UI.
```

Нужно убрать из UI понятие `Linked Power Source`, если оно не соответствует смыслу. В UI использовать:

```text
Power Network
Power Source Binding
Physical Source — read-only/debug if needed
```

### 4.4 State controls duplication

Power cable уже выявил проблему:

```text
Editable state override
Wire state
Powered/Unpowered/Broken preset buttons
```

Правило:

- объект должен иметь **один главный контрол состояния** в инспекторе;
- power cable — только `Wire state`;
- door — Door state / derived lock/open flags через Door normalization;
- terminal — Terminal status/state;
- power source — Source state / switchable state;
- generic state override только для объектов без специального editor control.

### 4.5 Level vs Version

Game-facing labels должны использовать `Version` для module requirements:

```text
Required Manipulator Version
Required Connector Version
Required Processor Version
```

Internal serialized fields можно оставить:

```text
required_manipulator_level
required_connector_level
required_processor_level
```

Нужно не переименовывать поля ради текста в UI.

### 4.6 Action/Connect/Heavy Claw разделение

Не смешивать:

```text
Action     — физическое действие/manipulator/local object interface.
Connect    — connector interaction through jack/port.
Heavy Claw — heavy object movement.
```

Запрещено:

- Connect как переименованный Action;
- Action, который делает digital key/access code connector flow;
- Heavy Claw, который просто вызывает generic pickup/action.

---

## 5. Следующий этап: порядок PR

### PR-P — Door control/access/power semantics

Содержание:

- убрать `terminal` из Door Control Type options;
- нормализовать legacy `control_type=terminal` -> `external`;
- развести `control_type` и `access_type`;
- Terminal/Power Source `blocks_movement=true`;
- Circuit Switch UI: Circuit 1/2/3;
- физическое питание через кабели проверяется корректно;
- main_power_net остаётся виртуальным исключением.

### PR-Q — TASK TEST modules, Heavy Claw, object visuals

Содержание:

- TASK TEST Bipob starts with Connector, Manipulator, Heavy Claw;
- Heavy Claw button;
- push heavy objects;
- object visual proxies;
- red cable stripe when visible;
- hidden cable invisible.

### PR-R — GameUI split phase 1

Статус: phase 1 начата. Center screen extraction, Runtime control panel extraction и Runtime object HUD extraction завершены; полный GameUI split ещё не завершён.

Следующие кандидаты на extraction:

- Runtime storage panel;
- Map Constructor screen/root;
- BipobController targeting/action view-model extraction.

Содержание:

- [x] вынести Center screen;
- [x] вынести Runtime control panel;
- [x] вынести Runtime object HUD refresh/positioning;
- [ ] `game_ui.gd` оставить coordinator.

Минимальный критерий:

```text
No behavior changes.
No gameplay changes.
Only move code into smaller files/classes.
All current UI still works.
```

### PR-S — BipobController split phase 1

Содержание:

- вынести targeting service;
- вынести capability service;
- вынести action view model builder;
- оставить старый controller как façade.

Критерий:

```text
Existing input/action behavior remains identical.
No logic rewrites beyond extracting pure helpers.
```

### PR-T — Map Constructor link/power services

Содержание:

- вынести Door/Terminal link sync;
- вынести Power source/network option builder;
- вынести validation helpers, если безопасно;
- убрать дубли link field handling.

---

## 6. Definition of Done для следующих этапов

Каждый code PR должен пройти:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Обязательно:

```text
- No project.godot changes unless explicitly approved.
- No Russian game-facing labels.
- No combat/enemies unless explicitly requested.
- No broad global power/cooling recalc after every movement/turn.
- Validation remains read-only or snapshot/restore.
- Runtime smoke checklist updated when behavior changes.
```

---

## 7. Runtime smoke checklist после ближайших PR

После PR-P/PR-Q вручную проверить:

```text
1. Door Control Type dropdown shows only Internal/External.
2. access_type=terminal + control_type=internal works: Terminal unlocks, Door opens locally.
3. access_type=key_card + control_type=external works: key unlocks, Terminal opens/closes.
4. digital_key Door requires Connect.
5. access_code Door requires Connect and keypad UI.
6. Terminal blocks movement.
7. Power Source blocks movement.
8. Fresh TASK TEST Bipob has Manipulator, Connector, Heavy Claw.
9. Circuit Switch shows Circuit 1 / Circuit 2 / Circuit 3.
10. Power Source -> cable path -> Door powers Door.
11. Missing physical cable path keeps warning/unpowered.
12. main_power_net powers virtual objects.
13. Heavy Claw button highlights in front of crate/barrel.
14. Heavy Claw pushes movable object if destination is free.
15. Important objects are visible on map.
16. Visible power cable is red stripe/line.
17. Hidden cable is not visible.
18. Dropped item can be picked up.
19. Object info target matches actual blocking/runtime object.
20. Action/Connect/Heavy Claw remain separate.
```

---

## 8. Главный принцип следующего этапа

Не добавлять ещё больше условий в `game_ui.gd` и `bipob_controller.gd`, если можно сначала создать маленький service/helper.

Правильный путь:

```text
1. Зафиксировать runtime contract.
2. Добавить/обновить validation.
3. Сделать минимальный UI/action behavior.
4. Написать smoke checklist.
5. Только потом выносить код в отдельные файлы.
```

Главная цель ближайших этапов — чтобы Bipob оставался модульным устройством, а не набором hardcoded UI branches. Его возможности должны вытекать из установленных модулей и contracts, а UI должен только отображать доступные действия.
