extends RefCounted
class_name ThreatDetectionTypes

# Shared constants for threat detection and alert helpers.
# Data-only / helper-only. Do not implement AI loops here.

const FACING_NW: String = "nw"
const FACING_NE: String = "ne"
const FACING_SW: String = "sw"
const FACING_SE: String = "se"

const DETECTION_MODE_VISION: String = "vision"
const DETECTION_MODE_RADAR: String = "radar"
const DETECTION_MODE_ALERT: String = "alert"

const DETECTION_STATE_IDLE: String = "idle"
const DETECTION_STATE_SUSPICIOUS: String = "suspicious"
const DETECTION_STATE_DETECTED: String = "detected"
const DETECTION_STATE_ALERTED: String = "alerted"

const RADAR_MAX_BOUNCES: int = 3
const DEFAULT_VISION_ANGLE: int = 90
const DEFAULT_ALERT_RADIUS: int = 0
const DEFAULT_RADAR_ROOM_SCOPE: String = "room"

static func normalize_facing(facing: String) -> String:
	var normalized: String = str(facing).strip_edges().to_lower()
	if normalized in [FACING_NW, FACING_NE, FACING_SW, FACING_SE]:
		return normalized
	return FACING_SE

static func facing_to_grid_direction(facing: String) -> Vector2i:
	match normalize_facing(facing):
		FACING_NW:
			return Vector2i(0, -1)
		FACING_NE:
			return Vector2i(1, 0)
		FACING_SW:
			return Vector2i(-1, 0)
		FACING_SE:
			return Vector2i(0, 1)
		_:
			return Vector2i(0, 1)

static func grid_direction_to_facing(direction: Vector2i) -> String:
	var abs_x: int = abs(direction.x)
	var abs_y: int = abs(direction.y)
	if abs_x >= abs_y:
		return FACING_NE if direction.x >= 0 else FACING_SW
	return FACING_SE if direction.y >= 0 else FACING_NW
