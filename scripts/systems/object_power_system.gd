extends RefCounted

const PowerNetworkSystemRef = preload("res://scripts/systems/power_network_system.gd")

static func evaluate_all(objects: Array[Dictionary]) -> Array[Dictionary]:
	var context: Dictionary = PowerNetworkSystemRef.build_power_context(objects)
	var patches: Array[Dictionary] = []
	for object_data: Dictionary in objects:
		var object_id: String = str(object_data.get("id", ""))
		if object_id.is_empty():
			continue
		var patch: Dictionary = {}
		var next_power_state: String = evaluate_power_state(object_data, context)
		if not next_power_state.is_empty() and str(object_data.get("power_state", "")) != next_power_state:
			patch["power_state"] = next_power_state
		var next_circuit_id: String = PowerNetworkSystemRef.get_circuit_id(object_id, context)
		if str(object_data.get("circuit_id", "")) != next_circuit_id:
			patch["circuit_id"] = next_circuit_id
		if not patch.is_empty():
			patches.append({"instance_id": object_id, "patch": patch})
	return patches

static func evaluate_power_state(object_data: Dictionary, context: Dictionary) -> String:
	var object_type: String = str(object_data.get("object_type", ""))
	var power_mode: String = str(object_data.get("power_mode", "none")).to_lower()
	if object_type == "power_source":
		return "unpowered" if str(object_data.get("state", "on")).to_lower() == "off" else "powered"
	if object_type == "power_cable":
		return "powered" if PowerNetworkSystemRef.is_powered_by_context(object_data, context) else "unpowered"
	if power_mode == "none":
		return "none"
	if power_mode == "source":
		return "powered"
	if power_mode == "external":
		return "powered" if PowerNetworkSystemRef.is_powered_by_context(object_data, context) else "unpowered"
	return str(object_data.get("power_state", "none"))
