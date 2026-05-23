extends RefCounted
class_name PowerSystem

const STATE_DRIVEN_POWER_TYPES := {
	"terminal": true,
	"turret": true,
	"light": true,
	"energy_wall": true,
	"energy_door": true,
	"cooling_block": true,
	"alarm": true,
	"camera": true,
	"lift": true,
	"platform": true
}

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var has_source := false
	var breaker_on := true
	var fuse_installed := true
	for obj in objects:
		if obj.get("power_network_id", "") != network_id:
			continue
		if obj.get("object_type", "") in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"] and obj.get("state", "") == "active":
			has_source = true
		if obj.get("object_type", "") == "circuit_breaker" and obj.get("state", "") == "switch_off":
			breaker_on = false
		if obj.get("object_type", "") == "fuse_box_empty" or (obj.get("object_type", "") == "fuse_box" and obj.get("state", "") == "empty"):
			fuse_installed = false
	var powered := has_source and breaker_on and fuse_installed
	for obj in objects:
		if obj.get("power_network_id", "") != network_id:
			continue
		obj["is_powered"] = powered
		var object_type := obj.get("object_type", "")
		if STATE_DRIVEN_POWER_TYPES.get(object_type, false) and not powered:
			obj["state"] = "unpowered"
		if object_type in ["energy_door", "energy_wall"] and not powered:
			obj["blocks_movement"] = false
		elif object_type in ["energy_door", "energy_wall"] and powered and obj.get("state", "") != "open":
			obj["blocks_movement"] = true
	return objects
