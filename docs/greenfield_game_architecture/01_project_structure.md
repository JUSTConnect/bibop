# Project Structure

Этот документ описывает целевую структуру файлов для новой правильной версии BIPOB. Имена папок, файлов, классов и функций — на английском. Описание — на русском.

---

## Root Layout

```text
project.godot
scenes/
scripts/
assets/
data/
docs/
tests/
tools/
```

### `scenes/`

Содержит только Godot scenes и composition. Сцены не должны содержать бизнес-логику.

```text
scenes/
  app/
    AppRoot.tscn
  gameplay/
    GameplayScene.tscn
    WorldView.tscn
    RuntimeHud.tscn
  map_constructor/
    MapConstructorScene.tscn
    ObjectInspectorPanel.tscn
    PalettePanel.tscn
  ui/
    CommonPanel.tscn
    CommonTabView.tscn
    CommonPropertyRow.tscn
    NotificationPanel.tscn
```

Правило: если UI-паттерн повторяется, он должен быть common scene/control, а не вручную собираться в каждом меню.

### `scripts/app/`

Главное приложение и переходы между режимами.

```text
scripts/app/
  app_root.gd
  app_state_machine.gd
  scene_router.gd
  save_load_service.gd
  input_router.gd
```

- `AppRoot` — корневой координатор.
- `AppStateMachine` — состояние приложения.
- `SceneRouter` — загрузка/выгрузка экранов.
- `SaveLoadService` — сохранения.
- `InputRouter` — маршрутизация input в текущий mode.

### `scripts/domain/`

Чистые правила без UI и без доступа к scene tree.

```text
scripts/domain/
  object_definition.gd
  object_definition_catalog.gd
  item_definition.gd
  item_definition_catalog.gd
  object_status_model.gd
  object_config_schema.gd
  object_link_model.gd
  power_model.gd
  cooling_model.gd
  access_model.gd
  control_model.gd
  validation_model.gd
```

Правило: domain classes не создают `Control`, не вызывают `get_tree()`, не знают про `GameUI`.

### `scripts/runtime/`

Системы, которые изменяют game state.

```text
scripts/runtime/
  mission_runtime.gd
  world_state_repository.gd
  actor_system.gd
  object_interaction_system.gd
  item_system.gd
  inventory_system.gd
  storage_system.gd
  power_system.gd
  cooling_system.gd
  access_system.gd
  control_system.gd
  link_system.gd
  status_system.gd
  validation_system.gd
  turn_system.gd
```

- `MissionRuntime` владеет текущей миссией.
- `WorldStateRepository` хранит объекты, items, actors, grid state.
- Системы меняют только свою область ответственности.

### `scripts/map_constructor/`

Редактор карты и объектов.

```text
scripts/map_constructor/
  map_constructor_runtime.gd
  map_edit_state.gd
  object_placement_system.gd
  object_selection_system.gd
  constructor_mutation_service.gd
  constructor_validation_system.gd
  constructor_undo_redo_service.gd
  prefab_kit_service.gd
  room_template_service.gd
```

Правило: map constructor меняет данные через `ConstructorMutationService`, а не напрямую из UI.

### `scripts/presentation/`

ViewModels для UI.

```text
scripts/presentation/
  runtime_hud_view_model.gd
  object_inspector_view_model.gd
  object_identity_view_model.gd
  object_status_view_model.gd
  object_config_view_model.gd
  object_links_view_model.gd
  storage_view_model.gd
  inventory_view_model.gd
  action_menu_view_model.gd
  notification_view_model.gd
```

ViewModel не меняет данные. Она только готовит структуру для отображения.

### `scripts/ui/`

UI builders, presenters и common controls.

```text
scripts/ui/
  common/
    common_panel_builder.gd
    common_tab_builder.gd
    common_section_builder.gd
    common_property_row_builder.gd
    common_button_factory.gd
    common_separator_factory.gd
  runtime_hud/
    runtime_hud_builder.gd
    runtime_hud_presenter.gd
    runtime_controls_builder.gd
    runtime_stats_presenter.gd
  object_inspector/
    object_inspector_builder.gd
    object_inspector_presenter.gd
    identity_section_builder.gd
    status_section_builder.gd
    config_section_builder.gd
    links_section_builder.gd
    validation_section_builder.gd
  map_constructor/
    palette_panel_builder.gd
    palette_panel_presenter.gd
    constructor_toolbar_builder.gd
  notifications/
    notification_bus.gd
    notification_presenter.gd
```

Правило: UI builder строит layout. UI presenter обновляет значения. Ни builder, ни presenter не должны содержать rules power/cooling/access/status.

### `scripts/rendering/`

Визуальная отрисовка.

```text
scripts/rendering/
  world_renderer.gd
  isometric_projection.gd
  object_visual_factory.gd
  item_visual_factory.gd
  overlay_renderer.gd
  preview_renderer.gd
```

Renderer получает render model и рисует. Renderer не меняет gameplay data.

### `data/`

Данные игры в декларативном формате.

```text
data/
  objects/
    power_source.json
    terminal.json
    door.json
    cooling_box.json
    turret.json
  items/
    fuse.json
    key_card.json
    digital_key.json
    access_code.json
    repair_parts.json
  prefabs/
    rooms/
    kits/
  schemas/
    object_config_schema.json
    item_config_schema.json
```

Правило: добавление нового объекта начинается с definition-файла, а не с UI-кода.

### `tests/`

Тесты чистых систем.

```text
tests/
  domain/
    test_object_status_model.gd
    test_power_model.gd
    test_access_model.gd
  runtime/
    test_link_system.gd
    test_cooling_system.gd
  presentation/
    test_object_inspector_view_model.gd
```

---

## Required Core Files

Минимальный набор файлов для правильной игры с нуля:

```text
scripts/app/app_root.gd
scripts/app/app_state_machine.gd
scripts/runtime/mission_runtime.gd
scripts/runtime/world_state_repository.gd
scripts/domain/object_definition_catalog.gd
scripts/domain/item_definition_catalog.gd
scripts/domain/object_config_schema.gd
scripts/domain/object_status_model.gd
scripts/map_constructor/map_constructor_runtime.gd
scripts/map_constructor/constructor_mutation_service.gd
scripts/presentation/object_inspector_view_model.gd
scripts/ui/object_inspector/object_inspector_builder.gd
scripts/ui/common/common_section_builder.gd
scripts/ui/common/common_property_row_builder.gd
scripts/ui/runtime_hud/runtime_hud_builder.gd
scripts/ui/runtime_hud/runtime_hud_presenter.gd
scripts/rendering/world_renderer.gd
scripts/rendering/object_visual_factory.gd
```

Без этих файлов проект снова начнёт расползаться в монолитные `GameUI` и `MissionManager`.

---

## Naming Rules

### `*_model.gd`

Чистая модель или расчёт. Не имеет side effects.

### `*_system.gd`

Runtime-система, которая может менять state.

### `*_service.gd`

Операция или сервис, который вызывается явно. Не autoload по умолчанию.

### `*_view_model.gd`

Данные для UI.

### `*_builder.gd`

Создаёт UI nodes.

### `*_presenter.gd`

Обновляет существующий UI.

### `*_repository.gd`

Хранит и выдаёт state.

---

## Autoload Policy

Autoload разрешён только для настоящих глобальных сервисов:

```text
AppRoot
NotificationBus
SaveLoadService
InputRouter
DebugConsole
SettingsService
```

Autoload запрещён для:

```text
ObjectInspectorPatchLayer
RuntimeControlMenuRecovery
ObjectStatusTreeScanner
WorldActionMenuPostProcessor
```

Если хочется сделать autoload, сначала нужно ответить: почему этот сервис не может быть обычной зависимостью, переданной владельцем?
