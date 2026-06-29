extends SceneTree

const ManagerRef = preload("res://tools/ci/movable_test_mission_manager.gd")
const MovableService = preload("res://scripts/game/movable/movable_action_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _actor(actor_type: String, arm: int, claw: int, occupied: bool = false) -> Dictionary:
	return {"actor_type":actor_type, "actor_count":1, "power_class":actor_type, "manipulator_level":arm, "manipulator_active":arm > 0, "manipulator_occupied":occupied, "heavy_claw_level":claw, "heavy_claw_active":claw > 0, "actor_position":Vector2i(0, 0), "facing_direction":Vector2i(1, 0)}

func _crate(object_id: String, weight: String) -> Dictionary:
	return {"id":object_id, "position":Vector2i(1, 0), "object_group":"physical_object", "object_type":"crate", "weight_class":weight, "entity_contract":{"entity_type":"movable"}, "state":"active", "health_state":"healthy"}

func _code(result: Dictionary) -> String:
	return str(result.get("code", result.get("reason_code", "")))

func _run() -> void:
	await process_frame
	var manager = ManagerRef.new()
	root.add_child(manager)
	var objects: Array[Dictionary] = [_crate("crate", "normal"), {"id":"source", "position":Vector2i(5, 5), "object_type":"power_source_class_1", "power_state":"source_on", "current_heat":7}]
	_assert(bool(manager.world_state_store.replace_snapshot(objects).get("ok", false)), "world load failed")
	var actor: Dictionary = _actor("scout", 1, 0)
	manager.set_test_cell_blocked(Vector2i(2, 0), true)
	var before: Dictionary = manager.world_state_store.get_object_by_id("crate")
	var preview: Dictionary = manager.preview_movable_action(actor, "crate", Vector2i(2, 0), "push")
	var execution: Dictionary = manager.move_world_object_with_requirements("crate", Vector2i(2, 0), actor, "push")
	_assert(_code(preview) == MovableService.CODE_DESTINATION_BLOCKED, "blocked preview code mismatch")
	_assert(_code(execution) == _code(preview), "preview and execution codes differ")
	_assert(manager.world_state_store.get_object_by_id("crate") == before, "failed move mutated crate")
	manager.set_test_cell_blocked(Vector2i(2, 0), false)
	var source_before: Dictionary = manager.world_state_store.get_object_by_id("source")
	var moved: Dictionary = manager.move_world_object_with_requirements("crate", Vector2i(2, 0), actor, "push")
	_assert(bool(moved.get("success", false)), "valid move failed")
	_assert(Vector2i(manager.world_state_store.get_object_by_id("crate").get("position", Vector2i(-1, -1))) == Vector2i(2, 0), "crate did not move")
	_assert(manager.world_state_store.get_object_by_id("source") == source_before, "move mutated unrelated power state")

	var heavy = ManagerRef.new()
	root.add_child(heavy)
	var heavy_objects: Array[Dictionary] = [_crate("heavy", "heavy")]
	heavy.world_state_store.replace_snapshot(heavy_objects)
	_assert(_code(heavy.preview_movable_action(actor, "heavy", Vector2i(2, 0), "push")) == MovableService.CODE_ACTOR_TYPE_INCOMPATIBLE, "heavy crate accepted scout")
	var engineer: Dictionary = _actor("engineer", 1, 1, true)
	var heavy_preview: Dictionary = heavy.preview_movable_action(engineer, "heavy", Vector2i(2, 0), "push")
	_assert(bool(heavy_preview.get("success", false)), "valid Heavy Claw preview failed")
	var heavy_move: Dictionary = heavy.move_world_object_with_requirements("heavy", Vector2i(2, 0), engineer, "push")
	_assert(bool(heavy_move.get("success", false)), "valid Heavy Claw move failed")

	manager.queue_free()
	heavy.queue_free()
	await process_frame
	if failures.is_empty():
		print("MOVABLE_MISSION_MANAGER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("MOVABLE_MISSION_MANAGER_GATE: FAIL: %s" % failure)
	quit(1)
