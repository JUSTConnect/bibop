extends RefCounted
class_name LightVisualService

const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")

const LIGHT_OFF_WALL_ASSET_ID := "light_off_wall_01"
const LIGHT_ON_WALL_ASSET_ID := "light_on_wall_01"
const LIGHT_ON_WALL_PULSAR_OVERLAY_ASSET_ID := "light_on_wall_pulsar_overlay_01"

static func is_light_object(object_data: Dictionary) -> bool:
	return VisualStateAssetServiceRef.is_light_object(object_data)

static func is_light_on(object_data: Dictionary) -> bool:
	return VisualStateAssetServiceRef.resolve_visual_state(object_data) == VisualStateAssetServiceRef.VISUAL_STATE_ON

static func get_light_base_asset_key(object_data: Dictionary) -> String:
	return VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)

static func get_light_overlay_asset_key(_object_data: Dictionary) -> String:
	return LIGHT_ON_WALL_PULSAR_OVERLAY_ASSET_ID

static func should_draw_pulsar_overlay(object_data: Dictionary) -> bool:
	return not VisualStateAssetServiceRef.resolve_overlay_asset_ids(object_data, get_light_base_asset_key(object_data)).is_empty()

static func get_pulsar_overlay_alpha(time_seconds: float, object_data: Dictionary = {}) -> float:
	return VisualStateAssetServiceRef.get_pulsar_overlay_alpha(time_seconds, object_data)

static func get_soft_glow_alpha(time_seconds: float, object_data: Dictionary = {}) -> float:
	return VisualStateAssetServiceRef.get_soft_glow_alpha(time_seconds, object_data)
