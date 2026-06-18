# Core Runtime Architecture

Этот документ описывает runtime-архитектуру игры: кто владеет данными, кто их меняет, как запускается миссия, как обрабатываются действия, как UI получает данные и почему нельзя смешивать эти роли.

---

## Runtime Ownership

В игре должен быть один владелец runtime-state:

```text
MissionRuntime
```

Он не обязан делать всё сам. Он владеет ссылками на системы и repository.

```text
MissionRuntime
  ├─ WorldStateRepository
  ├─ TurnSystem
  ├─ ActorSystem
  ├─ ObjectInteractionSystem
  ├─ ItemSystem
  ├─ InventorySystem
  ├─ StorageSystem
  ├─ PowerSystem
  ├─ CoolingSystem
  ├─ AccessSystem
  ├─ ControlSystem
  ├─ LinkSystem
  ├─ StatusSystem
  └─ ValidationSystem
```

---

## WorldStateRepository

`WorldStateRepository` — единственный владелец данных мира текущей миссии.

Хранит:

```text
world_grid
floor_cells
wall_cells
world_objects
items
actors
power_networks
cooling_networks
object_links
runtime_flags
mission_objectives
```

Разрешённые функции:

```gdscript
func get_object_by_id(object_id: String) -> Dictionary
func get_item_by_id(item_id: String) -> Dictionary
func get_actor_by_id(actor_id: String) -> Dictionary
func get_objects_at_cell(cell: Vector2i) -> Array[Dictionary]
func get_items_at_cell(cell: Vector2i) -> Array[Dictionary]
func apply_object_patch(object_id: String, patch: Dictionary) -> Result
func apply_item_patch(item_id: String, patch: Dictionary) -> Result
func move_object(object_id: String, target_cell: Vector2i) -> Result
func move_item(item_id: String, target_cell: Vector2i) -> Result
```

Правило: UI, renderer и inspector не меняют `world_objects` напрямую. Они вызывают mutation service/system.

---

## MissionRuntime

`MissionRuntime` координирует запуск миссии и runtime tick.

Разрешённые функции:

```gdscript
func start_mission(mission_id: String) -> Result
func restart_mission() -> Result
func end_mission(result: MissionResult) -> void
func apply_actor_command(command: ActorCommand) -> Result
func apply_object_action(action: ObjectAction) -> Result
func end_turn() -> TurnResult
func get_runtime_snapshot() -> RuntimeSnapshot
```

Он не строит UI. Он возвращает snapshot/view data для presentation layer.

---

## Runtime Update Flow

Правильный поток действия:

```text
InputRouter
  ↓
CurrentModeController
  ↓
MissionRuntime.apply_actor_command()
  ↓
ActorSystem / ObjectInteractionSystem
  ↓
WorldStateRepository mutation
  ↓
PowerSystem / CoolingSystem / StatusSystem recalc
  ↓
RuntimeEventBus emits events
  ↓
Presentation ViewModels updated
  ↓
UI Presenters refresh controls
  ↓
Renderer refresh visuals
```

Запрещённый поток:

```text
Button.pressed
  ↓
GameUI edits object dictionary
  ↓
Renderer sees changed dict
  ↓
Autoload repairs HUD
```

---

## RuntimeEventBus

События нужны для связи систем без жёстких зависимостей.

Типы событий:

```text
ActorMoved
ActorTurned
ObjectStateChanged
ItemPickedUp
ItemDropped
PowerNetworkChanged
CoolingNetworkChanged
AccessStateChanged
ControlLinkChanged
MissionObjectiveChanged
TurnEnded
MissionFailed
NotificationRequested
```

Правила:

- событие сообщает о факте, но не содержит UI logic;
- UI подписывается через presenter/coordinator;
- runtime system не знает, какие панели существуют.

---

## ActorSystem

Отвечает за персонажей и врагов.

Функции:

```gdscript
func can_move_actor(actor_id: String, direction: Direction) -> bool
func move_actor(actor_id: String, direction: Direction) -> Result
func turn_actor(actor_id: String, direction: Direction) -> Result
func spend_actor_energy(actor_id: String, amount: int) -> Result
func spend_actor_action(actor_id: String, amount: int) -> Result
```

Данные actor:

```text
id
actor_type
cell
direction
health
energy
actions
inventory_id
status_effects
```

---

## ObjectInteractionSystem

Отвечает за доступные действия с объектами.

Функции:

```gdscript
func get_available_actions(actor_id: String, object_id: String) -> Array[ObjectActionDescriptor]
func can_apply_action(actor_id: String, object_id: String, action_id: String) -> ActionCheck
func apply_action(actor_id: String, object_id: String, action_id: String, payload: Dictionary) -> Result
```

Примеры действий:

```text
open
close
activate
deactivate
connect
cut
repair
hack
scan
insert_item
remove_item
pickup
drop
move_with_claw
```

Правило: UI не решает, какие действия доступны. UI показывает `ActionMenuViewModel`.

---

## TurnSystem

Отвечает за ходовую систему.

Функции:

```gdscript
func begin_turn(actor_id: String) -> void
func end_turn(actor_id: String) -> TurnResult
func reset_actor_resources(actor_id: String) -> void
func tick_world_effects() -> void
```

При конце хода вызываются:

```text
PowerSystem.recalculate_all()
CoolingSystem.recalculate_all()
StatusSystem.recalculate_all()
ValidationSystem.collect_runtime_warnings()
```

---

## StatusSystem

Отвечает за общий статус объекта.

Функции:

```gdscript
func get_object_status(object_id: String) -> ObjectStatusModel
func recalculate_object_status(object_id: String) -> ObjectStatusModel
func recalculate_all_object_statuses() -> void
```

Статус не является UI-блоком. Это domain/runtime model.

---

## LinkSystem

Отвечает за все связи между объектами.

Функции:

```gdscript
func get_link_targets(object_id: String, link_type: String) -> Array[LinkTarget]
func set_link(source_id: String, link_type: String, target_id: String) -> Result
func clear_link(source_id: String, link_type: String) -> Result
func rebuild_backlinks() -> void
```

Типы связей:

```text
power_source
power_circuit
control_terminal
access_terminal
key_unlocks_object
stored_key_terminal
stored_code_terminal
cooling_input
cooling_output
```

Правило: backlinks не должны записываться из UI. Backlinks создаёт `LinkSystem`.

---

## Mutation Result

Все runtime mutations должны возвращать результат одного формата.

```gdscript
class_name Result

var ok: bool
var message: String
var changed_ids: Array[String]
var warnings: Array[String]
var events: Array[RuntimeEvent]
```

Описание: это предотвращает хаотичные `Dictionary` ответы, где каждый метод возвращает свои поля.

---

## Runtime Snapshot

UI и renderer должны читать snapshot, а не внутренние поля runtime напрямую.

```gdscript
func get_runtime_snapshot() -> RuntimeSnapshot
```

Содержит:

```text
actors
objects
items
visible_cells
selected_cell
selected_object_id
selected_item_id
active_actor_id
available_actions
mission_objectives
notifications
```

---

## Anti Duplication Rules

- Нельзя считать power state в `GameUI`.
- Нельзя считать total state в inspector.
- Нельзя менять object links из button callback напрямую.
- Нельзя держать отдельные object dictionaries в UI.
- Нельзя делать `get_tree().root` scan внутри runtime system.
- Нельзя иметь два способа mutation одного и того же поля.

---

## Minimal Runtime Startup

```text
AppRoot._ready()
  -> AppStateMachine.set_mode(MainMenu)
  -> User selects mission
  -> MissionRuntime.start_mission(mission_id)
  -> SceneRouter.show(GameplayScene)
  -> RuntimeHudBuilder.build(snapshot)
  -> WorldRenderer.render(snapshot)
```

---

## Minimal Runtime Command

```text
RuntimeControlsPanel.EndTurnButton.pressed
  -> InputRouter.dispatch(EndTurnCommand)
  -> MissionRuntime.end_turn()
  -> TurnSystem.end_turn(active_actor_id)
  -> World systems recalculate
  -> RuntimeEventBus emits TurnEnded
  -> RuntimeHudPresenter.refresh(RuntimeHudViewModel)
  -> WorldRenderer.refresh(WorldRenderModel)
```

В этой цепочке нет direct UI mutation object dictionaries.
