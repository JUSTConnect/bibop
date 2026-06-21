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

static func get_profile_key_for_object_data(object_data: Dictionary, fallback_profile_key: String = "generic_object") -> String:
	var type_value: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).to_lower().strip_edges()
	var prefab_value: String = str(object_data.get("map_constructor_prefab_id", "")).to_lower().strip_edges()
	var key_kind: String = str(object_data.get("key_kind", object_data.get("key_type", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s" % [type_value, prefab_value, key_kind]
	if type_value == "enemy":
		return "bug" if str(object_data.get("enemy_type", object_data.get("enemy_kind", "vagus"))).to_lower().strip_edges() == "bug" else "vagus"
	if blob.contains("digital_key") or blob.contains("keycard"): return "keycard"
	if blob.contains("key"): return "key"
	if blob.contains("fuse"): return "fuse"
	if blob.contains("repair_kit"): return "repair_kit"
	if blob.contains("access_code") or blob.contains("code"): return "access_code"
	if blob.contains("cable_reel") or blob.contains("cable reel"): return "cable_reel"
	if blob.contains("power_cable") or blob.contains("cable") or blob.contains("wire"): return "cable"
	if blob.contains("power_source"): return "power_source"
	if blob.contains("radiator"): return "radiator"
	if blob.contains("power_switcher"):
		var switcher_type: String = str(object_data.get("switcher_type", "")).strip_edges().to_lower()
		if switcher_type == "light_switcher": return "light_switcher"
		if switcher_type == "power_breaker": return "power_breaker"
		return "power_switcher"
	if blob.contains("circuit_switch") or blob.contains("light_switch") or blob.contains("breaker") or blob.contains("switch"): return "switch"
	if blob.contains("light"): return "light"
	if blob.contains("door") or blob.contains("powered_gate"): return "door"
	if blob.contains("terminal"): return "terminal"
	if blob.contains("barrel"): return "barrel"
	if VisualStateAssetServiceRef.is_loot_case_object(object_data): return "case"
	if blob.contains("crate") or blob.contains("box"): return "crate"
	return "generic_object" if fallback_profile_key.strip_edges().is_empty() else fallback_profile_key

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

static func get_asset_key_for_object_data(object_data: Dictionary, fallback_profile_key: String) -> String:
	var fallback_asset_key: String = get_asset_key_for_profile(fallback_profile_key)
	var type_value: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).to_lower().strip_edges()
	var prefab_value: String = str(object_data.get("map_constructor_prefab_id", object_data.get("catalog_id", ""))).to_lower().strip_edges()
	var group_value: String = str(object_data.get("group", "")).to_lower().strip_edges()
	var name_value: String = str(object_data.get("name", "")).to_lower().strip_edges()
	var id_value: String = str(object_data.get("id", object_data.get("object_id", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s %s %s %s" % [fallback_profile_key.to_lower(), type_value, prefab_value, group_value, name_value, id_value]
	var explicit_visual_asset_id: String = str(object_data.get("visual_asset_id", object_data.get("visual_texture_asset_id", object_data.get("texture_asset_id", object_data.get("asset_id", ""))))).strip_edges()
	if not explicit_visual_asset_id.is_empty():
		return VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if VisualStateAssetServiceRef.object_uses_visual_states(object_data):
		return VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if type_value == "platform" or blob.contains(" platform"):
		return ""
	if type_value == "power_switcher" or blob.contains("power_switcher"):
		var mount: String = get_mount_mode(object_data)
		var on_suffix: String = "on" if is_state_on(object_data) else "off"
		if mount == "wall":
			return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_wall" % on_suffix)
		return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_floor" % on_suffix)
	if type_value == "fuse_box" or blob.contains("fuse_box"):
		var fuse_suffix: String = "in" if is_fuse_present(object_data) else "out"
		if get_mount_mode(object_data) == "wall":
			return "fuse_box_%s_wall_01" % fuse_suffix
		return "fuse_box_%s_01" % fuse_suffix
	if blob.contains("circuit_switch") or blob.contains("light_switch") or blob.contains("breaker") or blob.contains("switch"):
		var switch_mount: String = get_mount_mode(object_data)
		var switch_suffix: String = "on" if is_state_on(object_data) else "off"
		if switch_mount == "wall":
			return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_wall" % switch_suffix)
		return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_floor" % switch_suffix)
	if type_value == "barrel" or type_value == "fire_barrel" or type_value == "normal_barrel" or blob.contains("barrel"):
		var barrel_variant: String = str(object_data.get("variant", "normal")).to_lower().strip_edges()
		if barrel_variant == "fire" or type_value == "fire_barrel" or blob.contains("fire_barrel") or blob.contains("fire barrel") or blob.contains("flammable"):
			return "fire_barrel_floor_01"
		return "normal_barrel_floor_01"
	if VisualStateAssetServiceRef.is_loot_case_object(object_data):
		return VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if type_value == "crate":
		var crate_type: String = str(object_data.get("crate_type", object_data.get("variant", "normal"))).to_lower().strip_edges()
		if crate_type in ["heavy", "steel", "steel_box", "heavy_crate"]:
			return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
		return "normal_crate_floor_01"
	if type_value == "heavy_crate" or blob.contains("heavy_crate") or blob.contains("heavy crate") or type_value == "steel_box" or blob.contains("steel_box") or blob.contains("steel box"):
		return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
	if type_value == "normal_crate" or blob.contains("normal_crate") or blob.contains("normal crate"):
		return "normal_crate_floor_01"
	if type_value == "cable_reel" or type_value == "power_cable_reel" or blob.contains("cable_reel") or blob.contains("cable reel"):
		return "cable_reel_02" if get_mount_mode(object_data) == "wall" else "cable_reel_01"
	if type_value == "power_source" or blob.contains("power_source"):
		return "power_source_01"
	if type_value == "radiator" or type_value == "external_radiator" or blob.contains("radiator"):
		return "radiator_floor_01"
	if blob.contains("terminal") or blob.contains("console") or blob.contains("control_panel"):
		return "terminal_01"
	if blob.contains("door") or blob.contains("powered_gate"):
		return VisualAssetCatalogRef.resolve_object_asset_id("door")
	if blob.contains("terminal") or blob.contains("console") or blob.contains("control_panel"):
		return "object_terminal"
	if blob.contains("keycard") or blob.contains("digital_key"):
		return "object_keycard"
	if blob.contains("key"):
		return "object_key"
	if blob.contains("fuse"):
		return VisualAssetCatalogRef.resolve_object_asset_id("fuse")
	if blob.contains("repair_kit") or blob.contains("repair kit"):
		return VisualAssetCatalogRef.resolve_object_asset_id("repair_kit")
	if blob.contains("access_code") or blob.contains("access code"):
		return "object_access_code"
	if blob.contains("component"):
		return "object_component"
	if blob.contains("socket"):
		return "object_socket"
	if blob.contains("cable_reel") or blob.contains("cable reel"):
		return "object_cable_reel"
	if blob.contains("cable"):
		return "object_cable"
	if blob.contains("button"):
		return "object_button"
	if blob.contains("switch") or blob.contains("breaker"):
		var fallback_mount: String = get_mount_mode(object_data)
		var fallback_switch_suffix: String = "on" if is_state_on(object_data) else "off"
		if fallback_mount == "wall":
			return "power_switcher_%s_wall_01" % fallback_switch_suffix
		return "power_switcher_%s_01" % fallback_switch_suffix
	if fallback_asset_key.is_empty():
		return "object_generic"
	return fallback_asset_key
