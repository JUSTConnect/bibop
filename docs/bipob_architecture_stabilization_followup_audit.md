# BIPOB — follow-up audit по архитектурной стабилизации

Этот документ дополняет `docs/bipob_architecture_stabilization_plan.md` и фиксирует актуальный статус после серии PR по Map Constructor validation и global configurable archetype system.

Цель документа — держать единый audit/checklist для следующих PR, чтобы не возвращаться к palette variant explosion, hardcoded fixes и непроверенным syntax regressions.

Последнее обновление: после проверки PR-J1.

---

## 1. Текущий статус PR-A–J1

```text
#750 Fix PR-A — English-only game UI labels
#18d3fbd Fix PR-B — Restore Floor placement metadata branch
#751 Fix PR-C — Strengthen archetype palette validation without manager context
#9fa4b6e Fix PR-D — Hide quick preset buttons for archetypes
#dfefe52 PR-E — Add Godot parser gate script
#752 PR-F — Add Terminal as configurable archetype
#753 Fix PR-G0 — Cleanup Terminal palette validation shim
#754 PR-G — Route Item/Key/Digital placement through archetype catalog
#755 PR-H — Canonicalize Door runtime identity to object_type="door"
#756 PR-J — Enforce Godot parser gate in CI/review flow
#757 Fix PR-J1 — Fix Godot parser gate CI failure
```

### 1.1 Что сейчас считается закрытым

```text
- Door, Floor, External Wall, Wall, Terminal and Item are now represented as base archetype rows.
- Floor placement branch was restored before Wall placement branch.
- Quick preset buttons are hidden for objects with non-empty archetype_id.
- English-only game-facing label rule was applied to catalog/schema/palette metadata.
- Terminal archetype exists with terminal_type, controlled_target_type, terminal_class, power_type, control_type, status, allowed_statuses and linked_* fields.
- The temporary visible_archetypes.gd shim was removed by PR-G0; Terminal palette validation now uses archetype_counts.
- Item/key/digital placement now routes through WorldObjectCatalog and normalize_item_contract.
- Legacy item ids mechanical_key/mechanical_keycard/keycard/key_card/digital_key/access_code/data_file are hidden compatibility aliases, not user-facing palette rows.
- Door runtime identity is canonical: archetype_id=door, object_group=door, object_type=door.
- Legacy door ids are hidden compatibility inputs and normalize to canonical Door data.
- Godot Parser Gate is CI-enforced and currently green.
```

### 1.2 Что сейчас не считается полностью закрытым

```text
- Terminal links/status/action availability need gameplay smoke testing.
- Item pickup/inventory/storage flow needs gameplay smoke testing after the one-Item-row migration.
- Door/key/power/control interactions need gameplay smoke testing after object_type="door" finalization.
- Fuse, Repair Kit, Reinforcement, Power Cable Reel and modules are no longer emitted as generic item OBJECT_LIBRARY palette rows; if they must remain placeable, they need their own archetype/catalog contracts.
```

---

## 2. Review result по PR-A–J1

### 2.1 PR-A — English-only game UI labels

Status: accepted with caveat.

```text
- Russian/mixed labels were removed from game-facing catalog/schema/palette metadata.
- Forbidden fields such as labels_ru, palette_label_ru and display_name_ru should no longer appear in scripts/world, scripts/game, scripts/ui.
- Godot CLI was not run in Codex environment.
```

Contract remains active:

```text
All in-game user-facing labels must be English only.
Russian text is allowed in docs/discussion only.
```

### 2.2 PR-B — Restore Floor placement metadata branch

Status: accepted.

Required placement priority:

```gdscript
if String(constructor_preview.get("replaces_tile_with", "")) == "floor":
	placed_tile_type = GridManager.TILE_FLOOR
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
elif requested_object_group == "wall":
	placed_tile_type = GridManager.TILE_WALL
	manager.grid_manager.call("set_tile", cell, placed_tile_type)
```

### 2.3 PR-C — Stronger archetype palette validation

Status: accepted after PR-G0 cleanup.

```text
- Catalog-level validation counts required archetypes through archetype_counts.
- Door/Floor/External Wall/Wall required-row checks moved out of manager-only context.
- Floor schema validation moved out of manager-only context.
- Terminal check was later corrected to use archetype_counts.
- Item check was added by PR-G.
```

Current target contract:

```gdscript
var required_archetype_warning_ids: Dictionary = {
	"door":"constructor_palette_requires_exactly_one_door",
	"floor":"constructor_palette_requires_exactly_one_floor",
	"external_wall":"constructor_palette_requires_exactly_one_external_wall",
	"wall":"constructor_palette_requires_exactly_one_wall",
	"terminal":"constructor_palette_requires_exactly_one_terminal",
	"item":"constructor_palette_requires_exactly_one_item"
}
```

### 2.4 PR-D — Hide quick preset buttons for archetypes

Status: accepted.

```gdscript
var object_archetype_id: String = ui._safe_ui_string(data.get("archetype_id", "")).strip_edges()
if object_is_configurable and object_archetype_id.is_empty():
	ui._add_preset_buttons(configurable, entity_kind, entity_id)
```

### 2.5 PR-E / PR-J / PR-J1 — Godot parser gate

Status: accepted and CI-enforced.

Files:

```text
tools/ci/parse_all_gd.gd
.github/workflows/godot-parser-gate.yml
```

Workflow behavior:

```text
- Runs on pull_request.
- Runs on push to main.
- Installs Python.
- Installs pinned Godot 4.6.3 through chickensoft-games/setup-godot@v2.
- Runs static checks.
- Runs Godot import smoke with --import.
- Runs GDScript parser/load gate.
```

Exact CI command list:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Required policy:

```text
No code PR is fully verified unless this parser/load gate ran successfully in CI or locally.
Gameplay/runtime smoke tests remain separate from parser/load validation.
```

### 2.6 PR-F — Terminal as configurable archetype

Status: accepted by static review; runtime smoke still required.

```text
- Terminal archetype exists.
- Terminal property schema exists.
- Terminal generated display name is based on terminal_type + controlled_target_type.
- Legacy terminal aliases exist as compatibility mappings.
- Constructor palette should expose one Terminal row, not terminal variants.
```

### 2.7 PR-G0 — Cleanup Terminal palette validation shim

Status: accepted.

```text
- Removed temporary scripts/game/visible_archetypes.gd.
- Replaced visible_archetypes.has("terminal") with archetype_counts.has("terminal").
- Added terminal to required_archetype_warning_ids.
- Kept visible_floor_prefabs == ["floor"] check.
```

### 2.8 PR-G — Item/key/digital placement through catalog/archetype registry

Status: accepted by static review; runtime smoke still required.

```text
- Added Item archetype with item_class/storage_route/state/allowed_states/linked_door_id/payload/access_code fields.
- Added canonical item classes: physical_item, key_card, digital_key, access_code, data_file.
- Added canonical storage routes: pocket, keychain, digital_buffer, digital_storage.
- Added legacy item alias mapping for mechanical_key, mechanical_keycard, keycard, key_card, digital_key, access_code, data_file.
- Map Constructor item placement now uses WorldObjectCatalog.create_world_object/create_archetype_object and normalize_item_contract.
- add_item_at_cell normalizes item data before storing it in cell_items and mission_world_objects.
- TASK TEST key/digital items now use Item archetype + item_class overrides.
- Item validation checks generated display_name, storage routing, and legacy key values.
```

Important caveat:

```text
- get_constructor_palette_rows skips all OBJECT_LIBRARY rows with group == item.
- This matches the one-Item-row direction.
- Fuse, Repair Kit, Reinforcement, modules and similar utility items need dedicated archetype/catalog contracts if they should remain placeable in Map Constructor.
```

### 2.9 PR-H — Door runtime object_type finalization

Status: accepted by static review; runtime smoke still required.

```text
- Door archetype now has object_type="door".
- Door runtime contract is canonicalized to archetype_id=door, object_group=door, object_type=door.
- Legacy material/type door ids remain hidden compatibility inputs.
- Legacy door aliases normalize to canonical Door data.
- Door display_name is generated from material + door_type.
- TASK TEST door entries were migrated from steel_door/energy_door/etc. to type="door" plus property overrides.
- Power/control/interaction logic was adjusted to read normalized Door properties instead of material-named runtime object_type where needed.
- Validation catches non-canonical Door object_type/object_group, generated display name drift, derived state flag drift, and no_key locked/key drift.
```

---

## 3. Current blockers and next required validation

### Blocker 1 — Runtime smoke tests

Parser gate is green in CI, but it does not prove gameplay behavior.

Manual checks:

```text
- Palette shows Door, Floor, External Wall, Wall, Terminal, Item.
- Palette does not show generated variant names as separate entries.
- Game UI labels are English only.
- Door variants are configured only through Door properties.
- Floor variants are configured only through Floor properties.
- Wall material is configured only through Wall properties.
- Terminal variants are configured only through Terminal properties.
- Item variants are configured only through Item properties.
- External Wall has no material selector and no preset buttons.
- Display name updates from properties.
- Floor placement still produces walkable floor tile.
- Wall placement still produces wall tile.
- Door placement produces object_type=door.
- Terminal placement produces normalized runtime object and does not crash validation.
- Item placement produces normalized runtime item and does not crash validation.
- Key Card pickup/usage works for key-card doors.
- Digital Key/Access Code route to digital storage.
- Powered Door power behavior works after power changes.
```

### Blocker 2 — Utility item placement decision

```text
Power Cable Reel, Fuse, Repair Kit, Reinforcement and module-like objects used to be raw OBJECT_LIBRARY item rows.
After PR-G they must not return as raw generic item palette rows.
If they are still needed as Map Constructor placeable objects, they need dedicated archetypes and normalization contracts.
```

---

## 4. UI language contract

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
item_class = physical_item | key_card | digital_key | access_code | data_file
state/status = active | damaged | unpowered | closed | open | locked | etc.
```

Документация может быть на русском, но Codex не должен копировать русские пояснения в игровые labels.

---

## 5. Syntax/parser verification gate

Обязательный минимальный gate для каждого code PR:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

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
Syntax verified = Godot parser/load gate реально запускался и зелёный.
Gameplay verified = ручной/автоматизированный runtime smoke реально выполнен.
```

---

## 6. Validation read-only contract

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

---

## 7. Global configurable-object contract

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
Key Card
Digital Key
Access Code
Data File
Physical Item
```

Вместо этого:

```text
Door → door_type/material/access_type/power_type/control_type/state/allowed_states
Floor → material/covering/visual_style/state/allowed_states
External Wall → fixed non-configurable archetype
Wall → material
Terminal → terminal_type/controlled_target_type/class/power/control/status/links
Item → item_class/storage_route/state/linked_door_id/payload
Power Source → source_type/output/network/state
Platform → platform_type/timer/trigger/state
Utility items → dedicated archetype contracts if still needed as placeable constructor objects
```

---

## 8. Archetype-specific current contracts

### 8.1 Door

```text
Palette: Door
Canonical runtime: archetype_id=door, object_group=door, object_type=door
Schema: door_type/material/access_type/door_class/power_type/control_type/power_behavior/state/allowed_states
Display name: {Material Label} {Door Type Label} Door
```

Hidden compatibility aliases:

```text
steel_door, reinforced_steel_door, titanium_door, energy_door, grid_door,
mechanical_door, digital_door, powered_gate,
mechanical_steel_door, mechanical_reinforced_steel_door, mechanical_titanium_door, mechanical_energy_door,
digital_steel_door, digital_reinforced_steel_door, digital_titanium_door, digital_energy_door,
powered_steel_door, powered_reinforced_steel_door, powered_titanium_door, powered_energy_door
```

### 8.2 Floor

```text
Palette: Floor
Schema: material/covering/visual_style/state/allowed_states
Display name examples: Steel Floor, Concrete Floor, Grate Floor
```

### 8.3 External Wall

```text
Palette: External Wall
Fixed: configurable=false, is_destructible=false, supports_embedded_objects=true, supports_cables=true, blocks_movement=true, blocks_vision=true
```

### 8.4 Wall

```text
Palette: Wall
Schema: material = brick | concrete | steel | reinforced_steel | titanium | grate | electromagnetic
Display name examples are generated only, not separate palette objects.
```

### 8.5 Terminal

```text
Palette: Terminal
Schema: terminal_type/controlled_target_type/terminal_class/power_type/control_type/status/allowed_statuses/links
Display name examples: Information Terminal, Control Terminal, Door Control Terminal
```

Important:

```text
- Do not add enemies/combat.
- Do not expose turret as user-facing controlled_target_type unless separately approved as non-combat device work.
- Existing turret/threat ids remain compatibility-only if present.
```

### 8.6 Item

```text
Palette: Item
Schema: item_class/storage_route/state/allowed_states/linked_door_id/payload_id/access_code
```

Canonical routing:

```text
physical_item -> physical, pocket, Physical Item
key_card -> physical, keychain, Key Card
digital_key -> digital, digital_storage, Digital Key
access_code -> digital, digital_storage, Access Code
data_file -> digital, digital_storage, Data File
```

Hidden compatibility aliases:

```text
mechanical_key -> key_card
mechanical_keycard -> key_card
keycard -> key_card
key_card -> key_card
digital_key -> digital_key
access_code -> access_code
data_file -> data_file
```

Important caveat:

```text
Fuse, Repair Kit, Reinforcement, Power Cable Reel and modules are not covered by the Item archetype contract yet.
They should not reappear as raw item palette rows; add dedicated archetype support if they must be placeable.
```

---

## 9. Next PR order

### PR-I — Utility item archetypes if needed

```text
- Decide whether Fuse, Repair Kit, Reinforcement, Power Cable Reel, modules and cable reel-like items should be placeable.
- If yes, add dedicated archetype/catalog contracts instead of restoring raw OBJECT_LIBRARY item rows.
- Preserve pickup/inventory behavior.
```

### PR-K — Runtime smoke validation pass

```text
- Run local gameplay smoke checks for Map Constructor palette and property panels.
- Smoke test Door/Terminal/Item runtime interactions.
- Record results in this audit or a dedicated smoke report.
```

---

## 10. PR review checklist

Every code PR:

```bash
git diff --check
python tools/check_gdscript_safety_patterns.py
python tools/check_map_constructor_sections.py
godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
```

Extra static checks:

```bash
rg "String\(" scripts/game/map_constructor_validation_service.gd
rg "raw_access_type" scripts/game/map_constructor_validation_service.gd
rg "mission_world_objects\.(append|erase|clear)" scripts/game/map_constructor_validation_service.gd
rg "world_objects_by_cell\[" scripts/game/map_constructor_validation_service.gd
rg "cell_items\[" scripts/game/map_constructor_validation_service.gd
rg "grid_manager\.call\(\"set_tile\"|set_tile\(" scripts/game/map_constructor_validation_service.gd
rg "visible_archetypes" scripts/game scripts/world scripts/ui
```

Configurable-object checks:

```bash
rg "Floor /|/ Пол|Стена|Дверь|Терминал|labels_ru|palette_label_ru|display_name_ru" scripts/world scripts/game scripts/ui
rg "object_type.*steel_door|object_type.*reinforced_steel_door|object_type.*titanium_door|object_type.*energy_door|object_type.*powered_gate" scripts/world scripts/game scripts/ui
rg "Steel Floor|Concrete Floor|Grate Floor|Dirty Floor|Water Floor|Oil Floor|Permission Floor" scripts/world scripts/game scripts/ui
rg "Brick Wall|Concrete Wall|Reinforced Steel Wall|Titanium Wall|Grate Wall|Electromagnetic Wall" scripts/world scripts/game scripts/ui
rg "Information Terminal|Control Terminal|Door Control Terminal|Cooling Control Terminal|Platform Control Terminal" scripts/world scripts/game scripts/ui
rg "Key Card|Digital Key|Access Code|Data File|Physical Item" scripts/world scripts/game scripts/ui
rg "mechanical_key|mechanical_keycard|keycard" scripts/world scripts/game scripts/ui
rg "archetype_id" scripts/world scripts/game scripts/ui
rg "property_schema" scripts/world scripts/game scripts/ui
rg "allowed_states|allowed_statuses" scripts/world scripts/game scripts/ui
```

Manual smoke checks:

```text
- Palette shows Door, Floor, External Wall, Wall, Terminal, Item.
- Palette does not show generated variant names as separate entries.
- Game UI labels are English only.
- Door variants are configured only through Door properties.
- Floor variants are configured only through Floor properties.
- Wall material is configured only through Wall properties.
- Terminal variants are configured only through Terminal properties.
- Item variants are configured only through Item properties.
- External Wall has no material selector and no preset buttons.
- Display name updates from properties.
- Floor placement still produces walkable floor tile.
- Wall placement still produces wall tile.
- Door placement produces object_type=door.
- Terminal placement produces normalized runtime object and does not crash validation.
- Item placement produces normalized runtime item and does not crash validation.
- Key Card pickup/usage works for key-card doors.
- Digital Key/Access Code route to digital storage.
- Powered Door power behavior works after power changes.
```

---

## 11. Historical notes

### PR #745 review is closed by PR #746

PR #745 introduced the original safe Variant conversion fix but left `raw_access_type` undefined and weakened `door_type` validation.

PR #746 fixed this by:

```text
- declaring raw_access_type before use;
- validating access_type through WorldObjectCatalogRef.normalize_access_type;
- restoring obj_invalid_door_type validation;
- keeping _safe_string for dynamic Variant fields.
```

Do not reopen this as an active blocker unless the same pattern reappears.

### Emergency update note

During the manual fix after PR-F review, there was an accidental truncated update attempt to `scripts/game/map_constructor_validation_service.gd`. It was immediately restored through commit `e23cf6cc0dc0901435900a8add3e866a7b5e244a`, then an emergency helper commit `5f3e171c46e81b758c23ea4f5592cd7dcfccb063` was added. PR-G0 later removed the helper and replaced the validation check with archetype_counts.
