extends SceneTree

const InteractionSystem = preload("res://scripts/world/interaction_system.gd")
const ReelService = preload("res://scripts/game/power_cable_reel_service.gd")
const StoreRef = preload("res://scripts/world/world_state_store.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _socket() -> Dictionary:
	return {
		"id":"socket",
		"position":Vector2i(0, 0),
		"object_group":"power",
		"object_type":"power_socket",
		"generic_power_role":"socket_input",
		"power_state":"powered",
		"resolved_source_id":"source",
		"resolved_circuit_id":"main",
		"is_powered":true
	}


func _target(kind: String) -> Dictionary:
	var base: Dictionary = {
		"id":"target",
		"position":Vector2i(2, 0),
		"state":"unpowered",
		"status":"unpowered",
		"is_powered":false,
		"power_state":"unpowered",
		"power_mode":"external",
		"runtime_reel_feed":true,
		"accepts_runtime_power_reel":true,
		"power_input_profiles":["runtime_reel_feed"],
		"intent_state":"on",
		"operational_state":"ready",
		"preferred_source_id":"authored_source"
	}
	match kind:
		"terminal":
			base["object_group"] = "terminal"
			base["object_type"] = "control_terminal"
		"door":
			base["object_group"] = "door"
			base["object_type"] = "door"
			base["requires_external_power"] = true
			base["power_behavior"] = "requires_power_to_open"
		"firewall":
			base["object_group"] = "security"
			base["object_type"] = "firewall"
			base["power_type"] = "external"
		_:
			base["object_group"] = "machine"
			base["object_type"] = "machine"
	return base


func _reel() -> Dictionary:
	var reel: Dictionary = ReelService.make_default_reel("reel", 6)
	reel["position"] = Vector2i(1, 1)
	return reel


func _actor_with_end(end_index: int) -> Dictionary:
	return {
		"held_item_type":"cable_reel_end",
		"held_item_data":{"item_type":"cable_reel_end", "reel_id":"reel", "end_index":end_index},
		"manipulator_occupied":true
	}


func _module() -> Dictionary:
	return {"id":"manipulator_arm_v1"}


func _find(objects: Array[Dictionary], object_id: String) -> Dictionary:
	for object_data in objects:
		if str(object_data.get("id", "")) == object_id:
			return object_data
	return {}


func _effect_by_type(effects: Array, effect_type: String) -> Dictionary:
	for effect_value in effects:
		if effect_value is Dictionary and str(Dictionary(effect_value).get("type", "")) == effect_type:
			return Dictionary(effect_value)
	return {}


func _apply(objects: Array[Dictionary], action: String, params: Dictionary) -> Dictionary:
	var result: Dictionary = ReelService.apply_action_to_world(objects, "reel", action, params)
	_assert(bool(result.get("success", false)), "reel action failed %s: %s" % [action, str(result)])
	return result


func _connect_with_reel_service(objects: Array[Dictionary], target_id: String) -> Dictionary:
	_apply(objects, ReelService.ACTION_HOLD_END, {"end":ReelService.END_1})
	_apply(objects, ReelService.ACTION_CONNECT_END, {"end":ReelService.END_1, "target_id":"socket"})
	_apply(objects, ReelService.ACTION_HOLD_END, {"end":ReelService.END_2})
	_apply(objects, ReelService.ACTION_CONNECT_END, {"end":ReelService.END_2, "target_id":target_id})
	return _apply(objects, ReelService.ACTION_SET_PATH, {"path_cells":[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]})


func _run_case(kind: String) -> void:
	var target: Dictionary = _target(kind)
	var actor: Dictionary = _actor_with_end(2)
	var gate: Dictionary = InteractionSystem.can_apply_action(actor, _module(), target, "plug_in")
	_assert(bool(gate.get("success", false)), "%s plug_in gate failed: %s" % [kind, str(gate)])
	var action: Dictionary = InteractionSystem.apply_action(actor, _module(), target.duplicate(true), "plug_in")
	_assert(bool(action.get("success", false)), "%s plug_in action failed: %s" % [kind, str(action)])
	var connect_effect: Dictionary = _effect_by_type(Array(action.get("effects", [])), "connect_cable_end_to_target")
	_assert(not connect_effect.is_empty(), "%s plug_in missing connect effect" % kind)
	_assert(not _effect_by_type(Array(action.get("effects", [])), "power_recalc_needed").is_empty(), "%s plug_in missing recalc effect" % kind)

	var objects: Array[Dictionary] = [_socket(), target, _reel()]
	var complete: Dictionary = _connect_with_reel_service(objects, "target")
	_assert(str(complete.get("code", "")) == ReelService.CODE_COMPLETE, "%s reel did not complete: %s" % [kind, str(complete)])
	var powered_target: Dictionary = _find(objects, "target")
	_assert(bool(powered_target.get("is_powered", false)), "%s target was not powered" % kind)
	_assert(str(powered_target.get("runtime_reel_feed_id", "")) == "reel", "%s runtime feed id missing" % kind)
	_assert(str(powered_target.get("resolved_source_id", "")) == "source", "%s source not inherited" % kind)
	_assert(str(powered_target.get("resolved_circuit_id", "")) == ReelService.CIRCUIT_MAIN, "%s circuit not main" % kind)
	_assert(str(powered_target.get("intent_state", "")) == "on", "%s intent mutated" % kind)
	_assert(str(powered_target.get("operational_state", "")) == "ready", "%s operation mutated" % kind)
	_assert(str(powered_target.get("preferred_source_id", "")) == "authored_source", "%s preferred source mutated" % kind)

	var store = StoreRef.new()
	_assert(bool(store.replace_snapshot(objects).get("ok", false)), "%s store rejected objects" % kind)
	_assert(store.get_all_bindings().is_empty(), "%s reel created BindingStore record" % kind)

	objects[0]["power_state"] = "unpowered"
	objects[0]["resolved_source_id"] = ""
	objects[0]["is_powered"] = false
	var reel_before: Dictionary = _find(objects, "reel").duplicate(true)
	var unpowered: Dictionary = ReelService.recalculate_for_socket(objects, "socket")
	_assert(bool(unpowered.get("success", false)), "%s socket recalc failed" % kind)
	var unpowered_target: Dictionary = _find(objects, "target")
	var reel_after: Dictionary = _find(objects, "reel")
	_assert(not bool(unpowered_target.get("is_powered", true)), "%s target stayed powered after socket loss" % kind)
	_assert(str(unpowered_target.get("power_state", "")) == "unpowered", "%s target power_state not unpowered" % kind)
	_assert(Dictionary(reel_after.get(ReelService.END_1, {})) == Dictionary(reel_before.get(ReelService.END_1, {})), "%s end_1 changed after socket loss" % kind)
	_assert(Dictionary(reel_after.get(ReelService.END_2, {})) == Dictionary(reel_before.get(ReelService.END_2, {})), "%s end_2 changed after socket loss" % kind)
	_assert(Array(reel_after.get("path_cells", [])) == Array(reel_before.get("path_cells", [])), "%s path changed after socket loss" % kind)
	_assert(str(reel_after.get("connection_state", "")) == ReelService.CONNECTION_COMPLETE, "%s physical connection broke after socket loss" % kind)


func _run() -> void:
	await process_frame
	for kind in ["terminal", "door", "firewall"]:
		_run_case(kind)
	await process_frame
	if failures.is_empty():
		print("POWER_CABLE_REEL_EXTERNAL_TARGETS_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("POWER_CABLE_REEL_EXTERNAL_TARGETS_GATE: FAIL: %s" % failure)
	quit(1)
