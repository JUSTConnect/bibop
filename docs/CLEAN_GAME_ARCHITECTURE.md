# BIPOB Clean Game Architecture

Этот документ описывает целевую архитектуру всей игры BIPOB: без дублей, наслоений, временных repair-слоёв, рваной UI-логики и бесконечных post-process патчей поверх уже собранной сцены.

Цель документа — стать главным правилом для дальнейших refactor-веток, Codex/LLM-правок и ручных изменений.

---

## 1. Главный принцип

В проекте должен быть один источник правды для каждой ответственности.

Если логика уже существует в центральном месте, нельзя добавлять второй слой, который пытается исправить её после факта. Нужно менять исходную точку сборки или выделять общий сервис данных.

Запрещённый паттерн:

```text
GameUI строит UI
↓
Autoload сканирует дерево
↓
Autoload переставляет UI
↓
Другой Autoload чинит сломанный layout
↓
Третий Autoload скрывает старую панель
```

Правильный паттерн:

```text
GameUI как UI-shell вызывает один builder/presenter
↓
Builder строит блоки один раз из модели данных
↓
Presenter обновляет видимые значения
↓
Domain service изменяет данные
```

---

## 2. Архитектурные слои

Проект делится на пять слоёв.

```text
Domain Data / Rules
    ↓
Runtime Systems
    ↓
Presentation Models
    ↓
UI Builders / Presenters
    ↓
Scenes / Controls
```

### 2.1 Domain Data / Rules

Слой содержит правила игры и чистые функции.

Примеры:

- типы объектов;
- правила power/cooling/status/access/control;
- проверка совместимости ссылок;
- расчёт ready/not-ready;
- валидация map constructor;
- преобразование данных в нормализованную модель.

Правила:

- не создаёт `Control`, `PanelContainer`, `Label`, `Button`;
- не ищет ноды через `get_tree()`;
- не зависит от `GameUI`;
- может использовать `Dictionary`, `Array`, `Vector2i`, enum-like strings;
- должен быть тестируемым отдельно.

Пример целевого расположения:

```text
scripts/domain/world_object_status_model.gd
scripts/domain/object_identity_model.gd
scripts/domain/power_state_model.gd
scripts/domain/access_link_model.gd
scripts/domain/cooling_model.gd
scripts/domain/map_constructor_validation_model.gd
```

### 2.2 Runtime Systems

Слой изменяет состояние игры во время миссии.

Примеры:

- mission runtime;
- power network runtime;
- cooling runtime;
- object interaction runtime;
- inventory/storage runtime;
- map constructor runtime mutation.

Правила:

- изменяет данные через один владеющий manager/service;
- не строит UI напрямую;
- не содержит визуальной логики;
- не должен знать, как именно inspector или HUD отображают состояние.

### 2.3 Presentation Models

Слой превращает domain/runtime данные в модели для UI.

Примеры:

```text
ObjectInspectorViewModel
RuntimeHudViewModel
WorldActionMenuViewModel
StoragePanelViewModel
MapConstructorPaletteViewModel
```

Правила:

- читает данные;
- ничего не мутирует;
- возвращает готовые строки, статусы, visibility flags, enabled/disabled reasons;
- не создаёт Godot UI-ноды.

### 2.4 UI Builders / Presenters

Слой создаёт и обновляет UI.

Builder создаёт структуру:

```text
Identity block
Status block
Configurable parameters block
Links block
Validation block
Debug block
```

Presenter обновляет значения уже существующих контролов.

Правила:

- builder отвечает за создание layout;
- presenter отвечает за refresh значений;
- builder не должен вызываться каждый кадр;
- presenter не должен перестраивать дерево без необходимости;
- UI-блоки создаются из view model, а не из сырых scattered dictionaries.

### 2.5 Scenes / Controls

Слой содержит Godot-сцены и узлы.

Правила:

- сцена собирает composition;
- сцена не должна содержать бизнес-правила;
- сцена не должна быть местом для runtime patch-логики;
- старые legacy-ноды либо удаляются, либо явно помечаются как deprecated и не участвуют в runtime.

---

## 3. Роли ключевых файлов

### `scripts/ui/game_ui.gd`

Целевая роль: UI shell / coordinator.

Разрешено:

- переключать экраны;
- держать ссылки на основные панели;
- вызывать builders/presenters;
- маршрутизировать пользовательские события в runtime/domain services.

Запрещено:

- содержать правила power/cooling/access/status;
- строить все меню вручную в одном файле;
- чинить UI через scattered deferred-костыли;
- напрямую дублировать логику inspector, storage, HUD и action menu.

Целевое направление:

```text
GameUI
  ├─ RuntimeHudBuilder
  ├─ RuntimeHudPresenter
  ├─ MapConstructorInspectorBuilder
  ├─ MapConstructorPalettePresenter
  ├─ StoragePanelPresenter
  └─ WorldActionMenuPresenter
```

### `scripts/game/mission_manager.gd`

Целевая роль: mission/runtime coordinator и владелец mission data.

Разрешено:

- хранить mission_world_objects;
- применять мутации к данным;
- делегировать расчёты в domain/runtime services;
- отдавать данные для view models.

Запрещено:

- строить UI;
- содержать большие блоки правил для всех систем;
- дублировать logic из power/cooling/status/access services.

Целевое направление:

```text
MissionManager
  ├─ MissionObjectRepository
  ├─ MapConstructorMutationService
  ├─ RuntimePersistenceService
  ├─ MissionValidationService
  └─ delegates to domain systems
```

### `scripts/field/grid_manager.gd`

Целевая роль: источник правды по клеткам, полу, стенам, занятости и геометрии сетки.

Разрешено:

- cell occupancy;
- floor/wall data;
- grid boundaries;
- доступность клетки;
- геометрия карты.

Запрещено:

- рисовать ассеты;
- решать UI-вопросы;
- хранить state object interaction вне своей области.

### `scripts/field/room_visual_renderer.gd`

Целевая роль: визуальная проекция runtime/map constructor state.

Разрешено:

- отрисовка объектов;
- isometric projection;
- z-order;
- визуальные overlay;
- preview markers.

Запрещено:

- менять gameplay state;
- принимать бизнес-решения;
- нормализовать object data;
- дублировать catalog rules.

### `scripts/bipob/bipob_controller.gd`

Целевая роль: состояние и команды активного Bipob.

Разрешено:

- направление;
- energy/actions;
- movement command bridge;
- interaction command bridge.

Запрещено:

- строить UI;
- хранить map constructor logic;
- знать внутреннюю структуру inspector/HUD.

Важно: публичные сигналы, уже используемые UI/runtime, нельзя удалять без миграции:

```text
world_action_panel_requested
mission_failed
hint_requested
```

---

## 4. Запрещённые архитектурные паттерны

### 4.1 Autoload как UI patch layer

Запрещено добавлять autoload, который:

- сканирует всё дерево сцены;
- ищет UI-ноды по имени;
- переставляет чужие children;
- создаёт fallback UI вместо исправления builder-а;
- чинит layout каждый `_process`;
- скрывает старую панель, потому что новая не работает.

Autoload допустим только если он является настоящим глобальным сервисом:

- notification bus;
- save/load service;
- input remap service;
- debug console service;
- asset registry;
- global configuration.

### 4.2 Рекурсивный scene-tree scan в gameplay

Запрещено:

```gdscript
func _process(delta):
    scan_scene_tree(get_tree().root)
```

Допустимо:

- явная ссылка, переданная владельцем;
- scoped lookup внутри известной панели;
- одноразовая инициализация при создании сцены;
- editor-only diagnostic scan, выключенный в runtime.

### 4.3 Две системы для одного UI

Запрещено держать одновременно:

```text
CommandPanel
RuntimeControlsPanel
RuntimeControlMenuRecovery
RuntimeHudRepair fallback controls
```

Если актуальная система — `RuntimeControlsPanel`, legacy `CommandPanel` должен быть удалён или deprecated и не использоваться.

### 4.4 Post-process inspector structure

Запрещено собирать inspector, а затем отдельным autoload переставлять блоки.

Правильно:

```text
MapConstructorInspectorBuilder строит блоки в правильном порядке сразу.
```

---

## 5. Единый inspector object architecture

Inspector объекта должен строиться из одного builder-а.

Целевой порядок блоков:

```text
1. Identity
2. Status
3. Configurable parameters
4. Links
5. Validation
6. Debug / Advanced
```

### 5.1 Identity

Всегда первый блок на каждой вкладке/режиме объекта.

Содержит только:

- Name;
- Description.

Правила UI:

- кнопка Apply находится справа от редактируемого поля;
- у Description кнопка Apply находится справа от TextEdit, не снизу;
- Identity не содержит Object type, Object class, power state, links, validation.

### 5.2 Status

Read-only блок.

Минимальный набор:

- Object type;
- Total state;
- Power state.

Правила:

- не редактирует данные;
- не содержит dropdown/spinbox/check box;
- получает данные из status view model;
- не дублирует configurable parameters.

### 5.3 Configurable parameters

Только настраиваемые поля.

Примеры:

- class;
- control mode;
- access mode;
- mount;
- side;
- routing mode;
- capacity;
- thresholds;
- object-specific editable schema fields.

Правила:

- строится из schema/model;
- не показывает internal ids;
- не показывает readonly status;
- не показывает links.

### 5.4 Links

Только связи между объектами.

Примеры:

- power source;
- power circuit;
- control terminal;
- access terminal;
- key/key-card/digital key;
- linked door/platform/device.

Правила:

- link UI получает targets из link view model;
- mutation проходит через один link mutation service;
- backlinks создаются там же, где link mutation, а не в UI.

### 5.5 Validation

Только ошибки, предупреждения, quick fixes.

Правила:

- Validation не изменяет layout других блоков;
- Quick fix вызывает mutation service;
- Preview/Apply должны быть явно разделены.

---

## 6. HUD architecture

Runtime HUD должен иметь один источник сборки.

Целевые блоки:

```text
RuntimeHudRoot
  ├─ RuntimeTopNotifications
  ├─ RuntimeBottomLeft
  │    ├─ RuntimeStatsStrip
  │    └─ RuntimeControlsPanel
  ├─ RuntimeStoragePanel
  └─ RuntimeWorldActionPanel
```

Правила:

- `RuntimeBottomLeft` строится одним builder-ом;
- `RuntimeStatsStrip` показывает energy/actions;
- `RuntimeControlsPanel` показывает актуальные runtime actions;
- legacy `CommandPanel` не используется в gameplay;
- repair service допустим только временно и должен быть удалён после переноса логики в builder.

Запрещено:

- пересчитывать anchors/offsets каждый tick без причины;
- строить fallback-кнопки, если штатная панель не появилась;
- держать две панели управления одновременно.

---

## 7. Object status architecture

Единая система статусов должна делиться на три части.

### 7.1 Status Model

Чистая модель данных:

```text
ObjectStatusModel
  ├─ object_type
  ├─ total_state
  ├─ power_state
  ├─ health_state
  ├─ energy_capacity_state
  ├─ overheat_state
  ├─ warnings
  └─ configurable_parameters
```

### 7.2 Status ViewModel

Готовит данные для UI:

```text
Status block rows
Configurable parameter rows
Warning rows
```

### 7.3 Status Mutation Service

Изменяет только editable параметры.

Запрещено:

- делать status UI autoload-слоем;
- сканировать все объекты каждый кадр;
- смешивать read-only status и editable parameters в одном блоке.

---

## 8. Power / Cooling / Links architecture

### 8.1 Power

Единый источник правды:

```text
PowerSystem
  ├─ normalize power type
  ├─ resolve source
  ├─ resolve circuit
  ├─ recalculate network
  └─ produce warnings
```

UI не должен сам решать, какие power links валидны. UI только показывает модель.

### 8.2 Cooling

Единый источник правды:

```text
CoolingSystem
  ├─ cooling box
  ├─ air duct
  ├─ water pipe
  ├─ contour / route mode
  └─ cooling delivery
```

Cooling UI должен быть отдельным tab/section, но данные маршрута и контуров должны жить в runtime/domain service, не в renderer.

### 8.3 Links

Единый источник правды:

```text
ObjectLinkService
  ├─ power links
  ├─ control links
  ├─ access links
  ├─ key/key-card/digital key links
  └─ backlinks
```

UI не должен вручную синхронизировать backlinks.

---

## 9. Naming and file rules

### 9.1 Builder

Файл с суффиксом `builder` создаёт UI-ноды.

Пример:

```text
map_constructor_inspector_builder.gd
runtime_hud_builder.gd
storage_panel_builder.gd
```

### 9.2 Presenter

Файл с суффиксом `presenter` обновляет уже созданный UI.

Пример:

```text
runtime_hud_presenter.gd
world_action_menu_presenter.gd
```

### 9.3 Model / ViewModel

Файл с суффиксом `model` или `view_model` возвращает данные без UI-ноды.

Пример:

```text
object_status_view_model.gd
object_identity_view_model.gd
```

### 9.4 Service

Файл с суффиксом `service` выполняет действие или расчёт.

Service не должен быть autoload по умолчанию.

### 9.5 Autoload

Autoload разрешён только для глобальных служб, а не для локальных UI-патчей.

---

## 10. Refactor strategy

Нельзя переписывать всю игру сразу. Нужно двигаться вертикальными срезами.

Каждый срез:

1. Документирует текущий duplicate/debt.
2. Выбирает один источник правды.
3. Переносит правильную логику в целевое место.
4. Удаляет старый слой.
5. Проверяет gameplay вручную в Godot.
6. Делает маленький commit.

Пример правильного среза:

```text
Object Inspector Identity
  remove post-process identity layer
  implement identity block in inspector builder
  ensure Name/Description only
  delete duplicate description block
  test in map constructor
```

---

## 11. Branch policy

Для архитектурной очистки использовать отдельные ветки.

Рекомендуемые ветки:

```text
refactor/clean-game-architecture
refactor/object-inspector-single-source
refactor/runtime-hud-single-source
refactor/mission-manager-split
refactor/power-cooling-domain-services
```

Правила:

- не смешивать gameplay feature и architecture cleanup в одном commit;
- не делать массовый рефакторинг без вертикального результата;
- каждая ветка должна иметь рабочий промежуточный milestone;
- deprecated-файл удаляется только после переноса всех callers.

---

## 12. Acceptance criteria for clean architecture

Фича считается архитектурно принятой, если:

- есть один владелец данных;
- есть один builder UI;
- нет post-process autoload patch layer;
- нет рекурсивного scan всей сцены в runtime;
- нет двух активных UI для одной функции;
- readonly status отделён от configurable parameters;
- UI не пишет backlinks вручную;
- renderer не меняет gameplay data;
- coordinator-файлы не растут без выделения сервиса;
- новый код можно найти по имени системы.

---

## 13. Immediate cleanup targets

Текущие зоны риска:

```text
scripts/ui/game_ui.gd
scripts/game/mission_manager.gd
scripts/field/room_visual_renderer.gd
scripts/field/grid_manager.gd
scripts/bipob/bipob_controller.gd
```

Цель — не удалить эти файлы, а превратить их в координаторы, которые вызывают маленькие, понятные модули.

Приоритеты:

1. Object inspector single source.
2. Runtime HUD single source.
3. Object status model/view model split.
4. Links service single source.
5. Power/cooling domain split.
6. MissionManager repository/mutation split.
7. Renderer asset/catalog split.

---

## 14. Rule for future LLM/Codex changes

Перед любой правкой нужно ответить на вопросы:

1. Где источник правды этой логики?
2. Уже есть builder/presenter/service для этого?
3. Не создаю ли я второй UI для той же функции?
4. Не добавляю ли autoload, который чинит чужой UI?
5. Можно ли исправить исходную точку сборки вместо post-process?
6. Какой старый код будет удалён после переноса?

Если ответ неясен — сначала изучить проект и написать план, затем менять код.

---

## 15. Short version

- Один источник правды.
- UI строится в builder-е, а не чинится autoload-ом.
- Domain rules не знают про Godot UI.
- Runtime systems не рисуют интерфейс.
- Renderer не меняет gameplay data.
- Inspector: Identity, Status, Configurable parameters, Links, Validation.
- HUD: один RuntimeControlsPanel, без legacy CommandPanel.
- Любой временный repair-layer должен иметь план удаления.
