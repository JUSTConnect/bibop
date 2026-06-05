extends RefCounted
class_name VisualAssetCatalog

# Shared visual asset catalog for BIPOB isometric rendering.
# This file is visual-only. It must not mutate gameplay state.
# Final projection target remains 128x71; asset paths here do not define gameplay geometry.

const ISO_OBJECT_ASSET_PACK_DIR: String = "res://assets/visual/isometric/objects/"
const ISO_MOVABLE_ASSET_PACK_DIR: String = "res://assets/visual/isometric/moovable/"
const ISO_WALL_ASSET_PACK_DIR: String = "res://assets/visual/isometric/wall/"
const ISO_PLACEHOLDER_ASSET_PACK_DIR: String = "res://assets/visual/isometric/placeholders/"

const ASSET_PATHS: Dictionary = {
	"floor_concrete": "res://assets/visual/isometric/floor/floor_concrete_01.png",
	"floor_steel": "res://assets/visual/isometric/floor/floor_steel_01.png",
	"floor_titan": "res://assets/visual/isometric/floor/floor_titan_01.png",
	"platform_floor": "res://assets/visual/isometric/floor/floor_platform_01.png",
	"floor_default": "res://assets/visual/isometric/floor/floor_concrete_01.png",
	"floor_stepped": "res://assets/visual/isometric/placeholders/iso_floor_stepped.svg",
	"floor_clean_lab": "res://assets/visual/isometric/placeholders/iso_floor_clean_lab.svg",
	"floor_dark_service": "res://assets/visual/isometric/placeholders/iso_floor_dark_service.svg",
	"floor_hazard": "res://assets/visual/isometric/placeholders/iso_floor_hazard.svg",
	"floor_power": "res://assets/visual/isometric/placeholders/iso_floor_power.svg",
	"floor_damaged": "res://assets/visual/isometric/placeholders/iso_floor_damaged.svg",
	"floor_reinforced": "res://assets/visual/isometric/placeholders/iso_floor_reinforced.svg",
	"floor_diagnostic": "res://assets/visual/isometric/placeholders/iso_floor_diagnostic.svg",
	"floor_door_underlay": "res://assets/visual/isometric/placeholders/iso_floor_door_underlay.svg",
	"ground_low": "res://assets/visual/isometric/ground/ground_low_01.png",
	"ground_halflow": "res://assets/visual/isometric/ground/ground_halflow_01.png",

	"wall_default": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_outer": "res://assets/visual/isometric/wall/outerwall/wall_outerwall_mid_01.png",
	"wall_brick": "res://assets/visual/isometric/wall/brick/wall_brick_mid_01.png",
	"wall_concrete": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_grate": "res://assets/visual/isometric/wall/grate/wall_grate_mid_01.png",
	"wall_damaged": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_concrete_damaged": "res://assets/visual/isometric/wall/concrete/wall_concrete_mid_01.png",
	"wall_brick_damaged": "res://assets/visual/isometric/wall/brick/wall_brick_mid_01.png",
	"wall_steel": "res://assets/visual/isometric/wall/steel/wall_steel_mid_01.png",
	"wall_reinforced_steel": "res://assets/visual/isometric/wall/reinforce_steel/wall_reinforcesteel_mid_01.png",
	"wall_titan": "res://assets/visual/isometric/wall/titan/wall_titan_mid_01.png",
	"wall_energy": "res://assets/visual/isometric/wall/reinforce_steel/wall_reinforcesteel_mid_01.png",

	"object_door": "res://assets/visual/isometric/placeholders/iso_object_door.svg",
	"object_terminal": "res://assets/visual/isometric/placeholders/iso_object_terminal.svg",
	"object_key": "res://assets/visual/isometric/placeholders/iso_object_key.svg",
	"object_component": "res://assets/visual/isometric/placeholders/iso_object_component.svg",
	"object_socket": "res://assets/visual/isometric/placeholders/iso_object_socket.svg",
	"object_cable": "res://assets/visual/isometric/placeholders/iso_object_cable.svg",
	"object_generic": "res://assets/visual/isometric/placeholders/iso_object_generic.svg",
	"object_fuse": "res://assets/visual/isometric/placeholders/iso_object_fuse.svg",
	"object_repair_kit": "res://assets/visual/isometric/placeholders/iso_object_repair_kit.svg",
	"object_keycard": "res://assets/visual/isometric/placeholders/iso_object_keycard.svg",
	"object_access_code": "res://assets/visual/isometric/placeholders/iso_object_access_code.svg",
	"object_cable_reel": "res://assets/visual/isometric/placeholders/iso_object_cable_reel.svg",
	"object_button": "res://assets/visual/isometric/placeholders/iso_object_button.svg",
	"object_switch": "res://assets/visual/isometric/placeholders/iso_object_switch.svg",

	"cable_reel_01": "res://assets/visual/isometric/objects/cable_reel_01.png",
	"cable_reel_02": "res://assets/visual/isometric/objects/cable_reel_02.png",
	"fuse_box_in_01": "res://assets/visual/isometric/objects/fuse_box_in_01.png",
	"fuse_box_out_01": "res://assets/visual/isometric/objects/fuse_box_out_01.png",
	"fuse_box_in_wall_01": "res://assets/visual/isometric/objects/fuse_box_in_wall_01.png",
	"fuse_box_out_wall_01": "res://assets/visual/isometric/objects/fuse_box_out_wall_01.png",
	"light_01": "res://assets/visual/isometric/objects/light_01.png",
	"power_source_01": "res://assets/visual/isometric/objects/power_source_01.png",
	"power_switcher_off_01": "res://assets/visual/isometric/objects/power_switcher_off_01.png",
	"power_switcher_off_wall_01": "res://assets/visual/isometric/objects/power_switcher_off_wall_01.png",
	"power_switcher_on_01": "res://assets/visual/isometric/objects/power_switcher_on_01.png",
	"power_switcher_on_wall_01": "res://assets/visual/isometric/objects/power_switcher_on_wall_01.png",
	"radiator_01": "res://assets/visual/isometric/objects/radiator_01.png",
	"terminal_01": "res://assets/visual/isometric/objects/terminal_01.png",
	"barrel_01": "res://assets/visual/isometric/moovable/barrel_01.png",
	"case_01": "res://assets/visual/isometric/objects/case_01.png",
	"steel_box_01": "res://assets/visual/isometric/moovable/steel_box_01.png",
	"fire_barrel_01": "res://assets/visual/isometric/moovable/fire_barrel_01.png"
}

const FLOOR_ASSET_ALIASES: Dictionary = {
	"default_floor": "floor_concrete",
	"floor_default": "floor_concrete",
	"concrete": "floor_concrete",
	"concrete_floor": "floor_concrete",
	"steel": "floor_steel",
	"steel_floor": "floor_steel",
	"titan": "floor_titan",
	"titan_floor": "floor_titan",
	"titanium": "floor_titan",
	"titanium_floor": "floor_titan",
	"clean_lab_floor": "floor_steel",
	"dark_service_floor": "floor_concrete",
	"hazard_floor": "floor_concrete",
	"power_floor": "floor_steel",
	"damaged_floor": "floor_concrete",
	"reinforced_floor": "floor_steel",
	"diagnostic_floor": "floor_steel"
}

const WALL_ASSET_ALIASES: Dictionary = {
	"default_wall": "wall_default",
	"wall_default_metal": "wall_concrete",
	"wall_clean_lab": "wall_concrete",
	"wall_dark_service": "wall_grate",
	"wall_orange_hazard": "wall_concrete_damaged",
	"wall_damaged_red": "wall_brick_damaged",
	"wall_reinforced": "wall_steel",
	"wall_power_room": "wall_reinforced_steel",
	"wall_diagnostic_blue": "wall_brick",
	"wall_concrete": "wall_concrete",
	"wall_concrete_default": "wall_concrete",
	"wall_steel": "wall_steel",
	"wall_brick": "wall_brick",
	"wall_brick_damage": "wall_brick_damaged",
	"wall_brick_damaged": "wall_brick_damaged",
	"wall_concrete_damage": "wall_concrete_damaged",
	"wall_concrete_damaged": "wall_concrete_damaged",
	"wall_reinforced_steel": "wall_reinforced_steel",
	"wall_titan": "wall_titan",
	"wall_titanium": "wall_titan",
	"wall_outer": "wall_outer",
	"wall_outerwall": "wall_outer",
	"wall_grate": "wall_grate",
	"wall_boundary": "wall_outer",
	"industrial_panel": "wall_brick",
	"wall_industrial_panel": "wall_brick",
	"wall_service_vent": "wall_grate",
	"outer": "wall_outer",
	"boundary": "wall_outer",
	"concrete": "wall_concrete",
	"brick": "wall_brick",
	"grate": "wall_grate",
	"vent": "wall_grate",
	"service": "wall_grate",
	"steel": "wall_steel",
	"reinforced": "wall_reinforced_steel",
	"titan": "wall_titan",
	"titanium": "wall_titan",
	"damaged": "wall_concrete_damaged",
	"red": "wall_brick_damaged",
	"broken": "wall_concrete_damaged",
	"energy": "wall_reinforced_steel",
	"powered": "wall_reinforced_steel"
}

const OBJECT_ASSET_ALIASES: Dictionary = {
	"door_state_generic": "object_door",
	"terminal_state_generic": "object_terminal",
	"item_generic_marker": "object_generic",
	"cable_reel": "cable_reel_01",
	"power_cable_reel": "cable_reel_01",
	"fuse_box": "fuse_box_out_01",
	"fuse_box_empty": "fuse_box_out_01",
	"fuse_box_installed": "fuse_box_in_01",
	"wall_fuse_box": "fuse_box_out_wall_01",
	"power_source": "power_source_01",
	"power_source_class_1": "power_source_01",
	"power_source_class_2": "power_source_01",
	"power_source_class_3": "power_source_01",
	"switcher": "power_switcher_off_01",
	"power_switcher": "power_switcher_off_01",
	"radiator": "radiator_01",
	"external_radiator": "radiator_01",
	"terminal": "terminal_01",
	"barrel": "barrel_01",
	"case": "case_01",
	"steel_box": "steel_box_01",
	"light": "light_01"
}

const CANONICAL_OBJECT_VISUAL_IDS: Array[String] = [
	"power_source_01",
	"terminal_01",
	"radiator_01",
	"light_01",
	"cable_reel_01",
	"cable_reel_02",
	"fuse_box_in_01",
	"fuse_box_out_01",
	"fuse_box_in_wall_01",
	"fuse_box_out_wall_01",
	"power_switcher_off_01",
	"power_switcher_on_01",
	"power_switcher_off_wall_01",
	"power_switcher_on_wall_01",
	"barrel_01",
	"fire_barrel_01",
	"case_01",
	"steel_box_01"
]

static func get_asset_path(asset_id: String) -> String:
	var normalized_id: String = str(asset_id).strip_edges()
	return str(ASSET_PATHS.get(normalized_id, ""))

static func has_asset(asset_id: String) -> bool:
	return not get_asset_path(asset_id).is_empty()

static func resolve_floor_asset_id(raw_id: String) -> String:
	var normalized_id: String = str(raw_id).strip_edges().to_lower()
	if FLOOR_ASSET_ALIASES.has(normalized_id):
		return str(FLOOR_ASSET_ALIASES.get(normalized_id, "floor_concrete"))
	if ASSET_PATHS.has(normalized_id):
		return normalized_id
	return "floor_concrete"

static func resolve_wall_asset_id(raw_id: String) -> String:
	var normalized_id: String = str(raw_id).strip_edges().to_lower()
	if WALL_ASSET_ALIASES.has(normalized_id):
		return str(WALL_ASSET_ALIASES.get(normalized_id, "wall_default"))
	if ASSET_PATHS.has(normalized_id):
		return normalized_id
	return "wall_default"

static func resolve_object_asset_id(raw_id: String) -> String:
	var normalized_id: String = str(raw_id).strip_edges().to_lower()
	if OBJECT_ASSET_ALIASES.has(normalized_id):
		return str(OBJECT_ASSET_ALIASES.get(normalized_id, "object_generic"))
	if ASSET_PATHS.has(normalized_id):
		return normalized_id
	return "object_generic"

static func get_canonical_object_visual_ids() -> Array[String]:
	return CANONICAL_OBJECT_VISUAL_IDS.duplicate()

static func get_all_asset_paths() -> Dictionary:
	return ASSET_PATHS.duplicate()

static func validate_asset_catalog() -> Array[String]:
	var warnings: Array[String] = []
	for asset_id_variant in ASSET_PATHS.keys():
		var asset_id: String = str(asset_id_variant)
		var path: String = str(ASSET_PATHS.get(asset_id, ""))
		if asset_id.strip_edges().is_empty():
			warnings.append("visual_asset_catalog_empty_asset_id")
		if path.strip_edges().is_empty():
			warnings.append("visual_asset_catalog_empty_path_%s" % asset_id)
		elif not path.begins_with("res://"):
			warnings.append("visual_asset_catalog_non_res_path_%s" % asset_id)
	return warnings
