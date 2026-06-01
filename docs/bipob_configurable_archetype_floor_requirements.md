# BIPOB — configurable Floor archetype requirements

Этот документ дополняет:

- `docs/bipob_architecture_stabilization_plan.md`
- `docs/bipob_architecture_stabilization_followup_audit.md`

Он фиксирует требования к полу как части глобальной configurable-object/archetype системы.

---

## 1. Главный принцип

Пол не должен размножаться в палитре как набор вариантов.

Запрещённый подход:

```text
Steel Floor
Concrete Floor
Grate Floor
Dirty Steel Floor
Wet Concrete Floor
Oil Steel Floor
Debris Grate Floor
Permission Floor
```

Правильный подход:

```text
Map Constructor palette: Floor / Пол
Property panel: material, covering, visual_style, future gameplay flags
Runtime: normalized canonical floor data
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

В палитре должен быть ровно один пользовательский объект пола:

```text
Floor / Пол
```

Не создавать и не показывать отдельные entries:

```text
Steel Floor
Concrete Floor
Grate Floor
Dirty Floor
Water Floor
Debris Floor
Oil Floor
Permission Floor
Steel Dirty Floor
Concrete Water Floor
```

Quick presets для пола не нужны.

Все варианты пола создаются через настройки выбранного объекта `Floor`.

---

## 3. Floor archetype

Canonical archetype:

```text
archetype_id = floor
object_group = floor
object_type = floor
```

Runtime canonical data example:

```gdscript
{
	"archetype_id": "floor",
	"object_group": "floor",
	"object_type": "floor",
	"material": "steel",
	"covering": "default",
	"visual_style": "default",
	"state": "normal",
	"allowed_states": ["normal", "damaged"],
	"display_name": "Steel Floor",
	"blocks_movement": false,
	"blocks_vision": false,
	"configurable": true
}
```

Runtime values должны быть canonical English ids. Русские названия используются только как display labels.

---

## 4. Floor property schema

### 4.1 Material

Пол должен иметь настраиваемый материал:

```text
material: steel | concrete | grate
```

Default:

```text
material = steel
```

Display labels:

```text
steel → Steel / Стальной
concrete → Concrete / Бетонный
grate → Grate / Решётка
```

Generated display name:

```text
steel → Steel Floor / Стальной пол
concrete → Concrete Floor / Бетонный пол
grate → Grate Floor / Пол из решётки
```

Название пола формируется из материала. Например:

```text
material = steel
→ Стальной пол
```

### 4.2 Covering

Пол должен иметь поле покрытия:

```text
covering: default | dirt | water | debris | oil
```

Default:

```text
covering = default
```

Display labels:

```text
default → Default / Базовое покрытие
dirt → Dirt / Грязь
water → Water / Вода
debris → Debris / Обломки
oil → Oil / Масло
```

Важно:

```text
- На текущем этапе gameplay-логика покрытия не обязательна.
- Покрытия могут быть доступны в property panel, но пока могут ничего не делать.
- Основное рабочее покрытие сейчас — default / базовое.
- Покрытие не должно создавать отдельные palette entries.
```

В будущем coverage может влиять на:

```text
- movement cost;
- slip/chance;
- noise;
- visibility/readability;
- fire/electric/water interactions;
- cleanup/repair actions.
```

Но эти эффекты не входят в первый PR, если их нет в текущей системе.

### 4.3 Visual style

Пол должен иметь поле визуального стиля:

```text
visual_style: default | permission
```

Default:

```text
visual_style = default
```

Display labels:

```text
default → Default / Обычный
permission → Permission Tile / Тайл разрешения
```

Важно:

```text
- Permission visual style пока может быть только metadata/placeholder.
- Эта логика сейчас не актуальна как gameplay, но должна быть заложена в contract, чтобы не забыть реализовать позже.
- Permission tile не должен быть отдельным объектом палитры.
- Permission tile не должен быть quick preset.
```

В будущем `visual_style = permission` может использоваться для:

```text
- визуального обозначения разрешённых зон;
- подсказок маршрута;
- robot-only markings;
- access/movement restrictions;
- editor overlays.
```

---

## 5. Display name generation

Display name должен генерироваться из property values, а не храниться как набор статических prefab variants.

Base rule:

```text
material_label + " Floor"
```

English examples:

```text
material = steel → Steel Floor
material = concrete → Concrete Floor
material = grate → Grate Floor
```

Russian examples:

```text
material = steel → Стальной пол
material = concrete → Бетонный пол
material = grate → Пол из решётки
```

Covering может отображаться дополнительно в property panel или вторичной строке, но не должен создавать отдельный основной name, пока нет утверждённого UX-правила.

Допустимый UI вариант:

```text
Стальной пол
Покрытие: Грязь
```

Не нужно превращать это в отдельный объект:

```text
Грязный стальной пол
```

---

## 6. Global system integration

Floor archetype обязан использовать тот же pipeline, что Door и Wall:

```text
Archetype definition
→ property_schema
→ palette row
→ placement default data
→ property overrides
→ normalized runtime floor data
→ display name generation
→ validation
→ save/load
→ TASK TEST
```

Это должно применяться во всей игре, включая:

```text
- Map Constructor palette;
- property panel выбранного объекта;
- object creation service;
- room templates;
- prefab kits, если они используют floor;
- patch import;
- TASK TEST construction;
- runtime validation;
- save/load compatibility;
- HUD/debug display, если floor отображается там.
```

Нельзя делать отдельную floor-only ветку логики, которая обходит archetype registry.

---

## 7. Compatibility

Если в старых данных уже есть floor-like ids, они должны стать hidden compatibility aliases.

Примеры возможных legacy ids:

```text
steel_floor
concrete_floor
grate_floor
permission_floor
water_floor
oil_floor
dirty_floor
debris_floor
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

## 8. Validation requirements

Global palette validation должна проверять Floor как часть общей archetype системы.

Floor-specific validation:

```text
- exactly one user-facing Floor entry exists;
- no separate floor material variants in palette;
- no separate floor covering variants in palette;
- no permission floor as separate palette object;
- Floor has property_schema;
- material is one of: steel, concrete, grate;
- covering is one of: default, dirt, water, debris, oil;
- visual_style is one of: default, permission;
- display_name can be generated from material;
- runtime values are canonical English ids;
- localized labels are display-only;
- TASK TEST floor objects are reproducible through Floor archetype + properties;
- legacy floor ids are hidden load/import aliases only.
```

Global validation must also catch if someone reintroduces:

```text
Steel Floor
Concrete Floor
Grate Floor
Dirty Floor
Water Floor
Oil Floor
Permission Floor
```

as palette rows or quick presets.

---

## 9. Acceptance

```text
- Map Constructor palette shows one Floor / Пол object.
- User can select Floor and configure material.
- User can create Стальной пол by setting material = steel.
- User can create Бетонный пол by setting material = concrete.
- User can create Пол из решётки by setting material = grate.
- User can select covering = default/dirt/water/debris/oil.
- covering exists in data contract even if only default has real gameplay meaning now.
- User can select visual_style = default/permission.
- permission visual style exists in data contract even if gameplay is not implemented now.
- No floor material variants appear in palette.
- No floor covering variants appear in palette.
- No quick presets for floor variants.
- Floor creation uses the same archetype/property/normalization pipeline as Door and Wall.
- Validation catches duplicated floor variants.
```

---

## 10. Codex prompt block

```text
PR title: Add Floor to global configurable archetype system

Goal:
Add Floor as a first-class configurable archetype in the global archetype/property schema system. This must affect the whole game pipeline, especially the Map Constructor palette.

Core rule:
Palette shows one Floor object. Material, covering, and visual style are configured through properties. Do not create floor presets or duplicated palette variants.

Palette:
- Show exactly one user-facing Floor / Пол entry.
- Do not show Steel Floor, Concrete Floor, Grate Floor, Water Floor, Oil Floor, Dirty Floor, Debris Floor, or Permission Floor as separate entries.
- Do not add quick presets.

Floor runtime contract:
{
    "archetype_id": "floor",
    "object_group": "floor",
    "object_type": "floor",
    "material": "steel",
    "covering": "default",
    "visual_style": "default",
    "state": "normal",
    "allowed_states": ["normal", "damaged"],
    "display_name": "Steel Floor",
    "blocks_movement": false,
    "blocks_vision": false,
    "configurable": true
}

Property schema:
- material: steel | concrete | grate, default steel
- covering: default | dirt | water | debris | oil, default default
- visual_style: default | permission, default default

Display name:
Generate from material:
- steel -> Steel Floor / Стальной пол
- concrete -> Concrete Floor / Бетонный пол
- grate -> Grate Floor / Пол из решётки

Covering:
- default is the main working covering now.
- dirt/water/debris/oil may exist as selectable metadata but do not need gameplay effects in this PR.
- Do not create palette variants for coverings.

Visual style:
- default is normal floor.
- permission is a future permission tile visual style placeholder.
- It may have no gameplay effect now.
- Do not create a separate Permission Floor palette object.

Integration:
Floor must use the same global pipeline as Door and Wall:
Archetype definition -> property_schema -> palette row -> placement default data -> property overrides -> normalized runtime data -> generated display_name -> validation -> save/load -> TASK TEST.

Compatibility:
Legacy ids like steel_floor, concrete_floor, grate_floor, permission_floor, water_floor, oil_floor, dirty_floor, debris_floor must be hidden load/import aliases only if they exist. They must not appear in user-facing palette, quick presets, editor search, prefab kit selectable variants, or room template selectable variants.

Validation:
Add/update validation so it catches:
- more than one user-facing Floor palette row;
- floor material variants in palette;
- floor covering variants in palette;
- permission floor as separate palette object;
- invalid material;
- invalid covering;
- invalid visual_style;
- display_name not generated from material;
- TASK TEST floor object not reproducible through Floor archetype + properties.

Do not:
- change project.godot;
- add enemies/combat;
- add unrelated mission content;
- add quick presets;
- create floor-only hardcode that bypasses archetype registry;
- use localized labels as runtime values.

Acceptance:
- Map Constructor palette shows one Floor / Пол.
- Floor material can be steel/concrete/grate.
- Floor covering can be default/dirt/water/debris/oil.
- Floor visual_style can be default/permission.
- Display name updates from material.
- No duplicated floor variants in palette.
- Floor is part of the global configurable archetype system and works through the same pipeline as Door and Wall.
```
