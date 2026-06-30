extends SceneTree

const Service = preload("res://scripts/game/bipob_action_view_model_service.gd")
const StoreRef = preload("res://scripts/world/world_state_store.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var door := {"id":"door_a", "object_group":"door", "object_type":"door", "display_name":"Door A", "access_type":"access_code", "access_code":"1234", "power_mode":"external", "control_mode":"external"}
	var terminal := {"id":"terminal_a", "object_group":"terminal", "object_type":"terminal", "display_name":"Terminal A", "power_mode":"internal"}
	var generator := {"id":"generator_a", "object_group":"power", "object_type":"power_source", "display_name":"Generator A", "power_mode":"internal", "source_capacity":4}
	var bindings: Array[Dictionary] = [
		{"id":"bind_control", "role":BindingContract.ROLE_CONTROL_TERMINAL, "source_id":"terminal_a", "target_id":"door_a", "parameters":{}},
		{"id":"bind_power", "role":BindingContract.ROLE_POWER_SOURCE, "source_id":"generator_a", "target_id":"door_a", "parameters":{}},
	]
	var actions: Array = [
		{"action_code":"open", "label_key":"action.open.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"open", "label":"Open", "enabled":true, "reason":"", "priority":100, "module_id":"manipulator_arm_v1", "module":{"id":"manipulator_arm_v1"}, "gate":{"success":true}},
		{"action_code":"scan", "label_key":"action.scan.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"scan", "label":"Scan", "enabled":true, "reason":"", "priority":101, "module_id":"scanner_v1", "module":{"id":"scanner_v1"}, "gate":{"success":true}}
	]
	var vm := {"actions":actions, "has_available_action":true, "available_action_ids":["open"]}
	var context := {"mode":"runtime", "objects":[door, terminal, generator], "bindings":bindings, "notification":{"player_action":true}}
	var before := var_to_str(context)
	var snap_a := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 3), vm, context)
	var snap_b := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 3), vm, context)
	_assert(var_to_str(context) == before, "snapshot builder must not mutate caller context")
	_assert(str(snap_a.get("signature", "")) == str(snap_b.get("signature", "")), "snapshot signature must be deterministic")
	_assert(Dictionary(snap_a.get("power", {})).has("state"), "snapshot must include power section")
	_assert(bool(Dictionary(snap_a.get("control", {})).get("external", false)), "snapshot must include external control state")
	_assert(bool(Dictionary(Dictionary(snap_a.get("access", {})).get("keypad", {})).get("show", false)), "access-code targets must prepare keypad context")
	_assert(Array(snap_a.get("bindings", [])).size() >= 2, "snapshot must expose sanitized canonical bindings")
	var public_actions: Array = Array(snap_a.get("actions", []))
	_assert(public_actions.size() == 1 and str(Dictionary(public_actions[0]).get("action_code", "")) == "scan", "external control must remove local mutating actions and preserve read-only scan")
	var public_action := Dictionary(public_actions[0])
	_assert(not public_action.has("module") and not public_action.has("gate") and not public_action.has("module_id"), "normal runtime action must hide technical fields")
	_assert(typeof(Dictionary(snap_a.get("notification", {})).get("player_action", false)) == TYPE_BOOL, "notification player_action must remain bool")
	var debug_context := context.duplicate(true)
	debug_context["mode"] = "task_test"
	var debug_snap := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 3), vm, debug_context)
	var debug_action := Dictionary(Array(debug_snap.get("actions", []))[0])
	_assert(debug_action.has("module") and debug_action.has("gate") and Dictionary(debug_snap.get("debug", {})).has("raw_bindings"), "TASK TEST debug must include technical data")
	if failures.is_empty():
		print("runtime entity presentation behavior: OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
