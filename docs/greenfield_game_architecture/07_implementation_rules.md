# Implementation Rules

Этот документ фиксирует правила разработки новой архитектуры BIPOB. Его задача — не дать проекту снова накопить дубли, временные слои, hidden fallback UI, post-process патчи и монолитные файлы.

---

## Rule 1: Fix Source, Not Symptom

Если UI выглядит неправильно, нужно исправить builder/view model, который его создаёт.

Нельзя добавлять слой, который после сборки:

```text
finds nodes
moves nodes
hides nodes
creates fallback nodes
recalculates layout every tick
```

Правильное решение:

```text
Update ViewModel -> Update Builder -> Update Presenter
```

---

## Rule 2: No Duplicate Active Systems

В проекте не должно быть двух активных систем для одной функции.

Примеры запрещённых дублей:

```text
CommandPanel + RuntimeControlsPanel
ObjectStatusLayer + StatusSectionBuilder
LinkLayer + LinksSectionBuilder
NotificationLayer + RuntimeNotificationPanel
```

Если новая система заменяет старую, старую нужно:

1. пометить deprecated;
2. удалить из active scene/autoload;
3. перенести callers;
4. удалить файл после проверки.

---

## Rule 3: No Runtime Scene Tree Scanners

Запрещено использовать runtime scanner как основу логики.

Запрещено:

```gdscript
func _process(delta):
    scan_tree(get_tree().root)
```

Разрешено:

```gdscript
func build(owner: Control, view_model: ViewModel) -> Control
func refresh(existing_panel: Control, view_model: ViewModel) -> void
```

Исключение: debug-only diagnostics, выключенные в gameplay.

---

## Rule 4: Builder Creates, Presenter Refreshes

Builder:

```text
создаёт nodes
создаёт layout
создаёт секции
подключает signals
```

Presenter:

```text
обновляет text/value/enabled/visible
не перестраивает всё дерево без причины
```

Запрещено, чтобы presenter создавал новые панели каждый tick.

---

## Rule 5: All Similar Menus Use Common Structures

Любое меню должно использовать:

```text
CommonPanelDefinition
CommonSectionDefinition
CommonPropertyRowDefinition
CommonActionDefinition
```

Если нужно новое поведение строки, добавляется новый `control_type`, а не уникальный UI-код в конкретном меню.

---

## Rule 6: Object Inspector Is Schema Driven

Object inspector строится из:

```text
ObjectDefinition
ObjectStatusViewModel
ObjectConfigSchema
ObjectLinkSchema
ValidationReport
```

Нельзя вручную добавлять поля объекта в inspector, если они могут быть описаны schema.

---

## Rule 7: New Object Checklist

Перед добавлением нового объекта нужно создать:

```text
ObjectDefinition
VisualDefinition
ConfigSchema
StatusRules
InteractionRules
LinkRules
ValidationRules
PaletteCategory
```

Checklist:

- [ ] объект появляется в palette;
- [ ] Identity отображается;
- [ ] Status read-only отображается;
- [ ] Configurable parameters отображаются из schema;
- [ ] Links отображаются из schema;
- [ ] Validation работает;
- [ ] Renderer отображает visual;
- [ ] Runtime actions приходят из ObjectInteractionSystem;
- [ ] нет custom inspector code для объекта.

---

## Rule 8: New Item Checklist

Перед добавлением нового item нужно создать:

```text
ItemDefinition
VisualDefinition
ConfigSchema
InteractionRules
StorageRules
ValidationRules
```

Checklist:

- [ ] item появляется в palette/inventory/storage;
- [ ] item inspector использует общую структуру;
- [ ] stack rules работают;
- [ ] pickup/drop/use идут через ItemSystem;
- [ ] renderer отображает item;
- [ ] links/access rules не пишутся в UI.

---

## Rule 9: Result-Based Mutations

Любое изменение state возвращает `Result`.

```gdscript
class_name Result

var ok: bool
var message: String
var changed_ids: Array[String]
var warnings: Array[String]
var events: Array[RuntimeEvent]
```

UI показывает `message`, presenter обновляет view models, systems получают events.

---

## Rule 10: No Direct Dictionary Mutation From UI

Запрещено:

```gdscript
object_data["power_state"] = "powered"
```

из UI.

Правильно:

```gdscript
CommandBus.dispatch(SetObjectPowerModeCommand.new(object_id, "external"))
```

или:

```gdscript
ConstructorMutationService.apply_patch(entity_id, patch)
```

---

## Rule 11: Renderer Is Read Only

Renderer:

- читает render model;
- создаёт visuals;
- обновляет z-order;
- показывает overlays.

Renderer не должен:

- менять object state;
- чинить links;
- нормализовать config;
- решать access/power/cooling rules.

---

## Rule 12: Legacy Code Policy

Legacy code допустим только временно.

Каждый legacy-файл должен иметь:

```text
Deprecated reason
Replacement module
Removal condition
Owner task/issue
```

Пример:

```gdscript
# Deprecated: Legacy CommandPanel.
# Replacement: RuntimeControlsPanel via RuntimeHudBuilder.
# Remove when runtime HUD single-source branch is merged.
```

---

## Rule 13: Commit Policy

Один commit = один вертикальный срез.

Плохо:

```text
Refactor inspector, HUD, power and storage together
```

Хорошо:

```text
Implement ObjectInspector Identity section from schema
```

---

## Rule 14: Branch Policy

Архитектурные ветки:

```text
refactor/object-inspector-single-source
refactor/runtime-hud-single-source
refactor/object-definition-catalog
refactor/domain-power-system
refactor/domain-cooling-system
```

Правила:

- branch должен иметь clear scope;
- не смешивать bugfix и architecture cleanup;
- каждый branch должен оставлять игру запускаемой;
- temporary repair layer запрещён без issue и removal plan.

---

## Rule 15: LLM/Codex Safety Checklist

Перед любой LLM/Codex правкой нужно ответить:

1. Где single source of truth?
2. Есть ли уже builder/presenter/service?
3. Не создаётся ли второй UI для той же функции?
4. Не добавляется ли autoload patch layer?
5. Какой старый код будет удалён?
6. Можно ли проверить это маленьким vertical slice?
7. Что будет, если feature refresh/rebuild вызовется несколько раз?
8. Не будет ли layout расти каждый tick?
9. Не сканируется ли всё дерево сцены?
10. Не пишет ли UI напрямую gameplay data?

Если на любой вопрос нет ответа — сначала изучить проект и написать план.

---

## Acceptance Criteria For Architecture

Новая архитектура считается соблюдённой, если:

- один источник правды на систему;
- все однотипные меню построены common builder-ами;
- object/item inspector schema driven;
- runtime HUD имеет один builder и один presenter;
- no active duplicate UI;
- no post-process patch autoload;
- no scene tree scanner in gameplay;
- domain не знает про UI;
- runtime не строит UI;
- renderer read-only;
- mutation через Result;
- validation отдельно от mutation;
- links/backlinks через LinkSystem;
- новый объект подключается через definition, а не через custom UI code.

---

## Migration Order From Existing Project

Если переносить текущий проект к этой архитектуре, порядок такой:

```text
1. Freeze feature additions that create new patch layers.
2. Create ObjectDefinitionCatalog.
3. Create CommonPropertyRowBuilder and CommonSectionBuilder.
4. Rebuild ObjectInspector from ViewModel.
5. Remove inspector structure autoloads.
6. Rebuild RuntimeHud from ViewModel.
7. Remove legacy CommandPanel and repair layers.
8. Extract ObjectStatusModel from existing object status logic.
9. Extract LinkSystem and remove UI backlink writes.
10. Extract PowerSystem and CoolingSystem.
11. Split MissionManager into repository + systems.
12. Make renderer read-only from RenderModel.
```

Каждый пункт должен быть отдельной веткой или отдельным маленьким milestone.
