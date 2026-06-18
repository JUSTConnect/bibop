# NewBIP Project Structure

Этот документ описывает созданный каркас новой чистой архитектуры в ветке `newbip`.

Цель ветки — не чинить старую архитектуру патчами, а постепенно переносить правильную логику в новые системные модули.

---

## Created Structure

```text
scripts/app/
scripts/domain/
scripts/runtime/
scripts/map_constructor/
scripts/presentation/
scripts/ui/common/
scripts/ui/runtime_hud/
scripts/ui/object_inspector/
scripts/ui/map_constructor_new/
scripts/ui/notifications/
scripts/rendering/
data/objects/
data/items/
data/schemas/
data/prefabs/rooms/
data/prefabs/kits/
tests/domain/
tests/runtime/
tests/presentation/
```

---

## Rules

- Старые временные autoload-патчи не переносить в эту ветку как архитектуру.
- Новый объект подключается через `ObjectDefinition` и schema.
- Все inspector-меню строятся через common section/property row builders.
- Runtime state принадлежит `MissionRuntime` и `WorldStateRepository`.
- UI не пишет gameplay data напрямую.
- Renderer получает render model и не меняет state.

---

## First Migration Slice

Первый практический срез:

```text
ObjectDefinitionCatalog
ObjectInspectorViewModel
CommonPropertyRowBuilder
IdentitySectionBuilder
StatusSectionBuilder
ObjectInspectorBuilder
```

После этого можно переносить текущий object inspector без external patch layers.
