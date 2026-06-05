extends RefCounted
class_name PlatformTypes

const MODE_ELEVATOR: String = "elevator"
const MODE_ROTATOR: String = "rotator"
const MODE_ELEVATOR_ROTATOR: String = "elevator_rotator"

const CONTROL_INTERNAL: String = "internal"
const CONTROL_EXTERNAL: String = "external"

const POWER_NONE: String = "none"
const POWER_INTERNAL: String = "internal"
const POWER_EXTERNAL: String = "external"

const ACTIVATION_INSTANT: String = "instant"
const ACTIVATION_DELAYED: String = "delayed"

const MOTION_IDLE: String = "idle"
const MOTION_RAISING: String = "raising"
const MOTION_LOWERING: String = "lowering"
const MOTION_ROTATING_LEFT: String = "rotating_left"
const MOTION_ROTATING_RIGHT: String = "rotating_right"

const ACTION_RAISE: String = "raise"
const ACTION_LOWER: String = "lower"
const ACTION_ROTATE_LEFT: String = "rotate_left"
const ACTION_ROTATE_RIGHT: String = "rotate_right"
const ACTION_CANCEL_PENDING: String = "cancel_pending"

const VISUAL_FLUSH_TOP: String = "flush_top"
const VISUAL_RAISED_FULL: String = "raised_full"

const DIRECTION_NORTH: String = "north"
const DIRECTION_EAST: String = "east"
const DIRECTION_SOUTH: String = "south"
const DIRECTION_WEST: String = "west"

static func normalize_platform_mode(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"", "lift", "lifting", "elevator", "elevator_platform", "platform_elevator":
			return MODE_ELEVATOR
		"rotate", "rotation", "rotator", "rotating", "turntable", "platform_rotator":
			return MODE_ROTATOR
		"both", "elevator_rotator", "rotator_elevator", "lift_rotate", "rotate_lift", "elevator_and_rotator":
			return MODE_ELEVATOR_ROTATOR
	return MODE_ELEVATOR

static func normalize_control_type(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"external", "remote", "terminal", "switch", "controller":
			return CONTROL_EXTERNAL
	return CONTROL_INTERNAL

static func normalize_power_type(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"external", "external_power", "power_source", "network":
			return POWER_EXTERNAL
		"internal", "self", "self_powered", "battery":
			return POWER_INTERNAL
		"none", "no", "no_power", "disabled":
			return POWER_NONE
	return POWER_NONE

static func normalize_activation_mode(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"delayed", "delay", "timer", "turn_delay", "after_turns":
			return ACTIVATION_DELAYED
	return ACTIVATION_INSTANT

static func normalize_motion_state(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		MOTION_RAISING, "raise", "up":
			return MOTION_RAISING
		MOTION_LOWERING, "lower", "down":
			return MOTION_LOWERING
		MOTION_ROTATING_LEFT, "rotate_left", "left":
			return MOTION_ROTATING_LEFT
		MOTION_ROTATING_RIGHT, "rotate_right", "right":
			return MOTION_ROTATING_RIGHT
	return MOTION_IDLE

static func normalize_platform_action(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"up", "raise", "lift":
			return ACTION_RAISE
		"down", "lower":
			return ACTION_LOWER
		"left", "rotate_left", "turn_left":
			return ACTION_ROTATE_LEFT
		"right", "rotate_right", "turn_right":
			return ACTION_ROTATE_RIGHT
		"cancel", "cancel_pending":
			return ACTION_CANCEL_PENDING
	return ""

static func platform_mode_supports_elevator(mode: String) -> bool:
	var normalized_mode: String = normalize_platform_mode(mode)
	return normalized_mode == MODE_ELEVATOR or normalized_mode == MODE_ELEVATOR_ROTATOR

static func platform_mode_supports_rotator(mode: String) -> bool:
	var normalized_mode: String = normalize_platform_mode(mode)
	return normalized_mode == MODE_ROTATOR or normalized_mode == MODE_ELEVATOR_ROTATOR

static func clamp_platform_level(value: int, max_level: int) -> int:
	return clampi(value, 0, maxi(max_level, 0))

static func normalize_delay_turns(value: int) -> int:
	return maxi(value, 0)

static func normalize_direction(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "_")
	normalized_value = normalized_value.replace("-", "_")
	match normalized_value:
		"n", "north", "up":
			return DIRECTION_NORTH
		"e", "east", "right":
			return DIRECTION_EAST
		"s", "south", "down":
			return DIRECTION_SOUTH
		"w", "west", "left":
			return DIRECTION_WEST
	return normalized_value

static func rotate_direction(direction: String, action: String) -> String:
	var normalized_direction: String = normalize_direction(direction)
	var normalized_action: String = normalize_platform_action(action)
	var order: Array[String] = [DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST]
	var index: int = order.find(normalized_direction)
	if index < 0:
		return normalized_direction
	if normalized_action == ACTION_ROTATE_RIGHT:
		return str(order[(index + 1) % order.size()])
	if normalized_action == ACTION_ROTATE_LEFT:
		return str(order[(index + order.size() - 1) % order.size()])
	return normalized_direction

static func action_label(action: String) -> String:
	match normalize_platform_action(action):
		ACTION_RAISE:
			return "Raise"
		ACTION_LOWER:
			return "Lower"
		ACTION_ROTATE_LEFT:
			return "Rotate Left"
		ACTION_ROTATE_RIGHT:
			return "Rotate Right"
		ACTION_CANCEL_PENDING:
			return "Cancel Pending"
	return "Platform Action"

static func available_actions_for_mode(mode: String, current_level: int = 0, max_level: int = 1) -> Array[String]:
	var actions: Array[String] = []
	var normalized_mode: String = normalize_platform_mode(mode)
	if platform_mode_supports_elevator(normalized_mode):
		if current_level < max_level:
			actions.append(ACTION_RAISE)
		if current_level > 0:
			actions.append(ACTION_LOWER)
	if platform_mode_supports_rotator(normalized_mode):
		actions.append(ACTION_ROTATE_LEFT)
		actions.append(ACTION_ROTATE_RIGHT)
	return actions

static func get_default_platform_config() -> Dictionary:
	return {
		"platform_mode": MODE_ELEVATOR,
		"platform_level": 0,
		"max_level": 1,
		"mechanism_id": "",
		"mechanism_role": "single",
		"control_type": CONTROL_INTERNAL,
		"power_type": POWER_NONE,
		"activation_mode": ACTIVATION_INSTANT,
		"activation_delay_turns": 0,
		"control_cell_x": 0,
		"control_cell_y": 0
	}
