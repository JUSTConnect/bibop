extends RefCounted
class_name PowerSystem

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var has_source := false
	var breaker_on := true
	var fuse_installed := true
	for obj in objects:
		if obj.get("power_network_id", "") != network_id:
			continue
		if obj.get("object_type", "") == "power_source" and obj.get("state", "") == "active":
			has_source = true
		if obj.get("object_type", "") == "circuit_breaker" and obj.get("state", "") == "switch_off":
			breaker_on = false
		if obj.get("object_type", "") == "fuse_box" and obj.get("state", "") == "empty":
			fuse_installed = false
	var powered := has_source and breaker_on and fuse_installed
	for obj in objects:
		if obj.get("power_network_id", "") != network_id:
			continue
		obj["is_powered"] = powered
		obj["state"] = "active" if powered else "unpowered"
		if obj.get("object_type", "") == "energy_door" and not powered:
			obj["blocks_movement"] = false
		if obj.get("object_type", "") == "energy_wall" and not powered:
			obj["blocks_movement"] = false
	return objects
