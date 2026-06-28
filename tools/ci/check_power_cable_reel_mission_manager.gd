extends SceneTree

const MissionManagerRef = preload("res://scripts/game/mission_manager.gd")
const ReelService = preload("res://scripts/game/power_cable_reel_service.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _find(objects: Array[Dictionary], object_id: String) -> Dictionary:
	for object_data in objects:
		if str(object_data.get("id", "")) == object_id:
			return object_data
	return {}

func _apply(manager: Node, action: String, parameters: Dictionary) -> void:
	var result: Dictionary = manager.apply_power_cable_reel_action("reel", action, parameters)
	_assert(bool(result.get("success", false)), "action failed: %s" % str(result))

func _run() -> void:
	await process_frame
	var manager = MissionManagerRef.new()
	root.add_child(manager)
	var reel: Dictionary = ReelService.make_default_reel("reel", 5)
	reel["position"] = Vector2i(1, 1)
	var objects: Array[Dictionary] = [
		{"id":"socket", "position":Vector2i(0, 0), "object_group":"power", "object_type":"power_socket", "generic_power_role":"socket_input", "power_state":"powered", "resolved_source_id":"source", "is_powered":true},
		{"id":"target", "position":Vector2i(2, 0), "object_type":"machine", "runtime_reel_feed":true, "power_state":"unpowered", "is_powered":false, "intent_state":"on", "operational_state":"ready"},
		reel
	]
	_assert(bool(manager.world_state_store.replace_snapshot(objects).get("ok", false)), "world load failed")
	var before: Array[Dictionary] = manager.world_state_store.get_all_objects()
	var preview: Dictionary = manager.preview_power_cable_reel_action("reel", ReelService.ACTION_SET_PATH, {"path_cells":[Vector2i(0, 0), Vector2i(2, 0)]})
	_assert(not bool(preview.get("success", true)), "invalid preview succeeded")
	_assert(manager.world_state_store.get_all_objects() == before, "preview mutated store")
	_apply(manager, ReelService.ACTION_HOLD_END, {"end":ReelService.END_1})
	_apply(manager, ReelService.ACTION_CONNECT_END, {"end":ReelService.END_1, "target_id":"socket"})
	_apply(manager, ReelService.ACTION_HOLD_END, {"end":ReelService.END_2})
	_apply(manager, ReelService.ACTION_CONNECT_END, {"end":ReelService.END_2, "target_id":"target"})
	_apply(manager, ReelService.ACTION_SET_PATH, {"path_cells":[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]})
	var powered: Array[Dictionary] = manager.world_state_store.get_all_objects()
	var target: Dictionary = _find(powered, "target")
	_assert(bool(target.get("is_powered", false)), "target not powered")
	_assert(str(target.get("resolved_source_id", "")) == "source", "source not inherited")
	_assert(str(target.get("resolved_circuit_id", "")) == ReelService.CIRCUIT_MAIN, "circuit not main")
	_assert(manager.world_state_store.get_all_bindings().is_empty(), "reel created binding")
	var reel_before: Dictionary = _find(powered, "reel").duplicate(true)
	var socket: Dictionary = _find(powered, "socket")
	socket["power_state"] = "unpowered"
	socket["resolved_source_id"] = ""
	socket["is_powered"] = false
	for index in range(powered.size()):
		if str(powered[index].get("id", "")) == "socket":
			powered[index] = socket
	manager.world_state_store.apply_non_structural_snapshot(powered, "socket_power_loss")
	_assert(bool(manager.recalculate_power_cable_reels_for_socket("socket").get("success", false)), "socket recalc failed")
	var after: Array[Dictionary] = manager.world_state_store.get_all_objects()
	target = _find(after, "target")
	var reel_after: Dictionary = _find(after, "reel")
	_assert(not bool(target.get("is_powered", true)), "target stayed powered")
	_assert(str(target.get("intent_state", "")) == "on", "intent changed")
	_assert(str(target.get("operational_state", "")) == "ready", "operation changed")
	_assert(Dictionary(reel_after.get(ReelService.END_1, {})) == Dictionary(reel_before.get(ReelService.END_1, {})), "end_1 changed")
	_assert(Dictionary(reel_after.get(ReelService.END_2, {})) == Dictionary(reel_before.get(ReelService.END_2, {})), "end_2 changed")
	_assert(Array(reel_after.get("path_cells", [])) == Array(reel_before.get("path_cells", [])), "path changed")
	_assert(manager.world_state_store.get_all_bindings().is_empty(), "recalc created binding")
	manager.queue_free()
	await process_frame
	if failures.is_empty():
		print("POWER_CABLE_REEL_MISSION_MANAGER_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("POWER_CABLE_REEL_MISSION_MANAGER_GATE: FAIL: %s" % failure)
	quit(1)
