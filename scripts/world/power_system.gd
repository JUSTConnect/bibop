extends RefCounted
class_name PowerSystem
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")

const STATE_DRIVEN_POWER_TYPES := {
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

const NON_RESTORABLE_STATES := {
	"damaged": true,
	"destroyed": true
}

static func _is_state_driven_powered_object(obj: Dictionary) -> bool:
	var object_type := obj.get("object_type", "")
	var object_group := obj.get("object_group", "")
	if object_group == "terminal":
		return true
	if object_group == "threat" and object_type == "turret":
		return true
	return STATE_DRIVEN_POWER_TYPES.get(object_type, false)

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var has_source := false
	var breaker_on := true
	var fuse_installed := true
	for obj in objects:
		if obj.get("power_network_id", "") != network_id:
			continue
		WorldObjectCatalog.update_world_object_heat_state(obj)
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
		if _is_state_driven_powered_object(obj):
			var current_state := obj.get("state", "")
			var object_group := String(obj.get("object_group", ""))
			if not powered:
				if current_state != "unpowered" and not NON_RESTORABLE_STATES.get(current_state, false):
					obj["state_before_unpowered"] = current_state
					if not (object_group == "threat" and object_type == "turret" and current_state in ["destroyed", "hacked", "disabled"]):
						obj["state"] = "unpowered"
				if object_group == "threat" and object_type == "turret" and String(obj.get("state", "")) == "unpowered":
					obj["behavior_state"] = "idle"
					obj.erase("target_position")
			elif current_state == "unpowered":
				var restored_state: String = obj.get("state_before_unpowered", "active")
				if restored_state == "":
					restored_state = "active"
				if not (object_group == "threat" and object_type == "turret" and restored_state in ["destroyed", "hacked", "disabled"]):
					obj["state"] = restored_state
				obj.erase("state_before_unpowered")
		if object_type in ["energy_door", "energy_wall"] and not powered:
			obj["blocks_movement"] = false
		elif object_type in ["energy_door", "energy_wall"] and powered and obj.get("state", "") not in ["open", "inactive", "destroyed"]:
			obj["blocks_movement"] = true
	return objects
