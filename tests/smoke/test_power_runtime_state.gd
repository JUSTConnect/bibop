extends RefCounted

const PowerSystemRef = preload("res://scripts/systems/object_power_system.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var objects: Array[Dictionary] = [
		{"id": "source", "object_type": "power_source", "state": "on", "power_mode": "source", "placement": {"cell_x": 0, "cell_y": 0}},
		{"id": "cable", "object_type": "power_cable", "state": "connected", "power_mode": "none", "placement": {"cell_x": 1, "cell_y": 0}},
		{"id": "terminal", "object_type": "terminal", "state": "idle", "power_mode": "external", "placement": {"cell_x": 2, "cell_y": 0}},
	]
	var patches: Array[Dictionary] = PowerSystemRef.evaluate_all(objects)
	var cable_patch: Dictionary = _patch_for(patches, "cable")
	if str(cable_patch.get("power_state", "")) != "powered":
		errors.append("cable must receive powered runtime state")
	if str(cable_patch.get("circuit_id", "")).is_empty():
		errors.append("cable must receive circuit_id")
	return errors

static func _patch_for(patches: Array[Dictionary], object_id: String) -> Dictionary:
	for info: Dictionary in patches:
		if str(info.get("instance_id", "")) == object_id:
			return Dictionary(info.get("patch", {}))
	return {}
