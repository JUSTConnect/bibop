extends SceneTree

const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")
const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_run_store_checks()
	_run_mission_manager_checks()
	if failures.is_empty():
		print("World state store checks passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
	return

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _floor(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "door", "object_type": "door", "position": cell}

func _item(id: String, cell: Vector2i) -> Dictionary:
	return {"id": id, "object_group": "item", "object_type": "item", "position": cell}

func _wall(id: String, cell: Vector2i, side: String) -> Dictionary:
	return {"id": id, "object_group": "terminal", "object_type": "terminal", "position": cell, "mount": "wall", "wall_side": side}

func _run_store_checks() -> void:
	var store: WorldStateStore = WorldStateStoreRef.new()
	_expect(bool(store.add_object(_floor("door_a", Vector2i(1, 1))).get("ok", false)), "adding floor object succeeds")
	_expect(not bool(store.add_object(_floor("door_a", Vector2i(2, 2))).get("ok", true)), "duplicate id rejected")
	_expect(str(store.get_object_by_id("door_a").get("id", "")) == "door_a", "lookup by id works")
	_expect(str(store.get_floor_object_at_cell(Vector2i(1, 1)).get("id", "")) == "door_a", "floor lookup works")
	store.move_object("door_a", Vector2i(3, 3))
	_expect(store.get_floor_object_at_cell(Vector2i(1, 1)).is_empty(), "move clears old floor index")
	_expect(str(store.get_floor_object_at_cell(Vector2i(3, 3)).get("id", "")) == "door_a", "move adds new floor index")
	store.add_item(Vector2i(3, 3), _item("item_a", Vector2i(3, 3)))
	store.add_item(Vector2i(3, 3), _item("item_b", Vector2i(3, 3)))
	_expect(store.get_items_at_cell(Vector2i(3, 3)).size() == 2, "two items can share a cell")
	_expect(str(store.get_floor_object_at_cell(Vector2i(3, 3)).get("id", "")) == "door_a", "items are not floor occupants")
	var removed_item := store.remove_first_item_at_cell(Vector2i(3, 3))
	_expect(str(Dictionary(removed_item.get("removed", {})).get("id", "")) == "item_a", "first item removed")
	_expect(str(store.get_items_at_cell(Vector2i(3, 3))[0].get("id", "")) == "item_b", "second item preserved")
	store.add_object(_wall("wall_a", Vector2i(3, 3), "north"))
	store.add_object(_wall("wall_b", Vector2i(3, 3), "east"))
	_expect(store.get_wall_mounted_objects_at_cell(Vector2i(3, 3)).size() == 2, "wall mounted lookup supports side separation")
	store.remove_object_by_id("door_a")
	_expect(store.get_floor_object_at_cell(Vector2i(3, 3)).is_empty(), "remove clears floor index")
	_expect(not bool(store.add_object({"position": Vector2i.ZERO}).get("ok", true)), "empty id fails")
	_expect(not bool(store.replace_snapshot([_floor("dup", Vector2i.ZERO), _floor("dup", Vector2i.ONE)]).get("ok", true)), "duplicate snapshot fails")
	store.replace_snapshot([_floor("a", Vector2i.ZERO), _item("b", Vector2i.ZERO), _wall("c", Vector2i.ZERO, "north")])
	_expect(store.validate_consistency().is_empty(), "valid store has no consistency warnings")
	var snapshot := store.get_diagnostic_snapshot()
	snapshot["floor"].clear()
	_expect(store.validate_consistency().is_empty(), "diagnostic snapshot cannot corrupt indexes")
	_expect(Array(store.get_diagnostic_snapshot().get("object_ids", [])) == ["a", "b", "c"], "order remains deterministic")

func _run_mission_manager_checks() -> void:
	var manager: Node = MissionManagerRef.new()
	manager.set_world_object_at_cell(Vector2i(5, 5), _floor("mm_floor", Vector2i(5, 5)))
	_expect(str(manager.get_world_object_at_cell(Vector2i(5, 5)).get("id", "")) == "mm_floor", "MissionManager get delegates to store")
	manager.world_state_store.move_object("mm_floor", Vector2i(6, 5))
	_expect(manager.get_world_object_at_cell(Vector2i(5, 5)).is_empty(), "MissionManager move clears old cell")
	manager.add_item_at_cell(Vector2i(6, 5), _item("mm_item", Vector2i(6, 5)))
	_expect(manager.get_items_at_cell(Vector2i(6, 5)).size() == 1, "MissionManager add item delegates")
	_expect(str(manager.remove_first_item_at_cell(Vector2i(6, 5)).get("id", "")) == "mm_item", "MissionManager remove item delegates")
	manager.remove_world_object_at_cell(Vector2i(6, 5))
	_expect(manager.world_state_store.get_object_count() == 0, "MissionManager remove object delegates")
	manager.world_state_store.replace_snapshot([_floor("mm_replace", Vector2i(1, 2))])
	_expect(str(manager.get_world_object_at_cell(Vector2i(1, 2)).get("id", "")) == "mm_replace", "MissionManager replacement snapshot works")
	_expect(manager.world_state_store.validate_consistency().is_empty(), "MissionManager store consistency remains valid")
	manager.queue_free()
