extends RefCounted
class_name PlatformRotationService

static func get_rotation_delta(action_id: String) -> int:
	match action_id:
		"rotate_left":
			return -90
		"rotate_right":
			return 90
	return 0
