# BIPOB — план архитектурной стабилизации объектов, дверей, инвентаря, действий и HUD

## 1. Назначение документа

Этот документ фиксирует комплексный план исправления архитектурных расхождений, которые сейчас приводят к повторным багам в уже реализованных системах.

Главная цель — не чинить каждый симптом отдельно, а привести проект к единому контракту данных:

```text
Catalog definition
→ canonical runtime object/item
→ Map Constructor placement
→ mission/TASK TEST setup
→ runtime action detection
→ runtime action execution
→ HUD display
→ validation
```

Если объект, дверь, предмет, ключ, цель миссии или действие создаются разными путями, они всё равно должны приходить к одному canonical runtime format.

---

## 2. Проблемы, которые нужно закрыть

### 2.1 Двери

Сейчас смешаны два разных понятия:

- тип двери как материал: `steel_door`, `titanium_door`, `energy_door`;
- тип двери как принцип открытия: mechanical, digital, powered.

Финальная модель должна быть другой:

```text
Door type = способ открытия / принцип работы
Material = из чего дверь сделана
Access type = какой доступ нужен
Door class = уровень требований
```

Правильные значения:

```text
door_type:
- mechanical
- digital
- powered

material:
- steel
- reinforced_steel
- titanium
- energy

access_type:
- no_key
- key_card
- digital_key
- access_code
- terminal

door_class:
- 1
- 2
- 3
```

`steel_door` не должен быть gameplay-типом двери. Это должна быть либо legacy alias, либо editor preset, который создаёт:

```text
object_group = door
door_type = mechanical / digital / powered
material = steel
```

### 2.2 Key-card

В проекте не должно быть двух параллельных понятий:

```text
mechanical_key
mechanical_keycard
keycard
key_card
```

Финальное canonical-понятие:

```text
key_card
```

Правила:

```text
Key-card хранится в keychain / ключнице.
Key-card не занимает manipulator.
Key-card не лежит в pocket.
Key-card не попадает в digital buffer/storage.
Для использования key-card на двери manipulator должен быть свободен.
```

### 2.3 Инвентарь

Нужно разделить 5 разных зон хранения:

```text
manipulator_slots — активные физические предметы в манипуляторе
pocket_slots — физические предметы в карманах
keychain — key-card / ключи доступа
digital_buffer — один активный цифровой файл/запись
digital_storage — цифровое хранилище
```

Физические предметы и цифровые данные не должны смешиваться:

```text
Fuse / Repair Kit / Cable Reel → manipulator / pocket
Key-card → keychain
Digital Key / Access Code / Data File → digital buffer / digital storage
```

### 2.4 Map Constructor

Map Constructor не должен иметь отдельный список объектов, который расходится с catalog.

Единое правило:

```text
WorldObjectCatalog = source of truth.
Map Constructor palette = view/presets над WorldObjectCatalog.
```

### 2.5 TASK TEST

TASK TEST должен использовать те же canonical object definitions, что и редактор и runtime.

TASK TEST не должен быть отдельной реальностью, где вручную прописанные объекты имеют поля, которые не может создать редактор.

### 2.6 Runtime actions

Action availability должен вычисляться из нормализованного target object/item, а не из UI и не из hardcoded object_type.

Правильная схема:

```text
facing target
→ normalize target
→ get available actions
→ UI displays action
→ execute selected action
→ refresh state/HUD
```

### 2.7 HUD

HUD должен отображать только реальное runtime state.

Запрещённые ситуации:

```text
UI показывает 3 свободных manipulator cells, backend имеет только 1 real slot.
UI показывает key-card как item in manipulator.
GOAL panel показывает hardcoded TASK TEST text.
Storage показывает physical item.
```

### 2.8 Validation

После каждого foundation PR должны появляться проверки, которые не дадут таким расхождениям вернуться.

---

## 3. Общие правила для всех PR

### 3.1 Запреты

Во всех PR запрещено без отдельного согласования:

```text
- менять project.godot
- добавлять enemies/combat
- добавлять новые обычные mission content
- переписывать всю mission system целиком
- переписывать весь HUD целиком
- делать визуальные изменения вместе с data-contract изменениями, если это не обязательно
- менять save schema без отдельного migration plan
- вносить глобальные refactor changes вне scope PR
```

### 3.2 GDScript safety

Каждый PR обязан соблюдать:

```text
- не использовать C-style ternary: condition ? a : b
- использовать: a if condition else b
- избегать := на Variant/dynamic/helper results
- явно типизировать результаты динамических helper-вызовов
- избегать unsafe Dictionary(value) / Array(value) без проверки типа
- не shadow-ить position, rotation, range
- не использовать GridManager.is_visible(); использовать is_cell_visible()
```

### 3.3 Обязательный syntax gate после каждого PR

После каждого PR нельзя переходить дальше, пока не выполнены проверки:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
```

Если доступен Godot CLI:

```bash
godot --headless --path . --quit
```

Если в проекте есть отдельная команда parser/headless check, использовать её вместо generic-команды.

### 3.4 Обязательное правило остановки

Если после PR есть:

```text
- parser error
- runtime error spam
- infinite Output spam
- TASK TEST crash/freeze
- broken basic door interaction
- broken physical/digital storage separation
```

следующий PR должен быть только fix PR для этой ошибки. Нельзя продолжать визуал или новые features.

---

## 4. Финальный door contract

Каждая дверь в runtime должна быть нормализована к такому контракту:

```gdscript
{
    "object_group": "door",

    "door_type": "mechanical", # mechanical | digital | powered
    "material": "steel",       # steel | reinforced_steel | titanium | energy
    "door_class": 1,            # 1 | 2 | 3

    "access_type": "key_card", # no_key | key_card | digital_key | access_code | terminal

    "required_key_id": "",
    "required_terminal_id": "",
    "required_access_code_id": "",
    "required_digital_key_id": "",

    "required_manipulator_level": 1,
    "required_connector_level": 0,
    "required_processor_level": 0,

    "power_behavior": "none", # none | opens_when_unpowered | requires_power_to_open

    "state": "closed",        # open | closed | locked | jammed | unpowered | broken
    "is_open": false,
    "is_locked": false,
    "blocks_movement": true
}
```

### 4.1 Mechanical door

```text
door_type = mechanical
```

Не требует питания и внешнего управления.

Может иметь:

```text
access_type = no_key
access_type = key_card
```

### 4.2 Digital door

```text
door_type = digital
```

Может открываться через:

```text
access_type = terminal
access_type = access_code
access_type = digital_key
access_type = no_key
```

### 4.3 Powered door

```text
door_type = powered
```

Открывается через power condition, например:

```text
power_behavior = opens_when_unpowered
```

`access_type = no_key` для powered door означает, что ключ не требуется, но power condition всё равно работает.

### 4.4 no_key

`no_key` — это обязательное canonical значение.

```text
access_type = no_key
```

Значит: дверь не требует key-card, digital key, access code или terminal authorization.

Это не значит, что дверь всегда открыта. Она всё равно может быть blocked by:

```text
- broken/jammed state
- power behavior
- door class/manipulator requirement
- physical obstruction
```

---

## 5. Финальный item/inventory contract

### 5.1 Item classes

```text
physical_tool
physical_consumable
key_card
digital_key
access_code
data_file
module
mission_item
```

### 5.2 Storage routing

```text
Fuse
- item_class = physical_consumable
- storage_route = manipulator_or_pocket

Repair Kit
- item_class = physical_consumable
- storage_route = manipulator_or_pocket

Cable Reel
- item_class = physical_tool
- storage_route = manipulator_or_pocket

Key-card
- item_class = key_card
- storage_route = keychain

Digital Key
- item_class = digital_key
- storage_route = digital_buffer_or_storage

Access Code
- item_class = access_code
- storage_route = digital_buffer_or_storage

Data File
- item_class = data_file
- storage_route = digital_buffer_or_storage
```

### 5.3 Key-card rule

```text
Key-card не занимает manipulator.
Key-card отображается в key strip как K.
Key-card используется из keychain.
Для применения key-card manipulator должен быть свободен.
```

---

## 6. PR-план

## PR-1 — Canonical Object and Item Contracts

### Цель

Зафиксировать canonical schema для объектов, дверей и предметов.

### Должно быть достигнуто

```text
- Добавлен единый contract для door object data.
- Добавлен единый contract для item data.
- Добавлена централизованная нормализация legacy aliases.
- Legacy names не используются как runtime truth.
- Старые данные не ломаются, но приводятся к canonical format.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
```

Godot syntax check:

```bash
godot --headless --path . --quit
```

### Acceptance

```text
- mechanical_door нормализуется в canonical door data.
- steel_door больше не является финальным gameplay door_type.
- key_card является canonical mechanical access item.
- no_key является canonical access_type.
```

---

## PR-2 — Door Registry and Door Presets

### Цель

Разделить door runtime object и editor presets.

### Должно быть достигнуто

```text
- Runtime имеет один generic door object contract.
- Presets создают door data через door_type/material/access_type.
- Mechanical Steel Door — preset, не отдельный runtime object_type.
- Digital Titanium Door — preset, не отдельный runtime object_type.
- Powered Energy Door — preset, не отдельный runtime object_type.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- В runtime нет divergent mechanical_door как отдельной логики.
- Все door presets создают normalized door data.
- material и door_type больше не смешиваются.
```

---

## PR-3 — Map Constructor Palette from Catalog

### Цель

Сделать Map Constructor consumer-ом catalog/preset registry.

### Должно быть достигнуто

```text
- Palette строится из единого registry.
- Все placeable objects доступны из одного источника.
- TASK TEST objects и editor objects не расходятся.
- Unknown prefab ids не появляются в runtime.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- В редакторе доступны все canonical door presets.
- Старые aliases не создают unknown runtime object_type.
- Placed object проходит normalization.
```

---

## PR-4 — Map Constructor Placement Normalization

### Цель

Гарантировать, что placement, preset load, patch import и manual edits всегда создают normalized runtime data.

### Должно быть достигнуто

```text
- При placement вызывается canonical normalization.
- При preset load вызывается canonical normalization.
- При patch import вызывается canonical normalization.
- Door state/access fields синхронизированы.
- Unknown object_type не попадает в mission_world_objects.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- Placed mechanical-style door имеет canonical door data.
- no_key сохраняется и применяется.
- access_type/lock_type/is_locked/state не расходятся.
```

---

## PR-5 — Door Access Runtime Contract

### Цель

Сделать door interaction generic и data-driven.

### Должно быть достигнуто

```text
- Door open/close не зависит от object_type = steel_door/mechanical_door.
- Interaction читает door_type/material/access_type/state.
- mechanical + no_key открывается без ключа.
- mechanical + key_card требует key-card и свободный manipulator.
- digital door открывается terminal/access_code/digital_key/no_key.
- powered door открывается по power_behavior.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- Unlocked/no-key mechanical door opens/closes.
- Key-card door works.
- Digital access doors work.
- Powered doors obey power condition.
- No “No available action” for valid interactable door.
```

---

## PR-6 — Inventory State Contract

### Цель

Ввести единый контракт manipulator/pocket/keychain/buffer/storage.

### Должно быть достигнуто

```text
- UI и pickup logic читают одно и то же inventory state.
- manipulator slots не расходятся с визуальными слотами.
- keychain отделён от manipulator/pocket.
- digital buffer/storage отделены от physical inventory.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- Fuse pickup → manipulator.
- Fuse manipulator ↔ pocket работает.
- Key-card pickup → keychain.
- Key-card отображается как K.
- Digital files → buffer/storage.
- Physical items не попадают в buffer/storage.
```

---

## PR-7 — Runtime Action Service / Action View Contract

### Цель

Убрать stale action/pulse и сделать список действий единым.

### Должно быть достигнуто

```text
- Action availability создаётся из normalized target.
- UI не хранит собственную action truth.
- После pickup/move/turn/action список действий пересчитывается.
- Stale target очищается.
- Pulse не остаётся на пустой клетке.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- Пустая клетка не даёт Action pulse.
- Предмет перед Bipob даёт pickup action.
- После pickup Action очищается.
- Дверь перед Bipob даёт door action.
- Output не спамится ошибками.
```

---

## PR-8 — Mission Goal / Runtime HUD Data Binding

### Цель

Убрать hardcoded GOAL и привязать HUD к mission data.

### Должно быть достигнуто

```text
- GOAL panel читает active mission objective.
- ACTIONS/ENERGY не дублируются в goal panel.
- Notification panel показывает уведомления.
- HUD отображает view models, не gameplay logic.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- TASK TEST goal берётся из mission data.
- Другие миссии показывают свои цели.
- Нет hardcoded “Use this mission to validate” в HUD.
```

---

## PR-9 — TASK TEST Alignment with Canonical Systems

### Цель

Привести TASK TEST к тем же canonical systems, что использует Map Constructor и runtime.

### Должно быть достигнуто

```text
- TASK TEST создаёт объекты через canonical registry/presets.
- Все TASK TEST objects доступны или воспроизводимы в Map Constructor.
- TASK TEST validation не мутирует active mission без snapshot/restore.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- TASK TEST запускается без runtime error spam.
- TASK TEST doors/items/actions проходят те же правила, что constructor-created objects.
- Developer validation read-only или snapshot/restore.
```

---

## PR-10 — Contract Validation Gate

### Цель

Добавить проверки, которые предотвращают возвращение архитектурных расхождений.

### Должно быть достигнуто

Validation должна ловить:

```text
- prefab exists in constructor but not in registry
- TASK TEST object type missing in registry
- runtime object has unknown object_type
- legacy object_type leaked into runtime
- door missing door_type/material/access_type/state
- invalid access_type
- no_key door still has required_key_id
- key_card item stored outside keychain
- physical item in digital buffer/storage
- digital item in manipulator/pocket
- UI manipulator slot count != backend slot count
- GOAL panel hardcode / missing mission objective binding
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- Contract validation fails if someone reintroduces mechanical_door as runtime type.
- Contract validation fails if physical item can enter digital storage.
- Contract validation fails if constructor prefab is unknown.
```

---

## PR-11 — Legacy Cleanup and Compatibility Boundary

### Цель

Оставить legacy names только на входе, а внутри runtime держать canonical data.

### Должно быть достигнуто

```text
- mechanical_door, digital_door, powered_gate существуют только как aliases/presets.
- mechanical_key, mechanical_keycard, keycard существуют только как aliases to key_card.
- runtime state хранит canonical values.
- UI display может показывать friendly names, но не меняет gameplay types.
```

### Проверки после PR

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

### Acceptance

```text
- В runtime data нет legacy object_type.
- Старые saved/constructor данные открываются через compatibility normalization.
- Вся новая data создаётся canonical.
```

---

## 7. Финальная проверка всего кода

После завершения всех foundation PR нужна отдельная финальная проверка.

## Final Verification PR / Milestone

### 7.1 Синтаксис

Обязательно:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
```

Godot parser/startup:

```bash
godot --headless --path . --quit
```

Если есть test runner:

```bash
godot --headless --path . -s res://path/to/test_runner.gd
```

### 7.2 Полная contract validation

Проверить:

```text
- object registry validation
- constructor prefab validation
- TASK TEST object validation
- door contract validation
- inventory contract validation
- runtime action validation
- mission goal binding validation
- validation read-only/snapshot-restore validation
```

### 7.3 Manual smoke test

Обязательные сценарии:

```text
1. Start TASK TEST.
2. Output не спамится ошибками.
3. GOAL panel показывает mission objective.
4. Пустая клетка перед Bipob не даёт Action pulse.
5. Fuse pickup идёт в manipulator.
6. Fuse перемещается manipulator ↔ pocket.
7. Key-card pickup идёт в keychain и отображается как K.
8. Key-card не занимает manipulator.
9. Mechanical no_key door открывается/закрывается.
10. Mechanical key_card door открывается key-card при свободном manipulator.
11. Mechanical key_card door не открывается, если manipulator занят.
12. Digital door открывается через digital_key/access_code/terminal по настройке.
13. Powered door открывается/закрывается по power_behavior.
14. Map Constructor palette содержит door presets.
15. Placed constructor door работает в runtime как TASK TEST door.
16. Preset save/load не создаёт unknown object_type.
17. Runtime storage не принимает physical item.
18. Manipulator UI показывает только реальные manipulator slots.
19. Key strip показывает до 6 compact K/empty cells.
20. No stale selected pulse after pickup/action/move/turn.
```

### 7.4 Финальный критерий готовности

Стабилизация считается завершённой только если:

```text
- нет parser errors
- нет endless output errors
- TASK TEST не зависает
- все object/prefab aliases нормализуются
- двери работают через один contract
- key-card работает через keychain
- physical/digital storage separation enforced
- UI отображает backend state, а не placeholder truth
- validation ловит возврат legacy divergence
```

---

## 8. Почему это не должно повториться

После этого плана любые новые объекты/предметы/двери должны добавляться только так:

```text
1. Добавить canonical definition или preset в registry/catalog.
2. Добавить metadata для constructor palette.
3. Добавить normalization/compatibility alias, если нужен legacy support.
4. Добавить action contract, если объект интерактивный.
5. Добавить validation rule.
6. Добавить TASK TEST coverage.
7. Только после этого делать UI display.
```

Запрещено добавлять новый object_type напрямую в UI, TASK TEST или Map Constructor без catalog/registry contract.

---

## 9. Главный итог

Финальная система должна быть не набором костылей, а цепочкой:

```text
Canonical Registry
→ Normalized Runtime Data
→ Generic Runtime Logic
→ View Models
→ UI Display
→ Contract Validation
```

Если это соблюдается, то больше не будет ситуации, где:

```text
в TASK TEST объект есть,
в редакторе его нет,
в runtime он называется иначе,
дверь не открывается,
UI показывает несуществующие слоты,
а баг приходится чинить заново.
```
