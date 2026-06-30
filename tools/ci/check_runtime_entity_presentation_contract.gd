extends SceneTree

const SnapshotService = preload("res://scripts/game/presentation/runtime_presentation_snapshot_service.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var door := {"id":"door_a", "position":Vector2i(2, 0), "object_group":"door", "object_type":"door", "power_mode":"external", "control_mode":"external", "power_network_id":"main", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"closed", "state":"closed"}
	var cable := {"id":"cable_a", "position":Vector2i(1, 0), "object_type":"power_cable", "power_network_id":"main", "health_state":"healthy", "operational_state":"connected", "connected":true}
	var generator := {"id":"generator_a", "position":Vector2i(0, 0), "object_type":"power_source_class_1", "generic_power_role":"power_source", "intent_state":"on", "health_state":"healthy", "thermal_state":"normal", "operational_state":"active", "power_network_id":"main"}
	var context := {"mode":"runtime", "objects":[door, cable, generator], "bindings":[]}
	var snapshot := SnapshotService.build(null, door, Vector2i(2, 0), {"actions":[]}, context)
	var state := str(Dictionary(snapshot.get("power", {})).get("state", ""))
	quit(0 if state == "powered" else 1)
