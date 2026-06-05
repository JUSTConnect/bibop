extends RefCounted
class_name BreachableWallService

const VISIBLE_BREACH_SIDES: Array[String] = ["sw", "se"]
const INVISIBLE_SIDE_WARNING := "NW side is not visible in current isometric projection."


static func normalize_breach_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match side:
		"southwest", "south_west", "south", "left_front":
			return "sw"
		"southeast", "south_east", "east", "right_front":
			return "se"
		"northwest", "north_west", "west", "left_back":
			return "nw"
		"northeast", "north_east", "north", "right_back":
			return "ne"
	return side if side in ["sw", "se", "nw", "ne"] else "sw"


static func normalize_breach_state(value: Variant) -> String:
	var state: String = str(value).strip_edges().to_lower()
	return state if state in ["intact", "breached", "destroyed"] else "intact"


static func is_visible_breach_side(side: Variant) -> bool:
	return VISIBLE_BREACH_SIDES.has(normalize_breach_side(side))


static func get_invisible_side_warning(_side: Variant) -> String:
	return INVISIBLE_SIDE_WARNING


static func is_breachable_wall_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	if bool(data.get("is_breachable_wall", false)):
		return true
	if str(data.get("wall_archetype", "")).strip_edges().to_lower() == "breachable":
		return true
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	return object_type == "breachable_wall"


static func is_active_breachable_wall_data(data: Dictionary) -> bool:
	if not is_breachable_wall_data(data):
		return false
	var state: String = str(data.get("breach_state", data.get("state", "intact"))).strip_edges().to_lower()
	return state not in ["open", "destroyed", "breached", "removed"]


static func build_runtime_wall_target(cell: Vector2i, material: Dictionary, height: String, breach_side: String) -> Dictionary:
	var material_id: String = str(material.get("id", material.get("material", "breachable_concrete"))).strip_edges().to_lower()
	return {
		"id": "breachable_wall_%d_%d" % [cell.x, cell.y],
		"archetype_id": "wall",
		"object_group": "wall",
		"object_type": "wall",
		"display_name": "Breachable Wall",
		"design_term_ru": "проламываемая стена",
		"wall_archetype": "breachable",
		"is_breachable_wall": true,
		"breach_state": "intact",
		"state": "intact",
		"material": material_id,
		"wall_material_id": material_id,
		"wall_height": height,
		"breach_side": normalize_breach_side(breach_side),
		"breach_tools": Array(material.get("breach_tools", ["heavy_claw"])).duplicate(),
		"position": cell,
		"blocks_movement": true,
		"blocks_vision": true,
		"supports_embedded_objects": false,
		"supports_cables": false
	}


static func get_crack_visual_descriptor(cell: Vector2i, object_data: Dictionary, wall_height_px: float, tile_half_size: Vector2) -> Dictionary:
	var side: String = normalize_breach_side(object_data.get("breach_side", "sw"))
	if not is_visible_breach_side(side):
		return {"visible": false, "warning": get_invisible_side_warning(side), "side": side, "cell": cell}
	var height_id: String = str(object_data.get("wall_height", object_data.get("wall_visual_height", "mid"))).strip_edges().to_lower().replace("_", "")
	var scale: float = 1.0
	var vertical_ratio: float = 0.34
	match height_id:
		"tallest", "tall", "high":
			scale = 1.12
			vertical_ratio = 0.38
		"halfmid", "halfmedium", "half":
			scale = 0.78
			vertical_ratio = 0.24
		"low", "halflow":
			scale = 0.66
			vertical_ratio = 0.18
		_:
			scale = 0.94
			vertical_ratio = 0.30
	var face_offset: Vector2 = Vector2(-tile_half_size.x * 0.22, wall_height_px * 0.08) if side == "sw" else Vector2(tile_half_size.x * 0.24, wall_height_px * 0.02)
	var center_offset: Vector2 = Vector2(0.0, -wall_height_px * vertical_ratio) + face_offset
	return {"visible": true, "warning": "", "side": side, "cell": cell, "center_offset": center_offset, "scale": scale}


static func get_texture_overlay_layout(base_texture_rect: Rect2, base_source_rect: Rect2, base_texture_size: Vector2, overlay_texture_size: Vector2, height_level: String, visible_bounds_by_height: Dictionary, baseline_bounds: Rect2) -> Dictionary:
	if base_texture_size.x <= 0.0 or base_texture_size.y <= 0.0 or overlay_texture_size.x <= 0.0 or overlay_texture_size.y <= 0.0:
		return {"ok": false}
	var normalized_height: String = str(height_level).strip_edges().to_lower()
	var tall_bounds: Rect2 = Rect2(visible_bounds_by_height.get("tall", baseline_bounds))
	var target_bounds: Rect2 = Rect2(visible_bounds_by_height.get(normalized_height, baseline_bounds))
	var height_scale: float = target_bounds.size.y / maxf(tall_bounds.size.y, 1.0)
	match normalized_height:
		"tall", "tallest", "high":
			height_scale = maxf(height_scale, 0.82)
		"halfmid":
			height_scale = clampf(height_scale, 0.58, 0.72)
		"low", "halflow":
			height_scale = 0.52
		_:
			height_scale = clampf(height_scale, 0.68, 0.9)
	var base_scale: Vector2 = Vector2(base_texture_rect.size.x / base_texture_size.x, base_texture_rect.size.y / base_texture_size.y)
	var source_bottom_center: Vector2 = base_source_rect.position + Vector2(base_source_rect.size.x * 0.5, base_source_rect.size.y)
	var base_bottom_center: Vector2 = base_texture_rect.position + source_bottom_center * base_scale
	var overlay_size: Vector2 = overlay_texture_size * base_scale * height_scale
	var vertical_lift: float = base_texture_rect.size.y * 0.08
	match normalized_height:
		"tall", "tallest", "high":
			vertical_lift = base_texture_rect.size.y * 0.12
		"halfmid":
			vertical_lift = base_texture_rect.size.y * 0.04
		"low", "halflow":
			vertical_lift = 0.0
	var overlay_bottom_center: Vector2 = base_bottom_center - Vector2(0.0, vertical_lift)
	return {"ok": true, "rect": Rect2((overlay_bottom_center - Vector2(overlay_size.x * 0.5, overlay_size.y)).round(), overlay_size.round())}
