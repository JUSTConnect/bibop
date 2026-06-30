extends SceneTree

const Service = preload("res://scripts/game/bipob_action_view_model_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	await process_frame
	var door := {"id":"door_a", "position":Vector2i(2, 0), "object_group":"door", "object_type":"door", "display_name":"Door A", "access_type":"access_code", "access_code":"1234", "power_mode":"external", "control_mode":"external", "power_network_id":"main", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"closed", "state":"closed"}
	var cable := {"id":"cable_a", "position":Vector2i(1, 0), "object_group":"cable", "object_type":"power_cable", "power_network_id":"main", "health_state":"healthy", "operational_state":"connected", "connected":true}
	var generator := {"id":"generator_a", "position":Vector2i(0, 0), "object_group":"power", "object_type":"power_source_class_1", "display_name":"Generator A", "generic_power_role":"power_source", "power_mode":"internal", "control_mode":"internal", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active", "power_network_id":"main", "outlet_capacity":4}
	var terminal := {"id":"terminal_a", "position":Vector2i(0, 2), "object_group":"terminal", "object_type":"control_terminal", "display_name":"Terminal A", "power_mode":"internal", "control_mode":"internal", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active"}
	var bindings: Array[Dictionary] = [{"id":"bind_control", "role":BindingContract.ROLE_CONTROL_TERMINAL, "source_id":"terminal_a", "target_id":"door_a", "parameters":{}, "format_version":BindingContract.FORMAT_VERSION}]
	var actions: Array = [
		{"action_code":"open", "label_key":"action.open.label", "available":true, "reason_code":"", "requirements":[{"type":"power"}, {"type":"power"}], "target_id":"door_a", "context":{}, "id":"open", "label":"Open", "enabled":true, "reason":"", "priority":100, "module_id":"manipulator_arm_v1", "module":{"id":"manipulator_arm_v1"}, "gate":{"success":true}},
		{"action_code":"scan", "label_key":"action.scan.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"scan", "label":"Scan", "enabled":true, "reason":"", "priority":101, "module_id":"scanner_v1", "module":{"id":"scanner_v1"}, "gate":{"success":true}},
		{"action_code":"hack", "label_key":"action.hack.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"hack", "label":"Hack", "enabled":true, "reason":"", "priority":102, "module_id":"hacker_v1", "module":{"id":"hacker_v1"}, "gate":{"success":true}}
	]
	var vm := {"actions":actions, "has_available_action":true, "available_action_ids":["open", "scan", "hack"]}
	var context := {"mode":"runtime", "objects":[door, cable, generator, terminal], "bindings":bindings, "notification":{"player_action":true, "result":"success", "message_key":"door.open", "fallback":"Door opened"}}
	var before := var_to_str(context)
	var snap_a := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), vm, context)
	var snap_b := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), vm, context)
	_assert(var_to_str(context) == before, "snapshot builder mutated caller context")
	_assert(str(snap_a.get("signature", "")) == str(snap_b.get("signature", "")), "snapshot signature is not deterministic")
	_assert(str(Dictionary(snap_a.get("power", {})).get("state", "")) == "powered", "physical source/cable/load topology did not power target")
	_assert(bool(Dictionary(snap_a.get("control", {})).get("external", false)), "external control result missing")
	_assert(str(Dictionary(snap_a.get("control", {})).get("controller_id", "")) == "terminal_a", "exact bound terminal was not preserved")
	_assert(bool(Dictionary(snap_a.get("access", {})).get("show_keypad", false)), "access-code keypad context missing")
	_assert(Dictionary(snap_a.get("access", {})).has("access_code_entry"), "access-code entry missing")
	var public_bindings: Array = Array(snap_a.get("bindings", []))
	_assert(public_bindings.size() == 1, "canonical control binding missing")
	if not public_bindings.is_empty():
		var binding_row := Dictionary(public_bindings[0])
		_assert(binding_row.has("role") and binding_row.has("source_name") and binding_row.has("state"), "binding row is not player-facing")
		_assert(not binding_row.has("source_id") and not binding_row.has("target_id") and not binding_row.has("binding_id"), "normal binding row leaks technical IDs")
	var public_actions: Array = Array(snap_a.get("actions", []))
	_assert(public_actions.size() == 1 and str(Dictionary(public_actions[0]).get("action_code", "")) == "scan", "external control did not preserve only read-only local actions")
	if not public_actions.is_empty():
		var public_action := Dictionary(public_actions[0])
		_assert(not public_action.has("module") and not public_action.has("gate") and not public_action.has("module_id") and not public_action.has("target_id"), "normal action leaks technical fields")
	_assert(Array(snap_a.get("requirements", [])).size() <= 1, "requirements were not deduplicated")
	_assert(typeof(Dictionary(snap_a.get("notification", {})).get("player_action", false)) == TYPE_BOOL, "notification player_action is not bool")
	var status_labels: Array[String] = []
	for row_value in Array(snap_a.get("status", [])):
		if row_value is Dictionary:
			status_labels.append(str(Dictionary(row_value).get("label", "")).to_lower())
	_assert(not status_labels.has("energy"), "unsupported energy row should be absent")
	var debug_context := context.duplicate(true)
	debug_context["mode"] = "task_test"
	var debug_snap := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), vm, debug_context)
	var debug_actions: Array = Array(debug_snap.get("actions", []))
	_assert(not debug_actions.is_empty(), "TASK TEST actions missing")
	if not debug_actions.is_empty():
		var debug_action := Dictionary(debug_actions[0])
		_assert(debug_action.has("module") and debug_action.has("gate") and debug_action.has("module_id"), "TASK TEST action technical data missing")
	var debug_data := Dictionary(debug_snap.get("debug", {}))
	_assert(debug_data.has("raw_bindings") and debug_data.has("real_values") and debug_data.has("forced_values"), "TASK TEST debug sections missing")
	if failures.is_empty():
		print("runtime entity presentation contract: OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
