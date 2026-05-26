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
	var object_type: String = String(obj.get("object_type", ""))
	var object_group: String = String(obj.get("object_group", ""))
	if object_group == "terminal":
		return true
	if object_group == "threat" and object_type == "turret":
		return true
	return bool(STATE_DRIVEN_POWER_TYPES.get(object_type, false))

static func _is_power_source_object(obj: Dictionary) -> bool:
	var object_type: String = String(obj.get("object_type", ""))
	return object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]

static func _get_power_source_capacity_for_load(source: Dictionary) -> int:
	if source.has("source_capacity"):
		return maxi(1, int(source.get("source_capacity", 1)))
	if source.has("allowed_socket_connections"):
		return maxi(1, int(source.get("allowed_socket_connections", 1)))
	if source.has("allowed_connections"):
		return maxi(1, int(source.get("allowed_connections", 1)))
	if source.has("source_class"):
		var source_class: int = int(source.get("source_class", 1))
		return maxi(1, mini(3, source_class))
	var object_type := String(source.get("object_type", "")).strip_edges().to_lower()
	if object_type == "power_source_class_1":
		return 1
	if object_type == "power_source_class_2":
		return 2
	if object_type == "power_source_class_3":
		return 3
	if object_type.find("class_2") != -1:
		return 2
	if object_type.find("class_3") != -1:
		return 3
	return 1

static func _is_power_consumer_object(obj: Dictionary) -> bool:
	if _is_power_source_object(obj):
		return false
	if String(obj.get("object_group", "")) == "power":
		return false
	if _is_state_driven_powered_object(obj):
		return true
	return bool(obj.get("is_powered", false))

static func recalculate_network(objects: Array[Dictionary], network_id: String) -> Array[Dictionary]:
	var network_objects: Array[Dictionary] = []
	for obj in objects:
		if obj.get("power_network_id", "") == network_id:
			network_objects.append(obj)

	for obj in network_objects:
		WorldObjectCatalog.update_world_object_heat_state(obj)

	var consumer_count: int = 0
	for obj in network_objects:
		if _is_power_consumer_object(obj):
			consumer_count += 1

	var has_source: bool = false
	var breaker_on: bool = true
	var fuse_installed: bool = true
	for obj in network_objects:
		if _is_power_source_object(obj):
			var source_capacity: int = _get_power_source_capacity_for_load(obj)
			obj["source_load"] = consumer_count
			obj["source_capacity"] = source_capacity
			obj["source_overloaded"] = consumer_count > source_capacity
			obj["heat_from_connections"] = maxi(0, consumer_count - source_capacity)
			WorldObjectCatalog.update_world_object_heat_state(obj)
			if obj.get("state", "") == "active":
				has_source = true
		if obj.get("object_type", "") == "circuit_breaker" and obj.get("state", "") == "switch_off":
			breaker_on = false
		if obj.get("object_type", "") == "fuse_box_empty" or (obj.get("object_type", "") == "fuse_box" and obj.get("state", "") == "empty"):
			fuse_installed = false

	var powered: bool = has_source and breaker_on and fuse_installed
	for obj in network_objects:
		if not _is_power_source_object(obj):
			obj["is_powered"] = powered
		var object_type: String = String(obj.get("object_type", ""))
		if _is_state_driven_powered_object(obj):
			var current_state: String = String(obj.get("state", ""))
			var object_group: String = String(obj.get("object_group", ""))
			if not powered:
				if current_state != "unpowered" and not NON_RESTORABLE_STATES.get(current_state, false):
					obj["state_before_unpowered"] = current_state
					if not (object_group == "threat" and object_type == "turret" and current_state in ["destroyed", "hacked", "disabled"]):
						obj["state"] = "unpowered"
				if object_group == "threat" and object_type == "turret" and String(obj.get("state", "")) == "unpowered":
					obj["behavior_state"] = "idle"
					obj.erase("target_position")
			elif current_state == "unpowered":
				var restored_state: String = String(obj.get("state_before_unpowered", "active"))
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
