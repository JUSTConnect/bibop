extends SceneTree

const Resolver = preload("res://scripts/world/power_control_resolver.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var door := {"id":"door_a", "position":Vector2i(2, 0), "object_group":"door", "object_type":"door", "power_mode":"external", "control_mode":"external", "power_network_id":"main", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"closed", "state":"closed"}
	var cable := {"id":"cable_a", "position":Vector2i(1, 0), "object_group":"cable", "object_type":"power_cable", "power_network_id":"main", "health_state":"healthy", "operational_state":"connected", "connected":true}
	var generator := {"id":"generator_a", "position":Vector2i(0, 0), "object_group":"power", "object_type":"power_source_class_1", "generic_power_role":"power_source", "power_mode":"internal", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active", "power_network_id":"main", "outlet_capacity":4}
	var result := Resolver.resolve_world([door, cable, generator], [], {"entity_id":"door_a"})
	var power := Dictionary(Dictionary(result.get("power_results", {})).get("door_a", {}))
	if str(power.get("power_state", "")) == "powered":
		print("canonical power topology fixture: OK")
		quit(0)
		return
	push_error("canonical power topology fixture failed")
	quit(1)
