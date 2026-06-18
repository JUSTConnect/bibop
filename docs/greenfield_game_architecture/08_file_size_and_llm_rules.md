# File Size And LLM Rules

Этот документ задаёт ограничения размера файлов, правила работы с кодом для LLM/Codex и обязательный процесс перед изменениями. Цель — сделать проект удобным для поддержки человеком и LLM: маленькие файлы, ясные ответственности, минимальный контекст, отсутствие скрытых дублей.

---

## File Size Policy

### Why This Exists

LLM плохо исправляет большие монолитные файлы, потому что:

- теряется контекст;
- тяжело увидеть дубли;
- повышается риск сломать соседнюю систему;
- tool response часто обрезается;
- маленький фикс превращается в случайный рефакторинг;
- файл начинает содержать UI, runtime, domain и data mutation одновременно.

Поэтому проект должен иметь жёсткие лимиты.

---

## Recommended File Sizes

### GDScript Source Files

| File Type | Target | Soft Limit | Hard Limit |
|---|---:|---:|---:|
| Domain model | 80-180 lines | 250 lines | 350 lines |
| Runtime system | 150-300 lines | 450 lines | 600 lines |
| UI builder | 120-280 lines | 400 lines | 550 lines |
| UI presenter | 100-240 lines | 350 lines | 500 lines |
| ViewModel factory | 120-260 lines | 350 lines | 500 lines |
| Repository | 150-350 lines | 500 lines | 700 lines |
| Coordinator | 120-300 lines | 450 lines | 600 lines |
| Test file | 100-300 lines | 500 lines | 700 lines |

### Documentation Files

| Document Type | Target | Soft Limit | Hard Limit |
|---|---:|---:|---:|
| Architecture document | 150-350 lines | 500 lines | 700 lines |
| System specification | 150-300 lines | 450 lines | 650 lines |
| Checklist / rules | 80-220 lines | 350 lines | 500 lines |
| Current project inventory | 150-400 lines | 600 lines | 900 lines |

### Data Definition Files

| File Type | Target | Soft Limit | Hard Limit |
|---|---:|---:|---:|
| Single object definition | 40-160 lines | 250 lines | 350 lines |
| Single item definition | 40-140 lines | 220 lines | 320 lines |
| Schema file | 100-300 lines | 500 lines | 700 lines |
| Catalog index | 50-200 lines | 400 lines | 600 lines |

---

## Function Size Policy

| Function Type | Target | Soft Limit | Hard Limit |
|---|---:|---:|---:|
| Pure helper | 5-25 lines | 40 lines | 60 lines |
| Builder function | 20-60 lines | 90 lines | 120 lines |
| Presenter refresh | 15-50 lines | 80 lines | 110 lines |
| Runtime mutation | 20-70 lines | 100 lines | 140 lines |
| Coordinator method | 10-50 lines | 80 lines | 100 lines |

Если функция больше hard limit — её нужно разделить.

---

## Class Responsibility Policy

Один файл должен иметь одну главную ответственность.

Правильно:

```text
ObjectInspectorBuilder builds inspector sections.
ObjectInspectorPresenter refreshes inspector values.
ObjectStatusModel calculates status.
ObjectStatusViewModel formats rows for UI.
```

Плохо:

```text
GameUI builds HUD, inspector, storage, map constructor, validation, renderer overlays and game rules.
MissionManager stores data, validates map, handles links, controls platforms, calculates visuals and owns asset aliases.
```

---

## When A File Exceeds Soft Limit

Если файл превышает soft limit, LLM/разработчик обязан:

1. Не добавлять новую unrelated логику.
2. Найти текущие responsibility groups.
3. Вынести новую логику в отдельный файл.
4. Добавить adapter только если нужен compatibility bridge.
5. Запланировать удаление старого кода.

---

## When A File Exceeds Hard Limit

Если файл превышает hard limit:

- новые features туда не добавлять;
- разрешены только bugfix-и;
- перед feature нужно создать split plan;
- каждый новый helper должен идти в отдельный module;
- refactor делается vertical slice, не massive rewrite.

---

## LLM Work Rules

### Rule 1: Read Before Writing

Перед изменением LLM обязан изучить:

```text
current file
caller file
called service/helper
project.godot autoloads
relevant scene if UI is involved
```

Для UI-логики обязательно проверить:

```text
Who builds the UI?
Who refreshes it?
Who owns the data?
Is there a duplicate legacy UI?
Is there an autoload patch layer?
```

### Rule 2: No Guess Fixes

Запрещены правки вида:

```text
make it visible every tick
create fallback panel
scan tree and fix nodes
force z_index until it appears
```

Такие правки допустимы только как temporary emergency patch с документированным removal plan.

### Rule 3: Prefer Source Of Truth

Если проблема в inspector, менять `ObjectInspectorBuilder`, а не post-process слой.

Если проблема в status, менять `ObjectStatusModel/ViewModel`, а не Label text вручную.

Если проблема в links, менять `LinkSystem`, а не UI callback.

### Rule 4: Never Create Duplicate Active UI

Перед созданием нового menu/panel LLM обязан найти существующие:

```text
scene node
builder
presenter
autoload
legacy panel
```

Если аналог уже есть — новый UI не создавать. Нужно заменить или мигрировать старый.

### Rule 5: No Runtime Tree Scanners

LLM не должен добавлять `_process` с поиском всего дерева.

Допустимо:

```gdscript
func refresh(panel: Control, view_model: Dictionary) -> void
```

Недопустимо:

```gdscript
func _process(delta):
    find_game_ui_in_tree()
    scan_all_nodes()
    repair_ui()
```

### Rule 6: Small Commits

Одна задача — один commit.

Формат commit message:

```text
<system>: <specific change>
```

Примеры:

```text
object inspector: add identity status structure
runtime hud: build controls from view model
power system: extract circuit selection model
```

### Rule 7: Update Docs When Architecture Changes

Если добавляется новая система, изменяется owner данных или меняется структура UI, нужно обновить:

```text
docs/greenfield_game_architecture/
docs/CLEAN_GAME_ARCHITECTURE.md
```

### Rule 8: Do Not Hide Legacy Problems

Если есть legacy UI, нельзя просто скрыть его и добавить новый. Нужно записать:

```text
legacy file
replacement file
migration status
removal condition
```

---

## Required LLM Investigation Template

Перед кодовой правкой LLM должен составить внутренний план по шаблону:

```text
Problem:
Observed behavior:
Expected behavior:
Current owner:
Duplicate systems found:
Files to inspect:
Source of truth:
Change target:
Files to modify:
Files to remove later:
Test path in Godot:
Rollback risk:
```

В ответ пользователю не обязательно выводить весь шаблон, но решение должно ему соответствовать.

---

## Required User-Facing Report

После правки LLM должен кратко написать:

```text
Что было причиной.
Что изменено.
Какие файлы изменены.
Какой commit.
Что проверить в Godot.
Что осталось временным.
```

Если это emergency workaround, прямо написать:

```text
Это временный слой. Его нужно удалить после переноса логики в <target file>.
```

---

## File Split Triggers

Файл нужно разделить, если есть хотя бы два пункта:

- больше 500 строк;
- больше 8 preload dependencies;
- больше 2 разных UI panels;
- содержит UI и runtime mutation;
- содержит renderer и gameplay rules;
- содержит schema parsing и control creation;
- содержит больше 12 public methods;
- LLM tool response обрезает файл;
- в файле есть sections с разной тематикой.

---

## Preferred Split Patterns

### Monolithic UI File

```text
GameUI
  -> RuntimeHudBuilder
  -> RuntimeHudPresenter
  -> ObjectInspectorBuilder
  -> ObjectInspectorPresenter
  -> StoragePanelBuilder
  -> StoragePanelPresenter
  -> MapConstructorScreenBuilder
```

### Monolithic Manager File

```text
MissionManager
  -> WorldStateRepository
  -> ConstructorMutationService
  -> LinkSystem
  -> PowerSystem
  -> CoolingSystem
  -> StatusSystem
  -> ValidationSystem
```

### Monolithic Inspector File

```text
MapConstructorInspector
  -> ObjectInspectorBuilder
  -> IdentitySectionBuilder
  -> StatusSectionBuilder
  -> ConfigSectionBuilder
  -> LinksSectionBuilder
  -> ValidationSectionBuilder
```

---

## LLM Forbidden Changes

Запрещено без явного разрешения пользователя:

- массово переписывать `project.godot`;
- удалять scenes;
- удалять public signals;
- заменять main scene;
- включать тяжёлые autoload scanners;
- создавать второй HUD вместо исправления текущего;
- переносить gameplay data в UI;
- менять формат saved mission без migration note.

---

## Emergency Patch Policy

Emergency patch допустим, если игра не запускается или critical UI недоступен.

Условия:

```text
1. Patch must be minimal.
2. Patch must not become permanent architecture.
3. Patch must be documented as temporary.
4. Patch must have target replacement file.
5. Patch must not scan full scene tree every frame.
```

---

## Greenfield File Size Summary

Короткое правило:

```text
200 lines = good
350 lines = acceptable
500 lines = warning
700+ lines = architecture debt
1000+ lines = split required before features
```

Для LLM-friendly разработки лучше держать большинство файлов в диапазоне 150-350 строк.
