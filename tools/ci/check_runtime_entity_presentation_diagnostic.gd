extends SceneTree

const Service = preload("res://scripts/game/bipob_action_view_model_service.gd")
const BindingContract = preload("res://scripts/world/world_binding_store_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var door := {"id":"door_a", "position":Vector2i(2, 0), "object_group":"door", "object_type":"door", "display_name":"Door A", "access_type":"access_code", "access_code":"1234", "power_mode":"external", "control_mode":"external", "power_network_id":"main", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"closed", "state":"closed"}
	var cable := {"id":"cable_a", "position":Vector2i(1, 0), "object_group":"cable", "object_type":"power_cable", "power_network_id":"main", "health_state":"healthy", "operational_state":"connected", "connected":true}
	var generator := {"id":"generator_a", "position":Vector2i(0, 0), "object_group":"power", "object_type":"power_source_class_1", "display_name":"Generator A", "generic_power_role":"power_source", "power_mode":"internal", "control_mode":"internal", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active", "power_network_id":"main", "outlet_capacity":4}
	var terminal := {"id":"terminal_a", "position":Vector2i(0, 2), "object_group":"terminal", "object_type":"control_terminal", "display_name":"Terminal A", "power_mode":"internal", "control_mode":"internal", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active"}
	var bindings: Array[Dictionary] = [{"id":"bind_control", "role":BindingContract.ROLE_CONTROL_TERMINAL, "source_id":"terminal_a", "target_id":"door_a", "parameters":{}, "format_version":BindingContract.FORMAT_VERSION}]
	var actions: Array = [
		{"action_code":"open", "label_key":"action.open.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"open", "label":"Open", "enabled":true, "reason":"", "priority":100, "module_id":"manipulator_arm_v1", "module":{"id":"manipulator_arm_v1"}, "gate":{"success":true}},
		{"action_code":"scan", "label_key":"action.scan.label", "available":true, "reason_code":"", "requirements":[], "target_id":"door_a", "context":{}, "id":"scan", "label":"Scan", "enabled":true, "reason":"", "priority":101, "module_id":"scanner_v1", "module":{"id":"scanner_v1"}, "gate":{"success":true}}
	]
	var context := {"mode":"runtime", "objects":[door, cable, generator, terminal], "bindings":bindings, "notification":{"player_action":true}}
	var snapshot := Service.build_runtime_presentation_snapshot(null, door, Vector2i(2, 0), {"actions":actions}, context)
	print("DIAG_POWER=", JSON.stringify(snapshot.get("power", {})))
	print("DIAG_CONTROL=", JSON.stringify(snapshot.get("control", {})))
	print("DIAG_ACCESS=", JSON.stringify(snapshot.get("access", {})))
	print("DIAG_BINDINGS=", JSON.stringify(snapshot.get("bindings", [])))
	print("DIAG_ACTIONS=", JSON.stringify(snapshot.get("actions", [])))
	print("DIAG_NOTIFICATION=", JSON.stringify(snapshot.get("notification", {})))
	print("DIAG_SIGNATURE=", str(snapshot.get("signature", "")))
	quit(0)
