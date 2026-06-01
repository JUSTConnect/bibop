# BIPOB — follow-up audit по архитектурной стабилизации

Этот документ дополняет `docs/bipob_architecture_stabilization_plan.md` и фиксирует результаты проверки текущей реализации после первичного плана стабилизации.

Цель документа — не заменить основной план, а добавить к нему список найденных слабых мест, порядок доработок и критерии проверки следующих PR.

---

## 1. Текущий статус

План стабилизации реализован частично.

Уже есть положительная база:

```text
- WorldObjectCatalog содержит canonical constants для door_type/material/access_type.
- Есть нормализация legacy aliases.
- Map Constructor частично использует WorldObjectCatalog rows.
- Runtime inventory уже частично отделяет manipulator/pocket/keychain/digital buffer/storage.
- Есть validation suites и developer audit helpers.
```

Но архитектурные расхождения ещё не закрыты:

```text
- Validation всё ещё может ломаться из-за небезопасных Variant/String conversions.
- Map Constructor всё ещё создаёт часть item/key/digital объектов вручную, мимо WorldObjectCatalog.
- Key-card contract расходится между catalog, constructor и runtime.
- Door contract пока смешивает material-named object_type и canonical door fields.
- Validation местами мутирует live runtime state.
- MissionManager остаётся God-object и содержит слишком много систем одновременно.
```

---

## 2. Главные блокеры

### 2.1 Map Constructor validation не должен падать на Variant values

Любой validation/reporting код обязан использовать безопасное приведение динамических значений:

```gdscript
func _safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value).strip_edges()
```

Запрещено в validation paths:

```gdscript
String(data.get("access_type", ""))
String(data.get("object_type", ""))
String(data.get("item_type", ""))
String(dictionary_key)
```

Разрешено:

```gdscript
_safe_string(data.get("access_type", ""))
_safe_string(data.get("object_type", ""))
_safe_string(data.get("item_type", ""))
_safe_string(dictionary_key)
```

Validation должна возвращать issue rows, а не падать runtime error-ом.

### 2.2 Validation не должна использовать undefined/temp variables

После PR-фиксов обязательно проверять не только поиск `String(`, но и parser-level ошибки.

Особенно опасны случаи, когда refactor удаляет переменную, но оставляет её использование:

```gdscript
elif not raw_access_type.is_empty():
	var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_access_type)
```

Если `raw_access_type` не объявлен в текущем scope, это parser/runtime blocker. Следующий PR обязан быть fix-only.

### 2.3 Map Constructor item placement должен идти через catalog

Текущая опасная схема:

```gdscript
var item_data: Dictionary = {
	"object_group": "item",
	"object_type": "item",
	"item_type": item_type,
	"storage_type": "pocket",
	...
}
```

Финальная схема:

```text
prefab_id
→ WorldObjectCatalog / item preset registry
→ normalized item contract
→ placement metadata
→ runtime item state
```

Map Constructor не должен вручную решать, что такое `mechanical_key`, `mechanical_keycard`, `digital_key`, `access_code`, `fuse`, `repair_kit`.

### 2.4 Key-card contract должен стать единым

Canonical:

```text
key_card
```

Legacy aliases:

```text
mechanical_key
mechanical_keycard
keycard
```

Они допустимы только на входе compatibility normalization.

Runtime storage:

```text
key_card → keychain
```

Запрещено:

```text
key_card → manipulator
key_card → pocket
key_card → digital_buffer
key_card → digital_storage
```

### 2.5 Door contract требует финального решения по object_type

Сейчас в проекте смешаны две модели:

```text
object_type = steel_door / titanium_door / energy_door
```

и

```text
object_group = door
object_type = door или canonical runtime id
door_type = mechanical / digital / powered
material = steel / reinforced_steel / titanium / energy
access_type = no_key / key_card / digital_key / access_code / terminal
```

Нужно выбрать один финальный contract.

Если `steel_door` остаётся runtime object_type, это нужно явно признать в плане и validation. Если нет — `steel_door` должен быть только alias/editor preset.

---

## 3. Validation read-only contract

Validation helpers не должны менять live state.

Запрещённые паттерны внутри validation:

```gdscript
mission_world_objects.append(...)
mission_world_objects.erase(...)
world_objects_by_cell[...] = ...
cell_items[...] = ...
grid_manager.set_tile(...)
runtime_inventory_state[...] = ...
active_bipob_ref.installed_modules = ...
```

Допустимые варианты:

```text
- pure validation over provided data snapshot;
- deep snapshot/restore через единый guard;
- temporary sandbox manager/state, не связанный с live mission;
- validation builder, который возвращает test data, но не применяет её к runtime.
```

Особенно проверить:

```text
- scan/xray validation;
- inventory/tools/modules validation;
- module port validation;
- platform timer validation;
- task test validation;
- map constructor readiness report.
```

---

## 4. Неэффективный код и scoped recalculation

Глобальные пересчёты должны быть ограничены.

Опасные случаи:

```text
- PowerSystem.recalculate_network(mission_world_objects, "") после обычного item placement.
- refresh_world_cooling_received() после операций, которые не меняют power/cooling topology.
- полный scan по mission_world_objects при каждом мелком constructor edit.
```

Правило:

```text
Если меняется только item без power/cooling metadata → не запускать global power/cooling refresh.
Если меняется power_network_id/source/socket/cable/switch/fuse/power consumer → пересчитывать только affected network.
Если меняется cooling device/heat metadata → пересчитывать только affected heat/cooling scope.
```

---

## 5. PowerSystem слабые места

### 5.1 cell → single object

Если power graph строит:

```gdscript
object_by_cell[cell] = obj
```

то несколько объектов на одной клетке перезаписывают друг друга.

Нужно перейти к:

```text
cell → Array[Dictionary]
```

и явно выбирать:

```text
- traversable power segment;
- consumer;
- source;
- wall-mounted object;
- item/non-power object.
```

### 5.2 Traversal cap должен давать warning

Если power traversal останавливается по cap, validation/debug report должен это показывать.

```text
power_traversal_cap_reached_<network_id>
```

### 5.3 Source load должен учитывать реальных consumers

Если gameplay предполагает нагрузку от lights/doors/terminals/platforms, source load не должен считать только sockets/outlets.

---

## 6. Hardcode и God-object

`MissionManager` сейчас содержит слишком много ролей:

```text
- mission state;
- world objects;
- inventory;
- Map Constructor state;
- constructor presets/kits/templates;
- validation suites;
- developer audit;
- visual reports;
- module port tests;
- debug scenarios;
- power/cooling refresh orchestration.
```

Целевое разбиение:

```text
MissionManager
- только active mission orchestration и runtime access facade.

WorldRuntimeStateService
- mission_world_objects/world_objects_by_cell/cell_items access/update.

RuntimeInventoryService
- manipulator/pocket/keychain/digital buffer/storage.

MapConstructorService
- placement/move/delete/duplicate/property update.

MapConstructorPresetCatalog
- kits/templates/palette presets.

MapConstructorValidationService
- read-only validation.

DeveloperValidationService
- validation suite orchestration, без runtime mutation.

PowerRuntimeService / CoolingRuntimeService
- scoped recalculation.
```

---

## 7. Обновлённый порядок доработок

### Fix PR-0 — Parser/runtime blocker after PR-1

Цель: исправить ошибки, появившиеся после первого PR-фикса validation.

Обязательно:

```text
- убрать undefined variable raw_access_type;
- восстановить canonical access_type validation;
- не возвращать String(...) на dynamic Variant;
- не расширять scope;
- не менять project.godot;
- не добавлять content/features.
```

### PR-1 — Map Constructor validation safe Variant conversion

Цель: validation не падает на `digital_key`, `key_card`, `access_code`, `StringName`, null, Dictionary/Array-like Variant values.

Acceptance:

```text
- get_map_constructor_validation_issues() не падает.
- access_type = digital_key проходит как canonical value.
- access_type = none репортится как legacy issue.
- invalid access_type репортится как validation issue.
- нет unsafe String(dynamic_value) в validation service.
- нет undefined variables.
```

### PR-2 — Constructor item placement через WorldObjectCatalog

Acceptance:

```text
- mechanical_key/mechanical_keycard/keycard нормализуются в key_card.
- key_card placement создаёт item_class/storage_route для keychain.
- digital_key/access_code/data_file идут в digital buffer/storage contract.
- fuse/repair_kit/cable_reel остаются physical.
```

### PR-3 — Key-card runtime/catalog alignment

Acceptance:

```text
- catalog не объявляет key_card как pocket item.
- pickup key_card всегда идёт в keychain.
- set_pocket_item/set_manipulator_item не принимают key_card.
- HUD key strip читает keychain.
```

### PR-4 — Validation read-only guard

Acceptance:

```text
- validation suites не мутируют live runtime.
- если suite требует mutation-like scenario, он работает на sandbox/snapshot guard.
- есть validation, которая сравнивает state before/after для read-only helpers.
```

### PR-5 — Scoped power/cooling recalculation

Acceptance:

```text
- item placement без power/cooling metadata не вызывает global recalculate_network(…, "").
- power edits пересчитывают только affected network.
- cooling edits пересчитывают только affected cooling/heat scope.
```

### PR-6 — Door runtime object_type decision

Acceptance:

```text
- либо material-named door object_type официально признан canonical и validation обновлена;
- либо steel_door/titanium_door/energy_door вынесены в aliases/presets;
- door_type/material/access_type больше не конфликтуют.
```

### PR-7 — MissionManager split

Acceptance:

```text
- kits/templates вынесены из MissionManager;
- developer validation orchestration вынесен из MissionManager;
- runtime inventory имеет отдельный service/facade;
- MissionManager не растёт новыми constructor/debug helper blocks.
```

---

## 8. PR review checklist

Каждый PR проверять так:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
```

Если Godot доступен:

```bash
godot --headless --path . --quit
```

Дополнительные grep/static checks:

```bash
rg "String\(" scripts/game/map_constructor_validation_service.gd
rg "raw_access_type" scripts/game/map_constructor_validation_service.gd
rg "mission_world_objects\.(append|erase|clear)" scripts/game/map_constructor_validation_service.gd
rg "world_objects_by_cell\[" scripts/game/map_constructor_validation_service.gd
rg "cell_items\[" scripts/game/map_constructor_validation_service.gd
rg "grid_manager\.call\(\"set_tile\"|set_tile\(" scripts/game/map_constructor_validation_service.gd
```

Для PR-1 дополнительно:

```text
- Проверить, что raw_access_type объявлен до использования.
- Проверить, что digital_key не вызывает crash.
- Проверить, что invalid access_type не игнорируется.
- Проверить, что door_type validation не была случайно удалена.
```

---

## 9. Review первого PR

Проверен PR `#745 — Fix Map Constructor validation safe Variant conversion`.

Статус PR на GitHub: merged.

Результат проверки: PR нельзя считать завершённым, нужен следующий fix-only PR.

Найден blocker:

```gdscript
if _safe_string(data.get("access_type", "")).strip_edges().to_lower() == "none":
	issues.append(...)
elif not raw_access_type.is_empty():
	var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_access_type)
```

`raw_access_type` используется, но не объявлен в этом scope.

Ожидаемый fix:

```gdscript
var raw_access_type: String = _safe_string(data.get("access_type", "")).strip_edges().to_lower()
if raw_access_type == "none":
	issues.append(...)
elif not raw_access_type.is_empty():
	var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_access_type)
	if normalized_access_type != raw_access_type or not normalized_access_type in WorldObjectCatalogRef.ACCESS_TYPES:
		issues.append(...)
```

Также PR ослабил door_type validation: проверка invalid `door_type` была удалена вместе с refactor block. Её нужно вернуть без unsafe conversions:

```gdscript
if object_group == "door":
	var door_type: String = _safe_string(data.get("door_type", "")).strip_edges().to_lower()
	if WorldObjectCatalogRef.is_material_named_door_object_type(object_type) and door_type.is_empty():
		issues.append(...)
	elif not door_type.is_empty() and not door_type in WorldObjectCatalogRef.DOOR_TYPES:
		issues.append(...)
```

До этого fix-only PR нельзя переходить к следующей архитектурной задаче.
