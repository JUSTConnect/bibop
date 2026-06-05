extends RefCounted
class_name PlatformVisualService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

static func get_platform_draw_descriptor(platform_data: Dictionary) -> Dictionary:
	var data: Dictionary = PlatformTypesRef.normalize_platform_config(platform_data)
	var level: int = int(data.get("platform_level", 0))
	var raised: bool = level > 0
	return {
		"ok": true,
		"texture_asset_id": "platform_floor",
		"floor_asset_key": "platform_floor",
		"level": level,
		"is_flush": not raised,
		"rim_visible": raised,
		"source_region_mode": "full_with_rim" if raised else "top_only_flush",
		"visual_y_offset": -18.0 * float(level) if raised else 0.0,
		"message": "Raised platform visual." if raised else "Flush platform visual."
	}
