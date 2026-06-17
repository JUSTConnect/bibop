extends SceneTree

const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")
const GridManagerRef = preload("res://scripts/field/grid_manager.gd")

var _failed: bool = false

func _initialize() -> void:
	_run()
	if _failed:
		quit(1)
		return
	print("OK: Map constructor inspection model checks passed")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failed = true

func _run() -> void:
	_check_item_only_cell_has_only_items_tab()
	_check_mixed_object_and_item_cell_can_show_both_tabs()

func _make_manager() -> Node:
	var manager: Node = MissionManagerRef.new()
	var grid_manager: Node = GridManagerRef.new()
	root.add_child(grid_manager)
	root.add_child(manager)
	manager.grid_manager = grid_manager
	manager.setup_task_test_sandbox_world()
	return manager

func _tab_ids(model: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for tab_variant in Array(model.get("tabs", [])):
		var tab: Dictionary = Dictionary(tab_variant)
		ids.append(str(tab.get("id", "")).to_lower())
	return ids

func _get_tab(model: Dictionary, tab_id: String) -> Dictionary:
	for tab_variant in Array(model.get("tabs", [])):
		var tab: Dictionary = Dictionary(tab_variant)
		if str(tab.get("id", "")).to_lower() == tab_id:
			return tab
	return {}

func _check_item_only_cell_has_only_items_tab() -> void:
	var manager: Node = _make_manager()
	var cell := Vector2i(2, 2)
	var placed: Dictionary = manager.place_map_constructor_prefab("physical_item", cell)
	_expect(bool(placed.get("ok", false)), "physical_item should place successfully in constructor map.")
	_expect(bool(placed.get("is_item", false)), "physical_item placement should be marked as an item.")
	var placed_item_id: String = str(placed.get("object_id", ""))
	var model: Dictionary = manager.get_map_constructor_cell_inspection_model(cell, "item", placed_item_id)
	var ids: Array[String] = _tab_ids(model)
	_expect(ids.has("items"), "Item-only inspection tabs should contain items.")
	_expect(not ids.has("objects"), "Item-only inspection tabs should not contain objects.")
	_expect(str(model.get("preferred_tab", "")) == "items", "Preferred tab for placed item should be items.")
	var items_tab: Dictionary = _get_tab(model, "items")
	for entity_variant in Array(items_tab.get("entities", [])):
		var entity: Dictionary = Dictionary(entity_variant)
		_expect(str(entity.get("entity_kind", "")) == "item", "Every item tab entity should have entity_kind=item.")
	var objects_tab: Dictionary = _get_tab(model, "objects")
	for entity_variant in Array(objects_tab.get("entities", [])):
		var entity: Dictionary = Dictionary(entity_variant)
		var data: Dictionary = Dictionary(entity.get("data", {}))
		_expect(str(data.get("object_group", "")).to_lower() != "item", "Object tab must not contain object_group=item.")
		_expect(str(data.get("object_type", "")).to_lower() != "item", "Object tab must not contain object_type=item.")
	manager.queue_free()

func _check_mixed_object_and_item_cell_can_show_both_tabs() -> void:
	var manager: Node = _make_manager()
	var cell := Vector2i(3, 3)
	var placed_crate: Dictionary = manager.place_map_constructor_prefab("crate", cell)
	_expect(bool(placed_crate.get("ok", false)), "crate should place successfully in constructor map.")
	var object_model: Dictionary = manager.get_map_constructor_cell_inspection_model(cell)
	_expect(_tab_ids(object_model).has("objects"), "Crate inspection tabs should contain objects.")
	var placed_item: Dictionary = manager.place_map_constructor_prefab("physical_item", cell)
	_expect(bool(placed_item.get("ok", false)), "physical_item should place successfully on a crate cell when allowed.")
	var mixed_model: Dictionary = manager.get_map_constructor_cell_inspection_model(cell, "item", str(placed_item.get("object_id", "")))
	var mixed_ids: Array[String] = _tab_ids(mixed_model)
	_expect(mixed_ids.has("objects"), "Mixed object/item cell should contain objects.")
	_expect(mixed_ids.has("items"), "Mixed object/item cell should contain items.")
	manager.queue_free()
