# BIPOB — configurable Terminal archetype requirements

Этот документ дополняет:

- `docs/bipob_architecture_stabilization_plan.md`
- `docs/bipob_architecture_stabilization_followup_audit.md`
- `docs/bipob_configurable_archetype_floor_requirements.md`

Он фиксирует требования к терминалу как части глобальной configurable-object/archetype системы.

---

## 1. Главный принцип

Терминал не должен размножаться в палитре как набор вариантов.

Запрещённый подход:

```text
Information Terminal
Control Terminal
Door Control Terminal
Cooling Control Terminal
Platform Control Terminal
Class 1 Door Terminal
Class 2 Door Terminal
Powered Door Terminal
Unpowered Door Terminal
```

Правильный подход:

```text
Map Constructor palette: Terminal / Терминал
Property panel: terminal_type, controlled_target_type, terminal_class, power_type, control_type, status, allowed_statuses, linked objects
Runtime: normalized canonical terminal data
HUD/actions/validation/save/load/TASK TEST: читают тот же contract
```

Это не локальная правка палитры. Это часть общей системы:

```text
archetype registry
→ property schema
→ palette row
→ property panel
→ normalized runtime object
→ generated display name
→ validation
→ save/load
→ TASK TEST
```

---

## 2. Палитра Map Constructor

В палитре должен быть ровно один пользовательский объект терминала:

```text
Terminal / Терминал
```

Не создавать и не показывать отдельные entries:

```text
Information Terminal
Control Terminal
Door Control Terminal
Cooling Control Terminal
Platform Control Terminal
Class 1 Terminal
Class 2 Terminal
Class 3 Terminal
Internal Power Terminal
External Power Terminal
Active Terminal
Damaged Terminal
Unpowered Terminal
```

Quick presets для терминалов не нужны.

Все варианты терминала создаются через настройки выбранного объекта `Terminal`.

---

## 3. Terminal archetype

Canonical archetype:

```text
archetype_id = terminal
object_group = terminal
object_type = terminal
```

Runtime canonical data example:

```gdscript
{
	"archetype_id": "terminal",
	"object_group": "terminal",
	"object_type": "terminal",
	"terminal_type": "information",
	"controlled_target_type": "none",
	"terminal_class": 1,
	"power_type": "internal",
	"control_type": "internal",
	"status": "active",
	"allowed_statuses": ["active", "damaged", "unpowered"],
	"linked_object_ids": [],
	"linked_door_ids": [],
	"linked_cooling_ids": [],
	"linked_platform_ids": [],
	"display_name": "Information Terminal",
	"configurable": true
}
```

Runtime values должны быть canonical English ids. Русские названия используются только как display labels.

---

## 4. Terminal property schema

### 4.1 Terminal type

Терминал должен иметь настраиваемый тип:

```text
terminal_type: information | control
```

Default:

```text
terminal_type = information
```

Display labels:

```text
information → Information / Информационный
control → Control / Управления
```

Display name generation:

```text
terminal_type = information
→ Information Terminal / Терминал информационный

terminal_type = control
→ Control Terminal / Терминал управления
```

Если выбран `terminal_type = information`, это окончательное основное имя терминала.

### 4.2 Controlled target type

Если выбран `terminal_type = control`, появляется/используется параметр того, чем управляет терминал:

```text
controlled_target_type: none | door | cooling | platform | power | lighting | device
```

Default:

```text
controlled_target_type = none
```

Display labels:

```text
none → None / Нет
door → Door / Дверь
cooling → Cooling / Охлаждение
platform → Platform / Платформа
power → Power / Питание
lighting → Lighting / Освещение
device → Device / Устройство
```

Display name generation for control terminals:

```text
terminal_type = control, controlled_target_type = none
→ Control Terminal / Терминал управления

terminal_type = control, controlled_target_type = door
→ Door Control Terminal / Терминал управления дверью

terminal_type = control, controlled_target_type = cooling
→ Cooling Control Terminal / Терминал управления охлаждением

terminal_type = control, controlled_target_type = platform
→ Platform Control Terminal / Терминал управления платформой
```

После выбора `controlled_target_type` основное имя считается сформированным. Остальные параметры не должны раздувать название в палитре или превращаться в отдельные варианты.

Важно по turret/combat:

```text
- Не добавлять новых турелей, врагов или combat gameplay.
- Если в старых данных уже есть turret/threat references, они могут оставаться только hidden legacy/compatibility values.
- Не показывать turret как новый user-facing controlled_target_type в этом PR, если это добавляет combat-facing gameplay.
- Если позже turret будет разрешён как non-combat device, его нужно добавить отдельным design decision, а не случайно через terminal archetype.
```

### 4.3 Terminal class

```text
terminal_class: 1 | 2 | 3
```

Default:

```text
terminal_class = 1
```

Класс влияет на требования/возможности терминала, но не должен создавать отдельные объекты в палитре.

### 4.4 Power type

```text
power_type: internal | external
```

Default:

```text
power_type = internal
```

Display labels:

```text
internal → Internal / Внутренний
external → External / Внешний
```

### 4.5 Control type

```text
control_type: internal | external
```

Default:

```text
control_type = internal
```

Display labels:

```text
internal → Internal / Внутренний
external → External / Внешний
```

### 4.6 Current status and allowed statuses

Current status хранится одним полем:

```text
status = active
```

Возможные статусы хранятся отдельно:

```text
allowed_statuses = [active, damaged, unpowered]
```

Allowed status values:

```text
active
damaged
unpowered
locked
disabled
error
```

Default:

```text
status = active
allowed_statuses = [active, damaged, unpowered]
```

Не использовать набор независимых source-of-truth bools:

```text
is_active
is_damage
is_unpower
```

Derived compatibility flags допустимы только если они синхронизируются из `status` одним helper-ом.

---

## 5. Linked/dependent objects

Терминал должен поддерживать привязки зависимых объектов и объектов в цепи через schema-driven fields.

Базовые поля:

```text
linked_object_ids: Array[String]
linked_door_ids: Array[String]
linked_cooling_ids: Array[String]
linked_platform_ids: Array[String]
linked_power_ids: Array[String]
linked_lighting_ids: Array[String]
chain_input_ids: Array[String]
chain_output_ids: Array[String]
```

Правила:

```text
- linked ids должны валидироваться как object references;
- тип linked ids должен соответствовать controlled_target_type, если он задан;
- изменение linked ids должно обновлять backlinks через единый helper/service;
- старые backlinks должны удаляться при изменении связи;
- недопустимые или отсутствующие linked ids должны давать validation issue, а не runtime crash.
```

Пример:

```text
terminal_type = control
controlled_target_type = door
linked_door_ids = [door_a]
→ Терминал управления дверью
```

---

## 6. Display name generation

Display name должен генерироваться из property values, а не храниться как набор статических prefab variants.

Rules:

```text
terminal_type = information
→ Information Terminal / Терминал информационный

terminal_type = control, controlled_target_type = none
→ Control Terminal / Терминал управления

terminal_type = control, controlled_target_type = door
→ Door Control Terminal / Терминал управления дверью

terminal_type = control, controlled_target_type = cooling
→ Cooling Control Terminal / Терминал управления охлаждением

terminal_type = control, controlled_target_type = platform
→ Platform Control Terminal / Терминал управления платформой
```

Класс, питание, тип управления, статус и связи не должны создавать новые palette entries и не должны автоматически раздувать основное имя.

Допустимый UI вариант:

```text
Терминал управления дверью
Класс: 2
Питание: Внешний
Статус: Active
Связи: door_a
```

Не нужно превращать это в отдельный объект:

```text
Class 2 External Powered Active Door Control Terminal
```

---

## 7. Global system integration

Terminal archetype обязан использовать тот же pipeline, что Door, Wall и Floor:

```text
Archetype definition
→ property_schema
→ palette row
→ placement default data
→ property overrides
→ normalized runtime terminal data
→ generated display_name
→ linked object/backlink sync
→ validation
→ save/load
→ TASK TEST
```

Это должно применяться во всей игре, включая:

```text
- Map Constructor palette;
- property panel выбранного объекта;
- object creation service;
- property update service;
- room templates;
- prefab kits;
- patch import;
- TASK TEST construction;
- runtime action availability;
- device scan/diagnostics;
- HUD/debug display;
- save/load compatibility;
- validation.
```

Нельзя делать отдельную terminal-only ветку логики, которая обходит archetype registry.

---

## 8. Compatibility

Если в старых данных уже есть terminal-like ids, они должны стать hidden compatibility aliases.

Примеры возможных legacy ids:

```text
terminal
information_terminal
control_terminal
door_terminal
door_control_terminal
cooling_terminal
platform_terminal
power_terminal
```

Они допустимы только внутри load/import/normalization compatibility layer.

Они не должны появляться в:

```text
- primary Map Constructor palette;
- quick presets;
- user-facing object list;
- editor search results;
- prefab kit selectable variants;
- room template selectable variants.
```

---

## 9. Validation requirements

Global palette validation должна проверять Terminal как часть общей archetype системы.

Terminal-specific validation:

```text
- exactly one user-facing Terminal entry exists;
- no separate information/control terminal variants in palette;
- no separate target-specific terminal variants in palette;
- no class-specific terminal variants in palette;
- no status-specific terminal variants in palette;
- no quick presets for terminal variants;
- Terminal has property_schema;
- terminal_type is one of: information, control;
- controlled_target_type is one of allowed target values;
- controlled_target_type is none or ignored for information terminals;
- terminal_class is 1, 2, or 3;
- power_type is internal or external;
- control_type is internal or external;
- status is one of allowed status values;
- status is included in allowed_statuses;
- linked ids point to existing objects when validation has world context;
- linked ids match controlled_target_type when applicable;
- backlinks are not stale after property edits;
- display_name can be generated from terminal_type/controlled_target_type;
- runtime values are canonical English ids;
- localized labels are display-only;
- TASK TEST terminal objects are reproducible through Terminal archetype + properties;
- legacy terminal ids are hidden load/import aliases only.
```

Global validation must also catch if someone reintroduces:

```text
Information Terminal
Control Terminal
Door Control Terminal
Cooling Control Terminal
Platform Control Terminal
Class 1 Terminal
Class 2 Terminal
Class 3 Terminal
```

as palette rows or quick presets.

---

## 10. Acceptance

```text
- Map Constructor palette shows one Terminal / Терминал object.
- User can select Terminal and configure terminal_type.
- terminal_type = information generates Терминал информационный.
- terminal_type = control generates Терминал управления.
- terminal_type = control + controlled_target_type = door generates Терминал управления дверью.
- User can configure terminal_class = 1/2/3.
- User can configure power_type = internal/external.
- User can configure control_type = internal/external.
- User can configure status = active/damaged/unpowered/etc.
- User can configure allowed_statuses.
- User can link dependent objects through schema-driven fields.
- No terminal variants appear in palette.
- No quick presets for terminal variants.
- Terminal creation uses the same archetype/property/normalization pipeline as Door, Wall and Floor.
- Validation catches duplicated terminal variants and stale/invalid links.
```

---

## 11. Codex prompt block

```text
PR title: Add Terminal to global configurable archetype system

Goal:
Add Terminal as a first-class configurable archetype in the global archetype/property schema system. This must affect the whole game pipeline, especially the Map Constructor palette, runtime action availability, device diagnostics, validation, save/load, and TASK TEST.

Core rule:
Palette shows one Terminal object. Terminal type, controlled target, class, power/control type, status, allowed statuses, and linked objects are configured through properties. Do not create terminal presets or duplicated palette variants.

Palette:
- Show exactly one user-facing Terminal / Терминал entry.
- Do not show Information Terminal, Control Terminal, Door Control Terminal, Cooling Control Terminal, Platform Control Terminal, Class 1 Terminal, Class 2 Terminal, Class 3 Terminal as separate entries.
- Do not add quick presets.

Terminal runtime contract:
{
    "archetype_id": "terminal",
    "object_group": "terminal",
    "object_type": "terminal",
    "terminal_type": "information",
    "controlled_target_type": "none",
    "terminal_class": 1,
    "power_type": "internal",
    "control_type": "internal",
    "status": "active",
    "allowed_statuses": ["active", "damaged", "unpowered"],
    "linked_object_ids": [],
    "linked_door_ids": [],
    "linked_cooling_ids": [],
    "linked_platform_ids": [],
    "display_name": "Information Terminal",
    "configurable": true
}

Property schema:
- terminal_type: information | control, default information
- controlled_target_type: none | door | cooling | platform | power | lighting | device, default none
- terminal_class: 1 | 2 | 3, default 1
- power_type: internal | external, default internal
- control_type: internal | external, default internal
- status: active | damaged | unpowered | locked | disabled | error, default active
- allowed_statuses: active/damaged/unpowered/locked/disabled/error, default ["active", "damaged", "unpowered"]
- linked_object_ids: Array[String]
- linked_door_ids: Array[String]
- linked_cooling_ids: Array[String]
- linked_platform_ids: Array[String]
- linked_power_ids: Array[String]
- linked_lighting_ids: Array[String]
- chain_input_ids: Array[String]
- chain_output_ids: Array[String]

Display name:
- information -> Information Terminal / Терминал информационный
- control + none -> Control Terminal / Терминал управления
- control + door -> Door Control Terminal / Терминал управления дверью
- control + cooling -> Cooling Control Terminal / Терминал управления охлаждением
- control + platform -> Platform Control Terminal / Терминал управления платформой

Do not include class/power/status/links in the main generated display name unless a future UX rule explicitly requires it.

Linked objects:
- linked ids must be schema-driven object references.
- update backlinks through a single helper/service.
- remove stale backlinks when links change.
- invalid links should produce validation issues, not runtime crashes.

Turret/combat note:
- Do not add new turrets, enemies, or combat gameplay.
- Do not expose turret as a new user-facing controlled target in this PR.
- If legacy turret references already exist, keep them hidden compatibility-only.

Integration:
Terminal must use the same global pipeline as Door, Wall and Floor:
Archetype definition -> property_schema -> palette row -> placement default data -> property overrides -> normalized runtime data -> generated display_name -> linked object/backlink sync -> validation -> save/load -> TASK TEST.

This must apply to:
- Map Constructor palette
- selected object property panel
- object creation service
- property update service
- room templates
- prefab kits
- patch import
- TASK TEST construction
- runtime action availability
- device scan/diagnostics
- HUD/debug display
- save/load compatibility
- validation

Compatibility:
Legacy ids like information_terminal, control_terminal, door_terminal, door_control_terminal, cooling_terminal, platform_terminal, power_terminal must be hidden load/import aliases only if they exist. They must not appear in user-facing palette, quick presets, editor search, prefab kit selectable variants, or room template selectable variants.

Validation:
Add/update validation so it catches:
- more than one user-facing Terminal palette row;
- information/control terminal variants in palette;
- target-specific terminal variants in palette;
- class/status-specific terminal variants in palette;
- quick presets for terminal variants;
- invalid terminal_type;
- invalid controlled_target_type;
- invalid terminal_class;
- invalid power_type/control_type;
- invalid status;
- status not included in allowed_statuses;
- invalid/stale linked object references;
- display_name not generated from terminal_type/controlled_target_type;
- TASK TEST terminal object not reproducible through Terminal archetype + properties.

Do not:
- change project.godot;
- add enemies/combat;
- add unrelated mission content;
- add quick presets;
- create terminal-only hardcode that bypasses archetype registry;
- use localized labels as runtime values.

Acceptance:
- Map Constructor palette shows one Terminal / Терминал.
- User can configure terminal_type information/control.
- Information terminal displays as Терминал информационный.
- Control terminal displays as Терминал управления.
- Door control terminal displays as Терминал управления дверью.
- User can configure class, power_type, control_type, status, allowed_statuses.
- User can configure linked dependent objects.
- No duplicated terminal variants in palette.
- Terminal is part of the global configurable archetype system and works through the same pipeline as Door, Wall and Floor.
```
