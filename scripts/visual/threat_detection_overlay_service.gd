extends RefCounted
class_name ThreatDetectionOverlayService

# Builds debug/preview overlay payloads for threat detection systems.
# This service is data-only. It does not draw, mutate scenes, run AI, or change missions.

const ThreatDetectionServiceRef = preload("res://scripts/game/threats/threat_detection_service.gd")
const ThreatAlertServiceRef = preload("res://scripts/game/threats/threat_alert_service.gd")
const ThreatDetectionTypesRef = preload("res://scripts/game/threats/threat_detection_types.gd")

const DEFAULT_TILE_WIDTH: float = 128.0
const DEFAULT_TILE_HEIGHT: float = 71.0
const DEFAULT_OVERLAY_ALPHA: float = 0.28
const DEFAULT_VISION_STEPS: int = 8

static func grid_to_iso(cell: Vector2i, tile_width: float = DEFAULT_TILE_WIDTH, tile_height: float = DEFAULT_TILE_HEIGHT) -> Vector2:
	var half_width: float = tile_width * 0.5
	var half_height: float = tile_height * 0.5
	return Vector2(
		float(cell.x - cell.y) * half_width,
		float(cell.x + cell.y) * half_height
	)

static func build_vision_overlay_payload(
	origin_cell: Vector2i,
	facing: String,
	threat_id: String,	tile_width: float = DEFAULT_TILE_WIDTH,
	tile_height: float = DEFAULT_TILE_HEIGHT,
	override_definition: Dictionary = {}
) -> Dictionary:
	var overlay_data: Dictionary = ThreatDetectionServiceRef.build_vision_overlay_data(origin_cell, facing, threat_id, override_definition)
	var range_value: int = int(overlay_data.get("range", 0))
	var angle_value: float = float(overlay_data.get("angle", 90.0))
	var polygon_cells: Array[Vector2i] = build_vision_cone_boundary_cells(origin_cell, facing, range_value, angle_value)
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_VISION,
		"shape": "polygon",
		"threat_id": threat_id,
		"origin_cell": origin_cell,
		"facing": ThreatDetectionTypesRef.normalize_facing(facing),
		"range": range_value,
		"angle": angle_value,
		"alpha": DEFAULT_OVERLAY_ALPHA,
		"cells": polygon_cells,
		"points": cells_to_iso_points(polygon_cells, tile_width, tile_height),
		"line_of_sight_required": true
	}

static func build_vision_cone_boundary_cells(origin_cell: Vector2i, facing: String, vision_range: int, vision_angle_degrees: float) -> Array[Vector2i]:
	var normalized_facing: String = ThreatDetectionTypesRef.normalize_facing(facing)
	var forward: Vector2 = Vector2(ThreatDetectionTypesRef.facing_to_grid_direction(normalized_facing)).normalized()
	if forward == Vector2.ZERO or vision_range <= 0:
		return [origin_cell]
	var half_angle: float = deg_to_rad(vision_angle_degrees * 0.5)
	var left_dir: Vector2 = forward.rotated(-half_angle)
	var right_dir: Vector2 = forward.rotated(half_angle)
	var left_cell: Vector2i = origin_cell + Vector2i(roundi(left_dir.x * vision_range), roundi(left_dir.y * vision_range))
	var center_cell: Vector2i = origin_cell + Vector2i(roundi(forward.x * vision_range), roundi(forward.y * vision_range))
	var right_cell: Vector2i = origin_cell + Vector2i(roundi(right_dir.x * vision_range), roundi(right_dir.y * vision_range))
	return [origin_cell, left_cell, center_cell, right_cell]

static func build_visible_cells_overlay_payload(
	origin_cell: Vector2i,
	candidate_cells: Array[Vector2i],
	facing: String,
	threat_id: String,
	blocked_cells: Dictionary = {},
	tile_width: float = DEFAULT_TILE_WIDTH,
	tile_height: float = DEFAULT_TILE_HEIGHT,
	override_definition: Dictionary = {}
) -> Dictionary:
	var visible_cells: Array[Vector2i] = []
	for cell in candidate_cells:
		if ThreatDetectionServiceRef.can_see_cell(origin_cell, cell, facing, threat_id, blocked_cells, override_definition):
			visible_cells.append(cell)
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_VISION,
		"shape": "cells",
		"threat_id": threat_id,
		"origin_cell": origin_cell,
		"facing": ThreatDetectionTypesRef.normalize_facing(facing),
		"alpha": DEFAULT_OVERLAY_ALPHA,
		"cells": visible_cells,
		"points": cells_to_iso_points(visible_cells, tile_width, tile_height),
		"line_of_sight_required": true
	}

static func build_alert_overlay_payload(
	origin_cell: Vector2i,
	threat_id: String,
	tile_width: float = DEFAULT_TILE_WIDTH,
	tile_height: float = DEFAULT_TILE_HEIGHT,
	override_definition: Dictionary = {}
) -> Dictionary:
	var radius: int = ThreatAlertServiceRef.get_alert_radius(threat_id, override_definition)
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_ALERT,
		"shape": "radius",
		"threat_id": threat_id,
		"origin_cell": origin_cell,
		"radius": radius,
		"alpha": DEFAULT_OVERLAY_ALPHA,
		"cells": build_radius_cells(origin_cell, radius),
		"center_point": grid_to_iso(origin_cell, tile_width, tile_height),
		"radius_point": grid_to_iso(origin_cell + Vector2i(radius, 0), tile_width, tile_height)
	}

static func build_radar_overlay_payload(
	origin_cell: Vector2i,
	room_id: String,
	tile_width: float = DEFAULT_TILE_WIDTH,
	tile_height: float = DEFAULT_TILE_HEIGHT
) -> Dictionary:
	return {
		"mode": ThreatDetectionTypesRef.DETECTION_MODE_RADAR,
		"shape": "room_scope",
		"origin_cell": origin_cell,
		"room_id": room_id,
		"max_bounces": ThreatDetectionTypesRef.RADAR_MAX_BOUNCES,
		"alpha": DEFAULT_OVERLAY_ALPHA,
		"center_point": grid_to_iso(origin_cell, tile_width, tile_height),
		"description": "Radar uses same-room detection with up to 3 bounce-style reflections."
	}

static func build_radius_cells(origin_cell: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if radius < 0:
		return cells
	for x in range(origin_cell.x - radius, origin_cell.x + radius + 1):
		for y in range(origin_cell.y - radius, origin_cell.y + radius + 1):
			var cell: Vector2i = Vector2i(x, y)
			if origin_cell.distance_to(cell) <= float(radius):
				cells.append(cell)
	return cells

static func cells_to_iso_points(cells: Array[Vector2i], tile_width: float = DEFAULT_TILE_WIDTH, tile_height: float = DEFAULT_TILE_HEIGHT) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cell in cells:
		points.append(grid_to_iso(cell, tile_width, tile_height))
	return points

static func build_debug_overlay_bundle(
	origin_cell: Vector2i,
	facing: String,
	threat_id: String,
	room_id: String = "",
	has_radar: bool = false,
	tile_width: float = DEFAULT_TILE_WIDTH,
	tile_height: float = DEFAULT_TILE_HEIGHT,
	override_definition: Dictionary = {}
) -> Dictionary:
	var overlays: Array[Dictionary] = []
	overlays.append(build_vision_overlay_payload(origin_cell, facing, threat_id, tile_width, tile_height, override_definition))
	overlays.append(build_alert_overlay_payload(origin_cell, threat_id, tile_width, tile_height, override_definition))
	if has_radar:
		overlays.append(build_radar_overlay_payload(origin_cell, room_id, tile_width, tile_height))
	return {
		"threat_id": threat_id,
		"origin_cell": origin_cell,
		"facing": ThreatDetectionTypesRef.normalize_facing(facing),
		"overlays": overlays
	}
