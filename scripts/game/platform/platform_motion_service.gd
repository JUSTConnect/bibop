extends RefCounted
class_name PlatformMotionService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

static func preview_level_after_action(platform_data: Dictionary, action_id: String) -> Dictionary:
	var data: Dictionary = PlatformTypesRef.normalize_platform_config(platform_data)
	var current_level: int = int(data.get("platform_level", 0))
	var max_level: int = int(data.get("max_level", 1))
	var next_level: int = current_level
	match action_id:
		"raise":
			next_level = mini(max_level, current_level + 1)
		"lower":
			next_level = maxi(0, current_level - 1)
	return {"ok": true, "current_level": current_level, "next_level": next_level, "changed": next_level != current_level}
