extends RefCounted
class_name PlatformOccupancyService

const PlatformMotionServiceRef = preload("res://scripts/game/platform/platform_motion_service.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

static func _cell_key(cell: Vector2i) -> String:
	return "%s:%s" % [cell.x, cell.y]

static func is_platform_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	return str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower() == "platform" or str(data.get("object_type", "")).strip_edges().to_lower() == "platform" or data.has("platform_cells")

static func is_platform_placeable_object(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	var placement_mode: String = str(data.get("placement_mode", "")).strip_edges().to_lower()
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var archetype: String = str(data.get("archetype_id", data.get("enemy_type", data.get("enemy_kind", "")))).strip_edges().to_lower()
	if group in ["wall", "door", "platform"] or object_type in ["wall", "floor", "platform"]:
		return false
	if placement_mode == "wall_mounted" or bool(data.get("is_wall_mounted", false)):
		return false
	if bool(data.get("platform_placeable", false)) or bool(data.get("movable", false)) or bool(data.get("heavy_claw_movable", false)):
		return true
	return object_type in ["radiator", "cooling_box", "external_air_cooler", "metal_cooling_block", "case", "crate", "normal_crate", "heavy_crate", "barrel", "box", "steel_box", "turret", "enemy", "vagus", "bug"] or archetype in ["radiator", "cooling_box", "external_air_cooler", "case", "crate", "barrel", "box", "turret", "enemy", "vagus", "bug"] or group in ["enemy", "threat"]

static func get_platform_for_cell(cell: Vector2i, world_objects: Array) -> Dictionary:
	for object_variant in world_objects:
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if not is_platform_data(object_data):
			continue
		for platform_cell_variant in Array(object_data.get("platform_cells", [object_data.get("position", Vector2i(-1, -1))])):
			if WorldObjectCatalogRef.to_world_cell(platform_cell_variant, Vector2i(-1, -1)) == cell:
				return object_data
		if WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)) == cell:
			return object_data
	return {}

static func get_surface_context_for_cell(cell: Vector2i, world_objects: Array, ground_level_lookup: Dictionary = {}) -> Dictionary:
	var platform_data: Dictionary = get_platform_for_cell(cell, world_objects)
	if not platform_data.is_empty():
		var level: int = PlatformMotionServiceRef.get_surface_level_for_platform(platform_data)
		return {"surface_kind":"platform", "cell":cell, "surface_level":level, "platform_id":str(platform_data.get("platform_id", platform_data.get("id", ""))), "platform_cell":cell, "platform_data":platform_data}
	var key: String = _cell_key(cell)
	return {"surface_kind":"ground", "cell":cell, "surface_level":maxi(int(ground_level_lookup.get(key, 0)), 0), "platform_id":"", "platform_cell":Vector2i(-1, -1), "platform_data":{}}

static func attach_entity_to_surface(data: Dictionary, surface_context: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var level: int = int(surface_context.get("surface_level", 0))
	result["surface_level"] = level
	if str(surface_context.get("surface_kind", "ground")) == "platform":
		result["on_platform"] = true
		result["platform_id"] = str(surface_context.get("platform_id", ""))
		result["platform_cell"] = surface_context.get("platform_cell", surface_context.get("cell", Vector2i(-1, -1)))
		result["platform_height_level"] = level
	else:
		result = clear_platform_surface_metadata(result)
	return result

static func clear_platform_surface_metadata(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result["on_platform"] = false
	result["platform_id"] = ""
	result["platform_height_level"] = 0
	result["surface_level"] = 0
	result.erase("platform_cell")
	return result

static func is_surface_move_allowed(from_context: Dictionary, to_context: Dictionary) -> bool:
	return int(from_context.get("surface_level", 0)) == int(to_context.get("surface_level", 0))

static func get_platform_occupants(platform_id: String, world_objects: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_variant in world_objects:
		if object_variant is Dictionary:
			var object_data: Dictionary = Dictionary(object_variant)
			if str(object_data.get("platform_id", "")) == platform_id and is_platform_placeable_object(object_data):
				result.append(object_data)
	return result

static func get_platform_occupants_for_cell(cell: Vector2i, world_objects: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_variant in world_objects:
		if object_variant is Dictionary:
			var object_data: Dictionary = Dictionary(object_variant)
			if is_platform_placeable_object(object_data) and WorldObjectCatalogRef.to_world_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)) == cell and (bool(object_data.get("on_platform", false)) or str(object_data.get("platform_id", "")) != ""):
				result.append(object_data)
	return result
