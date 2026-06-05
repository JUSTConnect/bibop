extends RefCounted
class_name PlatformVisualService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

const PLATFORM_ASSET_KEY: String = "platform_floor"
const PLATFORM_ASSET_PATH: String = "res://assets/visual/isometric/floor/floor_platform_01.png"
const DEFAULT_LEVEL_HEIGHT_PIXELS: float = 32.0

static func get_platform_asset_key(_platform_data: Dictionary = {}) -> String:
	return PLATFORM_ASSET_KEY

static func get_platform_asset_path(_platform_data: Dictionary = {}) -> String:
	return PLATFORM_ASSET_PATH

static func get_platform_level(platform_data: Dictionary) -> int:
	return int(platform_data.get("platform_level", platform_data.get("current_level", 0)))

static func get_platform_max_level(platform_data: Dictionary) -> int:
	return maxi(int(platform_data.get("max_level", 1)), 0)

static func get_clamped_platform_level(platform_data: Dictionary) -> int:
	return PlatformTypesRef.clamp_platform_level(get_platform_level(platform_data), get_platform_max_level(platform_data))

static func get_motion_progress(platform_data: Dictionary) -> float:
	return clampf(float(platform_data.get("motion_progress", platform_data.get("visual_motion_progress", 0.0))), 0.0, 1.0)

static func get_target_level(platform_data: Dictionary) -> int:
	var max_level: int = get_platform_max_level(platform_data)
	return PlatformTypesRef.clamp_platform_level(int(platform_data.get("target_level", get_platform_level(platform_data))), max_level)

static func get_visual_mode(platform_data: Dictionary) -> String:
	var level: int = get_clamped_platform_level(platform_data)
	var motion_state: String = PlatformTypesRef.normalize_motion_state(str(platform_data.get("motion_state", "")))
	if level <= 0 and motion_state == PlatformTypesRef.MOTION_IDLE:
		return PlatformTypesRef.VISUAL_FLUSH_TOP
	return PlatformTypesRef.VISUAL_RAISED_FULL

static func should_show_platform_rim(platform_data: Dictionary) -> bool:
	return get_visual_mode(platform_data) == PlatformTypesRef.VISUAL_RAISED_FULL

static func get_visual_level(platform_data: Dictionary) -> float:
	var level: int = get_clamped_platform_level(platform_data)
	var target_level: int = get_target_level(platform_data)
	var progress: float = get_motion_progress(platform_data)
	var motion_state: String = PlatformTypesRef.normalize_motion_state(str(platform_data.get("motion_state", "")))
	if motion_state == PlatformTypesRef.MOTION_RAISING:
		return lerpf(float(level), float(target_level), progress)
	if motion_state == PlatformTypesRef.MOTION_LOWERING:
		return lerpf(float(level), float(target_level), progress)
	return float(level)

static func get_visual_y_offset(platform_data: Dictionary, level_height_pixels: float = DEFAULT_LEVEL_HEIGHT_PIXELS) -> float:
	return -get_visual_level(platform_data) * level_height_pixels

static func get_source_region_mode(platform_data: Dictionary) -> String:
	if should_show_platform_rim(platform_data):
		return "full_with_rim"
	return "top_only_flush"

static func get_platform_draw_descriptor(platform_data: Dictionary, level_height_pixels: float = DEFAULT_LEVEL_HEIGHT_PIXELS) -> Dictionary:
	var visual_mode: String = get_visual_mode(platform_data)
	return {
		"asset_key": PLATFORM_ASSET_KEY,
		"floor_asset_key": PLATFORM_ASSET_KEY,
		"asset_path": PLATFORM_ASSET_PATH,
		"visual_mode": visual_mode,
		"source_region_mode": get_source_region_mode(platform_data),
		"show_rim": should_show_platform_rim(platform_data),
		"is_flush": visual_mode == PlatformTypesRef.VISUAL_FLUSH_TOP,
		"visual_level": get_visual_level(platform_data),
		"visual_y_offset": get_visual_y_offset(platform_data, level_height_pixels),
		"motion_progress": get_motion_progress(platform_data),
		"motion_state": PlatformTypesRef.normalize_motion_state(str(platform_data.get("motion_state", "")))
	}

static func get_overlay_descriptor(platform_data: Dictionary) -> Dictionary:
	var control_type: String = PlatformTypesRef.normalize_control_type(str(platform_data.get("control_type", "")))
	if control_type != PlatformTypesRef.CONTROL_INTERNAL:
		return {"visible": false}
	return {
		"visible": true,
		"kind": "platform_internal_control",
		"cell_x": int(platform_data.get("control_cell_x", platform_data.get("button_cell_x", 0))),
		"cell_y": int(platform_data.get("control_cell_y", platform_data.get("button_cell_y", 0))),
		"moves_with_platform": true,
		"visual_y_offset": get_visual_y_offset(platform_data)
	}
