extends RefCounted
class_name IsoProjectionService

const PROJECTION_STANDARD: String = "standard_128x71"
const PROJECTION_CLASSIC: String = "classic_128x64"
const PROJECTION_PREVIEW_181: String = "preview_128x71"
const PROJECTION_CUSTOM: String = "custom_export_values"
const STANDARD_TILE_SIZE: Vector2 = Vector2(128.0, 71.0)
const CLASSIC_TILE_SIZE: Vector2 = Vector2(128.0, 64.0)

static func normalize_mode(mode: String) -> String:
	if mode == PROJECTION_STANDARD or mode == PROJECTION_PREVIEW_181:
		return PROJECTION_STANDARD
	if mode == PROJECTION_CLASSIC:
		return PROJECTION_CLASSIC
	if mode == PROJECTION_CUSTOM:
		return PROJECTION_CUSTOM
	return PROJECTION_STANDARD

static func get_tile_size(mode: String, custom_width: float, custom_height: float) -> Vector2:
	var normalized_mode: String = normalize_mode(mode)
	if normalized_mode == PROJECTION_STANDARD:
		return STANDARD_TILE_SIZE
	if normalized_mode == PROJECTION_CLASSIC:
		return CLASSIC_TILE_SIZE
	return Vector2(maxf(custom_width, 1.0), maxf(custom_height, 1.0))

static func exported_tile_size_matches_active_mode(mode: String, exported_width: float, exported_height: float) -> bool:
	var active_size: Vector2 = get_tile_size(mode, exported_width, exported_height)
	return is_equal_approx(exported_width, active_size.x) and is_equal_approx(exported_height, active_size.y)

static func get_tile_half_size(tile_size: Vector2, pitch_correction_degrees: float) -> Vector2:
	var half_width: float = maxf(tile_size.x, 1.0) * 0.5
	var half_height: float = maxf(tile_size.y, 1.0) * 0.5
	if absf(pitch_correction_degrees) <= 0.001:
		return Vector2(half_width, half_height)
	var corrected_angle: float = clampf(
		atan2(half_height, half_width) + deg_to_rad(pitch_correction_degrees),
		deg_to_rad(8.0),
		deg_to_rad(60.0)
	)
	return Vector2(half_width, tan(corrected_angle) * half_width)

static func grid_to_iso(cell: Vector2i, origin: Vector2, half_size: Vector2) -> Vector2:
	return origin + Vector2(
		float(cell.x - cell.y) * half_size.x,
		float(cell.x + cell.y) * half_size.y
	)

static func iso_to_grid(iso_position: Vector2, origin: Vector2, half_size: Vector2) -> Vector2i:
	var safe_half: Vector2 = Vector2(maxf(absf(half_size.x), 0.0001), maxf(absf(half_size.y), 0.0001))
	var local_iso: Vector2 = iso_position - origin
	var grid_x: float = (local_iso.x / safe_half.x + local_iso.y / safe_half.y) * 0.5
	var grid_y: float = (local_iso.y / safe_half.y - local_iso.x / safe_half.x) * 0.5
	return Vector2i(int(round(grid_x)), int(round(grid_y)))

static func get_diamond_points(cell: Vector2i, origin: Vector2, half_size: Vector2) -> PackedVector2Array:
	var center: Vector2 = grid_to_iso(cell, origin, half_size)
	return PackedVector2Array([
		center + Vector2(0.0, -half_size.y),
		center + Vector2(half_size.x, 0.0),
		center + Vector2(0.0, half_size.y),
		center + Vector2(-half_size.x, 0.0)
	])

static func get_inset_diamond_points(cell: Vector2i, inset: float, origin: Vector2, half_size: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = get_diamond_points(cell, origin, half_size)
	if inset <= 0.0:
		return points
	var center: Vector2 = grid_to_iso(cell, origin, half_size)
	var result: PackedVector2Array = PackedVector2Array()
	for point in points:
		var toward_center: Vector2 = center - point
		var distance: float = toward_center.length()
		var safe_inset: float = minf(inset, distance - 0.01)
		result.append(point if distance <= 0.0001 or safe_inset <= 0.0 else point + toward_center.normalized() * safe_inset)
	return result

static func get_depth_key(cell: Vector2i, origin: Vector2, half_size: Vector2, local_bias: float = 0.0) -> float:
	return grid_to_iso(cell, origin, half_size).y + half_size.y + local_bias

static func sort_cells_by_depth(a: Vector2i, b: Vector2i, origin: Vector2, half_size: Vector2) -> bool:
	var depth_a: float = get_depth_key(a, origin, half_size)
	var depth_b: float = get_depth_key(b, origin, half_size)
	if is_equal_approx(depth_a, depth_b):
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	return depth_a < depth_b
