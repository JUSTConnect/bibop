# Objects And Items Model

Этот документ описывает единую модель объектов и items. Главная цель — при добавлении нового объекта или item он сразу получает базовые параметры, отображается в inspector по общей структуре, поддерживает статус, links, validation и runtime interaction без ручного дублирования UI.

---

## ObjectDefinition

Каждый игровой объект описывается через `ObjectDefinition`.

```gdscript
class_name ObjectDefinition

var id: String
var object_type: String
var object_group: String
var display_name: String
var description: String
var tags: Array[String]
var visual_id: String
var footprint: ObjectFootprint
var identity: IdentityDefinition
var status: StatusDefinition
var configuration: ObjectConfigSchema
var links: ObjectLinkSchema
var interactions: Array[InteractionDefinition]
var validation: Array[ValidationRuleDefinition]
```

Описание: `ObjectDefinition` — источник правды для нового типа объекта. UI, runtime и renderer читают definition, а не имеют свои отдельные списки.

---

## Base Object Data

Любой объект в runtime должен иметь общий набор полей.

```gdscript
class_name WorldObjectData

var id: String
var object_type: String
var object_group: String
var display_name: String
var description: String
var cell: Vector2i
var rotation: int
var mount: String
var side: String
var routing_mode: String
var state: String
var flags: Dictionary
var config: Dictionary
var links: Dictionary
var runtime: Dictionary
```

Описание: объект может иметь специфические параметры, но они должны лежать в `config`, `links` или `runtime`, а не хаотично в корне.

---

## Base Identity

Каждый object и item имеет identity.

```text
id
type
group
display_name
description
tags
```

Inspector всегда показывает:

```text
1. Identity
  Name
  Description
```

---

## Object Groups

Базовые группы объектов:

```text
power
control
access
cooling
door
terminal
platform
storage
hazard
defense
sensor
wall_mounted
floor_mounted
decor
debug
```

Описание: группа определяет стандартные секции inspector, доступные links и базовые interactions.

---

## Object Status Model

Каждый объект получает read-only статус.

```gdscript
class_name ObjectStatusModel

var object_type: String
var total_state: String
var power_state: String
var health_state: String
var access_state: String
var control_state: String
var overheat_state: String
var warnings: Array[String]
```

Минимальный блок Status:

```text
Object type
Total state
Power state
```

Расширенные поля могут отображаться ниже, но только read-only.

---

## ObjectConfigSchema

Все настраиваемые параметры описываются schema.

```gdscript
class_name ObjectConfigSchema

var fields: Array[ObjectConfigField]
```

```gdscript
class_name ObjectConfigField

var id: String
var label: String
var type: String
var default_value: Variant
var min_value: Variant
var max_value: Variant
var options: Array[ConfigOption]
var visible_if: Dictionary
var readonly: bool
var category: String
```

Типы field:

```text
string
text
int
float
bool
enum
enum_array
object_ref
object_ref_array
cell_ref
color
asset_ref
```

Правило: `Configurable Parameters` строится только из `ObjectConfigSchema`.

---

## Base Config Fields

Каждый объект автоматически получает базовые параметры.

```text
object_class
mount
side
routing_mode
state
health_max
health_current
power_mode
control_mode
access_mode
```

Но visibility зависит от definition.

Пример:

- floor object не показывает mount/side;
- wall-mounted object показывает side;
- object without power показывает `power_mode = none` и не показывает power links;
- access object показывает access parameters;
- cooling box показывает cooling parameters.

---

## Adding New Object Type

Чтобы добавить новый объект, нужно создать definition, а не писать новый inspector UI.

Минимальный файл:

```text
data/objects/my_object.json
```

Пример:

```json
{
  "id": "power_source_basic",
  "object_type": "power_source",
  "object_group": "power",
  "display_name": "Power Source",
  "description": "Basic power source.",
  "visual_id": "power_source_basic",
  "base_parameters": {
    "object_class": 1,
    "power_mode": "source",
    "control_mode": "none",
    "access_mode": "none",
    "mount": "floor"
  },
  "config_schema": [
    {"id": "object_class", "label": "Object class", "type": "enum", "values": ["1", "2", "3"]},
    {"id": "source_capacity", "label": "Source capacity", "type": "int", "min": 1, "max": 10},
    {"id": "overheat_threshold", "label": "Overheat threshold", "type": "int", "min": 1, "max": 5}
  ],
  "links_schema": [
    {"id": "power_circuit", "label": "Power circuit", "type": "power_circuit"}
  ],
  "interactions": ["scan", "repair", "connect", "cut"]
}
```

После добавления definition объект автоматически получает:

```text
Palette entry
Identity block
Status block
Configurable parameters block
Links block
Validation
Runtime interactions
Renderer visual lookup
```

---

## Required Object Categories

### Power Objects

```text
power_source
power_switcher
fuse_box
power_cable
power_connector
battery
```

Base status:

```text
Power state
Source capacity
Load
Overheat
Circuit
```

Base config:

```text
object_class
source_capacity
overheat_threshold
power_circuit
routing_mode
```

### Control Objects

```text
terminal
control_terminal
switch
console
remote_controller
```

Base status:

```text
Control state
Linked targets
Power state
```

Base config:

```text
control_mode
target_type
requires_power
terminal_class
```

### Access Objects

```text
door
locked_container
access_terminal
key_card_reader
code_panel
```

Base status:

```text
Access state
Lock state
Power state
```

Base config:

```text
access_mode
required_key_id
access_code
access_terminal_id
key_card_id
digital_key_id
```

### Cooling Objects

```text
cooling_box
air_duct
water_pipe
vent_channel
cooling_connector
```

Base status:

```text
Cooling state
Input route
Output route
Cooling delivery
```

Base config:

```text
cooling_capacity
routing_mode
side
mount
connected_contour_id
```

### Door Objects

```text
manual_door
energy_door
locked_door
blast_door
secret_door
```

Base status:

```text
Open state
Access state
Power state
Total state
```

Base config:

```text
door_class
access_mode
power_mode
control_mode
open_direction
```

### Terminal Objects

```text
info_terminal
control_terminal
access_terminal
storage_terminal
power_terminal
```

Base status:

```text
Terminal state
Power state
Stored payload
Linked targets
```

Base config:

```text
terminal_type
terminal_class
stored_data_type
payload_id
control_mode
access_mode
```

### Platform Objects

```text
lifting_platform
rotating_platform
moving_platform
pressure_plate
```

Base status:

```text
Platform state
Height level
Control state
Power state
```

Base config:

```text
platform_mode
height_level
activation_mode
control_mode
linked_terminal_id
```

### Storage Objects

```text
crate
locker
safe
parts_box
resource_cache
```

Base status:

```text
Storage state
Access state
Stored items
```

Base config:

```text
capacity
access_mode
allowed_item_groups
```

### Defense Objects

```text
turret
camera
alarm
trap
laser_emitter
```

Base status:

```text
Defense state
Power state
Targeting state
Control state
```

Base config:

```text
team
targeting_mode
range
requires_power
control_mode
```

---

## ItemDefinition

Items также описываются через definition.

```gdscript
class_name ItemDefinition

var id: String
var item_type: String
var item_group: String
var display_name: String
var description: String
var visual_id: String
var stackable: bool
var max_stack: int
var usable: bool
var consumable: bool
var config_schema: ObjectConfigSchema
var interactions: Array[InteractionDefinition]
```

---

## Base Item Data

```gdscript
class_name ItemData

var id: String
var item_type: String
var item_group: String
var display_name: String
var description: String
var count: int
var cell: Vector2i
var owner_inventory_id: String
var config: Dictionary
var runtime: Dictionary
```

---

## Required Item Categories

### Access Items

```text
key_card
digital_key
physical_key
access_code_note
```

Работа:

- открывают access objects;
- могут быть связаны с door/container;
- digital key может храниться в terminal;
- key-card показывает, что он открывает.

### Power Items

```text
fuse
battery
energy_cell
power_module
```

Работа:

- вставляются в power/control objects;
- могут иметь capacity/charge;
- могут быть required item для ремонта/активации.

### Repair Items

```text
repair_parts
wire_bundle
cooling_patch
mechanical_parts
```

Работа:

- используются action `repair`;
- могут быть валютой/ресурсом;
- могут иметь rarity/amount.

### Tool Items

```text
connector_tool
manipulator_module
hacking_tool
scanner
cutter
```

Работа:

- открывают новые actions;
- имеют tool_level;
- могут быть required by object interaction.

### Mission Items

```text
quest_item
data_chip
sample_container
artifact
```

Работа:

- связаны с mission objective;
- могут быть non-droppable;
- отображаются в objective/status UI.

---

## Item Inspector

Items используют ту же структуру inspector:

```text
1. Identity
2. Status
3. Configurable Parameters
4. Links
5. Validation
6. Debug
```

Пример Status для item:

```text
Item type
Stack state
Owner state
```

---

## Object And Item Shared Rules

- Identity одинаковый для всех.
- Status read-only.
- Configurable parameters из schema.
- Links из links schema.
- Validation из validation rules.
- Debug скрыт по умолчанию.
- Visual id отделён от gameplay type.
- Runtime state отделён от config.

---

## Acceptance Criteria For New Object

Новый объект считается правильно подключённым, если:

- есть `ObjectDefinition`;
- есть visual id;
- есть base parameters;
- есть config schema;
- есть status model;
- inspector строится без custom code;
- palette entry появляется автоматически;
- validation понимает объект;
- renderer может его нарисовать;
- runtime interaction получает actions из definition/system.

---

## Acceptance Criteria For New Item

Новый item считается правильно подключённым, если:

- есть `ItemDefinition`;
- есть item group;
- есть visual id;
- storage/inventory отображает item автоматически;
- inspector использует общую структуру;
- interactions идут через ItemSystem;
- links/access rules не пишутся вручную в UI.
