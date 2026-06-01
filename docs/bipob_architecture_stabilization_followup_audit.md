# BIPOB — follow-up audit по архитектурной стабилизации

Этот документ дополняет `docs/bipob_architecture_stabilization_plan.md` и фиксирует актуальный статус после серии PR по Map Constructor validation и global configurable archetype system.

Цель документа — держать единый audit/checklist для следующих PR, чтобы не возвращаться к palette variant explosion, hardcoded fixes и непроверенным syntax regressions.

---

## 1. Актуальный статус после последних PR

### 1.1 Уже реализовано / частично реализовано

```text
#745 Fix Map Constructor validation safe Variant conversion
#746 Fix raw_access_type blocker and restore door_type validation
#747 Add global archetype registry and migrate Door to schema-driven Map Constructor
#748 Add Floor archetype to global archetype registry and Map Constructor pipeline
#749 Introduce Wall archetype: External Wall + Wall
```

Текущий положительный сдвиг:

```text
- Map Constructor validation больше не должен падать на raw access_type/digital_key из-за unsafe String(value).
- raw_access_type blocker исправлен.
- door_type validation восстановлена.
- Появился global ARCHETYPE_REGISTRY / archetype-property-schema foundation.
- Door стал schema-driven archetype вместо набора user-facing door variants.
- Floor добавлен как archetype с material/covering/visual_style/state/allowed_states.
- Wall разделён на External Wall и Wall.
- Legacy door/floor/wall ids начали переноситься в hidden compatibility aliases.
```

### 1.2 Что ещё не завершено

```text
- Terminal ещё не мигрирован в один Terminal archetype.
- Item/key/digital placement всё ещё требует отдельного прохода через catalog/archetype contract.
- Door runtime object_type ещё не финализирован: Door уже archetype, но runtime может временно использовать material-named object_type.
- MissionManager всё ещё содержит слишком много constructor/runtime/validation/debug responsibilities.
- Godot parser-level gate пока не является обязательным CI-условием для каждого PR.
```

---

## 2. Новые blocking issues после PR #747–#749

### 2.1 Floor placement regression после Wall PR

PR #748 сделал Floor object archetype и добавил placement branch через metadata:

```gdscript
if String(constructor_preview.get("replaces_tile_with", "")) == "floor":
	placed_tile_type = GridManager.TILE_FLOOR
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
```

После PR #749 эта ветка была заменена на wall-only branch:

```gdscript
if requested_object_group == "wall":
	placed_tile_type = GridManager.TILE_WALL
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
```

Это потенциально ломает Floor placement: configurable Floor может перестать восстанавливать/ставить `GridManager.TILE_FLOOR`.

Ожидаемый fix-only PR:

```gdscript
if String(constructor_preview.get("replaces_tile_with", "")) == "floor":
	placed_tile_type = GridManager.TILE_FLOOR
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
elif requested_object_group == "wall":
	placed_tile_type = GridManager.TILE_WALL
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
```

Acceptance:

```text
- Placing Floor still creates/keeps walkable TILE_FLOOR.
- Placing Wall / External Wall creates TILE_WALL.
- Door placement behavior is unchanged.
- No broad refactor.
```

### 2.2 Floor palette validation was weakened

`validate_constructor_palette_contract()` должен проверять обязательные archetypes независимо от `manager != null`.

Обязательные top-level checks:

```text
- visible_archetypes.has("door")
- visible_archetypes.has("floor")
- visible_archetypes.has("external_wall")
- visible_archetypes.has("wall")
```

Manager-context checks могут дополнять это runtime проверками, но отсутствие manager не должно выключать базовую contract validation.

### 2.3 Quick presets must not appear for configurable archetypes

Configurable archetypes не должны получать quick preset buttons.

Запрещено:

```text
Door quick presets
Wall material quick presets
Floor material/covering quick presets
Terminal quick presets
```

Property schema — единственный пользовательский способ менять варианты.

UI rule:

```gdscript
if not _safe_string(data.get("archetype_id", "")).is_empty():
	# do not render preset buttons
```

Или эквивалентное schema-driven правило:

```text
archetype objects use property panel only; legacy quick presets are hidden.
```

### 2.4 UI labels language regression

В игре все user-facing labels должны быть только на английском.

Недопустимые игровые значения/лейблы:

```text
Floor / Пол
External Wall / Стена внешняя
Wall / Стена
Стальной пол
Стена из усиленной стали
labels_ru
palette_label_ru
display_name_ru
"Steel / Стальной"
"Default / Базовое покрытие"
```

Разрешено в документации/обсуждении на русском, но не в runtime/game UI/code metadata.

Ожидаемый fix-only PR:

```text
Normalize Map Constructor archetype UI labels to English-only
```

Acceptance:

```text
- palette_label values are English only: Door, Floor, External Wall, Wall, Terminal.
- display_name values are English only.
- property labels are English only.
- no labels_ru / palette_label_ru / display_name_ru in game runtime catalogs.
- no mixed labels like "Floor / Пол" or "Steel / Стальной".
- runtime values stay canonical English ids.
```

---

## 3. UI language contract

Этот контракт обязателен для всей игры.

```text
All in-game user-facing labels must be English.
```

Под это попадает:

```text
- Map Constructor palette labels;
- inspector/property labels;
- generated display_name;
- HUD text;
- action labels;
- validation messages shown inside game/dev UI;
- catalog display names;
- metadata display names;
- debug panel labels, если они видны в игре.
```

Запрещено в game code/runtime data:

```text
- Russian labels;
- mixed English/Russian labels;
- *_ru fields used by runtime/game UI;
- localized display names stored in runtime objects;
- Russian property labels inside WorldObjectCatalog/MapConstructor metadata.
```

Runtime values всегда canonical English ids:

```text
door_type = mechanical | digital | powered
material = steel | reinforced_steel | titanium | brick | concrete | grate
access_type = no_key | key_card | digital_key | access_code | terminal
state/status = active | damaged | unpowered | closed | open | locked | etc.
```

Документация может быть на русском, но Codex не должен копировать русские пояснения в игровые labels.

---

## 4. Syntax/parser verification gate

Больше нельзя считать PR полностью проверенным только по grep/static review.

Обязательный минимальный gate для каждого code PR:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
```

Но `godot --headless --path . --quit` может не загрузить каждый script. Нужен отдельный parser gate:

```bash
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Если такого script ещё нет, его нужно добавить отдельным PR.

`parse_all_gd.gd` должен:

```text
- рекурсивно найти все res://scripts/**/*.gd;
- вызвать load(path) для каждого файла;
- вывести список файлов с parse/load errors;
- завершиться с non-zero exit code при любой ошибке;
- не мутировать game state;
- не запускать gameplay scenes.
```

Review status wording:

```text
Static review passed = проверены diff/grep/known risky patterns.
Syntax verified = Godot parser/load gate реально запускался.
Godot unavailable = PR is not fully verified.
```

Если Godot недоступен у Codex, PR body должен явно писать:

```text
Godot parser validation was not executed.
```

И следующий reviewer обязан считать это risk, а не success.

---

## 5. Validation read-only contract

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

Особенно проверять:

```text
- scan/xray validation;
- inventory/tools/modules validation;
- module port validation;
- platform timer validation;
- task test validation;
- map constructor readiness report;
- archetype/palette validation.
```

---

## 6. Global configurable-object contract

Это системное изменение для всей игры, а не door-only / floor-only / wall-only hardcode.

Общее правило:

```text
Map Constructor palette = base archetypes.
Property panel = configurable archetype properties.
Runtime = normalized canonical object data.
HUD/actions/validation/save/load/TASK TEST = read the same normalized contract.
```

Запрещено создавать пользовательские объекты палитры как комбинации параметров:

```text
Digital Steel Door
Titanium Mechanical Door
Brick Wall
Concrete Wall
Reinforced Steel Wall
Steel Floor
Concrete Floor
Grate Floor
Dirty Steel Floor
Water Floor
Door Control Terminal
Class 2 Door Terminal
Damaged Control Terminal
```

Вместо этого:

```text
Door → door_type/material/access_type/power_type/control_type/state/allowed_states
Floor → material/covering/visual_style/state/allowed_states
External Wall → fixed non-configurable archetype
Wall → material
Terminal → terminal_type/controlled_target_type/class/power/control/status/links
Power Source → source_type/output/network/state
Platform → platform_type/timer/trigger/state
Item → item_class/storage_route/state
```

Каждый archetype должен иметь:

```text
- archetype_id
- object_group
- canonical object_type или explicit compatibility runtime object_type
- property_schema
- default data
- display_name generator/template
- validation rules
- state/status sync rules
- hidden compatibility aliases, если нужны для старых данных
```

Все пути создания объектов обязаны проходить через один pipeline:

```text
Catalog/archetype definition
→ default data
→ property overrides
→ normalized runtime object
→ generated display_name
→ derived state/status flags
→ validation
```

Это распространяется на:

```text
- Map Constructor placement;
- property edits;
- prefab kit application;
- room template application;
- patch import;
- TASK TEST construction;
- saved data loading;
- runtime spawning, если он появится позже.
```

---

## 7. Archetype-specific current contracts

### 7.1 Door

Palette:

```text
Door
```

Not palette entries:

```text
Steel Door
Titanium Door
Digital Door
Digital Steel Door
Digital Titanium Door
Mechanical Titanium Door
Energy Door
Powered Gate
```

Schema:

```text
door_type: mechanical | digital | powered
material: steel | reinforced_steel | titanium | energy
access_type: no_key | key_card | digital_key | access_code | terminal
door_class: 1 | 2 | 3
power_type: internal | external | none
control_type: internal | external | terminal
power_behavior: none | opens_when_unpowered | requires_power_to_open
state: closed | open | damaged | jammed | locked | unpowered
allowed_states: closed/open/damaged/jammed/locked/unpowered
required_key_id
required_terminal_id
required_access_code_id
required_digital_key_id
required_manipulator_level
required_connector_level
required_processor_level
```

Display name examples:

```text
Titanium Mechanical Door
Reinforced Steel Digital Door
Energy Powered Door
```

### 7.2 Floor

Palette:

```text
Floor
```

Not palette entries:

```text
Steel Floor
Concrete Floor
Grate Floor
Dirty Floor
Water Floor
Debris Floor
Oil Floor
Permission Floor
```

Schema:

```text
material: steel | concrete | grate
covering: default | dirt | water | debris | oil
visual_style: default | permission
state: normal | damaged
allowed_states: normal/damaged
```

Display name examples:

```text
Steel Floor
Concrete Floor
Grate Floor
```

Covering and visual_style are metadata for now unless gameplay systems already consume them.

### 7.3 External Wall

Palette:

```text
External Wall
```

Fixed archetype:

```text
configurable = false
is_destructible = false
supports_embedded_objects = true
supports_cables = true
blocks_movement = true
blocks_vision = true
```

No material selector. No quick presets.

### 7.4 Wall

Palette:

```text
Wall
```

Schema:

```text
material: brick | concrete | steel | reinforced_steel | titanium | grate | electromagnetic
```

Display name examples:

```text
Brick Wall
Concrete Wall
Steel Wall
Reinforced Steel Wall
Titanium Wall
Grate Wall
Electromagnetic Wall
```

Not palette entries:

```text
Brick Wall
Concrete Wall
Steel Wall
Reinforced Steel Wall
Titanium Wall
Grate Wall
Electromagnetic Wall
```

These names are generated display names only, not separate palette objects.

### 7.5 Terminal

Terminal requirements are documented, but implementation is still pending.

Palette target:

```text
Terminal
```

Not palette entries:

```text
Information Terminal
Control Terminal
Door Control Terminal
Cooling Control Terminal
Platform Control Terminal
Class 1 Terminal
Class 2 Terminal
Class 3 Terminal
Damaged Terminal
Unpowered Terminal
```

Schema target:

```text
terminal_type: information | control
controlled_target_type: none | door | cooling | platform | power | lighting | device
terminal_class: 1 | 2 | 3
power_type: internal | external
control_type: internal | external
status: active | damaged | unpowered | locked | disabled | error
allowed_statuses: active/damaged/unpowered/locked/disabled/error
linked_object_ids: Array[String]
linked_door_ids: Array[String]
linked_cooling_ids: Array[String]
linked_platform_ids: Array[String]
linked_power_ids: Array[String]
linked_lighting_ids: Array[String]
chain_input_ids: Array[String]
chain_output_ids: Array[String]
```

Display name examples:

```text
Information Terminal
Control Terminal
Door Control Terminal
Cooling Control Terminal
Platform Control Terminal
```

Important:

```text
- Do not add enemies/combat.
- Do not expose turret as user-facing controlled_target_type unless separately approved as non-combat device work.
- Existing turret/threat ids remain compatibility-only if present.
```

---

## 8. Global palette validation

Validation должна проверять весь system contract.

Required checks:

```text
- palette generated from archetype registry;
- no variant explosion for one archetype;
- no legacy aliases in user-facing palette;
- no quick presets for configurable archetypes;
- object creation path does not bypass archetype normalization;
- property panel uses selected archetype schema;
- display_name generated from properties;
- runtime values are canonical English ids;
- no Russian/mixed labels in game UI metadata;
- TASK TEST object is reproducible through archetype + properties;
- validation works without manager context for catalog/palette basics;
- validation with manager context checks runtime objects/links.
```

Specific checks:

```text
Door: exactly one Door, no door variants, no door presets.
Floor: exactly one Floor, no material/covering/permission variants.
Wall: exactly one External Wall and one Wall, no material variants.
Terminal: exactly one Terminal once migrated, no information/control/target/class/status variants.
```

---

## 9. Updated PR order

### Fix PR-A — English-only game UI labels

```text
- Remove Russian/mixed labels from runtime/game catalog metadata.
- Replace Floor / Пол with Floor.
- Replace External Wall / Стена внешняя with External Wall.
- Replace Wall / Стена with Wall.
- Replace Steel / Стальной with Steel, etc.
- Remove labels_ru / palette_label_ru / display_name_ru from game-facing data.
- Keep docs Russian where useful, but do not copy Russian labels into game code.
```

### Fix PR-B — Restore Floor placement metadata branch

```text
- Restore replaces_tile_with == floor branch before wall branch.
- Verify placing Floor sets/keeps GridManager.TILE_FLOOR.
- Verify placing Wall/External Wall sets GridManager.TILE_WALL.
```

### Fix PR-C — Strengthen archetype palette validation

```text
- Top-level validation requires door/floor/external_wall/wall.
- Validation does not depend on manager != null for catalog/palette basics.
- Add Terminal requirement once Terminal PR lands.
```

### Fix PR-D — Hide quick preset buttons for archetypes

```text
- Door/Floor/Wall/Terminal use property schema only.
- No preset buttons for non-empty archetype_id.
- Existing legacy presets, if any, are not user-facing.
```

### PR-E — Add Godot parser gate

```text
- Add tools/ci/parse_all_gd.gd or equivalent.
- CI/dev command loads all scripts and fails on parser errors.
- Update PR checklist to require parser gate for code PRs.
```

### PR-F — Terminal as configurable archetype

```text
- One Terminal palette row.
- terminal_type/controlled_target_type/class/power/control/status/links through schema.
- Existing terminal variants hidden as compatibility aliases only.
- Runtime diagnostics/action availability read normalized terminal contract.
```

### PR-G — Item/key/digital placement through catalog/archetype registry

```text
- mechanical_key/mechanical_keycard/keycard normalize to key_card.
- key_card placement creates keychain route.
- digital_key/access_code/data_file use digital storage contract.
- physical items remain physical.
```

### PR-H — Door runtime object_type finalization

```text
- Either object_type=door becomes safe canonical runtime type,
  or compatibility object_type is explicitly hidden behind archetype_id=door.
- No user-facing material-named door object types.
```

---

## 10. PR review checklist

Every code PR:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --quit
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

If Godot is unavailable, reviewer status must say:

```text
Static review only. Godot parser gate was not executed.
```

Extra static checks:

```bash
rg "String\(" scripts/game/map_constructor_validation_service.gd
rg "raw_access_type" scripts/game/map_constructor_validation_service.gd
rg "mission_world_objects\.(append|erase|clear)" scripts/game/map_constructor_validation_service.gd
rg "world_objects_by_cell\[" scripts/game/map_constructor_validation_service.gd
rg "cell_items\[" scripts/game/map_constructor_validation_service.gd
rg "grid_manager\.call\(\"set_tile\"|set_tile\(" scripts/game/map_constructor_validation_service.gd
```

Configurable-object checks:

```bash
rg "Floor /|/ Пол|Стена|Дверь|Терминал|labels_ru|palette_label_ru|display_name_ru" scripts/world scripts/game scripts/ui
rg "digital_.*door|mechanical_.*door|titanium_.*door|steel_.*door" scripts/world scripts/game scripts/ui
rg "Steel Floor|Concrete Floor|Grate Floor|Dirty Floor|Water Floor|Oil Floor|Permission Floor" scripts/world scripts/game scripts/ui
rg "Brick Wall|Concrete Wall|Reinforced Steel Wall|Titanium Wall|Grate Wall|Electromagnetic Wall" scripts/world scripts/game scripts/ui
rg "Information Terminal|Control Terminal|Door Control Terminal|Cooling Control Terminal|Platform Control Terminal" scripts/world scripts/game scripts/ui
rg "archetype_id" scripts/world scripts/game scripts/ui
rg "property_schema" scripts/world scripts/game scripts/ui
rg "allowed_states|allowed_statuses" scripts/world scripts/game scripts/ui
```

Manual smoke checks:

```text
- Palette shows Door, Floor, External Wall, Wall.
- Palette does not show generated variant names as separate entries.
- Game UI labels are English only.
- Door variants are configured only through Door properties.
- Floor variants are configured only through Floor properties.
- Wall material is configured only through Wall properties.
- External Wall has no material selector and no preset buttons.
- Display name updates from properties.
- Floor placement still produces walkable floor tile.
- Wall placement still produces wall tile.
```

---

## 11. Historical note: PR #745 review is closed by PR #746

PR #745 introduced the original safe Variant conversion fix but left `raw_access_type` undefined and weakened `door_type` validation.

PR #746 fixed this by:

```text
- declaring raw_access_type before use;
- validating access_type through WorldObjectCatalogRef.normalize_access_type;
- restoring obj_invalid_door_type validation;
- keeping _safe_string for dynamic Variant fields.
```

Do not reopen this as an active blocker unless the same pattern reappears.
