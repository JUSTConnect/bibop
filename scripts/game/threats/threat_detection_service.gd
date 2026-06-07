extends RefCounted
class_name ThreatDetectionService

# Pure helper functions for threat vision/radar detection.
# No AI movement, combat resolution, mission mutation or renderer code belongs here.

const ThreatCatalogRef = preload("res://scripts/game/threats/threat_catalog.gd")
const ThreatDetectionTypesRef = preload("res://scripts/game/threats/threat_detection_types.gd")

static func get_vision_range(threat_id: String, override_definition: Dictionary = {}) -> int:
	var definition: Dictionary = _resolve_definition(threat_id, override_definition)
	return int(definition.get("view_radius", 0))

static func get_vision_angle(threat_id: String, override_definition: Dictionary = {}) -> int:
	var definition: Dictionary = _resolve_definition(threat_id, override_definition)
	return int(definition.get("vision_angle", ThreatDetectionTypesRef.DEFAULT_VISION_ANGLE))

static func is_cell_in_vision_cone(
	origin_cell: Vector2i,
	target_cell: Vector2i,
	facing: String,
	vision_range: int,
	vision_angle_degrees: float
) -> bool:
	var delta: Vector2 = Vector2(target_cell - origin_cell)
	if delta == Vector2.ZERO:
		return true
	if delta.length() > float(vision_range):
		return false
	var forward: Vector2 = Vector2(ThreatDetectionTypesRef.facing_to_grid_direction(facing))
	if forward == Vector2.ZERO:
		return false
	var dot_value: float = forward.normalized().dot(delta.normalized())
	dot_value = clampf(dot_value, -1.0, 1.0)
	var angle: float = rad_to_deg(acos(dot_value))
	return angle <= vision_angle_degrees * 0.5

static func has_clear_line_of_sight(origin_cell: Vector2i, target_cell: Vector2i, blocked_cells: Dictionary) -> bool:
	if origin_cell == target_cell:
		return true
	var line_cells: Array[Vector2i] = get_grid_line_cells(origin_cell, target_cell)
	for index in range(1, max(1, line_cells.size() - 1)):
		if _is_cell_blocked(line_cells[index], blocked_cells):
			return false
	return true

static func can_see_cell(
	origin_cell: Vector2i,
	target_cell: Vector2i,
	facing: String,
	threat_id: String,
	blocked_cells: Dictionary = {},
	override_definition: Dictionary = {}
) -> bool:
	var vision_range: int = get_vision_range(threat_id, override_definition)
	var vision_angle: int = get_vision_angle(threat_id, override_definition)
	if not is_cell_in_vision_cone(origin_cell, target_cell, facing, vision_range, float(vision_angle)):
		return false
	return has_clear_line_of_sight(origin_cell, target_cell, blocked_cells)

static func get_grid_line_cells(origin_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x0: int = origin_cell.x
	var y0: int = origin_cell.y
	var x1: int = target_cell.x
	var y1: int = target_cell.y
	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return cells

static func build_vision_overlay_data(
	origin_cell: Vector2i,
	facing: String,
	threat_id: String,
	override_definition: Dictionary = {}
) -> Dictionary:
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_VISION,
		"origin_cell": origin_cell,
		"facing": ThreatDetectionTypesRef.normalize_facing(facing),
		"range": get_vision_range(threat_id, override_definition),
		"angle": get_vision_angle(threat_id, override_definition),
		"threat_id": threat_id
	}

static func can_radar_detect_in_room(
	threat_room_id: String,
	target_room_id: String,
	has_radar: bool,
	remaining_bounces: int = ThreatDetectionTypesRef.RADAR_MAX_BOUNCES
) -> bool:
	if not has_radar:
		return false
	if str(threat_room_id).strip_edges().is_empty() or str(target_room_id).strip_edges().is_empty():
		return false
	if threat_room_id != target_room_id:
		return false
	return remaining_bounces >= 0

static func make_radar_detection_result(
	threat_id: String,
	threat_cell: Vector2i,
	target_cell: Vector2i,\tthreat_room_id: String,
	target_room_id: String,
	has_radar: bool
) -> Dictionary:
	var detected: bool = can_radar_detect_in_room(threat_room_id, target_room_id, has_radar)
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_RADAR,
		"detected": detected,
		"threat_id": threat_id,
		"threat_cell": threat_cell,
		"target_cell": target_cell,
		"last_known_position": target_cell if detected else Vector2i(-1, -1),
		"notification": "enemy detected you" if detected else "",
		"max_bounces": ThreatDetectionTypesRef.RADAR_MAX_BOUNCES
	}

static func should_run_radar_again(reached_last_known_position: bool, has_visual_contact: bool) -> bool:
	return reached_last_known_position and not has_visual_contact

static func _resolve_definition(threat_id: String, override_definition: Dictionary = {}) -> Dictionary:
	if not override_definition.is_empty():
		return override_definition.duplicate(true)
	return ThreatCatalogRef.get_threat_definition(threat_id)

static func _is_cell_blocked(cell: Vector2i, blocked_cells: Dictionary) -> bool:
	if blocked_cells.has(cell):
		return bool(blocked_cells.get(cell, false))
	var key_as_string: String = "%s,%s" % [cell.x, cell.y]
	return bool(blocked_cells.get(key_as_string, false))
