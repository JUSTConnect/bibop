# Bipob — план разбивки кода на логические блоки

## 1. Цель

Цель рефакторинга — уменьшить размер и связность крупных файлов, прежде всего `scripts/ui/game_ui.gd`, чтобы дальнейшие задачи для Codex, code review и ручной debugging стали безопаснее и предсказуемее.

Итоговая цель не в том, чтобы “переписать всё заново”, а в том, чтобы:

- разделить UI, runtime logic, validation, world systems и catalog/schema logic по отдельным файлам;
- уменьшить риск случайных out-of-scope изменений;
- облегчить Codex анализ: один PR должен менять ограниченный набор файлов и одну логическую область;
- сохранить совместимость старых карт и runtime state;
- не менять gameplay behavior во время первых extract/refactor PR;
- дать стабильную архитектурную основу для последующих PR по power system, Map Constructor, interactions, terminals, keys, doors и cable reel.

## 2. Главная проблема сейчас

`scripts/ui/game_ui.gd` стал слишком большим и выполняет слишком много ролей одновременно:

- root HUD orchestration;
- runtime object HUD;
- Map Constructor UI;
- Map Constructor inspector;
- property editors;
- link pickers;
- validation/warnings rendering;
- floor/wall material UI;
- placement/move/duplicate/delete callbacks;
- runtime refresh calls;
- direct calls into `mission_manager_runtime`, `field_runtime` and other systems.

Из-за этого один маленький PR формально может менять один файл, но по смыслу затрагивать сразу несколько подсистем. Это усложняет review и увеличивает вероятность, что Codex исправит UI-симптом, но не исправит runtime logic.

## 3. Основные правила рефакторинга

### 3.1. Small focused PR

Каждый PR должен иметь одну цель:

- только extraction без изменения поведения;
- только inspector structure;
- только validation display;
- только power runtime fix;
- только cable reel logic;
- только tests/static checks.

Нельзя смешивать в одном PR:

- перенос файлов и gameplay fixes;
- UI refactor и renderer changes;
- Map Constructor layout и runtime interaction logic;
- power system fixes и unrelated Box UI/module icon visuals.

### 3.2. Сначала extraction, потом logic fixes

Правильный порядок:

1. Сначала вынести большие логические блоки в отдельные файлы без изменения поведения.
2. После этого чинить runtime bugs в маленьких PR.
3. Потом добавлять новые фичи поверх уже разделённой структуры.

### 3.3. Безопасность Godot/GDScript

Во всех новых файлах:

- избегать `:=`, если тип может быть `Variant` или ambiguous;
- явно типизировать UI nodes и Dictionary/Array там, где это важно;
- использовать `get_node_or_null` для optional nodes;
- проверять `mission_manager_runtime != null` перед вызовами;
- проверять `has_method(...)` перед dynamic calls;
- использовать safe helpers для `Dictionary`, `Array`, `String`, `Vector2i`;
- не делать прямой `Dictionary(value)`, если `value` может быть не Dictionary;
- не делать прямой `Array(value)`, если `value` может быть не Array;
- guard для object IDs, cell lookups, wall side, indexes, target IDs;
- runtime actions должны fail safely: показать hint/warning, но не crash.

### 3.4. Совместимость старых карт

Новые поля должны иметь safe defaults:

- отсутствующее поле не должно ломать inspector;
- старые doors/terminals/power objects должны открываться в inspector;
- старые runtime states должны продолжать загружаться;
- migration должна быть ленивой или optional, без принудительной поломки старых данных.

## 4. Целевая структура файлов

Ниже структура, к которой нужно постепенно прийти. Названия можно слегка адаптировать под стиль проекта, но смысловые границы должны сохраниться.

```text
scripts/
  ui/
    game_ui.gd
      # Root HUD orchestrator only.
      # Создаёт основные панели, делегирует Map Constructor/runtime HUD в отдельные компоненты.

    map_constructor/
      map_constructor_panel.gd
        # Главный orchestrator Map Constructor UI.
        # Координирует tabs, object palette, inspector, overlays.

      map_constructor_tabs.gd
        # Верхние вкладки Map settings / Objects & filters / Inspector / Validation.

      map_constructor_object_palette.gd
        # Список prefab/object groups, previews, filters, search.

      map_constructor_inspector.gd
        # Единый inspector выбранного объекта.
        # Строго отвечает за порядок секций и сборку блоков.

      map_constructor_inspector_sections.gd
        # Builders для 8 секций:
        # 1. Object Identity
        # 2. Current Status
        # 3. Placement
        # 4. Configurable Parameters
        # 5. Links
        # 6. Warnings
        # 7. Floor Coverage
        # 8. Wall Coverage

      map_constructor_property_controls.gd
        # Text/bool/enum property rows, presets, description editor.

      map_constructor_link_controls.gd
        # Key-door, terminal, power, control, physical/logical link pickers.

      map_constructor_validation_view.gd
        # Missing links, warnings, capacity issues, physical path warnings.

      map_constructor_floor_wall_controls.gd
        # Floor coverage, wall coverage, wall material, wall-mounted side editing.

      map_constructor_actions.gd
        # Move, duplicate, delete, place object, apply prefab actions.

      map_constructor_ui_safe.gd
        # Safe UI conversion helpers:
        # safe dictionary/array/string/vector/cell/index helpers.

  ui/runtime/
    runtime_hud.gd
      # Runtime HUD orchestrator.

    runtime_object_hud.gd
      # RMB inspect HUD for doors, terminals, power devices, items.

    runtime_interaction_panel.gd
      # Action rows: Unlock/Open/Close/Repair/Use/etc.

    runtime_notifications.gd
      # Top notifications, hint throttling, no-spam behavior.

  game/
    mission_manager.gd
      # Mission/map state API, constructor mutations, validation facade.

    map_constructor_service.gd
      # Optional future extraction from mission_manager:
      # object placement, move, duplicate, delete, property update.

    map_constructor_validation_service.gd
      # Optional future extraction:
      # link validation, missing connections, capacity warnings.

  world/
    power_system.gd
      # Pure power graph/runtime recalculation.

    power_device_logic.gd
      # Optional future extraction:
      # switches, fuse blocks, outlets, cable reel, light logic.

    interaction_system.gd
      # Runtime user actions: repair, open, unlock, use, fail-safe behavior.

    world_object_catalog.gd
      # Object schemas, prefab defaults, compatibility defaults.

  bipob/
    bipob_controller.gd
      # High-level runtime coordination only.
```

## 5. Целевая структура Map Constructor inspector

Когда выбран объект на клетке, inspector должен всегда использовать один порядок блоков:

1. **Object Identity**
   - object name;
   - description;
   - object type;
   - object class;
   - object ID, если нужен для debug.

2. **Current Status**
   - только read-only observation;
   - current runtime/world state;
   - visual state;
   - power/control/key status;
   - никаких editable fields.

3. **Placement**
   - cell;
   - placement mode;
   - grounding;
   - move;
   - duplicate;
   - delete;
   - object map placement only.

4. **Configurable Parameters**
   - editable object-specific parameters;
   - door parameters;
   - terminal parameters;
   - power mode/source;
   - control mode/source;
   - light/switch/fuse/cable reel fields;
   - editable state override, если нужен, но с явной подписью.

5. **Links**
   - physical links;
   - logical links;
   - power links;
   - control links;
   - key links;
   - terminal links;
   - linked targets.

6. **Warnings**
   - missing links;
   - broken connections;
   - capacity issues;
   - invalid physical/logical path;
   - validation warnings;
   - не дублировать то, что уже показано в Links.

7. **Floor Coverage**
   - floor/tile target;
   - floor material;
   - coating;
   - editable floor settings.

8. **Wall Coverage**
   - wall type/material;
   - wall-mounted anchor;
   - attached wall cell;
   - wall side;
   - editable wall settings.

## 6. План PR по этапам

### PR 1 — Audit and guardrail baseline

**Цель:** зафиксировать текущее состояние и добавить минимальные guardrails перед большим split.

**Разрешённые файлы:**

```text
README или docs только при необходимости
scripts/ui/game_ui.gd
```

**Что сделать:**

- Добавить комментарии-разделители в `game_ui.gd` вокруг крупных областей:
  - Runtime HUD;
  - Map Constructor root;
  - Map Constructor inspector;
  - property controls;
  - link controls;
  - floor/wall controls;
  - validation display.
- Не менять поведение.
- Найти функции, которые нужно выносить в следующих PR.
- Добавить TODO markers только если они не засоряют файл.

**Acceptance criteria:**

- Gameplay не изменился.
- Inspector работает как до PR.
- Нет out-of-scope изменений.
- Diff минимальный.

---

### PR 2 — Extract safe UI helpers

**Цель:** вынести safe conversion helpers из `game_ui.gd`.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_ui_safe.gd
```

**Что вынести:**

- safe dictionary helper;
- safe array helper;
- safe string helper, если он локален для inspector;
- safe Vector2i/cell helper;
- safe index helper;
- helper для `has_method` guarded calls, если это не усложняет код.

**Что нельзя делать:**

- Нельзя менять inspector layout.
- Нельзя менять gameplay logic.
- Нельзя чинить power/runtime bugs в этом PR.

**Acceptance criteria:**

- `game_ui.gd` использует helper module.
- Нет прямых unsafe `Dictionary(value)` / `Array(value)` в Map Constructor UI paths.
- Старые карты не ломаются при missing fields.

---

### PR 3 — Extract property controls

**Цель:** вынести generic UI controls для редактирования свойств.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_property_controls.gd
```

**Что вынести:**

- `_create_property_row` или map-constructor-specific wrapper;
- text property editor;
- bool property editor;
- enum property editor;
- description editor;
- preset buttons.

**Acceptance criteria:**

- Inspector визуально остаётся тем же.
- Description apply работает.
- Presets работают.
- Null/missing runtime API не крашит UI.

---

### PR 4 — Extract link controls

**Цель:** отделить link picker и object link UI от основного inspector.

**Новые файлы:**

```text
scripts/ui/map_constructor/map_constructor_link_controls.gd
```

**Что вынести:**

- generic link picker;
- key-door link section;
- door linked key section;
- terminal target links;
- power links;
- control links;
- platform target links.

**Acceptance criteria:**

- Links section строится из отдельного файла.
- Key-door links не потеряны.
- Terminal/power/control links не потеряны.
- Missing links пока можно оставить как было, если PR только extraction, но лучше не дублировать warnings.

---

### PR 5 — Extract validation/warnings view

**Цель:** сделать Warnings отдельной ответственностью.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_validation_view.gd
```

**Что сделать:**

- Вынести rendering validation entries.
- Разделить:
  - linked targets → Links;
  - missing links → Warnings;
  - warnings → Warnings;
  - capacity issues → Warnings;
  - physical path warnings → Warnings.
- Убрать duplicated warning entries.

**Acceptance criteria:**

- Warnings показывает missing/broken/capacity/validation.
- Links показывает связи и pickers.
- Нет дублирования одних и тех же validation messages.

---

### PR 6 — Extract floor/wall coverage controls

**Цель:** отделить Floor Coverage и Wall Coverage от основного inspector.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_floor_wall_controls.gd
```

**Что вынести:**

- floor material UI;
- floor coating UI;
- wall material UI;
- wall side picker;
- wall-mounted anchor display;
- attached wall cell display;
- Apply Side;
- Apply/Clear wall material.

**Important:**

- Wall-mounted configuration должна жить в Wall Coverage, не в Placement.
- Placement не должен содержать wall material editing.

**Acceptance criteria:**

- Floor Coverage идёт перед Wall Coverage.
- Wall Coverage содержит wall-mounted config.
- Все wall material calls guarded через `mission_manager_runtime != null` и `has_method`.
- Нельзя крашнуться при invalid wall side.

---

### PR 7 — Extract Map Constructor inspector builder

**Цель:** вынести весь inspector selected object flow из `game_ui.gd`.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_inspector.gd
```

**Что вынести:**

- `_show_map_constructor_inspector(...)` или большую часть его содержимого;
- section orchestration;
- selected object display logic;
- refresh callbacks, если они относятся только к inspector.

**Оставить в `game_ui.gd`:**

- root HUD references;
- high-level call: `map_constructor_inspector.show_for_selection(...)`;
- shared runtime dependencies injection.

**Acceptance criteria:**

- `game_ui.gd` стал заметно меньше.
- Section order строго соблюдён.
- Current Status read-only.
- Configurable Parameters не потеряли object-specific fields.
- Старые объекты открываются без crash.

---

### PR 8 — Extract Map Constructor actions

**Цель:** вынести placement actions из UI builder.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_actions.gd
```

**Что вынести:**

- move object;
- duplicate object;
- delete object;
- apply prefab placement;
- wall-mounted side apply action;
- refresh after mutation.

**Acceptance criteria:**

- Actions validate target cells.
- Actions fail safely.
- UI builder не содержит business logic для move/duplicate/delete.
- Invalid cell/wall side не вызывает crash.

---

### PR 9 — Extract Map Constructor object palette

**Цель:** отделить список объектов, группы, фильтры и preview tiles.

**Новый файл:**

```text
scripts/ui/map_constructor/map_constructor_object_palette.gd
```

**Что вынести:**

- prefab groups;
- object previews;
- filters;
- search;
- scroll preservation;
- selection handling.

**Acceptance criteria:**

- При выборе объекта меню не скроллится наверх без причины.
- Preview tiles показывают информацию и мини-вид объекта.
- Не затронуты module icon visuals, если они out-of-scope.

---

### PR 10 — Extract Map Constructor tabs and panel orchestration

**Цель:** сделать `game_ui.gd` root orchestrator, а Map Constructor — отдельным panel component.

**Новые файлы:**

```text
scripts/ui/map_constructor/map_constructor_panel.gd
scripts/ui/map_constructor/map_constructor_tabs.gd
```

**Что вынести:**

- root Map Constructor panel;
- tabs;
- switching between Map Settings / Objects & Filters / Inspector / Validation;
- connection between palette and inspector.

**Acceptance criteria:**

- `game_ui.gd` не содержит большой Map Constructor UI build flow.
- Tabs работают.
- Existing constructor workflows не потеряны.
- No unrelated layout changes.

---

### PR 11 — Extract runtime object HUD

**Цель:** отделить runtime RMB inspect HUD от Map Constructor и root UI.

**Новые файлы:**

```text
scripts/ui/runtime/runtime_hud.gd
scripts/ui/runtime/runtime_object_hud.gd
scripts/ui/runtime/runtime_interaction_panel.gd
```

**Что вынести:**

- RMB object inspection;
- object info display;
- action row rendering;
- Unlock/Open/Close/Repair/Use actions;
- door/terminal/power runtime information.

**Acceptance criteria:**

- Runtime object HUD показывает known/scanned info.
- Top notifications не спамятся.
- Runtime actions fail safely.
- No Map Constructor behavior changes.

---

### PR 12 — Extract notification/hint throttling

**Цель:** отделить top notifications и hints.

**Новый файл:**

```text
scripts/ui/runtime/runtime_notifications.gd
```

**Что вынести:**

- show_hint;
- top notification queue;
- throttling/no-spam behavior;
- repeated message collapse.

**Acceptance criteria:**

- Runtime object HUD не спамит top notifications.
- Inspector actions still show useful hints.
- No gameplay logic changes.

---

### PR 13 — Mission Manager service split preparation

**Цель:** подготовить `mission_manager.gd` к разделению, но без риска для save compatibility.

**Разрешённые файлы:**

```text
scripts/game/mission_manager.gd
scripts/game/map_constructor_service.gd
```

**Что сделать:**

- Вынести только Map Constructor mutations:
  - place object;
  - move object;
  - duplicate object;
  - remove object;
  - update property;
  - get entity by ID.
- `mission_manager.gd` может оставаться facade, который делегирует calls в service.

**Acceptance criteria:**

- Public methods, которые вызывает UI, сохраняют имена или имеют compatibility wrappers.
- Старые карты грузятся.
- No power behavior changes.

---

### PR 14 — Mission validation service split

**Цель:** вынести validation отдельно от mutation logic.

**Новый файл:**

```text
scripts/game/map_constructor_validation_service.gd
```

**Что вынести:**

- validate entity links;
- missing links;
- capacity issues;
- invalid wall/placement warnings;
- physical/logical path warnings facade.

**Acceptance criteria:**

- Inspector получает validation через один API.
- Missing/warnings/capacity возвращаются структурированно.
- UI не вычисляет validation сам.

---

### PR 15 — Power system runtime fixes after extraction

**Цель:** закрыть power follow-up issues без UI refactor.

**Разрешённые файлы:**

```text
scripts/world/power_system.gd
scripts/game/mission_manager.gd
scripts/world/world_object_catalog.gd
```

**Что исправить:**

- `Circuit Switch.active_output_index` должен реально ограничивать traversal.
- Fuse block validation: не больше 2 connected wires.
- Power path validation: warnings для logical links без physical wire path, кроме lighting exceptions.
- Safe defaults для старых объектов.

**Acceptance criteria:**

- `PowerSystem.recalculate_network()` не traverses all outputs when active output selected.
- Fuse capacity warning появляется в validation.
- Logical link without physical path даёт warning.
- Старые maps не ломаются.

---

### PR 16 — Light switch and terminal/control runtime fixes

**Цель:** закрыть control interaction logic.

**Разрешённые файлы:**

```text
scripts/world/interaction_system.gd
scripts/world/power_system.gd
scripts/game/mission_manager.gd
scripts/bipob/bipob_controller.gd
```

**Что исправить:**

- Light Switch toggles linked lights, not only itself.
- Terminal/control links fail safely.
- No invalid method calls or null target crashes.

**Acceptance criteria:**

- Linked lights change state/power visibility as expected.
- Missing linked light shows safe warning/hint, not crash.
- Existing terminal links remain compatible.

---

### PR 17 — Cable repair and cable reel runtime logic

**Цель:** закрыть cable/cable reel behavior.

**Разрешённые файлы:**

```text
scripts/world/interaction_system.gd
scripts/world/power_system.gd
scripts/game/mission_manager.gd
scripts/world/world_object_catalog.gd
```

**Что исправить:**

- Repair accepts appropriate damaged/broken cable states.
- Cable reel tracks two ends.
- Cable reel stores target IDs safely.
- Drop return behavior.
- Damaged wire side 1/2 connection state.
- Disconnect/switch behavior.

**Acceptance criteria:**

- Broken cable showing Repair can be repaired.
- Cable reel can connect/disconnect without crash.
- Missing targets fail safely.
- Old cable reels without new fields get defaults.

---

### PR 18 — Catalog/schema defaults cleanup

**Цель:** привести object catalog defaults к новой логике.

**Разрешённые файлы:**

```text
scripts/world/world_object_catalog.gd
scripts/game/mission_manager.gd только если нужен compatibility wrapper
```

**Что исправить:**

- wall-mounted defaults for:
  - `light`;
  - `light_switch`;
  - `fuse_box`;
  - `circuit_breaker`;
  - `power_cable_reel`, если по дизайну он wall-mounted;
- default fields for power/control/cable/fuse objects;
- compatibility defaults for old objects.

**Acceptance criteria:**

- New prefabs spawn with correct placement mode.
- Old maps without fields still work.
- No renderer changes.

---

### PR 19 — Static checks and review tooling

**Цель:** добавить lightweight checks, чтобы Codex и reviewer быстрее ловили regressions.

**Возможные файлы:**

```text
tools/check_map_constructor_sections.py
tools/check_gdscript_safety_patterns.py
README или docs/dev_review_checklist.md
```

**Что проверять:**

- inspector section order;
- no unsafe `Dictionary(row_variant)` in UI paths;
- no unsafe `Array(value)` in UI paths;
- no `mission_manager_runtime.call(...)` without nearby guard in UI callbacks;
- forbidden files not touched for focused PRs;
- optional grep for ambiguous `:=` in edited GDScript files.

**Acceptance criteria:**

- Tools можно запустить локально.
- Они не требуют Godot CLI.
- Не блокируют работу, но помогают review.

---

### PR 20 — Documentation: architecture and PR rules

**Цель:** зафиксировать новую архитектуру для дальнейших задач.

**Новые/обновлённые файлы:**

```text
docs/architecture/ui_split.md
docs/architecture/map_constructor.md
docs/review_rules.md
```

**Что описать:**

- кто за что отвечает;
- где менять inspector;
- где менять runtime HUD;
- где менять power system;
- какие файлы нельзя трогать в UI-only PR;
- Codex prompt templates.

**Acceptance criteria:**

- Новый contributor/Codex может понять, куда вносить изменения.
- Review checklist соответствует project rules.

## 7. Что должно получиться в итоге

После выполнения плана проект должен прийти к такому состоянию:

### 7.1. `game_ui.gd` становится root orchestrator

Он больше не содержит тысячи строк конкретных builder-функций. Его роль:

- создать HUD root;
- подключить runtime HUD;
- подключить Map Constructor panel;
- передать зависимости;
- управлять high-level visibility/refresh.

### 7.2. Map Constructor UI становится модульным

Отдельные файлы отвечают за:

- tabs;
- object palette;
- inspector;
- property controls;
- links;
- warnings;
- floor/wall coverage;
- actions.

Codex сможет получать задачу вида:

```text
Modify only scripts/ui/map_constructor/map_constructor_validation_view.gd.
Do not touch runtime systems.
```

Это намного безопаснее, чем просить его редактировать весь `game_ui.gd`.

### 7.3. Runtime HUD отделён от editor/constructor UI

Runtime RMB inspect и action rows не смешиваются с Map Constructor inspector. Это важно, потому что runtime user actions должны fail safely и не зависеть от editor-only state.

### 7.4. Mission Manager становится facade, а не god-object

`mission_manager.gd` может остаться public API facade, чтобы не ломать текущие вызовы, но внутренняя логика постепенно уходит в services:

- constructor mutation service;
- validation service;
- compatibility/default service, если нужно.

### 7.5. Power/runtime logic чинится отдельно от UI

Power system, interaction system, cable reel, fuse validation и switches больше не чинятся “через inspector”. UI только показывает и вызывает API, а реальная logic живёт в world/game services.

## 8. Рекомендуемый порядок выполнения

Самый безопасный порядок:

```text
1. PR 1  — audit markers / guardrail baseline
2. PR 2  — safe UI helpers
3. PR 3  — property controls
4. PR 4  — link controls
5. PR 5  — validation/warnings view
6. PR 6  — floor/wall coverage controls
7. PR 7  — inspector builder extraction
8. PR 8  — map constructor actions
9. PR 9  — object palette
10. PR 10 — panel/tabs orchestration
11. PR 11 — runtime HUD extraction
12. PR 12 — notifications
13. PR 13 — mission constructor service
14. PR 14 — validation service
15. PR 15 — power runtime fixes
16. PR 16 — light switch/control runtime fixes
17. PR 17 — cable repair/reel runtime logic
18. PR 18 — catalog/schema defaults
19. PR 19 — static checks
20. PR 20 — docs
```

Если нужно быстрее закрыть gameplay bugs после #674, можно сделать так:

```text
A. PR 2–7: быстро вынести inspector до управляемого состояния.
B. PR 15–18: закрыть power/runtime/cable/catalog bugs.
C. PR 8–14: продолжить архитектурное разделение.
D. PR 19–20: добавить tooling/docs.
```

## 9. Codex prompt template для extraction PR

```text
You are working in JUSTConnect/bibop, Godot 4 project Bipob.

Task:
Extract [specific component] from scripts/ui/game_ui.gd into [target file].

Rules:
- This PR is extraction-only.
- Preserve current behavior.
- Do not change gameplay logic.
- Do not touch Box UI, module icon visuals, floor renderer, wall renderer, room visual renderer, or unrelated runtime controls.
- Avoid ambiguous := in GDScript.
- Use explicit types where Variant inference may be ambiguous.
- Use safe Dictionary/Array/String helpers.
- Guard mission_manager_runtime and field_runtime calls.
- Preserve old maps/runtime state compatibility.

Allowed files:
- [exact file list]

Acceptance criteria:
- Existing UI behavior remains the same.
- No parser errors.
- No new runtime crash risks.
- game_ui.gd gets smaller.
- New file has one clear responsibility.
```

## 10. Codex prompt template для runtime-fix PR

```text
You are working in JUSTConnect/bibop, Godot 4 project Bipob.

Task:
Fix [specific runtime issue].

Rules:
- This PR is runtime logic only.
- Do not refactor UI in this PR.
- Do not touch renderer, Box UI, module icon visuals, unrelated Map Constructor layout, or unrelated runtime controls.
- Runtime user actions must fail safely, not crash.
- Guard dictionaries, arrays, indexes, object IDs, cell lookups, wall sides, and target IDs.
- Preserve old maps/runtime state compatibility.
- Avoid ambiguous := in GDScript.

Allowed files:
- [exact file list]

Acceptance criteria:
- [specific behavior]
- Missing/invalid targets show safe warning/hint, not crash.
- Old objects without new fields get safe defaults.
- No out-of-scope changes.
```

## 11. Review checklist для каждого PR

Для каждого PR проверять:

- changed files соответствуют declared scope;
- нет изменений в forbidden subsystems;
- нет parser risks;
- нет unsafe Variant casts;
- нет null node access;
- нет invalid method calls;
- нет array out-of-bounds/index risks;
- runtime actions fail safely;
- old maps/runtime state compatibility preserved;
- UI sections не дублируются;
- refresh callbacks не создают recursive refresh loop;
- PR не смешивает extraction и gameplay fix;
- если PR UI-only, он не должен менять runtime behavior;
- если PR runtime-only, он не должен менять UI layout.

## 12. Критерий завершения всего плана

План можно считать завершённым, когда:

- `game_ui.gd` больше не является 10k+ строк god-file;
- Map Constructor inspector живёт в отдельном module;
- Runtime HUD живёт отдельно от Map Constructor UI;
- property controls, link controls, validation, floor/wall coverage разделены;
- power/runtime fixes не зависят от UI refactor;
- Codex prompts могут ограничивать изменения 1–3 файлами;
- review PR занимает проверку конкретной подсистемы, а не всего UI сразу;
- старые карты и runtime state продолжают работать.
