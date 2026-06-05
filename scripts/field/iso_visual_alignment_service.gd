extends RefCounted
class_name IsoVisualAlignmentService

const STANDARD_TILE_SIZE: Vector2 = Vector2(128.0, 71.0)
const MIN_SCALE_VALUE: float = 0.01
const GROUND_TOP_SURFACE_SAFETY_OVERLAP: float = 1.0

static func clamp_visible_bounds(visible_bounds: Rect2, texture_size: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var safe_bounds: Rect2 = visible_bounds
	if safe_bounds.size.x <= 0.0 or safe_bounds.size.y <= 0.0:
		safe_bounds = Rect2(Vector2.ZERO, texture_size)
	var min_x: float = clampf(safe_bounds.position.x, 0.0, texture_size.x)
	var min_y: float = clampf(safe_bounds.position.y, 0.0, texture_size.y)
	var max_x: float = clampf(safe_bounds.position.x + safe_bounds.size.x, min_x, texture_size.x)
	var max_y: float = clampf(safe_bounds.position.y + safe_bounds.size.y, min_y, texture_size.y)
	var clamped_bounds: Rect2 = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	if clamped_bounds.size.x <= 0.0 or clamped_bounds.size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size)
	return clamped_bounds

static func get_floor_destination_rect(cell_center: Vector2, tile_size: Vector2, placement: Dictionary, surface_y_offset: float = 0.0) -> Rect2:
	var target_footprint: Vector2 = Vector2(placement.get("target_footprint", tile_size))
	if is_equal_approx(target_footprint.x, STANDARD_TILE_SIZE.x) and is_equal_approx(target_footprint.y, STANDARD_TILE_SIZE.y):
		target_footprint = tile_size
	if target_footprint.x <= 0.0 or target_footprint.y <= 0.0:
		target_footprint = tile_size
	var floor_overlap: Vector2 = Vector2(placement.get("overlap", Vector2.ZERO))
	var placement_offset: Vector2 = Vector2(placement.get("offset", Vector2.ZERO))
	var surface_offset: Vector2 = Vector2(0.0, surface_y_offset)
	var destination_position: Vector2 = cell_center - target_footprint * 0.5 - floor_overlap + placement_offset + surface_offset
	var destination_size: Vector2 = target_footprint + floor_overlap * 2.0
	return Rect2(destination_position.round(), destination_size)

static func get_ground_destination_rect(cell_center: Vector2, tile_size: Vector2, texture_size: Vector2, placement: Dictionary) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var visible_bounds: Rect2 = clamp_visible_bounds(Rect2(placement.get("visible_bounds", Rect2(Vector2.ZERO, texture_size))), texture_size)
	var target_base_width: float = maxf(float(placement.get("target_base_width", tile_size.x)), tile_size.x)
	var placement_scale: float = maxf(float(placement.get("scale", 1.0)), MIN_SCALE_VALUE)
	var scale_value: float = (target_base_width / visible_bounds.size.x) * placement_scale
	var destination_size: Vector2 = texture_size * scale_value
	var visible_bottom_center_in_source: Vector2 = visible_bounds.position + Vector2(visible_bounds.size.x * 0.5, visible_bounds.size.y)
	var visible_bottom_center_in_destination: Vector2 = visible_bottom_center_in_source * scale_value
	var base_anchor: Vector2 = (cell_center + Vector2(0.0, tile_size.y * 0.5) + Vector2(placement.get("offset", Vector2.ZERO))).round()
	return Rect2((base_anchor - visible_bottom_center_in_destination).round(), destination_size)

static func get_ground_visible_side_height(tile_size: Vector2, texture_size: Vector2, placement: Dictionary) -> float:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return 0.0
	var visible_bounds: Rect2 = clamp_visible_bounds(Rect2(placement.get("visible_bounds", Rect2(Vector2.ZERO, texture_size))), texture_size)
	var target_base_width: float = maxf(float(placement.get("target_base_width", tile_size.x)), tile_size.x)
	var placement_scale: float = maxf(float(placement.get("scale", 1.0)), MIN_SCALE_VALUE)
	var scale_value: float = (target_base_width / visible_bounds.size.x) * placement_scale
	var visible_height: float = visible_bounds.size.y * scale_value
	return maxf(visible_height - tile_size.y, 0.0)

static func get_ground_top_surface_y_offset(tile_size: Vector2, texture_size: Vector2, placement: Dictionary) -> float:
	var side_height: float = get_ground_visible_side_height(tile_size, texture_size, placement)
	if side_height <= 0.0:
		return 0.0
	return -(side_height + GROUND_TOP_SURFACE_SAFETY_OVERLAP)
