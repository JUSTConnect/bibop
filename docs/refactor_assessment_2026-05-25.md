# Refactoring assessment (2026-05-25)

## TL;DR

Да, в проекте есть несколько перегруженных файлов, которые уже повышают стоимость поддержки и риск регрессий.

Приоритетные кандидаты:

1. `scripts/ui/game_ui.gd` — 10 236 строк, 578 функций.
2. `scripts/bipob/bipob_controller.gd` — 8 641 строка, 589 функций.
3. `scripts/game/mission_manager.gd` — 3 972 строки, 132 функции.

## What I measured

- Размер файлов (LOC).
- Количество функций.
- Наличие «длинных» функций (80+ строк).

### Raw metrics

| File | LOC | Functions | Long functions (80+ lines) |
|---|---:|---:|---:|
| `scripts/ui/game_ui.gd` | 10236 | 578 | 11 |
| `scripts/bipob/bipob_controller.gd` | 8641 | 589 | 8 |
| `scripts/game/mission_manager.gd` | 3972 | 132 | 5 |
| `scripts/field/grid_manager.gd` | 502 | 42 | 0 |

## Why this is a maintenance risk

### 1) God-object symptoms in UI

`GameUI` объединяет:

- построение layout,
- навигацию экранов,
- состояние миссий,
- состояние конструктора,
- отрисовку превью,
- события кнопок,
- тексты/подсказки.

Это видно по большому блоку состояния и enum режимов в одном классе.

Риск: любой фикс по UI увеличивает шанс задеть смежные режимы (`MAIN_MENU`, `GAMEPLAY`, `BOX_CONSTRUCTOR`, `TASKS`, и т.д.).

### 2) Смешение ответственности в Bipob controller

`bipob_controller.gd` содержит одновременно:

- управление движением/энергией,
- инвентарь/модули,
- взаимодействия с объектами мира,
- диагностику и длинные утилитарные функции текстового/визуального представления.

Риск: сложно безопасно менять механику без побочных эффектов в визуальных и системных частях.

### 3) Mission manager перегружен debug/runtime логикой

В `mission_manager.gd` рядом живут:

- боевой runtime,
- world object orchestration,
- power/cooling/interaction сценарии,
- большие debug/validation сценарии.

Риск: debug-код и runtime логика тесно связаны, усложняя чтение и точечные изменения.

## Recommended refactor strategy (small, MVP-safe)

Ниже шаги без изменения `.tscn`, только `.gd` и с минимальным риском.

### Phase 1 — decomposition without behavior changes

1. `scripts/ui/game_ui.gd`:
   - Вынести в отдельные скрипты «чистые» текстовые/форматирующие helper-функции:
     - тексты меню,
     - модульные описания,
     - форматирование статусов.
   - Вынести сборку экранов в маленькие builders:
     - `ui_builders/tasks_layout_builder.gd`,
     - `ui_builders/box_layout_builder.gd`.
   - В `GameUI` оставить orchestration + binding к узлам.

2. `scripts/bipob/bipob_controller.gd`:
   - Вынести каталог/метаданные модулей и текстовые label-функции в `bipob_module_presenter.gd`.
   - Вынести сложные interaction/hack ветки в `bipob_interaction_service.gd`.
   - Оставить в контроллере state machine хода и делегирование.

3. `scripts/game/mission_manager.gd`:
   - Вынести debug/validation сценарии в `mission_debug_tools.gd`.
   - Оставить в `mission_manager.gd` только production runtime path.

### Phase 2 — introduce boundaries

- Явно разделить публичные API методов по секциям (`# region` комментарии):
  - input,
  - world updates,
  - UI sync,
  - diagnostics.
- Для больших словарей world objects добавить typed access wrappers (без смены формата данных).

### Phase 3 — safety net

- Добавить минимальные smoke-check вызовы через Godot headless (если CI/локально доступно).
- Для ключевых правил миссии вынести deterministic checks в отдельные небольшие unit-style scripts.

## Concrete first targets (high ROI)

1. `GameUI._build_tasks_menu_layout` (≈231 lines) — выделить builder + small helper methods.
2. `BipobController.interact` (≈231 lines) — разделить по объектным группам/веткам действий.
3. `MissionManager.validate_power_network_debug_scenario` (≈738 lines) — перенос в debug-only модуль.

## Expected impact

- Ниже когнитивная нагрузка при ревью.
- Меньше конфликтов при параллельной разработке.
- Быстрее онбординг и локализация багов.
- Проще готовить дальнейший рост (миссии/модули/новые экраны) без ломки MVP.

## Note on scope

Оценка сделана без изменения сцены (`.tscn`) и без архитектурного «переписывания с нуля».
