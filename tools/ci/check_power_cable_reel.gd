extends SceneTree

const ReelService = preload("res://scripts/game/power_cable_reel_service.gd")
const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _socket(object_id: String, cell: Vector2i, source_id: String, powered: bool = true) -> Dictionary:
	return {
		"id": object_id,
		"position": cell,
		"object_group": "power",
		"object_type": "power_socket",
		"generic_power_role": "socket_input",
		"power_state": "powered" if powered else "unpowered",
		"resolved_source_id": source_id if powered else "",
		"resolved_circuit_id": "main",
		"is_powered": powered
	}

func _target(object_id: String, cell: Vector2i) -> Dictionary:
	return {
		"id": object_id,
		"position": cell,
		"object_group": "machine",
		"object_type": "machine",
		"runtime_reel_feed": true,
		"power_state": "unpowered",
		"is_powered": false,
		"intent_state": "on",
		"operational_state": "ready",
		"preferred_source_id": "preferred_authoring_source"
	}

func _reel(object_id: String, cell: Vector2i, max_length: int = 8) -> Dictionary:
	var reel: Dictionary = ReelService.make_default_reel(object_id, max_length)
	reel["position"] = cell
	return reel

func _find_index(objects: Array[Dictionary], object_id: String) -> int:
	for index in range(objects.size()):
		if str(objects[index].get("id", "")) == object_id:
			return index
	return -1

func _find(objects: Array[Dictionary], object_id: String) -> Dictionary:
	var index: int = _find_index(objects, object_id)
	if index < 0:
		return {}
	return Dictionary(objects[index])

func _apply(objects: Array[Dictionary], reel_id: String, action: String, parameters: Dictionary = {}, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var result: Dictionary = ReelService.apply_action_to_world(objects, reel_id, action, parameters, blocked_cells)
	_assert(bool(result.get("success", false)), "action %s failed: %s" % [action, str(result)])
	return result

func _connect_complete(objects: Array[Dictionary], reel_id: String, socket_id: String, target_id: String, socket_end: String = ReelService.END_1) -> Dictionary:
	var target_end: String = ReelService.END_2 if socket_end == ReelService.END_1 else ReelService.END_1
	_apply(objects, reel_id, ReelService.ACTION_HOLD_END, {"end": socket_end})
	var first_connect: Dictionary = _apply(objects, reel_id, ReelService.ACTION_CONNECT_END, {"end": socket_end, "target_id": socket_id})
	_assert(str(first_connect.get("connection_state", "")) == ReelService.CONNECTION_PARTIAL, "first endpoint was not partial")
	_apply(objects, reel_id, ReelService.ACTION_HOLD_END, {"end": target_end})
	_apply(objects, reel_id, ReelService.ACTION_CONNECT_END, {"end": target_end, "target_id": target_id})
	var socket_cell: Vector2i = Vector2i(_find(objects, socket_id).get("position", Vector2i.ZERO))
	var target_cell: Vector2i = Vector2i(_find(objects, target_id).get("position", Vector2i.ZERO))
	var path: Array[Vector2i] = []
	var step: int = 1 if target_cell.x >= socket_cell.x else -1
	for x in range(socket_cell.x, target_cell.x + step, step):
		path.append(Vector2i(x, socket_cell.y))
	var path_result: Dictionary = _apply(objects, reel_id, ReelService.ACTION_SET_PATH, {"path_cells": path})
	_assert(str(path_result.get("connection_state", "")) == ReelService.CONNECTION_COMPLETE, "complete reel did not reach complete state: %s" % str(path_result))
	return path_result

func _run() -> void:
	await process_frame
	var objects: Array[Dictionary] = [
		_socket("socket_a", Vector2i(0, 0), "source_a", true),
		_socket("socket_b", Vector2i(4, 0), "source_b", true),
		_target("machine_a", Vector2i(2, 0)),
		_reel("reel_a", Vector2i(1, 1), 8)
	]
	var complete: Dictionary = _connect_complete(objects, "reel_a", "socket_a", "machine_a", ReelService.END_2)
	_assert(str(complete.get("code", "")) == ReelService.CODE_COMPLETE, "complete feed code missing")
	_assert(str(complete.get("socket_end", "")) == ReelService.END_2, "socket end was inferred from number instead of type")
	_assert(str(complete.get("target_end", "")) == ReelService.END_1, "target end was inferred incorrectly")
	var target: Dictionary = _find(objects, "machine_a")
	_assert(bool(target.get("is_powered", false)), "complete reel did not power target")
	_assert(str(target.get("resolved_source_id", "")) == "source_a", "target did not inherit socket source")
	_assert(str(target.get("resolved_circuit_id", "")) == ReelService.CIRCUIT_MAIN, "target circuit is not main")
	_assert(str(target.get("intent_state", "")) == "on", "feed changed intent_state")
	_assert(str(target.get("operational_state", "")) == "ready", "feed changed operational_state")
	_assert(str(target.get("preferred_source_id", "")) == "preferred_authoring_source", "feed mutated preferred_source_id")

	var reel_before_power_loss: Dictionary = _find(objects, "reel_a").duplicate(true)
	var socket_a_index: int = _find_index(objects, "socket_a")
	objects[socket_a_index]["power_state"] = "unpowered"
	objects[socket_a_index]["resolved_source_id"] = ""
	objects[socket_a_index]["is_powered"] = false
	var unpowered: Dictionary = ReelService.recalculate_for_socket(objects, "socket_a")
	_assert(bool(unpowered.get("success", false)), "socket-scoped recalculation failed")
	target = _find(objects, "machine_a")
	_assert(not bool(target.get("is_powered", true)), "unpowered socket kept target powered")
	_assert(str(target.get("power_state", "")) == "unpowered", "target power state not cleared")
	_assert(str(target.get("intent_state", "")) == "on", "power loss changed intent_state")
	_assert(str(target.get("operational_state", "")) == "ready", "power loss changed operational_state")
	var reel_after_power_loss: Dictionary = _find(objects, "reel_a")
	_assert(Dictionary(reel_after_power_loss.get(ReelService.END_1, {})) == Dictionary(reel_before_power_loss.get(ReelService.END_1, {})), "power loss changed end_1")
	_assert(Dictionary(reel_after_power_loss.get(ReelService.END_2, {})) == Dictionary(reel_before_power_loss.get(ReelService.END_2, {})), "power loss changed end_2")
	_assert(Array(reel_after_power_loss.get("path_cells", [])) == Array(reel_before_power_loss.get("path_cells", [])), "power loss changed path")
	_assert(str(reel_after_power_loss.get("connection_state", "")) == ReelService.CONNECTION_COMPLETE, "unpowered socket broke physical connection")

	objects[socket_a_index]["power_state"] = "powered"
	objects[socket_a_index]["resolved_source_id"] = "source_a_restored"
	objects[socket_a_index]["is_powered"] = true
	ReelService.recalculate_for_socket(objects, "socket_a")
	target = _find(objects, "machine_a")
	_assert(bool(target.get("is_powered", false)), "restored socket did not automatically restore target")
	_assert(str(target.get("resolved_source_id", "")) == "source_a_restored", "restored socket source was not inherited")

	var reel_current: Dictionary = _find(objects, "reel_a")
	var socket_end: String = ReelService.END_1 if str(Dictionary(reel_current.get(ReelService.END_1, {})).get("target_id", "")) == "socket_a" else ReelService.END_2
	_apply(objects, "reel_a", ReelService.ACTION_DISCONNECT_END, {"end": socket_end})
	_apply(objects, "reel_a", ReelService.ACTION_CONNECT_END, {"end": socket_end, "target_id": "socket_b"})
	var repath: Array[Vector2i] = [Vector2i(4, 0), Vector2i(3, 0), Vector2i(2, 0)]
	var reconnected: Dictionary = _apply(objects, "reel_a", ReelService.ACTION_SET_PATH, {"path_cells": repath})
	_assert(str(reconnected.get("resolved_source_id", "")) == "source_b", "reconnected reel kept old socket source")
	target = _find(objects, "machine_a")
	_assert(str(target.get("resolved_source_id", "")) == "source_b", "target source did not follow new socket")

	var before_failed_preview: Array[Dictionary] = objects.duplicate(true)
	var invalid_preview: Dictionary = ReelService.preview_action(objects, "reel_a", ReelService.ACTION_SET_PATH, {"path_cells": [Vector2i(4, 0), Vector2i(2, 0)]})
	_assert(not bool(invalid_preview.get("success", true)), "non-contiguous path preview succeeded")
	_assert(objects == before_failed_preview, "failed preview mutated world")
	var blocked_preview: Dictionary = ReelService.preview_action(objects, "reel_a", ReelService.ACTION_SET_PATH, {"path_cells": repath}, [Vector2i(3, 0)])
	_assert(str(blocked_preview.get("code", "")) == ReelService.CODE_PATH_BLOCKED, "blocked path code missing")
	_assert(objects == before_failed_preview, "blocked preview mutated world")
	var too_long_preview: Dictionary = ReelService.preview_action(objects, "reel_a", ReelService.ACTION_SET_PATH, {"path_cells": [Vector2i(4, 0), Vector2i(4, 1), Vector2i(3, 1), Vector2i(2, 1), Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-2, 0), Vector2i(-3, 0)]})
	_assert(str(too_long_preview.get("code", "")) == ReelService.CODE_PATH_TOO_LONG, "too-long path code missing")

	var damage_result: Dictionary = _apply(objects, "reel_a", ReelService.ACTION_DAMAGE)
	_assert(str(damage_result.get("connection_state", "")) == ReelService.CONNECTION_BROKEN, "damaged reel did not become broken")
	_assert(not bool(_find(objects, "machine_a").get("is_powered", true)), "broken reel kept target powered")
	var repair_result: Dictionary = _apply(objects, "reel_a", ReelService.ACTION_REPAIR)
	_assert(str(repair_result.get("code", "")) == ReelService.CODE_RECONNECT_REQUIRED, "repair restored feed without reconnect")
	_assert(not bool(_find(objects, "machine_a").get("is_powered", true)), "repair alone restored target power")
	var reconnect_result: Dictionary = _apply(objects, "reel_a", ReelService.ACTION_RECONNECT)
	_assert(str(reconnect_result.get("code", "")) == ReelService.CODE_COMPLETE, "explicit reconnect did not restore complete state")
	_assert(bool(_find(objects, "machine_a").get("is_powered", false)), "explicit reconnect did not restore power")

	var occupancy_objects: Array[Dictionary] = [
		_socket("shared_socket", Vector2i(0, 2), "shared_source", true),
		_target("shared_target", Vector2i(2, 2)),
		_reel("reel_one", Vector2i(0, 3)),
		_reel("reel_two", Vector2i(1, 3))
	]
	_apply(occupancy_objects, "reel_one", ReelService.ACTION_HOLD_END, {"end": ReelService.END_1})
	_apply(occupancy_objects, "reel_one", ReelService.ACTION_CONNECT_END, {"end": ReelService.END_1, "target_id": "shared_socket"})
	_apply(occupancy_objects, "reel_two", ReelService.ACTION_HOLD_END, {"end": ReelService.END_1})
	var occupied_preview: Dictionary = ReelService.preview_action(occupancy_objects, "reel_two", ReelService.ACTION_CONNECT_END, {"end": ReelService.END_1, "target_id": "shared_socket"})
	_assert(str(occupied_preview.get("code", "")) == ReelService.CODE_ENDPOINT_OCCUPIED, "occupied endpoint was accepted")

	var incompatible_objects: Array[Dictionary] = [
		_reel("reel_bad", Vector2i(0, 4)),
		{"id": "plain_crate", "position": Vector2i(1, 4), "object_type": "crate"}
	]
	_apply(incompatible_objects, "reel_bad", ReelService.ACTION_HOLD_END, {"end": ReelService.END_1})
	var incompatible_preview: Dictionary = ReelService.preview_action(incompatible_objects, "reel_bad", ReelService.ACTION_CONNECT_END, {"end": ReelService.END_1, "target_id": "plain_crate"})
	_assert(str(incompatible_preview.get("code", "")) == ReelService.CODE_TARGET_INCOMPATIBLE, "incompatible target was accepted")

	var store = WorldStateStoreRef.new()
	var store_objects: Array[Dictionary] = [
		_socket("store_socket", Vector2i(0, 5), "store_source", true),
		_target("store_target", Vector2i(2, 5)),
		_reel("store_reel", Vector2i(1, 6))
	]
	var store_load: Dictionary = store.replace_snapshot(store_objects)
	_assert(bool(store_load.get("ok", false)), "WorldStateStore rejected reel test objects")
	var runtime_objects: Array[Dictionary] = store.get_all_objects()
	_connect_complete(runtime_objects, "store_reel", "store_socket", "store_target")
	var store_commit: Dictionary = store.apply_non_structural_snapshot(runtime_objects, "runtime_reel_action")
	_assert(bool(store_commit.get("ok", false)), "WorldStateStore rejected runtime reel mutation: %s" % str(store_commit))
	_assert(store.get_all_bindings().is_empty(), "runtime reel created a BindingStore record")

	for field_name in ["success", "code", "reason_code", "reel_id", "connection_state", "socket_id", "target_id", "resolved_source_id", "resolved_circuit_id", "powered", "details", "notification_event"]:
		_assert(complete.has(field_name), "reel result missing field %s" % field_name)
	_assert(Dictionary(complete.get("notification_event", {})).is_empty(), "autonomous reel resolution created popup event")

	await process_frame
	if failures.is_empty():
		print("POWER_CABLE_REEL_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("POWER_CABLE_REEL_GATE: FAIL: %s" % failure)
	quit(1)
