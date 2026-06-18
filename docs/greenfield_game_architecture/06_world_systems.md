# World Systems

Этот документ описывает системную архитектуру мира: power, cooling, access, control, links, status, validation, inventory и rendering. Цель — чтобы системы не дублировали друг друга и не смешивали данные, UI и визуал.

---

## System Map

```text
WorldStateRepository
  ├─ PowerSystem
  ├─ CoolingSystem
  ├─ AccessSystem
  ├─ ControlSystem
  ├─ LinkSystem
  ├─ StatusSystem
  ├─ ItemSystem
  ├─ InventorySystem
  ├─ StorageSystem
  ├─ ValidationSystem
  └─ RenderModelFactory
```

Каждая система получает данные из repository и возвращает результат. UI и renderer не должны реализовывать правила этих систем.

---

## PowerSystem

### Responsibility

Отвечает за питание, источники, circuits, load, overload, power state.

### Data Model

```gdscript
class_name PowerNode

var object_id: String
var power_role: String
var circuit_id: String
var source_id: String
var is_powered: bool
var capacity: int
var load: int
var overload: bool
var warnings: Array[String]
```

### Functions

```gdscript
func get_power_state(object_id: String) -> PowerStateModel
func get_available_power_sources(object_id: String) -> Array[LinkTarget]
func get_available_power_circuits(source_id: String) -> Array[PowerCircuit]
func set_power_source(object_id: String, source_id: String) -> Result
func set_power_circuit(object_id: String, circuit_id: String) -> Result
func recalculate_network(circuit_id: String) -> Result
func recalculate_all() -> Result
```

### Rules

- UI не выбирает power source из raw object list.
- UI запрашивает targets у `PowerSystem` или `LinkSystem`.
- Circuit `main` существует по умолчанию.
- Power state считается одной системой.

---

## CoolingSystem

### Responsibility

Отвечает за cooling boxes, vent channels, water pipes, routes, contours, cooling delivery, overheat reduction.

### Data Model

```gdscript
class_name CoolingNode

var object_id: String
var cooling_role: String
var contour_id: String
var route_mode: String
var capacity: int
var delivered_cooling: int
var input_links: Array[String]
var output_links: Array[String]
```

### Functions

```gdscript
func get_cooling_state(object_id: String) -> CoolingStateModel
func get_available_cooling_links(object_id: String) -> Array[LinkTarget]
func set_cooling_link(source_id: String, target_id: String) -> Result
func recalculate_contour(contour_id: String) -> Result
func recalculate_all() -> Result
```

### Rules

- Cooling box — активный источник cooling.
- Air duct / water pipe — route elements.
- Cooling UI не должен менять object heat напрямую.
- Overheat reduction идёт через `CoolingSystem` -> `StatusSystem`.

---

## AccessSystem

### Responsibility

Отвечает за доступ: code, key card, digital key, terminal access.

### Access Modes

```text
none
access_code
key_card
digital_key
terminal
```

### Functions

```gdscript
func get_access_state(object_id: String) -> AccessStateModel
func can_actor_access(actor_id: String, object_id: String) -> AccessCheck
func set_access_mode(object_id: String, mode: String) -> Result
func set_access_credential(object_id: String, credential_id: String) -> Result
func validate_access_links(object_id: String) -> Array[ValidationIssue]
```

### Rules

- Access check не делается в UI.
- Access credentials являются item/link data.
- Terminal storage для code/key создаётся через `LinkSystem`.
- Backlinks обновляет `LinkSystem`, не inspector.

---

## ControlSystem

### Responsibility

Отвечает за управление объектами через internal/external/none.

### Control Modes

```text
none
internal
external
```

### Functions

```gdscript
func get_control_state(object_id: String) -> ControlStateModel
func get_control_targets(controller_id: String) -> Array[LinkTarget]
func set_control_terminal(object_id: String, terminal_id: String) -> Result
func can_control(controller_id: String, target_id: String) -> ControlCheck
func apply_control_command(controller_id: String, target_id: String, command_id: String) -> Result
```

### Rules

- External control всегда идёт через link.
- Internal control не должен показывать terminal selector.
- Control state read-only в Status.
- Control mode editable в Configurable Parameters.

---

## LinkSystem

### Responsibility

Единая система всех links и backlinks.

### Link Types

```text
power_source
power_circuit
control_terminal
access_terminal
required_key
stored_key
stored_access_code
target_door
target_platform
connected_device
cooling_input
cooling_output
```

### Data Model

```gdscript
class_name ObjectLink

var source_id: String
var link_type: String
var target_id: String
var metadata: Dictionary
```

### Functions

```gdscript
func get_links(object_id: String) -> Array[ObjectLink]
func get_backlinks(object_id: String) -> Array[ObjectLink]
func get_link_targets(object_id: String, link_type: String) -> Array[LinkTarget]
func set_link(source_id: String, link_type: String, target_id: String) -> Result
func clear_link(source_id: String, link_type: String) -> Result
func rebuild_backlinks() -> void
func validate_links(object_id: String) -> Array[ValidationIssue]
```

### Rules

- UI вызывает только `set_link` / `clear_link`.
- UI не пишет `linked_*` поля вручную.
- Backlinks пересчитываются централизованно.
- Link validation единая.

---

## StatusSystem

### Responsibility

Единый статус объектов и items.

### Total State

```text
Ready
Not ready
Unknown
Excluded
```

### Functions

```gdscript
func get_object_status(object_id: String) -> ObjectStatusModel
func get_item_status(item_id: String) -> ItemStatusModel
func recalculate_object_status(object_id: String) -> ObjectStatusModel
func recalculate_all() -> void
```

### Status Inputs

```text
object state
power state
health state
overheat state
access state
control state
validation warnings
```

### Rules

- Status block read-only.
- Configurable parameters не смешиваются со status.
- Total state считается здесь, не в inspector.

---

## ValidationSystem

### Responsibility

Ошибки, warning-и и quick fixes.

### Issue Model

```gdscript
class_name ValidationIssue

var id: String
var severity: String
var message: String
var entity_kind: String
var entity_id: String
var cell: Vector2i
var quick_fixes: Array[QuickFixDefinition]
```

### Functions

```gdscript
func validate_mission() -> ValidationReport
func validate_object(object_id: String) -> Array[ValidationIssue]
func validate_item(item_id: String) -> Array[ValidationIssue]
func get_quick_fixes(issue_id: String) -> Array[QuickFixDefinition]
func preview_quick_fix(fix_id: String) -> QuickFixPreview
func apply_quick_fix(fix_id: String) -> Result
```

### Rules

- Validation не исправляет автоматически без Apply.
- Preview и Apply разделены.
- Validation UI не знает правила; он только отображает report.

---

## ItemSystem

### Responsibility

Items on world, pickup/drop/use/consume.

### Functions

```gdscript
func get_item_actions(actor_id: String, item_id: String) -> Array[ActionDefinition]
func pickup_item(actor_id: String, item_id: String) -> Result
func drop_item(actor_id: String, item_id: String, cell: Vector2i) -> Result
func use_item(actor_id: String, item_id: String, target_id: String) -> Result
func consume_item(actor_id: String, item_id: String, amount: int) -> Result
```

---

## InventorySystem

### Responsibility

Inventory ownership, capacity, stacks.

### Functions

```gdscript
func get_inventory(inventory_id: String) -> InventoryModel
func add_item(inventory_id: String, item_id: String) -> Result
func remove_item(inventory_id: String, item_id: String, amount: int) -> Result
func move_item_between(source_inventory_id: String, target_inventory_id: String, item_id: String, amount: int) -> Result
```

---

## StorageSystem

### Responsibility

World storage objects and terminal storage.

### Functions

```gdscript
func get_storage_state(object_id: String) -> StorageStateModel
func store_item(storage_id: String, item_id: String) -> Result
func take_item(storage_id: String, item_id: String) -> Result
func can_store_item(storage_id: String, item_id: String) -> StorageCheck
```

---

## RenderModelFactory

### Responsibility

Преобразует runtime data в render data.

```gdscript
func build_world_render_model(snapshot: RuntimeSnapshot) -> WorldRenderModel
func build_object_render_model(object_data: WorldObjectData) -> ObjectRenderModel
func build_item_render_model(item_data: ItemData) -> ItemRenderModel
```

### Rules

- Renderer не считает gameplay state.
- Renderer не меняет object dictionaries.
- Renderer читает render model.

---

## Recalculation Order

После mutation порядок пересчёта должен быть единым:

```text
1. Repository mutation
2. LinkSystem.rebuild_backlinks()
3. PowerSystem.recalculate_all()
4. CoolingSystem.recalculate_all()
5. AccessSystem.refresh_cached_state()
6. ControlSystem.refresh_cached_state()
7. StatusSystem.recalculate_all()
8. ValidationSystem.collect_runtime_warnings()
9. RuntimeEventBus.emit(changed events)
10. UI/Renderer refresh from ViewModels
```

---

## Acceptance Criteria

Система считается правильной, если:

- имеет один файл/system owner;
- имеет clear input/output;
- не создаёт UI;
- не сканирует scene tree;
- mutation идёт через Result;
- UI получает ViewModel;
- renderer получает RenderModel;
- validation знает, как проверить систему;
- добавление объекта не требует ручного дублирования logic в UI.
