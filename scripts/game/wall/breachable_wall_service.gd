extends RefCounted
class_name BreachableWallService

const ACTION_BREAK_BREACHABLE_WALL: String = "break_breachable_wall"
const TOOL_HEAVY_CLAW: String = "heavy_claw"
const HEAVY_CLAW_MODULE_ID: String = "manipulator_heavy_claw_v1"
const VISIBLE_BREACH_SIDES: Array[String] = ["sw", "se"]
const HIDDEN_BREACH_SIDES: Array[String] = ["nw", "ne"]
const INVISIBLE_SIDE_WARNING: String = "Selected breach side is hidden in the current isometric projection. Crack overlay is not rendered for hidden sides."
const BREACHABLE_WALL_BLOCKED_PLACEMENT_MESSAGE: String = "Cannot place objects, wall-mounted devices, or cables on a Breachable Wall."


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
	return state if state in ["intact", "breached", "destroyed", "removed"] else "intact"


static func is_visible_breach_side(side: Variant) -> bool:
	return VISIBLE_BREACH_SIDES.has(normalize_breach_side(side))


static func is_hidden_breach_side(side: Variant) -> bool:
	return HIDDEN_BREACH_SIDES.has(normalize_breach_side(side))


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


static func is_breachable_wall_destroyed(data: Dictionary) -> bool:
	if not is_breachable_wall_data(data):
		return false
	var state: String = str(data.get("breach_state", data.get("state", "intact"))).strip_edges().to_lower()
	return state in ["open", "destroyed", "breached", "removed"]


static func is_normal_action_forbidden(action_id: String, data: Dictionary) -> bool:
	if not is_breachable_wall_data(data):
		return false
	var normalized_action: String = action_id.strip_edges().to_lower()
	return normalized_action in ["open", "close", "unlock", "force_open", "cut", "impact", "breach"]


static func can_use_heavy_claw_module(module_id: String, data: Dictionary) -> bool:
	if not is_active_breachable_wall_data(data):
		return false
	if module_id != HEAVY_CLAW_MODULE_ID:
		return false
	return Array(data.get("breach_tools", [TOOL_HEAVY_CLAW])).has(TOOL_HEAVY_CLAW)


static func normalize_runtime_breachable_wall_data(data: Dictionary) -> Dictionary:
	var normalized: Dictionary = data.duplicate(true)
	if not is_breachable_wall_data(normalized):
		return normalized
	normalized["object_group"] = "wall"
	normalized["object_type"] = "wall"
	normalized["wall_archetype"] = "breachable"
	normalized["is_breachable_wall"] = true
	normalized["breach_side"] = normalize_breach_side(normalized.get("breach_side", "sw"))
	var state: String = normalize_breach_state(normalized.get("breach_state", normalized.get("state", "intact")))
	normalized["breach_state"] = state
	normalized["state"] = state
	normalized["blocks_movement"] = not is_breachable_wall_destroyed(normalized)
	normalized["blocks_vision"] = not is_breachable_wall_destroyed(normalized)
	normalized["supports_embedded_objects"] = false
	normalized["supports_cables"] = false
	if not normalized.has("breach_tools"):
		normalized["breach_tools"] = [TOOL_HEAVY_CLAW]
	return normalized


static func build_runtime_wall_target(cell: Vector2i, material: Dictionary, height: String, breach_side: String) -> Dictionary:
	var material_id: String = str(material.get("id", material.get("material", "breachable_concrete"))).strip_edges().to_lower()
	var normalized: Dictionary = {
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
		"breach_tools": Array(material.get("breach_tools", [TOOL_HEAVY_CLAW])).duplicate(),
		"position": cell,
		"blocks_movement": true,
		"blocks_vision": true,
		"supports_embedded_objects": false,
		"supports_cables": false
	}
	return normalize_runtime_breachable_wall_data(normalized)


static func build_placement_block_result(reason: String = "breachable_wall_blocks_placement") -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"message": BREACHABLE_WALL_BLOCKED_PLACEMENT_MESSAGE,
		"object_id": "",
		"warnings": []
	}


static func can_place_on_breachable_wall(cell_data: Dictionary) -> bool:
	return not is_active_breachable_wall_data(cell_data)


static func get_crack_visual_descriptor(cell: Vector2i, object_data: Dictionary, wall_height_px: float, tile_half_size: Vector2) -> Dictionary:
	var normalized_data: Dictionary = normalize_runtime_breachable_wall_data(object_data)
	var side: String = normalize_breach_side(normalized_data.get("breach_side", "sw"))
	if not is_visible_breach_side(side):
		return {"visible": false, "warning": get_invisible_side_warning(side), "side": side, "cell": cell}
	var height_id: String = str(normalized_data.get("wall_height", normalized_data.get("wall_visual_height", "mid"))).strip_edges().to_lower().replace("_", "")
	var scale: float = 0.80
	var vertical_drop_ratio: float = 0.22
	match height_id:
		"tallest", "tall", "high":
			scale = 0.94
			vertical_drop_ratio = 0.16
		"halfmid", "halfmedium", "half":
			scale = 0.62
			vertical_drop_ratio = 0.28
		"low", "halflow":
			scale = 0.46
			vertical_drop_ratio = 0.34
		_:
			scale = 0.76
			vertical_drop_ratio = 0.24
	var face_offset: Vector2 = Vector2(-tile_half_size.x * 0.20, wall_height_px * 0.18) if side == "sw" else Vector2(tile_half_size.x * 0.22, wall_height_px * 0.16)
	var center_offset: Vector2 = face_offset + Vector2(0.0, wall_height_px * vertical_drop_ratio)
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
			height_scale = maxf(height_scale, 0.78)
		"halfmid":
			height_scale = clampf(height_scale, 0.52, 0.64)
		"low", "halflow":
			height_scale = 0.42
		_:
			height_scale = clampf(height_scale, 0.62, 0.80)
	var base_scale: Vector2 = Vector2(base_texture_rect.size.x / base_texture_size.x, base_texture_rect.size.y / base_texture_size.y)
	var source_bottom_center: Vector2 = base_source_rect.position + Vector2(base_source_rect.size.x * 0.5, base_source_rect.size.y)
	var base_bottom_center: Vector2 = base_texture_rect.position + source_bottom_center * base_scale
	var overlay_size: Vector2 = overlay_texture_size * base_scale * height_scale
	var vertical_drop: float = base_texture_rect.size.y * 0.08
	match normalized_height:
		"tall", "tallest", "high":
			vertical_drop = base_texture_rect.size.y * 0.06
		"halfmid":
			vertical_drop = base_texture_rect.size.y * 0.10
		"low", "halflow":
			vertical_drop = base_texture_rect.size.y * 0.12
	var overlay_bottom_center: Vector2 = base_bottom_center + Vector2(0.0, vertical_drop)
	return {"ok": true, "rect": Rect2((overlay_bottom_center - Vector2(overlay_size.x * 0.5, overlay_size.y)).round(), overlay_size.round())}
