extends RefCounted
class_name ObjectRenderer

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")

const WALL_SIDE_ORDER: Array[String] = ["north", "east", "south", "west"]

static func get_asset_key_for_profile(profile_key: String) -> String:
	var key: String = profile_key.strip_edges().to_lower()
	match key:
		"door", "digital_door", "powered_gate": return VisualAssetCatalogRef.resolve_object_asset_id("door")
		"terminal", "airflow_terminal", "door_terminal", "platform_terminal", "cooling_terminal": return "terminal_01"
		"key": return "object_key"
		"keycard", "digital_key": return "object_keycard"
		"fuse": return VisualAssetCatalogRef.resolve_object_asset_id("fuse")
		"fuse_box": return "fuse_box_in_01"
		"repair_kit": return VisualAssetCatalogRef.resolve_object_asset_id("repair_kit")
		"access_code", "datafile": return "object_access_code"
		"component": return "object_component"
		"socket": return "object_socket"
		"cable": return "object_cable"
		"cable_reel", "power_cable_reel": return "cable_reel_01"
		"button", "platform_control", "fan_control", "fan_speed_control": return "object_button"
		"switch", "breaker", "circuit_breaker", "light_switch", "power_switcher": return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_off")
		"power_source": return "power_source_01"
		"radiator": return "radiator_01"
		"light": return "light_off_wall_01"
		"barrel": return "barrel_01"
		"crate": return "normal_crate_floor_01"
		"box", "steel_box": return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
		"case": return VisualAssetCatalogRef.resolve_object_asset_id("case")
	return "object_generic"

static func get_mount_mode(object_data: Dictionary) -> String:
	var mount: String = str(object_data.get("mount", object_data.get("cable_install_mode", object_data.get("install_mode", object_data.get("placement_mode", object_data.get("placement", "floor")))))).to_lower().strip_edges()
	return "wall" if mount in ["wall", "wall_mounted"] or bool(object_data.get("is_wall_mounted", false)) else "floor"

static func is_state_on(object_data: Dictionary) -> bool:
	var type_value: String = str(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	var state: String = str(object_data.get("switch_state", object_data.get("state", "off"))).to_lower().strip_edges()
	if type_value.ends_with("_on") or type_value.contains("_on_"): return true
	if type_value.ends_with("_off") or type_value.contains("_off_"): return false
	if state in ["on", "off", "switch_on", "switch_off", "active", "inactive"]: return state in ["on", "switch_on", "active"]
	return bool(object_data.get("is_on", false)) if object_data.has("is_on") else false

static func is_fuse_present(object_data: Dictionary) -> bool:
	var type_value: String = str(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	if type_value.contains("installed") or type_value.contains("_in"): return true
	if type_value.contains("empty") or type_value.contains("_out"): return false
	if object_data.has("fuse_present"): return bool(object_data.get("fuse_present", false))
	return bool(object_data.get("fuse_installed", str(object_data.get("state", "")).to_lower().strip_edges() == "installed"))

static func is_wall_mounted_runtime_object(object_data: Dictionary) -> bool:
	return str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower() == "wall_mounted" or bool(object_data.get("is_wall_mounted", false))

static func get_wall_mounted_cardinal_side(object_data: Dictionary) -> String:
	var wall_side: String = str(object_data.get("interaction_side", object_data.get("wall_side", ""))).strip_edges().to_lower()
	var direction: Vector2i = WallMountedPlacementRulesServiceRef.get_required_interaction_direction(object_data)
	if direction == Vector2i(0, -1): return "north"
	if direction == Vector2i(1, 0): return "east"
	if direction == Vector2i(0, 1): return "south"
	if direction == Vector2i(-1, 0): return "west"
	return wall_side if wall_side in WALL_SIDE_ORDER else "west"
