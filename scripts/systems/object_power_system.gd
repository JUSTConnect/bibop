extends RefCounted

const PowerNetworkSystemRef = preload("res://scripts/systems/power_network_system.gd")

static func evaluate_all(objects: Array[Dictionary]) -> Array[Dictionary]:
	var context: Dictionary = PowerNetworkSystemRef.build_power_context(objects)
	var patches: Array[Dictionary] = []
	for object_data in objects:
		var object_id := str(object_data.get("id", ""))
		if object_id.is_empty():
			continue
		var next_power_state := evaluate_power_state(object_data, context)
		if not next_power_state.is_empty() and str(object_data.get("power_state", "")) != next_power_state:
			patches.append({"instance_id": object_id, "patch": {"power_state": next_power_state}})
	return patches

static func evaluate_power_state(object_data: Dictionary, context: Dictionary) -> String:
	var object_type := str(object_data.get("object_type", ""))
	var power_mode := str(object_data.get("power_mode", "none")).to_lower()
	if object_type == "power_source":
		return "unpowered" if str(object_data.get("state", "on")).to_lower() == "off" else "powered"
	if power_mode == "none":
		return "none"
	if power_mode == "source":
		return "powered"
	if power_mode == "external":
		return "powered" if PowerNetworkSystemRef.is_powered_by_context(object_data, context) else "unpowered"
	return str(object_data.get("power_state", "none"))
