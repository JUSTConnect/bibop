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
	var vm := {"actions":[]}
	var context := {"mode":"runtime", "objects":[door, cable, generator, terminal], "bindings":bindings, "notification":{"player_action":true}}
	var before := var_to_str(context)
	var snap_a := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), vm, context)
	var snap_b := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), vm, context)
	_assert(var_to_str(context) == before, "snapshot builder must not mutate caller context")
	_assert(str(snap_a.get("signature", "")) == str(snap_b.get("signature", "")), "snapshot signature must be deterministic")
	_assert(str(Dictionary(snap_a.get("power", {})).get("state", "")) == "powered", "physical source/cable/load topology must power target")
	_assert(bool(Dictionary(snap_a.get("control", {})).get("external", false)), "snapshot must include external control state")
	if failures.is_empty():
		print("runtime entity presentation core: OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
