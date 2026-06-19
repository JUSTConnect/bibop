extends RefCounted
class_name WorldObjectCatalog

const WorldObjectDataRef = preload("res://scripts/world/world_object_data.gd")

const DOOR_TYPE_MECHANICAL := "mechanical"
const DOOR_TYPE_DIGITAL := "digital"
const DOOR_TYPE_POWERED := "powered"
const DOOR_TYPES: Array[String] = [DOOR_TYPE_MECHANICAL, DOOR_TYPE_DIGITAL, DOOR_TYPE_POWERED]

const DOOR_MATERIAL_STEEL := "steel"
const DOOR_MATERIAL_REINFORCED_STEEL := "reinforced_steel"
const DOOR_MATERIAL_TITANIUM := "titanium"
const DOOR_MATERIAL_ENERGY := "energy"
const DOOR_MATERIALS: Array[String] = [DOOR_MATERIAL_STEEL, DOOR_MATERIAL_REINFORCED_STEEL, DOOR_MATERIAL_TITANIUM, DOOR_MATERIAL_ENERGY]

const ACCESS_TYPE_NO_KEY := "no_key"
const ACCESS_TYPE_KEY_CARD := "key_card"
const ACCESS_TYPE_DIGITAL_KEY := "digital_key"
const ACCESS_TYPE_ACCESS_CODE := "access_code"
const ACCESS_TYPE_TERMINAL := "terminal"
const ACCESS_TYPES: Array[String] = [ACCESS_TYPE_NO_KEY, ACCESS_TYPE_KEY_CARD, ACCESS_TYPE_DIGITAL_KEY, ACCESS_TYPE_ACCESS_CODE, ACCESS_TYPE_TERMINAL]
const KEY_ITEM_TYPE_KEY_CARD := "key_card"
const ITEM_STORAGE_CLASS_PHYSICAL := "physical"
const ITEM_STORAGE_CLASS_KEY_CARD := "key_card"
const ITEM_STORAGE_CLASS_DIGITAL := "digital"
const ITEM_STORAGE_CLASS_UNKNOWN := "unknown"
const DIGITAL_ITEM_TYPE_ALIASES: Array[String] = ["digital_key", "access_code", "access_data", "data_file", "encrypted_file", "damaged_file", "information_file", "info_key", "record"]
const ITEM_CLASS_PHYSICAL_ITEM := "physical_item"
const ITEM_CLASS_KEY_CARD := "key_card"
const ITEM_CLASS_DIGITAL_KEY := "digital_key"
const ITEM_CLASS_ACCESS_CODE := "access_code"
const ITEM_CLASS_DATA_FILE := "data_file"
const ITEM_CLASSES: Array[String] = [ITEM_CLASS_PHYSICAL_ITEM, ITEM_CLASS_KEY_CARD, ITEM_CLASS_DIGITAL_KEY, ITEM_CLASS_ACCESS_CODE, ITEM_CLASS_DATA_FILE]
const ITEM_STORAGE_ROUTE_POCKET := "pocket"
const ITEM_STORAGE_ROUTE_KEYCHAIN := "keychain"
const ITEM_STORAGE_ROUTE_DIGITAL_BUFFER := "digital_buffer"
const ITEM_STORAGE_ROUTE_DIGITAL_STORAGE := "digital_storage"
const ITEM_STORAGE_ROUTES: Array[String] = [ITEM_STORAGE_ROUTE_POCKET, ITEM_STORAGE_ROUTE_KEYCHAIN, ITEM_STORAGE_ROUTE_DIGITAL_BUFFER, ITEM_STORAGE_ROUTE_DIGITAL_STORAGE]
const ITEM_DISPLAY_NAMES: Dictionary = {
	ITEM_CLASS_PHYSICAL_ITEM:"Physical Item",
	ITEM_CLASS_KEY_CARD:"Key Card",
	ITEM_CLASS_DIGITAL_KEY:"Digital Key",
	ITEM_CLASS_ACCESS_CODE:"Access Code",
	ITEM_CLASS_DATA_FILE:"Data File"
}
const POWER_BEHAVIOR_NONE := "none"
const POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED := "opens_when_unpowered"
const POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN := "requires_power_to_open"
const POWER_BEHAVIORS: Array[String] = [POWER_BEHAVIOR_NONE, POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, POWER_BEHAVIOR_REQUIRES_POWER_TO_OPEN]
const DOOR_POWER_TYPES: Array[String] = ["internal", "external", "none"]
const DOOR_CONTROL_TYPES: Array[String] = ["internal", "external"]
const DOOR_STATES: Array[String] = ["closed", "open", "damaged", "jammed", "locked", "unpowered"]

const FLOOR_MATERIALS: Array[String] = ["concrete", "steel", "titan"]
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const FLOOR_COVERINGS: Array[String] = ["default", "dirt", "water", "debris", "oil"]
const FLOOR_VISUAL_STYLES: Array[String] = ["default", "permission"]
const FLOOR_STATES: Array[String] = ["normal", "damaged"]

const SWITCHER_TYPE_LIGHT := "light_switcher"
const SWITCHER_TYPE_POWER_BREAKER := "power_breaker"
const SWITCHER_TYPE_POWER_SWITCHER := "power_switcher"
const SWITCHER_TYPES: Array[String] = [SWITCHER_TYPE_LIGHT, SWITCHER_TYPE_POWER_BREAKER, SWITCHER_TYPE_POWER_SWITCHER]
const SWITCHER_LINE_DIRECTIONS: Array[String] = ["", "NORTH", "EAST", "SOUTH", "WEST"]
const SWITCHER_LINE_COLORS: Array[String] = ["red", "blue", "green", "yellow", "orange", "purple", "white"]

const PREFAB_ALIASES: Dictionary = {
	"fuse_box_installed": "fuse_box",
	"fuse_box_empty": "fuse_box",
	"light_switch": "power_switcher",
	"circuit_breaker": "power_switcher",
	"power_switch": "power_switcher",
	"power_switcher_floor_off": "power_switcher",
	"power_switcher_floor_on": "power_switcher",
	"power_switcher_wall_off": "power_switcher",
	"power_switcher_wall_on": "power_switcher",
	"explosive_barrel": "barrel",
	"fire_barrel": "barrel",
	"normal_crate": "crate",
	"heavy_crate": "crate",
	"steel_box": "crate",
	"concrete_floor": "floor",
	"steel_floor": "floor",
	"titan_floor": "floor",
	"titanium_floor": "floor",
	"grate_floor": "floor",
	"permission_floor": "floor",
	"water_floor": "floor",
	"oil_floor": "floor",
	"dirty_floor": "floor",
	"debris_floor": "floor",
	"breachable_wall": "wall",
	"loot_case": "case",
	"loot_crate": "case",
	"case_locked": "case",
	"case_class1": "case",
	"case_class2": "case",
	"case_class3": "case",
	"case_not_empty": "case",
	"case_empty": "case",
	"external_air_cooler": "metal_cooling_block",
	"air_cooling": "metal_cooling_block",
	"air_cooler": "metal_cooling_block",
	"cooling_fan": "metal_cooling_block",
	"digital_key": "digital_item",
	"access_code": "digital_item",
	"data_file": "digital_item",
	"key_card": "access_item",
	"mechanical_key": "access_item",
	"mechanical_keycard": "access_item",
	"keycard": "access_item",
	"fuse": "physical_item",
	"repair_kit": "physical_item",
	"reinforcement": "physical_item",
	"parts": "physical_item",
	"parts_small": "physical_item",
	"parts_medium": "physical_item",
	"parts_large": "physical_item",
	"module_internal": "module_item",
	"module_external": "module_item",
	"vagus": "enemy",
	"bug": "enemy"
}

const CONSTRUCTOR_PALETTE_GROUP_ORDER: Array[String] = [
	"Recent",
	"Power",
	"Cooling system",
	"Movable",
	"Environments",
	"Item",
	"Traps",
	"Robots",
	"Control",
	"Other"
]

const CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB: Dictionary = {
	"power_cable_reel": "Power",
	"power_source": "Power",
	"power_cable": "Power",
	"power_socket": "Power",
	"fuse_box": "Power",
	"power_switcher": "Power",
	"light": "Power",
	"light_switcher": "Power",
	"radiator": "Cooling system",
	"external_water_pipe": "Cooling system",
	"external_air_duct": "Cooling system",
	"metal_cooling_block": "Cooling system",
	"crate": "Movable",
	"barrel": "Movable",
	"wall": "Environments",
	"floor": "Environments",
	"platform": "Environments",
	"station": "Environments",
	"digital_item": "Item",
	"access_item": "Item",
	"physical_item": "Item",
	"module_item": "Item",
	"turret": "Traps",
	"enemy": "Robots",
	"bipob": "Robots",
	"terminal": "Control",
	"door": "Control",
	"firewall": "Control",
	"debris": "Other",
	"case": "Other"
}

const CONSTRUCTOR_PALETTE_PREFAB_ORDER: Array[String] = [
	"power_cable_reel",
	"power_source",
	"power_cable",
	"power_socket",
	"fuse_box",
	"power_switcher",
	"light",
	"light_switcher",
	"radiator",
	"external_water_pipe",
	"external_air_duct",
	"metal_cooling_block",
	"crate",
	"barrel",
	"wall",
	"floor",
	"platform",
	"station",
	"digital_item",
	"access_item",
	"physical_item",
	"module_item",
	"turret",
	"enemy",
	"bipob",
	"terminal",
	"door",
	"firewall",
	"debris",
	"case"
]

static func object_accepts_runtime_power_plug(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false

	var state: String = str(object_data.get("state", object_data.get("status", ""))).strip_edges().to_lower()
	if state in ["damaged", "broken", "destroyed", "disabled"]:
		return false
	if bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)):
		return false

	if bool(object_data.get("requires_external_power", false)):
		return true

	var power_mode: String = str(object_data.get("power_mode", object_data.get("power_type", ""))).strip_edges().to_lower()
	power_mode = power_mode.replace("-", "_").replace(" ", "_")
	if power_mode in ["external", "external_power"]:
		return true

	if bool(object_data.get("can_connect_cable", false)):
		return true

	var object_group: String = str(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower()
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var classifier: String = "%s|%s|%s|%s" % [
		object_group,
		object_type,
		str(object_data.get("archetype_id", "")),
		str(object_data.get("map_constructor_prefab_id", ""))
	]
	classifier = classifier.to_lower()

	if object_type in ["power_socket", "outlet"]:
		return true

	if object_group == "terminal" or object_type.contains("terminal"):
		return state == "unpowered" or not bool(object_data.get("is_powered", true))
	if object_group == "door" or object_type.contains("door") or object_type.contains("gate"):
		return state == "unpowered" or not bool(object_data.get("is_powered", true)) or power_mode in ["external", "external_power"]
	if classifier.contains("firewall"):
		return state == "unpowered" or not bool(object_data.get("is_powered", true))

	return false

const LEGACY_SOURCE_METADATA_FIELDS: Array[String] = ["legacy_prefab_id", "map_constructor_prefab_id", "legacy_object_type", "source_prefab_id"]

const PREFAB_ALIAS_DEFAULTS: Dictionary = {
	"case": {"visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"loot_case": {"visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"loot_crate": {"visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_locked": {"locked":true, "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_class1": {"locked":false, "loot_class":"class1", "case_loot_state":"unsearched", "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_class2": {"locked":false, "loot_class":"class2", "case_loot_state":"unsearched", "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_class3": {"locked":false, "loot_class":"class3", "case_loot_state":"unsearched", "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_not_empty": {"locked":false, "opened":true, "searched":true, "remaining_loot_count":1, "case_loot_state":"partially_looted", "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"case_empty": {"locked":false, "opened":true, "searched":true, "remaining_loot_count":0, "case_loot_state":"empty", "visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class"},
	"vagus": {"enemy_type":"vagus", "enemy_kind":"vagus"},
	"bug": {"enemy_type":"bug", "enemy_kind":"bug"},
	"light_switch": {"switcher_type":"light_switcher", "default_placement_surface":"wall", "placement_mode":"wall_mounted"},
	"circuit_breaker": {"switcher_type":"power_breaker", "default_placement_surface":"wall", "placement_mode":"wall_mounted", "is_on":true, "switch_state":"on", "state":"switch_on"},
	"power_switch": {"switcher_type":"power_breaker"},
	"fire_barrel": {"variant":"fire"},
	"explosive_barrel": {"variant":"fire"},
	"normal_crate": {"crate_type":"normal", "variant":"normal", "weight_class":"normal", "required_bipob_power_class":"scout"},
	"heavy_crate": {"crate_type":"heavy", "variant":"heavy", "weight_class":"heavy", "required_bipob_power_class":"engineer", "heavy_claw_movable":true, "heavy_claw_mode":"push", "magnetic":true, "material_tags":["metal"]},
	"steel_box": {"crate_type":"heavy", "variant":"heavy", "weight_class":"heavy", "required_bipob_power_class":"engineer", "heavy_claw_movable":true, "heavy_claw_mode":"push", "magnetic":true, "material_tags":["metal"]},
	"concrete_floor": {"object_group":"floor", "material":"concrete"},
	"steel_floor": {"object_group":"floor", "material":"steel"},
	"titan_floor": {"object_group":"floor", "material":"titan"},
	"titanium_floor": {"object_group":"floor", "material":"titan"},
	"grate_floor": {"object_group":"floor", "material":"steel"},
	"permission_floor": {"object_group":"floor", "visual_style":"permission"},
	"water_floor": {"object_group":"floor", "covering":"water"},
	"oil_floor": {"object_group":"floor", "covering":"oil"},
	"dirty_floor": {"object_group":"floor", "covering":"dirt"},
	"debris_floor": {"object_group":"floor", "covering":"debris"},
	"breachable_wall": {"object_group":"wall", "is_breachable_wall":true, "wall_archetype":"breachable", "material":"breachable_concrete", "breach_side":"sw", "breach_state":"intact", "supports_embedded_objects":false, "supports_cables":false},
	"external_air_cooler": {"object_group":"cooling"},
	"air_cooling": {"object_group":"cooling"},
	"air_cooler": {"object_group":"cooling"},
	"cooling_fan": {"object_group":"cooling"},
	"digital_key": {"digital_item_type":"digital_key", "item_class":"digital_key", "item_type":"digital_key"},
	"access_code": {"digital_item_type":"access_code", "item_class":"access_code", "item_type":"access_code"},
	"data_file": {"digital_item_type":"data_file", "item_class":"data_file", "item_type":"data_file"},
	"key_card": {"access_item_type":"key_card", "item_class":"key_card", "item_type":"key_card"},
	"mechanical_key": {"access_item_type":"key_card", "item_class":"key_card", "item_type":"key_card"},
	"mechanical_keycard": {"access_item_type":"key_card", "item_class":"key_card", "item_type":"key_card"},
	"keycard": {"access_item_type":"key_card", "item_class":"key_card", "item_type":"key_card"},
	"fuse": {"physical_item_type":"fuse", "item_type":"fuse", "visual_asset_id":"fuse_floor_01"},
	"reinforcement": {"physical_item_type":"reinforcement", "item_type":"reinforcement", "visual_asset_id":"reinforcement_floor_01"},
	"repair_kit": {"physical_item_type":"repair_kit", "item_type":"repair_kit", "visual_asset_id":"repair_kit_floor_01"},
	"parts": {"physical_item_type":"parts", "item_type":"parts", "visual_asset_id":"parts_floor_01", "amount":1},
	"parts_small": {"physical_item_type":"parts", "item_type":"parts", "visual_asset_id":"parts_floor_01", "amount":5},
	"parts_medium": {"physical_item_type":"parts", "item_type":"parts", "visual_asset_id":"parts_floor_01", "amount":10},
	"parts_large": {"physical_item_type":"parts", "item_type":"parts", "visual_asset_id":"parts_floor_01", "amount":20},
	"module_internal": {"module_item_type":"module_internal", "item_type":"module_internal"},
	"module_external": {"module_item_type":"module_external", "item_type":"module_external"},
	"enemy_robot": {"enemy_type":"vagus", "enemy_kind":"vagus"}
}

# Hidden compatibility mappings for loading old constructor/runtime data only.
# These aliases must never be emitted as user-facing palette entries or presets.
const LEGACY_ITEM_ALIAS_CONFIGS: Dictionary = {
	"mechanical_key": {"object_type":"item", "item_class":ITEM_CLASS_KEY_CARD},
	"mechanical_keycard": {"object_type":"item", "item_class":ITEM_CLASS_KEY_CARD},
	"keycard": {"object_type":"item", "item_class":ITEM_CLASS_KEY_CARD},
	"key_card": {"object_type":"item", "item_class":ITEM_CLASS_KEY_CARD},
	"digital_key": {"object_type":"item", "item_class":ITEM_CLASS_DIGITAL_KEY},
	"access_code": {"object_type":"item", "item_class":ITEM_CLASS_ACCESS_CODE},
	"data_file": {"object_type":"item", "item_class":ITEM_CLASS_DATA_FILE}
}

const LEGACY_DOOR_ALIAS_CONFIGS: Dictionary = {
	"steel_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"reinforced_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_TERMINAL, "power_behavior":POWER_BEHAVIOR_NONE},
	"titanium_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_ACCESS_CODE, "power_behavior":POWER_BEHAVIOR_NONE},
	"energy_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"grid_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"powered_gate": {"object_type":"door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"mechanical_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_reinforced_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_titanium_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_energy_door": {"object_type":"door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_reinforced_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_titanium_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_energy_door": {"object_type":"door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"powered_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_reinforced_steel_door": {"object_type":"door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_titanium_door": {"object_type":"door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_energy_door": {"object_type":"door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"}
}

const WALL_MATERIAL_BRICK := "brick"
const WALL_MATERIAL_CONCRETE := "concrete"
const WALL_MATERIAL_STEEL := "steel"
const WALL_MATERIAL_REINFORCED_STEEL := "reinforced_steel"
const WALL_MATERIAL_TITANIUM := "titanium"
const WALL_MATERIAL_GRATE := "grate"
const WALL_MATERIAL_ELECTROMAGNETIC := "electromagnetic"
const WALL_MATERIAL_BREACHABLE_CONCRETE := "breachable_concrete"
const WALL_MATERIAL_BREACHABLE_BRICK := "breachable_brick"
const WALL_MATERIALS: Array[String] = [WALL_MATERIAL_BRICK, WALL_MATERIAL_CONCRETE, WALL_MATERIAL_STEEL, WALL_MATERIAL_REINFORCED_STEEL, WALL_MATERIAL_TITANIUM, WALL_MATERIAL_GRATE, WALL_MATERIAL_ELECTROMAGNETIC, WALL_MATERIAL_BREACHABLE_CONCRETE, WALL_MATERIAL_BREACHABLE_BRICK]
const BREACHABLE_WALL_MATERIALS: Array[String] = [WALL_MATERIAL_BREACHABLE_CONCRETE, WALL_MATERIAL_BREACHABLE_BRICK]
const BREACHABLE_WALL_HEIGHTS: Array[String] = ["mid", "halfmid", "tall"]
const WALL_SIDES: Array[String] = ["north", "east", "south", "west"]
const WALL_DISPLAY_NAMES: Dictionary = {
	WALL_MATERIAL_BRICK: "Brick Wall",
	WALL_MATERIAL_CONCRETE: "Concrete Wall",
	WALL_MATERIAL_STEEL: "Steel Wall",
	WALL_MATERIAL_REINFORCED_STEEL: "Reinforced Steel Wall",
	WALL_MATERIAL_TITANIUM: "Titanium Wall",
	WALL_MATERIAL_GRATE: "Grate Wall",
	WALL_MATERIAL_ELECTROMAGNETIC: "Electromagnetic Wall",
	WALL_MATERIAL_BREACHABLE_CONCRETE: "Breachable Concrete Wall",
	WALL_MATERIAL_BREACHABLE_BRICK: "Breachable Brick Wall"
}

# Hidden compatibility mappings for historic wall ids. Constructor palettes must
# expose only one configurable wall row; old ids normalize while loading legacy data.
const LEGACY_WALL_ALIAS_CONFIGS: Dictionary = {
	"outer_wall": {"object_type":"external_wall"},
	"breachable_wall": {"object_type":"wall", "material":WALL_MATERIAL_BREACHABLE_CONCRETE, "is_breachable_wall":true, "heavy_claw_breachable":true, "supports_embedded_objects":false, "supports_cables":false, "wall_height":"mid", "breach_side":"sw"},
	"brick_wall": {"object_type":"wall", "material":WALL_MATERIAL_BRICK},
	"concrete_wall": {"object_type":"wall", "material":WALL_MATERIAL_CONCRETE},
	"steel_wall": {"object_type":"wall", "material":WALL_MATERIAL_STEEL},
	"reinforced_steel_wall": {"object_type":"wall", "material":WALL_MATERIAL_REINFORCED_STEEL},
	"titanium_wall": {"object_type":"wall", "material":WALL_MATERIAL_TITANIUM},
	"grate_wall": {"object_type":"wall", "material":WALL_MATERIAL_GRATE},
	"electromagnetic_wall": {"object_type":"wall", "material":WALL_MATERIAL_ELECTROMAGNETIC},
	"energy_wall": {"object_type":"wall", "material":WALL_MATERIAL_ELECTROMAGNETIC},
	"damaged_wall": {"object_type":"wall", "material":WALL_MATERIAL_CONCRETE, "damaged":true}
}

const LEGACY_PLATFORM_ALIAS_CONFIGS: Dictionary = {
	"movable_platform_block": {"object_type":"platform", "platform_mode":"elevator", "platform_level":0, "max_level":1, "control_type":"internal", "power_type":"none"}
}

const TERMINAL_TYPES: Array[String] = ["information", "control"]
const TERMINAL_CONTROLLED_TARGET_TYPES: Array[String] = ["none", "door", "cooling", "platform", "power", "lighting", "device"]
const TERMINAL_CLASSES: Array[int] = [1, 2, 3]
const TERMINAL_POWER_TYPES: Array[String] = ["internal", "external"]
const TERMINAL_CONTROL_TYPES: Array[String] = ["internal", "external"]
const TERMINAL_STATUSES: Array[String] = ["active", "damaged", "unpowered", "locked", "disabled", "error"]

const BIPOB_TYPES: Array[String] = ["scout", "engineer", "heavy"]
const BIPOB_STATUSES: Array[String] = ["active", "disabled", "broken", "infected"]
const BIPOB_ALIGNMENTS: Array[String] = ["friendly", "hostile"]
const BIPOB_CHASSIS_TYPES: Array[String] = ["wheels", "legs", "tracks", "hover"]
const BIPOB_VISOR_TYPES: Array[String] = ["basic", "radar", "thermal", "xray"]
const BIPOB_LOADOUT_PROFILES: Array[String] = ["none", "light", "utility", "heavy"]

# Hidden compatibility mappings for historic Map Constructor Bipob prefab ids.
# Constructor palettes must expose only the canonical configurable `bipob` archetype.
const LEGACY_BIPOB_ALIAS_CONFIGS: Dictionary = {
	"disabled_bipop_scout": {"object_type":"bipob", "bipob_type":"scout", "bipob_status":"disabled", "bipob_alignment":"friendly", "weight_class":"normal", "required_bipob_power_class":"scout"},
	"disabled_bipop_engineer": {"object_type":"bipob", "bipob_type":"engineer", "bipob_status":"disabled", "bipob_alignment":"friendly", "weight_class":"heavy", "required_bipob_power_class":"engineer"},
	"disabled_bipop_juggernaut": {"object_type":"bipob", "bipob_type":"heavy", "bipob_status":"disabled", "bipob_alignment":"friendly", "weight_class":"heavy", "required_bipob_power_class":"heavy"},
	"disabled_bipob_scout": {"object_type":"bipob", "bipob_type":"scout", "bipob_status":"disabled", "bipob_alignment":"friendly"},
	"disabled_bipob_engineer": {"object_type":"bipob", "bipob_type":"engineer", "bipob_status":"disabled", "bipob_alignment":"friendly"},
	"disabled_bipob_heavy": {"object_type":"bipob", "bipob_type":"heavy", "bipob_status":"disabled", "bipob_alignment":"friendly"},
	"bipob_scout": {"object_type":"bipob", "bipob_type":"scout"},
	"bipob_engineer": {"object_type":"bipob", "bipob_type":"engineer"},
	"bipob_heavy": {"object_type":"bipob", "bipob_type":"heavy"},
	"bipob_disabled": {"object_type":"bipob", "bipob_status":"disabled", "bipob_alignment":"friendly"},
	"bipob_found": {"object_type":"bipob", "bipob_status":"disabled", "bipob_alignment":"friendly"},
	"bipob_broken": {"object_type":"bipob", "bipob_status":"broken", "bipob_alignment":"friendly"},
	"broken_bipob": {"object_type":"bipob", "bipob_status":"broken", "bipob_alignment":"friendly"},
	"bipob_infected": {"object_type":"bipob", "bipob_status":"infected", "bipob_alignment":"hostile"},
	"infected_bipob": {"object_type":"bipob", "bipob_status":"infected", "bipob_alignment":"hostile"},
	"corrupted_bipob": {"object_type":"bipob", "bipob_status":"infected", "bipob_alignment":"hostile"},
	"bipob_corrupted": {"object_type":"bipob", "bipob_status":"infected", "bipob_alignment":"hostile"},
	"hostile_bipob": {"object_type":"bipob", "bipob_alignment":"hostile"},
	"bipob_hostile": {"object_type":"bipob", "bipob_alignment":"hostile"},
	"enemy_robot": {"object_type":"bipob", "bipob_type":"scout", "bipob_status":"infected", "bipob_alignment":"hostile"}
}

const FACING_SIDE_SW := "SW"
const FACING_SIDE_SE := "SE"
const FACING_SIDES: Array[String] = [FACING_SIDE_SW, FACING_SIDE_SE]
const FACING_SIDE_SCHEMA: Dictionary = {"field":"facing_side", "type":"enum", "values":["SW", "SE"], "default":"SW", "labels":{"SW":"SW", "SE":"SE"}, "label":"Facing Side"}

const COOLING_SYSTEM_WALL_ROUTING_PROPERTY_SCHEMA: Array[Dictionary] = [
	{"field":"route_mode","type":"enum","values":["inner","outer"],"default":"inner","labels":{"inner":"Inner","outer":"Outer"},"tab":"Cooling System"},
	{"field":"cooling_contour_mode","type":"enum","values":["auto","manual"],"default":"auto","labels":{"auto":"Auto contour","manual":"Manual contour"},"tab":"Cooling System"},
	{"field":"cooling_contour_id","type":"string","default":"","internal":true,"legacy":true,"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},
	{"field":"cooling_contour_member_ids","type":"object_ref_array","target_group":"cooling","default":[],"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},
	{"field":"wall_side_1","type":"enum","values":["NE","NW","SE","SW"],"default":"NW","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}},
	{"field":"wall_side_2","type":"enum","values":["NE","NW","SE","SW"],"default":"SE","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}}
]

# Hidden compatibility mappings for historic terminal ids. Constructor palettes,
# searches, kits, and templates must expose only the configurable terminal archetype.
const LEGACY_TERMINAL_ALIAS_CONFIGS: Dictionary = {
	"information_terminal": {"terminal_type":"information", "controlled_target_type":"none"},
	"control_terminal": {"terminal_type":"control", "controlled_target_type":"none"},
	"door_terminal": {"terminal_type":"control", "controlled_target_type":"door"},
	"door_control_terminal": {"terminal_type":"control", "controlled_target_type":"door"},
	"cooling_terminal": {"terminal_type":"control", "controlled_target_type":"cooling"},
	"platform_terminal": {"terminal_type":"control", "controlled_target_type":"platform"},
	"power_terminal": {"terminal_type":"control", "controlled_target_type":"power"},
	"terminal_class_1": {"terminal_class":1},
	"terminal_class_2": {"terminal_class":2},
	"terminal_class_3": {"terminal_class":3},
	"elevator_terminal": {"terminal_type":"control", "controlled_target_type":"platform"},
	"turret_terminal": {"terminal_type":"control", "controlled_target_type":"device"}
}

const UTILITY_ITEM_ARCHETYPE_IDS: Array[String] = ["fuse", "repair_kit", "reinforcement", "module_external", "module_internal"]

const DOOR_MATERIAL_BY_OBJECT_TYPE: Dictionary = {
	"steel_door": DOOR_MATERIAL_STEEL,
	"reinforced_steel_door": DOOR_MATERIAL_REINFORCED_STEEL,
	"titanium_door": DOOR_MATERIAL_TITANIUM,
	"energy_door": DOOR_MATERIAL_ENERGY,
	"grid_door": DOOR_MATERIAL_STEEL
}

# Global authoring contract. Add the next migrations here (terminal, platform,
# power_source, item, wall, cooling_device, data_device) without adding palette variants.
const ARCHETYPE_REGISTRY: Dictionary = {

	"external_air_duct": {
		"archetype_id":"external_air_duct", "object_group":"cooling", "group":"cooling", "constructor_group":"cooling_system", "constructor_category":"Cooling System", "constructor_tab":"cooling_system", "object_type":"external_air_duct", "palette_label":"External Air Duct",
		"display_name_template":"External Air Duct", "name":"External Air Duct", "state":"active", "cooling_device_type":"air_duct", "carries_airflow":true, "passive_cooling":true, "generic_airflow_role":"airflow_path_cell", "airflow_roles":["airflow_path_cell"], "blocks_airflow":false,
		"movable":false, "material":"metal", "blocks_movement":false, "blocks_vision":false, "durability":12, "placement_mode":"wall_mounted", "placement_surfaces":["wall"], "default_placement_surface":"wall", "requires_floor_anchor_when_wall_mounted":true, "mount":"wall", "install_mode":"wall", "is_wall_mounted":true, "changes_passability":false, "configurable":true,
		"route_mode":"inner", "wall_routing_mode":"inner", "routing_kind":"air_duct", "cooling_system_type":"air_duct", "cooling_contour_id":"", "cooling_contour_mode":"auto", "cooling_contour_member_ids":[], "cooling_system_tab":true, "routing_label":"Air Duct", "wall_side_1":"NW", "wall_side_2":"SE",
		"visual_family":"wall_routing_utility", "visual_surface":"wall", "wall_routing_visual_enabled":true, "property_schema":COOLING_SYSTEM_WALL_ROUTING_PROPERTY_SCHEMA
	},
	"external_water_pipe": {
		"archetype_id":"external_water_pipe", "object_group":"cooling", "group":"cooling", "constructor_group":"cooling_system", "constructor_category":"Cooling System", "constructor_tab":"cooling_system", "object_type":"external_water_pipe", "palette_label":"External Water Pipe",
		"display_name_template":"External Water Pipe", "name":"External Water Pipe", "state":"active", "cooling_device_type":"water_pipe", "cooling_output":2, "passive_cooling":true,
		"movable":false, "material":"metal", "blocks_movement":false, "blocks_vision":false, "durability":15, "placement_mode":"wall_mounted", "placement_surfaces":["wall"], "default_placement_surface":"wall", "requires_floor_anchor_when_wall_mounted":true, "mount":"wall", "install_mode":"wall", "is_wall_mounted":true, "changes_passability":false, "configurable":true,
		"route_mode":"inner", "wall_routing_mode":"inner", "routing_kind":"water_pipe", "cooling_system_type":"water_pipe", "cooling_contour_id":"", "cooling_contour_mode":"auto", "cooling_contour_member_ids":[], "cooling_system_tab":true, "routing_label":"Water Pipe", "wall_side_1":"NW", "wall_side_2":"SE",
		"visual_family":"wall_routing_utility", "visual_surface":"wall", "wall_routing_visual_enabled":true, "property_schema":COOLING_SYSTEM_WALL_ROUTING_PROPERTY_SCHEMA
	},
	"external_wall": {
		"archetype_id":"external_wall", "object_group":"wall", "object_type":"external_wall", "palette_label":"External Wall", "show_in_palette":false,
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"External Wall", "material":"external_structural", "is_destructible":false, "supports_embedded_objects":true, "supports_cables":true, "configurable":false, "blocks_movement":true, "blocks_vision":true,
		"property_schema":[]
	},
	"wall": {
		"archetype_id":"wall", "object_group":"wall", "object_type":"wall", "palette_label":"Wall",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{material_label} Wall", "is_destructible":true, "supports_embedded_objects":true, "supports_cables":true, "configurable":true, "blocks_movement":true, "blocks_vision":true,
		"property_schema":[
			{"field":"material", "type":"enum", "values":["brick", "concrete", "steel", "reinforced_steel", "titanium", "grate", "electromagnetic", "breachable_concrete", "breachable_brick"], "default":"brick", "labels":{"brick":"Brick", "concrete":"Concrete", "steel":"Steel", "reinforced_steel":"Reinforced Steel", "titanium":"Titanium", "grate":"Grate", "electromagnetic":"Electromagnetic", "breachable_concrete":"Breachable Concrete", "breachable_brick":"Breachable Brick"}},
			{"field":"is_breachable_wall", "type":"bool", "default":false},
			{"field":"wall_height", "type":"enum", "values":["mid", "halfmid", "tall"], "default":"mid", "labels":{"mid":"Mid", "halfmid":"Half Mid", "tall":"Tall"}},
			{"field":"breach_side", "type":"enum", "values":["sw", "se", "nw", "ne"], "default":"sw", "labels":{"sw":"SW", "se":"SE", "nw":"NW", "ne":"NE"}}
		]
	},
	"door": {
		"archetype_id":"door", "object_group":"door", "object_type":"door", "palette_label":"Door", "placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "facing_side":"SW",
		"visual_family":"door", "visual_surface":"floor", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"configurable":true,
		"display_name_template":"{material_label} {door_type_label} Door",
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"door_type", "type":"enum", "values":["mechanical", "digital", "powered"], "default":"mechanical"},
			{"field":"material", "type":"enum", "values":["steel", "reinforced_steel", "titanium", "energy"], "default":"steel"},
			{"field":"access_type", "type":"enum", "values":["no_key", "key_card", "digital_key", "access_code", "terminal"], "default":"key_card"},
			{"field":"door_class", "type":"enum", "values":[1, 2, 3], "default":1},
			{"field":"power_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal"},
			{"field":"control_type", "type":"enum", "values":["internal", "external"], "default":"internal", "labels":{"internal":"Internal", "external":"External"}},
			{"field":"power_behavior", "type":"enum", "values":["none", "opens_when_unpowered", "requires_power_to_open"], "default":"none"},
			{"field":"state", "type":"enum", "values":["closed", "open", "damaged", "jammed", "locked", "unpowered"], "default":"closed"},
			{"field":"allowed_states", "type":"enum_array", "values":["closed", "open", "damaged", "jammed", "locked", "unpowered"], "default":["closed", "open", "damaged", "jammed", "locked", "unpowered"]},
			{"field":"required_key_id", "type":"string", "default":""},
			{"field":"required_terminal_id", "type":"string", "default":""},
			{"field":"required_access_code_id", "type":"string", "default":""},
			{"field":"required_digital_key_id", "type":"string", "default":""},
			{"field":"required_manipulator_level", "type":"int", "default":0},
			{"field":"has_connector_jack", "type":"bool", "default":false},
			{"field":"required_connector_level", "type":"int", "default":0},
			{"field":"required_processor_level", "type":"int", "default":0}
		]
	},
	"platform": {
		"archetype_id":"platform", "object_group":"platform", "object_type":"platform", "palette_label":"Platform",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Platform", "configurable":true, "blocks_movement":false, "blocks_vision":false, "walkable":true,
		"property_schema":[
			{"field":"platform_mode", "type":"enum", "values":["elevator", "rotator", "elevator_rotator"], "default":"elevator", "labels":{"elevator":"Elevator", "rotator":"Rotator", "elevator_rotator":"Elevator + Rotator"}},
			{"field":"platform_level", "type":"int", "default":0},
			{"field":"max_level", "type":"int", "default":1},
			{"field":"mechanism_id", "type":"string", "default":""},
			{"field":"mechanism_role", "type":"enum", "values":["single"], "default":"single"},
			{"field":"control_type", "type":"enum", "values":["internal", "external"], "default":"internal"},
			{"field":"power_type", "type":"enum", "values":["none", "internal", "external"], "default":"none"},
			{"field":"activation_mode", "type":"enum", "values":["instant", "delayed"], "default":"instant"},
			{"field":"activation_delay_turns", "type":"int", "default":0},
			{"field":"control_cell_x", "type":"int", "default":0},
			{"field":"control_cell_y", "type":"int", "default":0}
		]
	},
	"terminal": {
		"archetype_id":"terminal", "object_group":"terminal", "object_type":"terminal", "palette_label":"Terminal", "placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "facing_side":"SW",
		"visual_family":"terminal", "visual_surface":"floor", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"configurable":true,
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"terminal_type", "type":"enum", "values":["information", "control"], "default":"information", "labels":{"information":"Information", "control":"Control"}},
			{"field":"controlled_target_type", "type":"enum", "values":["none", "door", "cooling", "platform", "power", "lighting", "device"], "default":"none", "labels":{"none":"None", "door":"Door", "cooling":"Cooling", "platform":"Platform", "power":"Power", "lighting":"Lighting", "device":"Device"}},
			{"field":"terminal_class", "type":"enum", "values":[1, 2, 3], "default":1, "labels":{"1":"Class 1", "2":"Class 2", "3":"Class 3"}},
			{"field":"has_connector_jack", "type":"bool", "default":true},
			{"field":"power_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal", "labels":{"internal":"Internal", "external":"External", "none":"None"}},
			{"field":"control_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal", "labels":{"internal":"Internal", "external":"External", "none":"None"}},
			{"field":"test_override_enabled", "type":"bool", "default":false},
			{"field":"status", "type":"enum", "values":["active", "damaged", "unpowered", "locked", "disabled", "error"], "default":"active", "labels":{"active":"Active", "damaged":"Damaged", "unpowered":"Unpowered", "locked":"Locked", "disabled":"Disabled", "error":"Error"}},
			{"field":"allowed_statuses", "type":"enum_array", "values":["active", "damaged", "unpowered", "locked", "disabled", "error"], "default":["active", "damaged", "unpowered"]},
			{"field":"linked_object_ids", "type":"object_ref_array", "default":[]},
			{"field":"linked_door_ids", "type":"object_ref_array", "target_group":"door", "default":[]},
			{"field":"linked_cooling_ids", "type":"object_ref_array", "target_group":"cooling", "default":[]},
			{"field":"linked_platform_ids", "type":"object_ref_array", "target_group":"platform", "default":[]},
			{"field":"linked_power_ids", "type":"object_ref_array", "target_group":"power", "default":[]},
			{"field":"linked_lighting_ids", "type":"object_ref_array", "target_group":"lighting", "default":[]},
			{"field":"chain_input_ids", "type":"object_ref_array", "default":[]},
			{"field":"chain_output_ids", "type":"object_ref_array", "default":[]}
		]
	},
	"bipob": {
		"archetype_id":"bipob", "object_group":"bipob", "group":"bipob", "constructor_group":"characters", "constructor_category":"Characters", "constructor_tab":"characters", "object_type":"bipob", "palette_label":"Bipob",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Bipob", "configurable":true, "blocks_movement":true, "blocks_vision":false, "visual_family":"bipob", "visual_surface":"floor", "state":"disabled",
		"bipob_type":"scout", "bipob_status":"disabled", "bipob_alignment":"friendly", "chassis_type":"wheels", "visor_type":"basic", "loadout_profile":"none",
		"property_schema":[
			{"field":"bipob_type", "type":"enum", "values":["scout", "engineer", "heavy"], "default":"scout", "labels":{"scout":"Scout", "engineer":"Engineer", "heavy":"Heavy"}, "tab":"Bipob"},
			{"field":"bipob_status", "type":"enum", "values":["active", "disabled", "broken", "infected"], "default":"disabled", "labels":{"active":"Active", "disabled":"Disabled", "broken":"Broken", "infected":"Infected"}, "tab":"Bipob"},
			{"field":"bipob_alignment", "type":"enum", "values":["friendly", "hostile"], "default":"friendly", "labels":{"friendly":"Friendly", "hostile":"Hostile"}, "tab":"Bipob"},
			{"field":"chassis_type", "type":"enum", "values":["wheels", "legs", "tracks", "hover"], "default":"wheels", "labels":{"wheels":"Wheels", "legs":"Legs", "tracks":"Tracks", "hover":"Hover"}, "tab":"Bipob"},
			{"field":"visor_type", "type":"enum", "values":["basic", "radar", "thermal", "xray"], "default":"basic", "labels":{"basic":"Basic", "radar":"Radar", "thermal":"Thermal", "xray":"X-Ray"}, "tab":"Bipob"},
			{"field":"loadout_profile", "type":"enum", "values":["none", "light", "utility", "heavy"], "default":"none", "labels":{"none":"None", "light":"Light", "utility":"Utility", "heavy":"Heavy"}, "tab":"Bipob"}
		]
	},

	"enemy": {
		"archetype_id":"enemy", "object_group":"enemy", "object_type":"enemy", "palette_label":"Enemies",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{enemy_type_label}", "configurable":true, "interactable":false,
		"blocks_movement":true, "blocks_vision":false, "enemy_type":"vagus", "enemy_kind":"vagus",
		"property_schema":[
			{"field":"enemy_type", "type":"enum", "values":["vagus", "bug"], "default":"vagus", "labels":{"vagus":"Vagus", "bug":"Bug"}}
		]
	},
	"station": {
		"archetype_id":"station", "object_group":"station", "object_type":"station", "palette_label":"Station",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{station_type_label} Station", "configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"station_type":"lab", "allowed_station_types":["decrypt", "lab", "recharge", "repair", "shop"],
		"visual_family":"station", "visual_surface":"floor", "visual_state_policy":"static", "visual_variant":"lab",
		"state":"active", "status":"active", "is_powered":true,
		"property_schema":[
			{
				"field":"station_type",
				"type":"enum",
				"values":["decrypt", "lab", "recharge", "repair", "shop"],
				"default":"lab",
				"labels":{
					"decrypt":"Decrypt",
					"lab":"Research Lab",
					"recharge":"Recharge",
					"repair":"Repair",
					"shop":"Shop"
				}
			}
		]
	},
	"firewall": {
		"archetype_id":"firewall", "object_group":"security", "object_type":"firewall", "palette_label":"Firewall",
		"display_name_template":"Firewall", "placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "facing_side":"SW", "configurable":true,
		"blocks_movement":false, "blocks_vision":false, "interactable":true,
		"visual_family":"firewall", "visual_surface":"floor", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true,
		"power_type":"external", "control_type":"internal", "status":"unpowered",
		"allowed_statuses":["active", "unpowered", "locked", "disabled", "damaged", "error"],
		"firewall_class":1, "security_level":1, "requires_terminal":true, "linked_terminal_ids":[], "linked_object_ids":[],
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"firewall_class", "type":"enum", "values":[1, 2, 3], "default":1, "labels":{"1":"Class 1", "2":"Class 2", "3":"Class 3"}},
			{"field":"security_level", "type":"enum", "values":[1, 2, 3], "default":1, "labels":{"1":"Level 1", "2":"Level 2", "3":"Level 3"}},
			{"field":"power_type", "type":"enum", "values":["internal", "external", "none"], "default":"external", "labels":{"internal":"Internal", "external":"External", "none":"None"}},
			{"field":"control_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal", "labels":{"internal":"Internal", "external":"External", "none":"None"}},
			{"field":"status", "type":"enum", "values":["active", "unpowered", "locked", "disabled", "damaged", "error"], "default":"unpowered", "labels":{"active":"Active", "unpowered":"Unpowered", "locked":"Locked", "disabled":"Disabled", "damaged":"Damaged", "error":"Error"}},
			{"field":"allowed_statuses", "type":"enum_array", "values":["active", "unpowered", "locked", "disabled", "damaged", "error"], "default":["active", "unpowered", "locked", "disabled", "damaged", "error"]},
			{"field":"linked_terminal_ids", "type":"object_ref_array", "target_group":"terminal", "default":[]},
			{"field":"linked_object_ids", "type":"object_ref_array", "default":[]}
		]
	},
	"item": {
		"archetype_id":"item", "object_group":"item", "object_type":"item", "palette_label":"Digital Items", "show_in_palette":false,
		"placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{digital_item_type_label}",
		"configurable":true, "can_pickup":true, "interactable":true, "item_category":"digital", "item_form":"digital", "storage_route":"digital_storage", "storage_type":"digital_storage", "digital_item_type":"data_file", "item_class":"data_file", "item_type":"data_file", "state":"available", "allowed_states":["available", "collected", "disabled"],
		"property_schema":[
			{"field":"digital_item_type", "type":"enum", "values":["digital_key", "access_code", "data_file"], "default":"data_file", "labels":{"digital_key":"Digital Key", "access_code":"Access Code", "data_file":"Data File"}},
			{"field":"state", "type":"enum", "values":["available", "collected", "disabled"], "default":"available"},
			{"field":"linked_door_id", "type":"object_ref", "target_group":"door", "default":""},
			{"field":"payload_id", "type":"string", "default":""},
			{"field":"access_code", "type":"string", "default":""}
		]
	},
	"digital_item": {
		"archetype_id":"digital_item", "object_group":"item", "object_type":"item", "palette_label":"Digital Items",
		"placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{digital_item_type_label}",
		"configurable":true, "can_pickup":true, "interactable":true, "item_category":"digital", "item_form":"digital", "storage_route":"digital_storage", "storage_type":"digital_storage", "digital_item_type":"data_file", "item_class":"data_file", "item_type":"data_file", "state":"available", "allowed_states":["available", "collected", "disabled"],
		"property_schema":[
			{"field":"digital_item_type", "type":"enum", "values":["digital_key", "access_code", "data_file"], "default":"data_file", "labels":{"digital_key":"Digital Key", "access_code":"Access Code", "data_file":"Data File"}},
			{"field":"state", "type":"enum", "values":["available", "collected", "disabled"], "default":"available"},
			{"field":"linked_door_id", "type":"object_ref", "target_group":"door", "default":""},
			{"field":"payload_id", "type":"string", "default":""},
			{"field":"access_code", "type":"string", "default":""}
		]
	},
	"access_item": {
		"archetype_id":"access_item", "object_group":"item", "object_type":"item", "palette_label":"Access Items", "placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{access_item_type_label}", "configurable":true, "can_pickup":true, "interactable":true, "item_category":"access", "item_form":"physical", "storage_route":"keychain", "storage_type":"keychain", "access_item_type":"key_card", "item_class":"key_card", "item_type":"key_card", "key_kind":"key_card", "key_type":"key_card", "state":"available", "allowed_states":["available", "collected", "disabled"],
		"property_schema":[{"field":"access_item_type", "type":"enum", "values":["key_card"], "default":"key_card", "labels":{"key_card":"Key Card"}}, {"field":"state", "type":"enum", "values":["available", "collected", "disabled"], "default":"available"}, {"field":"linked_door_id", "type":"object_ref", "target_group":"door", "default":""}]
	},
	"physical_item": {
		"archetype_id":"physical_item", "object_group":"item", "object_type":"item", "palette_label":"Physical Items", "placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{physical_item_type_label}", "configurable":true, "can_pickup":true, "interactable":true, "item_category":"physical", "item_form":"physical", "storage_route":"pocket", "storage_type":"pocket", "physical_item_type":"parts", "item_class":"physical_item", "item_type":"parts", "visual_asset_id":"parts_floor_01", "visual_family":"parts", "visual_surface":"floor", "state":"available", "allowed_states":["available", "collected", "disabled"],
		"property_schema":[{"field":"physical_item_type", "type":"enum", "values":["fuse", "reinforcement", "repair_kit", "parts"], "default":"parts", "labels":{"fuse":"Fuse", "reinforcement":"Reinforcement Kit", "repair_kit":"Repair Kit", "parts":"Parts"}}, {"field":"state", "type":"enum", "values":["available", "collected", "disabled"], "default":"available"}, {"field":"amount", "type":"int", "default":1, "min":1}]
	},
	"module_item": {
		"archetype_id":"module_item", "object_group":"item", "object_type":"item", "palette_label":"Module Items", "placement_mode":"item", "display_name_template":"{module_item_type_label}", "configurable":true, "can_pickup":true, "interactable":true, "item_category":"module", "item_form":"physical", "storage_route":"pocket", "storage_type":"pocket", "module_item_type":"module_internal", "item_class":"physical_item", "item_type":"module_internal", "state":"available", "allowed_states":["available", "collected", "disabled"],
		"property_schema":[{"field":"module_item_type", "type":"enum", "values":["module_internal", "module_external"], "default":"module_internal", "labels":{"module_internal":"Internal Module", "module_external":"External Module"}}, {"field":"state", "type":"enum", "values":["available", "collected", "disabled"], "default":"available"}]
	},
	"power_switcher": {
		"archetype_id":"power_switcher", "object_group":"power", "object_type":"power_switcher", "palette_label":"Power Switcher", "facing_side":"SW",
		"placement_mode":"object", "placement_surfaces":["floor", "wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true, "display_name_template":"Power Switcher", "configurable":true, "state":"switch_off", "switch_state":"off", "is_on":false, "can_be_switched":true, "switcher_type":"power_breaker", "power_mode":"external_power", "control_mode":"internal_control", "is_powered":false, "visual_family":"power_switcher", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true, "mount":"floor", "blocks_movement":false, "blocks_vision":false, "light_group_id":"", "target_light_ids":[], "linked_light_ids":[], "switcher_lines":[], "active_line_id":"",
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"mount", "type":"enum", "values":["floor", "wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"switcher_type", "type":"enum", "values":["light_switcher", "power_breaker", "power_switcher"], "default":"power_breaker", "labels":{"light_switcher":"Light switcher", "power_breaker":"Power breaker", "power_switcher":"Power switcher"}},
			{"field":"switch_state", "type":"enum", "values":["off", "on"], "default":"off", "labels":{"off":"Off", "on":"On"}},
			{"field":"light_group_id", "type":"string", "default":""},
			{"field":"target_light_ids", "type":"object_ref_array", "target_group":"lighting", "default":[]},
			{"field":"active_line_id", "type":"string", "default":""},
			{"field":"line_1_label", "type":"string", "default":"Line A"},
			{"field":"line_1_direction", "type":"enum", "values":["", "NORTH", "EAST", "SOUTH", "WEST"], "default":""},
			{"field":"line_1_color_id", "type":"enum", "values":["red", "blue", "green", "yellow", "orange", "purple", "white"], "default":"red"},
			{"field":"line_1_circuit_id", "type":"string", "default":""},
			{"field":"line_2_label", "type":"string", "default":"Line B"},
			{"field":"line_2_direction", "type":"enum", "values":["", "NORTH", "EAST", "SOUTH", "WEST"], "default":""},
			{"field":"line_2_color_id", "type":"enum", "values":["red", "blue", "green", "yellow", "orange", "purple", "white"], "default":"blue"},
			{"field":"line_2_circuit_id", "type":"string", "default":""},
			{"field":"line_3_label", "type":"string", "default":"Line C"},
			{"field":"line_3_direction", "type":"enum", "values":["", "NORTH", "EAST", "SOUTH", "WEST"], "default":""},
			{"field":"line_3_color_id", "type":"enum", "values":["red", "blue", "green", "yellow", "orange", "purple", "white"], "default":"green"},
			{"field":"line_3_circuit_id", "type":"string", "default":""}
		]
	},
	"light_switcher": {
		"archetype_id":"light_switcher", "object_group":"power", "object_type":"light_switcher", "palette_label":"Light Switcher", "facing_side":"SW",
		"placement_mode":"wall_mounted", "placement_surfaces":["wall"], "default_placement_surface":"wall", "requires_floor_anchor_when_wall_mounted":true, "display_name_template":"Light Switcher", "configurable":true, "state":"switch_off", "switch_state":"off", "is_on":false, "can_be_switched":true, "switcher_type":"light_switcher", "switcher_base_type":"power_switcher", "mount":"wall", "power_mode":"external_power", "control_mode":"internal_control", "is_powered":false, "blocks_movement":false, "blocks_vision":false, "visual_family":"light_switcher", "visual_surface":"wall", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true, "light_group_id":"", "target_light_ids":[], "linked_light_ids":[],
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"switch_state", "type":"enum", "values":["off", "on"], "default":"off", "labels":{"off":"Off", "on":"On"}},
			{"field":"light_group_id", "type":"string", "default":""},
			{"field":"target_light_ids", "type":"object_ref_array", "target_group":"lighting", "default":[]}
		]
	},
	"fuse_box": {
		"archetype_id":"fuse_box", "object_group":"power", "object_type":"fuse_box", "palette_label":"Fuse Box", "facing_side":"SW",
		"placement_mode":"object", "placement_surfaces":["floor", "wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true, "display_name_template":"Fuse Box", "configurable":true, "interactable":true, "state":"inactive", "requires_fuse":true, "has_fuse":false, "fuse_present":false, "fuse_installed":false, "mount":"floor", "power_mode":"external_power", "control_mode":"internal_control", "is_powered":false, "blocks_movement":false, "blocks_vision":false,
		"visual_family":"fuse_box", "visual_state_policy":"fuse_box_line_power_state", "variant_policy":"fuse_presence",
		"property_schema":[
			FACING_SIDE_SCHEMA,
			{"field":"mount", "type":"enum", "values":["floor", "wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"has_fuse", "type":"bool", "default":false}
		]
	},
	"barrel": {
		"archetype_id":"barrel", "object_group":"physical_object", "object_type":"barrel", "palette_label":"Barrel",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Barrel", "configurable":true, "weight_class":"normal", "required_bipob_power_class":"scout", "movable":true, "heavy_claw_movable":true, "heavy_claw_mode":"push", "blocks_movement":true,
		"property_schema":[
			{"field":"variant", "type":"enum", "values":["normal", "fire"], "default":"normal", "labels":{"normal":"Normal", "fire":"Fire"}}
		]
	},
	"crate": {
		"archetype_id":"crate", "object_group":"physical_object", "object_type":"crate", "palette_label":"Crate",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{crate_type_label} Crate", "configurable":true, "blocks_movement":true, "blocks_vision":false, "movable":true, "heavy_claw_movable":true, "heavy_claw_mode":"push", "crate_type":"normal", "variant":"normal", "weight_class":"normal", "required_bipob_power_class":"scout",
		"property_schema":[
			{"field":"crate_type", "type":"enum", "values":["normal", "heavy"], "default":"normal", "labels":{"normal":"Normal crate", "heavy":"Heavy crate"}}
		]
	},
	"steel_box": {
		"archetype_id":"steel_box", "object_group":"physical_object", "object_type":"steel_box", "palette_label":"Steel Box", "show_in_palette":false,
		"placement_mode":"object", "display_name_template":"Steel Box", "configurable":true, "weight_class":"heavy", "required_bipob_power_class":"engineer", "movable":true, "heavy_claw_movable":true, "heavy_claw_mode":"push", "blocks_movement":true, "magnetic":true, "material_tags":["metal"],
		"property_schema":[
			{"field":"movable", "type":"bool", "default":true},
			{"field":"heavy_claw_movable", "type":"bool", "default":true}
		]
	},
	"case": {
		"archetype_id":"case", "object_group":"container", "object_type":"case", "palette_label":"Case",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Case", "configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false,
		"locked":true, "loot_class":"class1", "opened":false, "searched":false, "remaining_loot_count":1,
		"visual_family":"case", "visual_surface":"floor", "visual_state_policy":"loot_case_state", "variant_policy":"loot_case_class",
		"property_schema":[
			{"field":"locked", "type":"enum", "values":[true, false], "default":true, "labels":{"true":"Locked", "false":"Unlocked"}},
			{"field":"loot_class", "type":"enum", "values":["class1", "class2", "class3"], "default":"class1", "labels":{"class1":"Class 1", "class2":"Class 2", "class3":"Class 3"}},
			{"field":"case_loot_state", "type":"enum", "values":["unsearched", "partially_looted", "empty"], "default":"unsearched", "labels":{"unsearched":"Unsearched", "partially_looted":"Opened, not empty", "empty":"Empty"}}
		]
	},
	"power_source": {
		"archetype_id":"power_source", "object_group":"power", "object_type":"power_source", "palette_label":"Power Source",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Power Source", "configurable":false, "state":"on", "is_powered":true, "power_mode":"internal", "control_mode":"internal", "visual_family":"power_source", "visual_surface":"floor", "visual_state_policy":"powered_three_state", "power_visual_state_enabled":true, "blocks_movement":true, "property_schema":[]
	},
	"radiator": {
		"archetype_id":"radiator", "object_group":"cooling", "object_type":"radiator", "palette_label":"Radiator",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Radiator", "configurable":false, "cooling_device_type":"radiator", "cooling_output":1, "movable":true, "heavy_claw_movable":true, "blocks_movement":true, "property_schema":[]
	},
	"light": {
		"archetype_id":"light", "object_group":"power", "object_type":"light", "palette_label":"Light",
		"placement_mode":"wall_mounted", "placement_surfaces":["wall"], "default_placement_surface":"wall", "requires_floor_anchor_when_wall_mounted":true, "display_name_template":"Light", "configurable":true, "state":"active", "is_powered":false, "is_on":true, "light_enabled":true, "light_group_id":"", "blocks_movement":false,
		"property_schema":[
			{"field":"light_group_id", "type":"string", "default":""},
			{"field":"light_enabled", "type":"bool", "default":true}
		]
	},
	"power_cable_reel": {
		"archetype_id":"power_cable_reel", "object_group":"power", "object_type":"power_cable_reel", "palette_label":"Cable Reel",
		"placement_mode":"object", "placement_surfaces":["floor", "wall"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":true, "display_name_template":"Cable Reel", "configurable":true, "interactable":true, "blocks_movement":false, "blocks_vision":false, "cable_install_mode":"floor", "install_mode":"floor", "mount":"floor",
		"cable_reel_state":"base", "connected_endpoint_count":0, "socket_connected_endpoint_count":0, "max_cable_endpoints":2,
		"visual_family":"cable_reel", "visual_surface":"floor", "visual_state_policy":"cable_reel_connection_state", "power_visual_state_enabled":false,
		"property_schema":[
			{"field":"mount", "type":"enum", "values":["floor", "wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}},
			{"field":"cable_reel_state", "type":"enum", "values":["base", "off", "on"], "default":"base", "labels":{"base":"Base", "off":"One socket endpoint", "on":"Socket-linked cable"}}
		]
	},
	"fuse": {
		"archetype_id":"fuse", "object_group":"item", "show_in_palette":false, "object_type":"fuse", "palette_label":"Fuse",
		"placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Fuse", "configurable":false, "visual_asset_id":"fuse_floor_01", "visual_family":"fuse", "visual_surface":"floor", "property_schema":[]
	},
	"repair_kit": {
		"archetype_id":"repair_kit", "object_group":"item", "show_in_palette":false, "object_type":"repair_kit", "palette_label":"Repair Kit",
		"placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Repair Kit", "configurable":false, "visual_asset_id":"repair_kit_floor_01", "visual_family":"repair_kit", "visual_surface":"floor", "property_schema":[]
	},
	"reinforcement": {
		"archetype_id":"reinforcement", "object_group":"item", "show_in_palette":false, "object_type":"reinforcement", "palette_label":"Reinforcement Kit",
		"placement_mode":"item", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"Reinforcement Kit", "configurable":false, "visual_asset_id":"reinforcement_floor_01", "visual_family":"reinforcement", "visual_surface":"floor", "property_schema":[]
	},
	"module_external": {
		"archetype_id":"module_external", "object_group":"item", "show_in_palette":false, "object_type":"module_external", "palette_label":"External Module",
		"placement_mode":"item", "display_name_template":"External Module", "configurable":false, "property_schema":[]
	},
	"module_internal": {
		"archetype_id":"module_internal", "object_group":"item", "show_in_palette":false, "object_type":"module_internal", "palette_label":"Internal Module",
		"placement_mode":"item", "display_name_template":"Internal Module", "configurable":false, "property_schema":[]
	},
	"floor": {
		"archetype_id":"floor", "object_group":"floor", "object_type":"floor", "palette_label":"Floor",
		"placement_mode":"object", "placement_surfaces":["floor"], "default_placement_surface":"floor", "requires_floor_anchor_when_wall_mounted":false, "display_name_template":"{material_label} Floor",
		"blocks_movement":false, "blocks_vision":false, "configurable":true, "replaces_tile_with":"floor",
		"property_schema":[
			{"field":"material", "type":"enum", "values":["concrete", "steel", "titan"], "default":"concrete", "labels":{"concrete":"Concrete", "steel":"Steel", "titan":"Titan"}},
			{"field":"covering", "type":"enum", "values":["default", "dirt", "water", "debris", "oil"], "default":"default", "labels":{"default":"Default", "dirt":"Dirt", "water":"Water", "debris":"Debris", "oil":"Oil"}},
			{"field":"visual_style", "type":"enum", "values":["default", "permission"], "default":"default", "labels":{"default":"Default", "permission":"Permission Tile"}},
			{"field":"state", "type":"enum", "values":["normal", "damaged"], "default":"normal"},
			{"field":"allowed_states", "type":"enum_array", "values":["normal", "damaged"], "default":["normal", "damaged"]}
		]
	}
}

const LEGACY_DOOR_IDS: Array[String] = ["steel_door", "reinforced_steel_door", "titanium_door", "energy_door", "grid_door", "mechanical_door", "digital_door", "powered_gate", "mechanical_steel_door", "mechanical_reinforced_steel_door", "mechanical_titanium_door", "mechanical_energy_door", "digital_steel_door", "digital_reinforced_steel_door", "digital_titanium_door", "digital_energy_door", "powered_steel_door", "powered_reinforced_steel_door", "powered_titanium_door", "powered_energy_door"]
const LEGACY_FLOOR_IDS: Array[String] = ["steel_floor", "concrete_floor", "grate_floor", "permission_floor", "water_floor", "oil_floor", "dirty_floor", "debris_floor"]

static func canonical_prefab_id(prefab_id: String) -> String:
	var normalized_type: String = prefab_id.strip_edges().to_lower()
	if PREFAB_ALIASES.has(normalized_type):
		return str(PREFAB_ALIASES[normalized_type])
	var preset_variant: Variant = LEGACY_ITEM_ALIAS_CONFIGS.get(normalized_type, LEGACY_DOOR_ALIAS_CONFIGS.get(normalized_type, LEGACY_WALL_ALIAS_CONFIGS.get(normalized_type, LEGACY_PLATFORM_ALIAS_CONFIGS.get(normalized_type, LEGACY_TERMINAL_ALIAS_CONFIGS.get(normalized_type, LEGACY_BIPOB_ALIAS_CONFIGS.get(normalized_type, {}))))))
	if preset_variant is Dictionary:
		return str(preset_variant.get("object_type", "terminal" if LEGACY_TERMINAL_ALIAS_CONFIGS.has(normalized_type) else normalized_type))
	return normalized_type

# Compatibility name retained for existing constructor and runtime callers.
static func canonical_object_type(object_type: String) -> String:
	return canonical_prefab_id(object_type)

static func _get_constructor_prefab_definition(canonical_id: String) -> Dictionary:
	if ARCHETYPE_REGISTRY.has(canonical_id):
		return Dictionary(ARCHETYPE_REGISTRY[canonical_id]).duplicate(true)
	if OBJECT_LIBRARY.has(canonical_id):
		return Dictionary(OBJECT_LIBRARY[canonical_id]).duplicate(true)
	return {}

static func _schema_field_values(definition: Dictionary, field_names: Array) -> Array[String]:
	var result: Array[String] = []
	var raw_schema: Variant = definition.get("property_schema", [])
	if not raw_schema is Array:
		return result
	for schema_entry_variant in raw_schema:
		if not schema_entry_variant is Dictionary:
			continue
		var schema_entry: Dictionary = Dictionary(schema_entry_variant)
		var field_name: String = str(schema_entry.get("field", "")).strip_edges().to_lower()
		if not field_names.has(field_name):
			continue
		var values_variant: Variant = schema_entry.get("values", [])
		if values_variant is Array:
			for value_variant in Array(values_variant):
				var value: String = str(value_variant).strip_edges().to_lower()
				if not value.is_empty() and not result.has(value):
					result.append(value)
		var default_value: String = str(schema_entry.get("default", "")).strip_edges().to_lower()
		if not default_value.is_empty() and not result.has(default_value):
			result.append(default_value)
	return result

static func _normalized_placement_surfaces(values_variant: Variant) -> Array[String]:
	var surfaces: Array[String] = []
	if values_variant is Array:
		for surface_variant in Array(values_variant):
			var surface: String = str(surface_variant).strip_edges().to_lower()
			if surface in ["floor", "wall"] and not surfaces.has(surface):
				surfaces.append(surface)
	elif values_variant is String:
		var surface: String = str(values_variant).strip_edges().to_lower()
		if surface in ["floor", "wall"]:
			surfaces.append(surface)
	return surfaces

static func get_constructor_placement_contract(prefab_id: String) -> Dictionary:
	var requested_id: String = prefab_id.strip_edges().to_lower()
	var canonical_id: String = canonical_prefab_id(requested_id)
	var definition: Dictionary = _get_constructor_prefab_definition(canonical_id)
	if definition.is_empty():
		return {}

	var alias_defaults: Dictionary = {}
	if PREFAB_ALIAS_DEFAULTS.has(requested_id):
		alias_defaults = Dictionary(PREFAB_ALIAS_DEFAULTS[requested_id]).duplicate(true)
	var placement_mode: String = str(alias_defaults.get("placement_mode", definition.get("placement_mode", "object"))).strip_edges().to_lower()
	if placement_mode.is_empty():
		placement_mode = "object"

	var placement_surfaces: Array[String] = _normalized_placement_surfaces(definition.get("placement_surfaces", []))
	if placement_surfaces.is_empty():
		var schema_mount_values: Array[String] = _schema_field_values(definition, ["mount", "install_mode", "cable_install_mode"])
		for schema_surface in schema_mount_values:
			if schema_surface in ["floor", "wall"] and not placement_surfaces.has(schema_surface):
				placement_surfaces.append(schema_surface)
	if placement_surfaces.is_empty():
		return {}

	var alias_surfaces: Array[String] = _normalized_placement_surfaces(alias_defaults.get("placement_surfaces", []))
	if not alias_surfaces.is_empty():
		placement_surfaces = alias_surfaces

	var default_placement_surface: String = str(alias_defaults.get("default_placement_surface", definition.get("default_placement_surface", ""))).strip_edges().to_lower()
	if not placement_surfaces.has(default_placement_surface):
		default_placement_surface = str(placement_surfaces[0])

	var supports_floor: bool = placement_surfaces.has("floor")
	var supports_wall: bool = placement_surfaces.has("wall")
	var floor_only: bool = supports_floor and not supports_wall
	var wall_only: bool = supports_wall and not supports_floor
	var requires_floor_anchor_when_wall_mounted: bool = bool(definition.get("requires_floor_anchor_when_wall_mounted", supports_wall))
	if alias_defaults.has("requires_floor_anchor_when_wall_mounted"):
		requires_floor_anchor_when_wall_mounted = bool(alias_defaults.get("requires_floor_anchor_when_wall_mounted"))

	return {
		"requested_prefab_id": requested_id,
		"canonical_prefab_id": canonical_id,
		"default_placement_mode": placement_mode,
		"default_placement_surface": default_placement_surface,
		"placement_surfaces": placement_surfaces,
		"supports_floor": supports_floor,
		"supports_wall": supports_wall,
		"floor_only": floor_only,
		"wall_only": wall_only,
		"requires_floor": floor_only,
		"requires_wall": wall_only,
		"requires_floor_anchor_when_wall_mounted": requires_floor_anchor_when_wall_mounted,
		"requires_floor_anchor": requires_floor_anchor_when_wall_mounted,
		"changes_passability": bool(definition.get("changes_passability", definition.get("blocks_movement", false)))
	}

static func is_legacy_prefab_alias(value: String) -> bool:
	var normalized_value: String = value.strip_edges().to_lower()
	return PREFAB_ALIASES.has(normalized_value) or LEGACY_DOOR_ALIAS_CONFIGS.has(normalized_value) or LEGACY_ITEM_ALIAS_CONFIGS.has(normalized_value) or LEGACY_WALL_ALIAS_CONFIGS.has(normalized_value) or LEGACY_PLATFORM_ALIAS_CONFIGS.has(normalized_value) or LEGACY_TERMINAL_ALIAS_CONFIGS.has(normalized_value) or LEGACY_BIPOB_ALIAS_CONFIGS.has(normalized_value)

static func is_legacy_door_object_type(value: String) -> bool:
	var normalized_value: String = value.strip_edges().to_lower()
	return LEGACY_DOOR_IDS.has(normalized_value) or LEGACY_DOOR_ALIAS_CONFIGS.has(normalized_value)

static func is_material_named_door_object_type(value: String) -> bool:
	return DOOR_MATERIAL_BY_OBJECT_TYPE.has(value.strip_edges().to_lower())

static func get_legacy_source_id(object_data: Dictionary) -> String:
	for field_name in LEGACY_SOURCE_METADATA_FIELDS:
		var source_id: String = _normalized_contract_token(object_data.get(field_name, ""))
		if not source_id.is_empty():
			return source_id
	return ""

static func mark_legacy_source(object_data: Dictionary, source_id: String) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var normalized_source_id: String = _normalized_contract_token(source_id)
	if normalized_source_id.is_empty():
		return data
	data["source_prefab_id"] = normalized_source_id
	if is_legacy_prefab_alias(normalized_source_id):
		data["legacy_prefab_id"] = normalized_source_id
		data["map_constructor_prefab_id"] = normalized_source_id
	return data

static func canonicalize_legacy_object_data(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	if data.is_empty():
		return data
	var original_object_type: String = _normalized_contract_token(data.get("object_type", ""))
	var source_id: String = _normalized_contract_token(data.get("map_constructor_prefab_id", original_object_type))
	if is_legacy_prefab_alias(original_object_type):
		data = mark_legacy_source(data, original_object_type)
		data["legacy_object_type"] = original_object_type
		data["object_type"] = canonical_prefab_id(original_object_type)
		for key_variant in get_prefab_alias_defaults(original_object_type).keys():
			var key: String = str(key_variant)
			if not data.has(key):
				data[key] = get_prefab_alias_defaults(original_object_type)[key]
		if data["object_type"] in ["floor", "item", "digital_item", "access_item", "physical_item", "module_item"]:
			data["archetype_id"] = data["object_type"]
	elif is_legacy_prefab_alias(source_id):
		data = mark_legacy_source(data, source_id)
	if data.has("access_type") or data.has("lock_type"):
		data["access_type"] = normalize_access_type(data.get("access_type", data.get("lock_type", ACCESS_TYPE_NO_KEY)))
	if _normalized_contract_token(data.get("object_type", "")) == "crate" or _normalized_contract_token(data.get("archetype_id", "")) == "crate" or source_id in ["crate", "normal_crate", "heavy_crate", "steel_box"]:
		data = normalize_crate_contract(data)
	return data

static func normalize_crate_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var source_id := _normalized_contract_token(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	var crate_type := _normalized_contract_token(data.get("crate_type", data.get("variant", "")))

	if crate_type.is_empty():
		if source_id in ["steel_box", "heavy_crate"]:
			crate_type = "heavy"
		elif source_id in ["normal_crate", "crate"]:
			crate_type = "normal"

	if crate_type in ["steel", "steel_box", "heavy_crate"]:
		crate_type = "heavy"
	if crate_type not in ["normal", "heavy"]:
		crate_type = "normal"

	data["archetype_id"] = "crate"
	data["object_group"] = "physical_object"
	data["object_type"] = "crate"
	data["crate_type"] = crate_type
	data["variant"] = crate_type

	if crate_type == "heavy":
		data["weight_class"] = "heavy"
		data["required_bipob_power_class"] = "engineer"
		data["heavy_claw_movable"] = true
		data["heavy_claw_mode"] = "push"
		data["magnetic"] = bool(data.get("magnetic", true))
		if not data.has("material_tags"):
			data["material_tags"] = ["metal"]
	else:
		data["weight_class"] = "normal"
		data["required_bipob_power_class"] = "scout"
		data["heavy_claw_movable"] = bool(data.get("heavy_claw_movable", true))
		data["heavy_claw_mode"] = str(data.get("heavy_claw_mode", "push"))

	return data

static func get_prefab_alias_defaults(prefab_id: String) -> Dictionary:
	var normalized_prefab_id: String = prefab_id.strip_edges().to_lower()
	var raw_defaults: Variant = PREFAB_ALIAS_DEFAULTS.get(normalized_prefab_id, {})
	if raw_defaults is Dictionary and not raw_defaults.is_empty():
		return raw_defaults.duplicate(true)
	var preset_variant: Variant = LEGACY_ITEM_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_DOOR_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_WALL_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_PLATFORM_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_TERMINAL_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_BIPOB_ALIAS_CONFIGS.get(normalized_prefab_id, {}))))))
	if preset_variant is Dictionary:
		var preset_defaults: Dictionary = preset_variant.duplicate(true)
		preset_defaults.erase("object_type")
		preset_defaults.erase("display_name")
		return preset_defaults
	return {}

static func is_constructor_door_preset(prefab_id: String) -> bool:
	return LEGACY_DOOR_ALIAS_CONFIGS.has(prefab_id.strip_edges().to_lower())

static func get_wall_material_quick_presets() -> Array[Dictionary]:
	return []

static func get_constructor_palette_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var rows_by_prefab: Dictionary = {}
	for archetype_id_variant in ARCHETYPE_REGISTRY.keys():
		var archetype_id: String = str(archetype_id_variant)
		var definition: Dictionary = ARCHETYPE_REGISTRY[archetype_id]
		if not bool(definition.get("show_in_palette", true)):
			continue
		if not CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB.has(archetype_id):
			continue
		rows_by_prefab[archetype_id] = _normalize_constructor_palette_row({"id":archetype_id, "prefab_id":archetype_id, "archetype_id":archetype_id, "canonical_object_type":str(definition.get("object_type", archetype_id)), "display_name":str(definition.get("palette_label", archetype_id.capitalize())), "label":str(definition.get("palette_label", archetype_id.capitalize())), "category":str(definition.get("object_group", "Objects")).capitalize(), "object_group":str(definition.get("object_group", "physical_object")), "placement_mode":str(definition.get("placement_mode", "object")), "blocks_movement":bool(definition.get("blocks_movement", true)), "is_alias":false})
	for object_type_variant in OBJECT_LIBRARY.keys():
		var object_type: String = str(object_type_variant)
		var definition: Dictionary = OBJECT_LIBRARY[object_type]
		if ARCHETYPE_REGISTRY.has(object_type) or is_legacy_prefab_alias(object_type) or not bool(definition.get("placeable_in_constructor", true)) or str(definition.get("group", "")) in ["door", "terminal", "item", "platform"]:
			continue
		if not CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB.has(object_type):
			continue
		rows_by_prefab[object_type] = _normalize_constructor_palette_row(_build_constructor_palette_row(object_type, object_type, definition, false))
	for prefab_id in CONSTRUCTOR_PALETTE_PREFAB_ORDER:
		if rows_by_prefab.has(prefab_id):
			rows.append(rows_by_prefab[prefab_id])
	return rows

static func get_constructor_palette_group_order() -> Array[String]:
	return CONSTRUCTOR_PALETTE_GROUP_ORDER.duplicate()

static func get_constructor_palette_group_for_prefab(prefab_id: String) -> String:
	return str(CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB.get(canonical_prefab_id(prefab_id), ""))

static func is_visible_constructor_palette_prefab(prefab_id: String) -> bool:
	return CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB.has(canonical_prefab_id(prefab_id))

static func _normalize_constructor_palette_row(row: Dictionary) -> Dictionary:
	var normalized_row: Dictionary = row.duplicate(true)
	var canonical_prefab_id_value: String = canonical_prefab_id(str(normalized_row.get("prefab_id", normalized_row.get("id", ""))))
	var palette_group: String = str(CONSTRUCTOR_PALETTE_GROUP_BY_PREFAB.get(canonical_prefab_id_value, "Other"))
	normalized_row["id"] = canonical_prefab_id_value
	normalized_row["prefab_id"] = canonical_prefab_id_value
	normalized_row["category"] = palette_group
	normalized_row["constructor_group"] = palette_group
	normalized_row["constructor_tab"] = palette_group
	normalized_row["palette_group"] = palette_group
	normalized_row["is_alias"] = false
	normalized_row["alias_source_id"] = ""
	return normalized_row

static func _build_constructor_palette_row(prefab_id: String, canonical_type: String, definition: Dictionary, is_alias: bool) -> Dictionary:
	var object_group: String = str(definition.get("group", definition.get("object_group", "physical_object")))
	var category: String = str(definition.get("constructor_category", object_group.capitalize()))
	var placement_mode: String = str(definition.get("placement_mode", "object"))
	var row: Dictionary = {
		"id": prefab_id,
		"prefab_id": prefab_id,
		"canonical_object_type": canonical_type,
		"display_name": str(definition.get("name", prefab_id.capitalize())),
		"label": str(definition.get("name", prefab_id.capitalize())),
		"category": category,
		"constructor_tab": str(definition.get("constructor_tab", "")),
		"constructor_group": str(definition.get("constructor_group", "")),
		"object_group": object_group,
		"placement_mode": placement_mode,
		"blocks_movement": bool(definition.get("blocks_movement", false)),
		"is_alias": is_alias,
		"alias_source_id": prefab_id if is_alias else ""
	}
	if object_group == "door":
		for field_name in ["door_type", "material", "access_type", "door_class", "power_behavior"]:
			row[field_name] = definition.get(field_name, "")
	return row

static func is_constructor_solid_prefab(prefab_id: String) -> bool:
	var object_data: Dictionary = create_world_object(prefab_id, "constructor_solid_preview")
	return not object_data.is_empty() and bool(object_data.get("blocks_movement", false))

static func get_constructor_placeable_door_types() -> Array[String]:
	var door_types: Array[String] = []
	for object_type_variant in OBJECT_LIBRARY.keys():
		var object_type: String = str(object_type_variant)
		var definition: Dictionary = OBJECT_LIBRARY[object_type]
		if str(definition.get("group", "")) == "door" and bool(definition.get("placeable_in_constructor", true)):
			door_types.append(object_type)
	door_types.sort()
	return door_types

static func apply_prefab_alias_defaults(canonical_type: String, original_type: String, object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var normalized_original_type: String = original_type.strip_edges().to_lower()
	data["object_type"] = canonical_type
	if is_legacy_prefab_alias(normalized_original_type):
		data = mark_legacy_source(data, normalized_original_type)
	var defaults: Dictionary = get_prefab_alias_defaults(normalized_original_type)
	if defaults.is_empty():
		return normalize_world_object_contract(data)
	data["map_constructor_prefab_id"] = normalized_original_type
	for key_variant in defaults.keys():
		var key: String = str(key_variant)
		if not data.has(key):
			data[key] = defaults[key]
	if normalized_original_type == "powered_gate":
		data["requires_external_power"] = bool(data.get("requires_external_power", true))
		data["power_mode"] = str(data.get("power_mode", "external_power"))
	return normalize_world_object_contract(data)


const OBJECT_LIBRARY := {
	"terminal": {"group":"terminal","name":"Information Terminal","state":"active","status":"active","is_powered":true,"power_mode":"internal","control_mode":"internal","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","connection_type":"wired","terminal_class":1,"required_connector_level":1,"required_processor_level":1,"encrypts_data":false,"drain_pool":10,"durability":10,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":"","placeable_in_constructor":false},
	"steel_door": {"group":"door","name":"Steel Door","placeable_in_constructor":false,"door_type":"mechanical","material":"steel","access_type":"key_card","power_behavior":"none","durability":30,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":1,"lock_type":"mechanical_key","required_manipulator_level":1,"required_connector_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"reinforced_steel_door": {"group":"door","name":"Reinforced Steel Door","placeable_in_constructor":false,"door_type":"digital","material":"reinforced_steel","access_type":"terminal","power_behavior":"none","durability":40,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":2,"lock_type":"terminal_lock","required_manipulator_level":2,"required_connector_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"titanium_door": {"group":"door","name":"Titanium Door","placeable_in_constructor":false,"door_type":"digital","material":"titanium","access_type":"access_code","power_behavior":"none","durability":100,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":3,"lock_type":"password","required_manipulator_level":3,"required_connector_level":0},
	"energy_door": {"group":"door","name":"Energy Door","placeable_in_constructor":false,"door_type":"digital","material":"energy","access_type":"digital_key","power_behavior":"none","durability":1,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"digital_key","required_manipulator_level":1,"required_connector_level":1,"invulnerable_while_powered":true,"power_mode":"external_power","control_mode":"external_control"},
	"grid_door": {"group":"door","name":"Grid Door","placeable_in_constructor":false,"door_type":"mechanical","material":"steel","access_type":"no_key","power_behavior":"none","durability":15,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"none","required_manipulator_level":1,"required_connector_level":0},
	"rotating_platform": {"group":"platform","name":"Rotating Platform","platform_type":"rotating","platform_id":"","platform_cells":[],"state":"active","is_powered":true,"power_type":"internal","control_type":"internal","requires_terminal_enabled":false,"linked_terminal_id":"","local_switch_cell":[0,0],"local_switch_facing_dir":"up","non_destructible":true,"destructible":false,"movable":false,"heavy_claw_movable":false,"activation_mode":"instant","timer_turns":0,"timer_remaining_turns":0,"period_turns":0,"periodic_active":false,"permanent_state":false,"pending_activation":false,"rotation_direction":"clockwise"},
	"lifting_platform": {"group":"platform","name":"Lifting Platform","platform_type":"lifting","platform_id":"","platform_cells":[],"state":"active","is_powered":true,"power_type":"internal","control_type":"internal","requires_terminal_enabled":false,"linked_terminal_id":"","local_switch_cell":[0,0],"local_switch_facing_dir":"up","non_destructible":true,"destructible":false,"movable":false,"heavy_claw_movable":false,"height_level":0,"min_height_level":0,"max_height_level":1,"activation_mode":"instant","timer_turns":0,"timer_remaining_turns":0,"period_turns":0,"periodic_active":false,"permanent_state":false,"pending_activation":false},
	"firewall": {"group":"security","object_group":"security","object_type":"firewall","archetype_id":"firewall","palette_label":"Firewall","name":"Firewall Node","placement_mode":"object","state":"active","required_connector_level":1,"required_processor_level":1,"durability":10,"blocks_movement":false,"blocks_vision":false,"visual_surface":"floor","mount":"floor","install_mode":"floor"},
	"external_wall": {"group":"wall","name":"External Wall","material":"external_structural","is_destructible":false,"supports_embedded_objects":true,"supports_cables":true,"configurable":false,"indestructible":true,"blocks_movement":true,"blocks_vision":true},
	"wall": {"group":"wall","name":"Brick Wall","material":"brick","is_destructible":true,"supports_embedded_objects":true,"supports_cables":true,"configurable":true,"durability":10,"blocks_movement":true,"blocks_vision":true},
	"outer_wall": {"group":"wall","name":"Outer Wall","material":"steel","durability":9999,"indestructible":true,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"grate_wall": {"group":"wall","name":"Grate Wall","material":"steel","durability":15,"blocks_movement":true,"blocks_vision":false,"placeable_in_constructor":false},
	"damaged_wall": {"group":"wall","name":"Damaged Wall","material":"concrete","durability":3,"blocks_movement":true,"blocks_vision":false,"hidden_content":["secret_passage"],"placeable_in_constructor":false},
	"brick_wall": {"group":"wall","name":"Brick Wall","material":"brick","durability":10,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"concrete_wall": {"group":"wall","name":"Concrete Wall","material":"concrete","durability":20,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"steel_wall": {"group":"wall","name":"Steel Wall","material":"steel","durability":30,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"reinforced_steel_wall": {"group":"wall","name":"Reinforced Steel Wall","material":"reinforced_steel","durability":40,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"titanium_wall": {"group":"wall","name":"Titanium Wall","material":"titanium","durability":100,"blocks_movement":true,"blocks_vision":true,"placeable_in_constructor":false},
	"energy_wall": {"group":"wall","name":"Energy Wall","material":"energy_flow","durability":1,"blocks_movement":true,"blocks_vision":false,"invulnerable_while_powered":true,"power_mode":"external_power","placeable_in_constructor":false},
	"power_cable": {"group":"power","name":"Power Cable","placement_surfaces":["floor", "wall"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":true,"state":"ok","durability":5,"power_mode":"external_power","control_mode":"internal_control","generic_power_role":"cable_link","is_powered":false,"power_state":"unpowered","power_required":false,"power_received":0,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","power_source_id":"","physical_connection_source_id":"","is_connected":true,"connected":true,"disconnected":false,"connected_side":true,"cut":false,"damaged":false,"broken":false,"is_hidden":false,"hidden_installation":false,"route_surface":"floor","cable_install_mode":"floor","install_mode":"floor","cable_health_state":"normal","health_state":"normal","cable_path_cells":[],"cable_length":0},
	"circuit_breaker": {"group":"power","name":"Circuit Breaker","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"switch_on","durability":8,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"is_on":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"circuit_switch": {"group":"power","name":"Circuit Switch","placeable_in_constructor":false,"state":"switch_off","durability":8,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false,"input_wire_id":"","output_1_wire_id":"","output_2_wire_id":"","output_3_wire_id":"","active_output_index":1},
	"legacy_fuse_box_library": {"group":"power","name":"Fuse Box","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"installed","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"fuse_box_installed": {"group":"power","name":"Fuse Box Installed","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"installed","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"fuse_box_empty": {"group":"power","name":"Fuse Box Empty","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"empty","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"legacy_light_library": {"group":"power","name":"Light","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"active","durability":6,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false,"brightness":1.0,"color":"#ffffff"},
	"light_switch": {"group":"power","name":"Light Switch","placeable_in_constructor":false,"placement_mode":"wall_mounted","state":"switch_off","durability":6,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"is_on":false,"can_be_switched":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"power_socket": {"group":"power","placement_surfaces":["floor", "wall"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":true,"object_group":"power","object_type":"power_socket","archetype_id":"power_socket","palette_label":"Power Socket","name":"Power Socket","display_name_template":"Power Socket","placement_mode":"object","configurable":true,"interactable":true,"blocks_movement":false,"blocks_vision":false,"state":"disconnected","status":"inactive","durability":8,"power_mode":"external_power","control_mode":"internal_control","generic_power_role":"socket_input","socket_role":"socket_input","visual_family":"power_socket","visual_state_policy":"power_socket_connection_state","power_visual_state_enabled":false,"has_connected_cable":false,"connected_endpoint_count":0,"socket_connected_endpoint_count":0,"is_powered":false,"power_state":"unpowered","power_required":false,"power_received":0,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","power_source_id":"","physical_connection_source_id":"","is_connected":false,"connected":false,"disconnected":true,"connected_side":false,"damaged":false,"broken":false,"can_connect_cable":true,"mount":"floor","install_mode":"floor","property_schema":[FACING_SIDE_SCHEMA,{"field":"mount", "type":"enum", "values":["floor", "wall"], "default":"floor", "labels":{"floor":"Floor", "wall":"Wall"}}]},
	"power_cable_reel": {"group":"item","name":"Power Cable Reel","placement_surfaces":["floor", "wall"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":true,"placement_mode":"wall_mounted","state":"disconnected","generic_power_role":"cable_endpoint","power_state":"unpowered","power_required":false,"power_received":0,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","item_form":"physical","storage_type":"pocket","can_connect_socket":true,"max_cable_length":5,"is_connected":false,"connected":false,"disconnected":true,"connected_side":false,"connected_side_1":false,"connected_side_2":false,"end_1_state":"on_reel","end_1_target_id":"","end_1_path_cells":[],"end_1_cable_length":0,"end_2_state":"on_reel","end_2_target_id":"","end_2_path_cells":[],"end_2_cable_length":0,"cable_endpoint_a_id":"","cable_endpoint_b_id":"","cable_path_cells":[],"cable_length":0,"cut":false,"damaged":false,"broken":false,"cable_install_mode":"floor","install_mode":"floor","cable_health_state":"normal","health_state":"normal"},
	"power_source_class_1": {"group":"power","name":"Power Source C1","placeable_in_constructor":false,"state":"on","power_mode":"internal","control_mode":"internal","visual_family":"power_source","visual_surface":"floor","visual_state_policy":"powered_three_state","power_visual_state_enabled":true,"requires_external_control":false,"generic_power_role":"power_source","is_powered":true,"power_state":"source_on","power_required":false,"power_received":1,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","is_connected":true,"damaged":false,"broken":false,"durability":30,"power_source_class":1,"outlet_capacity":4,"drain_pool":60,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":1,"connected_device_ids":[]},
	"power_source_class_2": {"group":"power","name":"Power Source C2","placeable_in_constructor":false,"state":"on","power_mode":"internal","control_mode":"internal","visual_family":"power_source","visual_surface":"floor","visual_state_policy":"powered_three_state","power_visual_state_enabled":true,"requires_external_control":false,"generic_power_role":"power_source","is_powered":true,"power_state":"source_on","power_required":false,"power_received":1,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","is_connected":true,"damaged":false,"broken":false,"durability":30,"power_source_class":2,"outlet_capacity":5,"drain_pool":120,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":2,"connected_device_ids":[]},
	"power_source_class_3": {"group":"power","name":"Power Source C3","placeable_in_constructor":false,"state":"on","power_mode":"internal","control_mode":"internal","visual_family":"power_source","visual_surface":"floor","visual_state_policy":"powered_three_state","power_visual_state_enabled":true,"requires_external_control":false,"generic_power_role":"power_source","is_powered":true,"power_state":"source_on","power_required":false,"power_received":1,"power_network_id":"","connection_id":"","source_object_id":"","sink_object_id":"","socket_id":"","endpoint_a_id":"","endpoint_b_id":"","is_connected":true,"damaged":false,"broken":false,"durability":30,"power_source_class":3,"outlet_capacity":6,"drain_pool":240,"working_heat":3,"current_heat":3,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":3,"connected_device_ids":[]},
	"external_radiator": {"group":"cooling","name":"External Radiator","placeable_in_constructor":false,"state":"active","cooling_device_type":"radiator","cooling_output":1,"movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20},
	"external_air_cooler": {"group":"cooling","object_group":"cooling","object_type":"external_air_cooler","placeable_in_constructor":false,"palette_label":"Air Cooling","name":"External Air Cooler","display_name_template":"Air Cooling","placement_mode":"object","configurable":true,"interactable":true,"state":"off","status":"active","is_powered":false,"power_mode":"external_power","control_mode":"internal_control","cooling_device_type":"air_cooler","cooling_output":2,"directed_airflow":true,"generic_airflow_role":"fan","airflow_roles":["fan","airflow_source"],"fan_enabled":false,"fan_speed":0,"airflow_range":0,"cooling_state":"uncooled","airflow_direction":"sw","facing_side":"SW","facing_dir":"SW","allowed_airflow_directions":["ne","nw","se","sw"],"visual_family":"air_cooling","visual_surface":"floor","visual_state_policy":"powered_three_state","variant_policy":"airflow_direction","visual_variant":"sw","power_visual_state_enabled":true,"movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20,"property_schema":[{"field":"airflow_direction","type":"enum","values":["ne","nw","se","sw"],"default":"sw","labels":{"ne":"NE","nw":"NW","se":"SE","sw":"SW"}},{"field":"state","type":"enum","values":["base","off","on"],"default":"off","labels":{"base":"Base","off":"Off","on":"On"}},{"field":"fan_enabled","type":"bool","default":false},{"field":"airflow_range","type":"int","default":0,"min":0}]},
	"metal_cooling_block": {"group":"cooling","placement_surfaces":["floor"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":false,"object_group":"cooling","object_type":"metal_cooling_block","placeable_in_constructor":true,"palette_label":"Cooling block","name":"Cooling block","display_name_template":"Cooling block","placement_mode":"object","visual_family":"air_cooling","visual_surface":"floor","visual_asset_id":"air_cooling_base_floor_sw_01","state":"base","material":"metal","cooling_amplifier":true,"movable":true,"heavy_claw_movable":true,"blocks_movement":true,"blocks_vision":false,"durability":30},
	"external_water_pipe": {"group":"cooling","object_group":"cooling","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","object_type":"external_water_pipe","archetype_id":"external_water_pipe","palette_label":"External Water Pipe","name":"External Water Pipe","display_name_template":"External Water Pipe","state":"active","cooling_device_type":"water_pipe","cooling_output":2,"passive_cooling":true,"movable":false,"material":"metal","blocks_movement":false,"blocks_vision":false,"durability":15,"placement_mode":"wall_mounted","mount":"wall","install_mode":"wall","is_wall_mounted":true,"changes_passability":false,"configurable":true,"route_mode":"inner","wall_routing_mode":"inner","routing_kind":"water_pipe","cooling_system_type":"water_pipe","cooling_contour_id":"","cooling_contour_mode":"auto","cooling_contour_member_ids":[],"cooling_system_tab":true,"routing_label":"Water Pipe","wall_side_1":"NW","wall_side_2":"SE","visual_family":"wall_routing_utility","visual_surface":"wall","wall_routing_visual_enabled":true,"property_schema":[{"field":"route_mode","type":"enum","values":["inner","outer"],"default":"inner","labels":{"inner":"Inner","outer":"Outer"},"tab":"Cooling System"},{"field":"cooling_contour_mode","type":"enum","values":["auto","manual"],"default":"auto","labels":{"auto":"Auto contour","manual":"Manual contour"},"tab":"Cooling System"},{"field":"cooling_contour_id","type":"string","default":"","internal":true,"legacy":true,"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},{"field":"cooling_contour_member_ids","type":"object_ref_array","target_group":"cooling","default":[],"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},{"field":"wall_side_1","type":"enum","values":["NE","NW","SE","SW"],"default":"NW","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}},{"field":"wall_side_2","type":"enum","values":["NE","NW","SE","SW"],"default":"SE","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}}]},
	"external_air_duct": {"group":"cooling","object_group":"cooling","constructor_group":"cooling_system","constructor_category":"Cooling System","constructor_tab":"cooling_system","object_type":"external_air_duct","archetype_id":"external_air_duct","palette_label":"External Air Duct","name":"External Air Duct","display_name_template":"External Air Duct","state":"active","cooling_device_type":"air_duct","carries_airflow":true,"passive_cooling":true,"generic_airflow_role":"airflow_path_cell","airflow_roles":["airflow_path_cell"],"blocks_airflow":false,"movable":false,"material":"metal","blocks_movement":false,"blocks_vision":false,"durability":12,"placement_mode":"wall_mounted","mount":"wall","install_mode":"wall","is_wall_mounted":true,"changes_passability":false,"configurable":true,"route_mode":"inner","wall_routing_mode":"inner","routing_kind":"air_duct","cooling_system_type":"air_duct","cooling_contour_id":"","cooling_contour_mode":"auto","cooling_contour_member_ids":[],"cooling_system_tab":true,"routing_label":"Air Duct","wall_side_1":"NW","wall_side_2":"SE","visual_family":"wall_routing_utility","visual_surface":"wall","wall_routing_visual_enabled":true,"property_schema":[{"field":"route_mode","type":"enum","values":["inner","outer"],"default":"inner","labels":{"inner":"Inner","outer":"Outer"},"tab":"Cooling System"},{"field":"cooling_contour_mode","type":"enum","values":["auto","manual"],"default":"auto","labels":{"auto":"Auto contour","manual":"Manual contour"},"tab":"Cooling System"},{"field":"cooling_contour_id","type":"string","default":"","internal":true,"legacy":true,"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},{"field":"cooling_contour_member_ids","type":"object_ref_array","target_group":"cooling","default":[],"tab":"Cooling System","visible_if":{"field":"cooling_contour_mode","equals":"manual"}},{"field":"wall_side_1","type":"enum","values":["NE","NW","SE","SW"],"default":"NW","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}},{"field":"wall_side_2","type":"enum","values":["NE","NW","SE","SW"],"default":"SE","labels":{"NE":"NE","NW":"NW","SE":"SE","SW":"SW"},"tab":"Cooling System","visible_if":{"field":"route_mode","equals":"inner"}}]},
	"module_external": {"group":"item","name":"Module External","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"module_internal": {"group":"item","name":"Module Internal","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"fuse": {"group":"item","name":"Fuse","visual_asset_id":"fuse_floor_01","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["fuse_box","fuse_box_empty"]},
	"repair_kit": {"group":"item","name":"Repair Kit","visual_asset_id":"repair_kit_floor_01","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door","terminal","power"]},
	"reinforcement": {"group":"item","name":"Reinforcement","visual_asset_id":"reinforcement_floor_01","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door"],"damage":2},
	"parts": {"group":"item","name":"Parts","visual_asset_id":"parts_floor_01","item_form":"physical","storage_type":"pocket","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_small": {"group":"item","name":"Parts (Small)","visual_asset_id":"parts_floor_01","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":5,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_medium": {"group":"item","name":"Parts (Medium)","visual_asset_id":"parts_floor_01","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":10,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_large": {"group":"item","name":"Parts (Large)","visual_asset_id":"parts_floor_01","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":20,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"sample": {"group":"item","name":"Sample","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mission_item": {"group":"item","name":"Mission Item","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"digital_key_opened": {"group":"item","name":"Digital Key Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"opened","consumable":false,"fits_targets":["door"]},
	"digital_key_encrypted": {"group":"item","name":"Digital Key Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"encrypted","consumable":false,"fits_targets":["door"]},
	"digital_key_damaged": {"group":"item","name":"Digital Key Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"damaged","consumable":false,"fits_targets":["door"]},
	"access_code": {"group":"item","name":"Access Code","item_form":"digital","storage_type":"digital_storage","can_place_in_digital_buffer":false,"digital_state":"opened","consumable":false,"fits_targets":["door","terminal"]},
	"data_file_opened": {"group":"item","name":"Data File Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"opened","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_encrypted": {"group":"item","name":"Data File Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"encrypted","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_damaged": {"group":"item","name":"Data File Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"damaged","consumable":false,"fits_targets":["terminal","firewall"]},
	"normal_crate": {"group":"physical_object","name":"Normal Crate","weight_class":"normal","required_bipob_power_class":"scout","durability":8,"movable":true,"heavy_claw_movable":true,"heavy_claw_mode":"push","blocks_movement":true},"heavy_crate": {"group":"physical_object","name":"Heavy Crate","placeable_in_constructor":false,"weight_class":"heavy","required_bipob_power_class":"engineer","durability":14,"movable":true,"heavy_claw_movable":true,"heavy_claw_mode":"push","blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"movable_platform_block": {"group":"physical_object","name":"Movable Platform Block","weight_class":"block","required_bipob_power_class":"juggernaut","durability":20,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"disabled_bipop_scout": {"group":"physical_object","name":"Disabled Bipop Scout","weight_class":"normal","required_bipob_power_class":"scout","durability":10},"disabled_bipop_engineer": {"group":"physical_object","name":"Disabled Bipop Engineer","weight_class":"heavy","required_bipob_power_class":"engineer","durability":15},"disabled_bipop_juggernaut": {"group":"physical_object","name":"Disabled Bipop Juggernaut","weight_class":"block","required_bipob_power_class":"juggernaut","durability":25},"legacy_barrel_library": {"group":"physical_object","name":"Barrel","placeable_in_constructor":false,"weight_class":"normal","required_bipob_power_class":"scout","durability":8,"movable":true,"heavy_claw_movable":true,"heavy_claw_mode":"push","blocks_movement":true},"explosive_barrel": {"group":"physical_object","name":"Explosive Barrel","placeable_in_constructor":false,"weight_class":"normal","required_bipob_power_class":"scout","durability":6,"movable":true,"heavy_claw_movable":true,"heavy_claw_mode":"push","blocks_movement":true,"on_destroy":"explode"},"debris": {"group":"physical_object","placement_surfaces":["floor"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":false,"name":"Debris","weight_class":"normal","required_bipob_power_class":"scout","durability":1,"blocks_movement":false,"terrain_tag":"debris","movement_debuff":-1},
	"enemy_robot": {"group":"threat","name":"Enemy Robot","state":"active","behavior_state":"patrolling","durability":20,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":20,"drained_this_turn":false,"detection_range":3,"vision_range":3,"radar_range":3,"thermal_range":0,"detection_modes":["vision","radar"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":5,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"turret": {"group":"threat","placement_surfaces":["floor"],"default_placement_surface":"floor","requires_floor_anchor_when_wall_mounted":false,"name":"Turret","state":"active","behavior_state":"idle","durability":15,"blocks_movement":true,"blocks_vision":false,"power_mode":"external_power","power_network_id":"power_net_A","is_powered":true,"control_mode":"external_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":15,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":0,"thermal_range":4,"detection_modes":["vision","thermal"],"detection_shape":"cardinal","detection_cone_enabled":false,"detection_direction":"forward","attack_range":4,"attack_damage":4,"can_be_controlled_by_terminal":true,"required_processor_level":1,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"bug": {"group":"threat","name":"Bug","show_in_palette":false,"state":"active","behavior_state":"patrolling","durability":8,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["organic"],"heat_signature":true,"magnetic":false,"drain_energy_pool":5,"drained_this_turn":false,"detection_range":2,"vision_range":2,"radar_range":0,"thermal_range":0,"detection_modes":["vision"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":2,"drops":["sample","parts_small"],"on_destroy":["drop_items"]},
	"vagus": {"group":"threat","name":"Vagus","show_in_palette":false,"state":"active","behavior_state":"idle","durability":30,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_heavy"],"heat_signature":true,"magnetic":true,"drain_energy_pool":30,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":4,"thermal_range":4,"detection_modes":["vision","radar","thermal"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":2,"attack_damage":7,"drops":["mission_item","parts_large"],"on_destroy":["drop_items","debris"]}
}

static func _safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value)

static func _safe_non_negative_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	if value is int:
		return maxi(0, value)
	if value is float:
		return maxi(0, int(value))
	if value is bool:
		return 1 if value else 0
	var text := str(value).strip_edges()
	if text.is_valid_int():
		return maxi(0, int(text))
	if text.is_valid_float():
		return maxi(0, int(float(text)))
	return fallback


static func _is_bool_like(value: Variant) -> bool:
	if value is bool:
		return true
	if value is int or value is float:
		return int(value) in [0, 1]
	return _safe_string(value).strip_edges().to_lower() in ["true", "false", "1", "0", "yes", "no", "on", "off"]


static func _safe_bool_like(value: Variant, fallback: bool = false) -> bool:
	if not _is_bool_like(value):
		return fallback
	if value is bool:
		return value
	if value is int or value is float:
		return int(value) == 1
	return _safe_string(value).strip_edges().to_lower() in ["true", "1", "yes", "on"]


static func _normalized_contract_token(value: Variant) -> String:
	return _safe_string(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")

static func normalize_access_type(value: Variant) -> String:
	var access_type: String = _normalized_contract_token(value)
	match access_type:
		"", "none", "no_key":
			return ACCESS_TYPE_NO_KEY
		"mechanical", "mechanical_key", "mechanical_keycard", "keycard", "key_card":
			return ACCESS_TYPE_KEY_CARD
		"digital", "digital_key":
			return ACCESS_TYPE_DIGITAL_KEY
		"terminal_access", "terminal_lock", "terminal":
			return ACCESS_TYPE_TERMINAL
		"password", "code", "access_code":
			return ACCESS_TYPE_ACCESS_CODE
	return access_type

static func normalize_key_item_type(value: Variant) -> String:
	var item_type: String = _normalized_contract_token(value)
	if item_type in ["mechanical_key", "mechanical_keycard", "keycard", "key_card"]:
		return KEY_ITEM_TYPE_KEY_CARD
	return item_type

static func normalize_item_type(value: Variant) -> String:
	return normalize_key_item_type(value)

static func normalize_item_form(value: Variant) -> String:
	var item_form: String = _normalized_contract_token(value)
	if item_form in [ITEM_STORAGE_CLASS_PHYSICAL, ITEM_STORAGE_CLASS_DIGITAL]:
		return item_form
	return ""

static func normalize_item_class(value: Variant) -> String:
	var item_class: String = normalize_item_type(value)
	if item_class in ITEM_CLASSES:
		return item_class
	return ITEM_CLASS_PHYSICAL_ITEM

static func normalize_item_contract(item_data: Dictionary) -> Dictionary:
	var data: Dictionary = item_data.duplicate(true)
	var archetype_token: String = _normalized_contract_token(data.get("archetype_id", ""))
	var source_type: String = _normalized_contract_token(data.get("item_class", data.get("item_type", data.get("object_type", ""))))
	var is_grouped_item: bool = archetype_token in ["item", "digital_item", "access_item", "physical_item", "module_item"]
	var is_catalog_item: bool = is_grouped_item or _normalized_contract_token(data.get("object_type", "")) == "item" or LEGACY_ITEM_ALIAS_CONFIGS.has(source_type)
	if not is_catalog_item:
		return data

	data["object_group"] = "item"
	data["object_type"] = "item"
	data["can_pickup"] = bool(data.get("can_pickup", true))
	data["interactable"] = bool(data.get("interactable", true))
	data["configurable"] = bool(data.get("configurable", true))
	data["state"] = _normalized_contract_token(data.get("state", "available"))
	if not data["state"] in ["available", "collected", "disabled"]:
		data["state"] = "available"
	if not data.has("allowed_states"):
		data["allowed_states"] = ["available", "collected", "disabled"]

	if archetype_token == "digital_item" or data.has("digital_item_type"):
		var digital_item_type: String = _normalized_contract_token(data.get("digital_item_type", source_type))
		if not digital_item_type in [ITEM_CLASS_DIGITAL_KEY, ITEM_CLASS_ACCESS_CODE, ITEM_CLASS_DATA_FILE]:
			digital_item_type = ITEM_CLASS_DATA_FILE
		data["archetype_id"] = "digital_item"
		data["item_category"] = "digital"
		data["digital_item_type"] = digital_item_type
		data["item_class"] = digital_item_type
		data["item_type"] = digital_item_type
		data["item_form"] = "digital"
		data["storage_route"] = ITEM_STORAGE_ROUTE_DIGITAL_STORAGE
		data["storage_type"] = ITEM_STORAGE_ROUTE_DIGITAL_STORAGE
		if digital_item_type == ITEM_CLASS_DIGITAL_KEY:
			data["key_kind"] = "digital"
			data["key_type"] = ITEM_CLASS_DIGITAL_KEY
		elif digital_item_type == ITEM_CLASS_ACCESS_CODE:
			data["key_kind"] = ITEM_CLASS_ACCESS_CODE
			data["key_type"] = ITEM_CLASS_ACCESS_CODE
		else:
			data.erase("key_kind")
			data.erase("key_type")
	elif archetype_token == "access_item" or data.has("access_item_type") or source_type == ITEM_CLASS_KEY_CARD:
		data["archetype_id"] = "access_item"
		data["item_category"] = "access"
		data["access_item_type"] = ITEM_CLASS_KEY_CARD
		data["item_class"] = ITEM_CLASS_KEY_CARD
		data["item_type"] = ITEM_CLASS_KEY_CARD
		data["item_form"] = "physical"
		data["storage_route"] = ITEM_STORAGE_ROUTE_KEYCHAIN
		data["storage_type"] = ITEM_STORAGE_ROUTE_KEYCHAIN
		data["key_kind"] = ITEM_CLASS_KEY_CARD
		data["key_type"] = ITEM_CLASS_KEY_CARD
	elif archetype_token == "module_item" or data.has("module_item_type"):
		var module_item_type: String = _normalized_contract_token(data.get("module_item_type", data.get("item_type", "module_internal")))
		if not module_item_type in ["module_internal", "module_external"]:
			module_item_type = "module_internal"
		data["archetype_id"] = "module_item"
		data["item_category"] = "module"
		data["module_item_type"] = module_item_type
		data["item_class"] = ITEM_CLASS_PHYSICAL_ITEM
		data["item_type"] = module_item_type
		data["item_form"] = "physical"
		data["storage_route"] = ITEM_STORAGE_ROUTE_POCKET
		data["storage_type"] = ITEM_STORAGE_ROUTE_POCKET
		data.erase("key_kind")
		data.erase("key_type")
	elif archetype_token == "physical_item" or data.has("physical_item_type") or source_type in ["fuse", "reinforcement", "repair_kit", "parts"]:
		var physical_item_type: String = _normalized_contract_token(data.get("physical_item_type", data.get("item_type", "parts")))
		if not physical_item_type in ["fuse", "reinforcement", "repair_kit", "parts"]:
			physical_item_type = "parts"
		data["archetype_id"] = "physical_item"
		data["item_category"] = "physical"
		data["physical_item_type"] = physical_item_type
		data["item_class"] = ITEM_CLASS_PHYSICAL_ITEM
		data["item_type"] = physical_item_type
		data["item_form"] = "physical"
		data["storage_route"] = ITEM_STORAGE_ROUTE_POCKET
		data["storage_type"] = ITEM_STORAGE_ROUTE_POCKET
		data["visual_asset_id"] = "%s_floor_01" % physical_item_type
		data["visual_family"] = physical_item_type
		data["visual_surface"] = "floor"
		data.erase("key_kind")
		data.erase("key_type")
	else:
		var item_class: String = normalize_item_class(source_type)
		data["archetype_id"] = "item"
		data["item_class"] = item_class
		data["item_type"] = item_class
		match item_class:
			ITEM_CLASS_DIGITAL_KEY, ITEM_CLASS_ACCESS_CODE, ITEM_CLASS_DATA_FILE:
				data["digital_item_type"] = item_class
				return normalize_item_contract(data)
			ITEM_CLASS_KEY_CARD:
				data["access_item_type"] = ITEM_CLASS_KEY_CARD
				return normalize_item_contract(data)
			_:
				data["physical_item_type"] = str(data.get("item_type", "parts"))
				return normalize_item_contract(data)

	data["display_name"] = generate_display_name(data)
	return data

static func get_item_storage_class(item_data: Dictionary) -> String:
	var item_type: String = normalize_item_type(item_data.get("item_type", item_data.get("object_type", "")))
	var item_family: String = normalize_item_type(item_data.get("item_family", ""))
	var storage_type: String = _normalized_contract_token(item_data.get("storage_type", ""))
	var item_form: String = normalize_item_form(item_data.get("item_form", ""))
	var key_kind: String = _normalized_contract_token(item_data.get("key_kind", ""))
	if item_type == ITEM_STORAGE_CLASS_KEY_CARD or key_kind == "mechanical":
		return ITEM_STORAGE_CLASS_KEY_CARD
	if item_form == ITEM_STORAGE_CLASS_DIGITAL or storage_type in ["digital_buffer", "digital_storage"]:
		return ITEM_STORAGE_CLASS_DIGITAL
	for digital_alias in DIGITAL_ITEM_TYPE_ALIASES:
		if item_type == digital_alias or item_family == digital_alias or item_type.begins_with("%s_" % digital_alias):
			return ITEM_STORAGE_CLASS_DIGITAL
	if item_form == ITEM_STORAGE_CLASS_PHYSICAL or storage_type in ["manipulator", "pocket", "box", "box_storage"]:
		return ITEM_STORAGE_CLASS_PHYSICAL
	return ITEM_STORAGE_CLASS_UNKNOWN

static func is_physical_inventory_item(item_data: Dictionary) -> bool:
	return get_item_storage_class(item_data) == ITEM_STORAGE_CLASS_PHYSICAL

static func is_key_card_item(item_data: Dictionary) -> bool:
	return get_item_storage_class(item_data) == ITEM_STORAGE_CLASS_KEY_CARD

static func is_digital_inventory_item(item_data: Dictionary) -> bool:
	return get_item_storage_class(item_data) == ITEM_STORAGE_CLASS_DIGITAL

static func _legacy_lock_type_for_access_type(access_type: String) -> String:
	match access_type:
		ACCESS_TYPE_NO_KEY:
			return "none"
		ACCESS_TYPE_KEY_CARD:
			return "mechanical_key"
		ACCESS_TYPE_DIGITAL_KEY:
			return "digital_key"
		ACCESS_TYPE_ACCESS_CODE:
			return "password"
		ACCESS_TYPE_TERMINAL:
			return "terminal_lock"
	return access_type

static func _normalize_door_material(value: Variant, object_type: String) -> String:
	var material: String = _normalized_contract_token(value)
	if material == "electromagnetic":
		material = DOOR_MATERIAL_ENERGY
	if material in DOOR_MATERIALS:
		return material
	return str(DOOR_MATERIAL_BY_OBJECT_TYPE.get(object_type, DOOR_MATERIAL_STEEL))

static func _normalize_door_type(value: Variant) -> String:
	var door_type: String = _normalized_contract_token(value)
	if door_type in DOOR_TYPES:
		return door_type
	return ""

static func normalize_door_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	if data.is_empty():
		return data
	var object_type: String = _normalized_contract_token(data.get("object_type", ""))
	var prefab_id: String = _normalized_contract_token(data.get("map_constructor_prefab_id", object_type))
	var defaults: Dictionary = get_prefab_alias_defaults(prefab_id)
	for key_variant in defaults.keys():
		var key: String = str(key_variant)
		if not data.has(key):
			data[key] = defaults[key]
	var group_text: String = _normalized_contract_token(data.get("object_group", data.get("group", "")))
	if group_text != "door" and not object_type.contains("door") and not object_type.contains("gate") and defaults.is_empty():
		return data
	data["archetype_id"] = "door"
	data["object_group"] = "door"
	data["object_type"] = "door"
	var raw_access_type: Variant = data.get("access_type", data.get("lock_type", ACCESS_TYPE_NO_KEY))
	var access_type: String = normalize_access_type(raw_access_type)
	data["access_type"] = access_type
	data["lock_type"] = _legacy_lock_type_for_access_type(access_type)
	var power_behavior: String = _normalized_contract_token(data.get("power_behavior", POWER_BEHAVIOR_NONE))
	if power_behavior not in POWER_BEHAVIORS:
		power_behavior = POWER_BEHAVIOR_NONE
	var door_type: String = _normalize_door_type(data.get("door_type", ""))
	if door_type.is_empty():
		if prefab_id == "mechanical_door":
			door_type = DOOR_TYPE_MECHANICAL
		elif prefab_id == "digital_door":
			door_type = DOOR_TYPE_DIGITAL
		elif prefab_id == "powered_gate":
			door_type = DOOR_TYPE_POWERED
		elif access_type == ACCESS_TYPE_KEY_CARD:
			door_type = DOOR_TYPE_MECHANICAL
		elif access_type in [ACCESS_TYPE_DIGITAL_KEY, ACCESS_TYPE_ACCESS_CODE, ACCESS_TYPE_TERMINAL]:
			door_type = DOOR_TYPE_DIGITAL
		elif power_behavior != POWER_BEHAVIOR_NONE:
			door_type = DOOR_TYPE_POWERED
		else:
			door_type = DOOR_TYPE_MECHANICAL
	data["door_type"] = door_type
	if door_type == DOOR_TYPE_POWERED and power_behavior == POWER_BEHAVIOR_NONE:
		power_behavior = POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED
	data["power_behavior"] = power_behavior
	data["material"] = _normalize_door_material(data.get("material", ""), object_type)
	data["door_class"] = clampi(int(data.get("door_class", 1)), 1, 3)
	if int(data["door_class"]) == 1:
		data["required_manipulator_level"] = 1
	var power_type: String = _normalized_contract_token(data.get("power_type", data.get("power_mode", "internal"))).trim_suffix("_power")
	data["power_type"] = power_type if power_type in DOOR_POWER_TYPES else "internal"
	var control_type: String = _normalized_contract_token(data.get("control_type", data.get("control_mode", "internal"))).trim_suffix("_control")
	# Historic maps serialized terminal as a Door control type. Terminal is an
	# external controller, not a third control mode, so preserve compatibility
	# while emitting only the canonical two-value contract.
	if control_type == "terminal":
		control_type = "external"
	data["control_type"] = control_type if control_type in DOOR_CONTROL_TYPES else "internal"
	data["control_mode"] = data["control_type"]
	data["has_connector_jack"] = _safe_bool_like(data.get("has_connector_jack", false), false)
	if not data.has("allowed_states"):
		data["allowed_states"] = DOOR_STATES.duplicate()
	if access_type == ACCESS_TYPE_NO_KEY:
		data["required_key_id"] = ""
		if _normalized_contract_token(data.get("state", "closed")) == "locked":
			data["state"] = "closed"
		data["is_locked"] = false
		data["locked"] = false
	return data

static func normalize_terminal_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var archetype_id: String = get_archetype_id_for_object(data)
	var object_group: String = _normalized_contract_token(data.get("object_group", data.get("group", "")))
	var object_type: String = _normalized_contract_token(data.get("object_type", ""))
	if archetype_id != "terminal" and object_group != "terminal" and not object_type.contains("terminal"):
		return data
	data["archetype_id"] = "terminal"
	data["object_group"] = "terminal"
	data["object_type"] = "terminal"
	var test_override_enabled: bool = _safe_bool_like(data.get("test_override_enabled", false), false)
	data["test_override_enabled"] = test_override_enabled
	if not data.has("status"):
		data["status"] = _normalized_contract_token(data.get("state", "active"))
	elif test_override_enabled and data.has("state") and str(data.get("state", "active")) != str(data.get("status", "active")):
		data["status"] = _normalized_contract_token(data.get("state", "active"))
	if not data.has("allowed_statuses"):
		data["allowed_statuses"] = ["active", "damaged", "unpowered"]
	var power_mode: String = _normalized_contract_token(data.get("power_type", data.get("power_mode", "internal"))).trim_suffix("_power")
	if power_mode not in ["internal", "external", "none"]:
		power_mode = "external" if bool(data.get("requires_external_power", false)) else "internal"
	var control_mode: String = _normalized_contract_token(data.get("control_type", data.get("control_mode", "internal"))).trim_suffix("_control")
	if control_mode == "terminal":
		control_mode = "external"
	if control_mode not in ["internal", "external", "none"]:
		control_mode = "internal"
	data["power_mode"] = power_mode
	data["power_type"] = power_mode
	data["control_mode"] = control_mode
	data["control_type"] = control_mode
	var status: String = _normalized_contract_token(data.get("status", data.get("state", "active")))
	var raw_state: String = _normalized_contract_token(data.get("state", status))
	var broken_states: Array[String] = ["damaged", "broken", "destroyed", "disabled", "error"]
	if test_override_enabled:
		data["status"] = status
		data["state"] = status
		data["is_powered"] = status != "unpowered" and not (status in broken_states)
	elif raw_state in broken_states or status in broken_states or bool(data.get("damaged", false)) or bool(data.get("broken", false)) or bool(data.get("destroyed", false)):
		data["status"] = raw_state if raw_state in broken_states else status
		data["state"] = str(data.get("status", "damaged"))
		data["is_powered"] = false
	elif power_mode in ["internal", "none"]:
		data["status"] = "active"
		data["state"] = "active"
		data["is_powered"] = true
	else:
		var has_physical_power: bool = bool(data.get("is_powered", false)) and (bool(data.get("cable_power_connected", false)) or not str(data.get("physical_connection_source_id", data.get("power_source_id", ""))).strip_edges().is_empty())
		data["status"] = "active" if has_physical_power else "unpowered"
		data["state"] = str(data.get("status", "unpowered"))
		data["is_powered"] = has_physical_power
	data["requires_external_power"] = power_mode == "external"
	data["can_connect_cable"] = power_mode == "external" or _safe_bool_like(data.get("can_connect_cable", false), false)
	data["has_connector_jack"] = _safe_bool_like(data.get("has_connector_jack", true), true)
	data["blocks_movement"] = true
	data["blocks_vision"] = _safe_bool_like(data.get("blocks_vision", false), false)
	data["can_interact"] = true
	return data


static func normalize_cable_install_mode(value: Variant) -> String:
	var install_mode: String = _normalized_contract_token(value)
	match install_mode:
		"", "ground", "floor_mounted", "floor_cable":
			return "floor"
		"wall", "wall_cable", "wall_surface", "surface_wall":
			return "wall"
		"hidden", "concealed", "embedded", "under_floor", "underfloor":
			return "hidden"
	return "floor"

static func normalize_switcher_type(object_data: Dictionary) -> String:
	var explicit_type: String = _normalized_contract_token(object_data.get("switcher_type", object_data.get("power_switcher_type", "")))
	if explicit_type in SWITCHER_TYPES:
		return explicit_type
	if object_data.has("switcher_lines") and object_data.get("switcher_lines", []) is Array and not Array(object_data.get("switcher_lines", [])).is_empty():
		return SWITCHER_TYPE_POWER_SWITCHER
	for light_field in ["light_group_id", "target_light_id", "linked_light_id", "target_light_ids", "linked_light_ids", "light_targets"]:
		if object_data.has(light_field):
			var value: Variant = object_data.get(light_field)
			if value is Array and not Array(value).is_empty():
				return SWITCHER_TYPE_LIGHT
			if not (value is Array) and not str(value).strip_edges().is_empty():
				return SWITCHER_TYPE_LIGHT
	return SWITCHER_TYPE_POWER_BREAKER

static func normalize_switcher_lines(object_data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var suffixes: Array[String] = ["a", "b", "c"]
	var labels: Array[String] = ["A", "B", "C"]
	var raw_lines: Variant = object_data.get("switcher_lines", [])
	if raw_lines is Array:
		for raw_line in Array(raw_lines):
			if result.size() >= 3:
				break
			if not (raw_line is Dictionary):
				continue
			var line: Dictionary = Dictionary(raw_line).duplicate(true)
			var line_id: String = str(line.get("line_id", "")).strip_edges()
			if line_id.is_empty():
				line_id = "line_%s" % suffixes[result.size()]
			var label: String = str(line.get("label", "")).strip_edges()
			if label.is_empty():
				label = "Line %s" % labels[result.size()]
			var direction: String = str(line.get("direction", line.get("branch_side", ""))).strip_edges().to_upper()
			if direction not in SWITCHER_LINE_DIRECTIONS:
				direction = ""
			var color_id: String = _normalized_contract_token(line.get("color_id", line.get("line_color_id", "")))
			if color_id.is_empty():
				color_id = SWITCHER_LINE_COLORS[result.size() % SWITCHER_LINE_COLORS.size()]
			result.append({"line_id":line_id, "label":label, "direction":direction, "color_id":color_id, "circuit_id":str(line.get("circuit_id", line.get("power_network_id", ""))).strip_edges()})
	for index in range(1, 4):
		if result.size() >= 3:
			break
		var circuit_id: String = str(object_data.get("line_%d_circuit_id" % index, "")).strip_edges()
		var direction: String = str(object_data.get("line_%d_direction" % index, "")).strip_edges().to_upper()
		var has_flat_line: bool = not circuit_id.is_empty() or (direction in SWITCHER_LINE_DIRECTIONS and not direction.is_empty())
		if not has_flat_line:
			continue
		var line_id: String = str(object_data.get("line_%d_id" % index, "line_%s" % suffixes[index - 1])).strip_edges()
		if line_id.is_empty():
			line_id = "line_%s" % suffixes[index - 1]
		var duplicate: bool = false
		for existing in result:
			if str(existing.get("line_id", "")) == line_id:
				duplicate = true
		if duplicate:
			continue
		if direction not in SWITCHER_LINE_DIRECTIONS:
			direction = ""
		var label: String = str(object_data.get("line_%d_label" % index, "Line %s" % labels[index - 1])).strip_edges()
		var color_id: String = _normalized_contract_token(object_data.get("line_%d_color_id" % index, SWITCHER_LINE_COLORS[(index - 1) % SWITCHER_LINE_COLORS.size()]))
		result.append({"line_id":line_id, "label":label, "direction":direction, "color_id":color_id, "circuit_id":circuit_id})
	return result

static func normalize_cable_health_state(value: Variant) -> String:
	var health_state: String = _normalized_contract_token(value)
	match health_state:
		"", "ok", "active", "powered", "healthy":
			return "normal"
		"damaged":
			return "damaged"
		"broken":
			return "broken"
		"cut", "severed":
			return "cut"
	return "normal"

static func normalize_cable_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var object_type: String = _normalized_contract_token(data.get("object_type", data.get("item_type", "")))
	if not object_type.contains("cable") and not object_type.contains("wire"):
		return data
	var raw_install_mode: Variant = data.get("cable_install_mode", data.get("install_mode", data.get("placement_mode", data.get("route_surface", "floor"))))
	if bool(data.get("hidden_installation", data.get("is_hidden", data.get("hidden", false)))):
		raw_install_mode = "hidden"
	var install_mode: String = normalize_cable_install_mode(raw_install_mode)
	var raw_health_state: Variant = data.get("cable_health_state", data.get("health_state", data.get("state", "normal")))
	if bool(data.get("cut", false)):
		raw_health_state = "cut"
	elif bool(data.get("broken", false)):
		raw_health_state = "broken"
	elif bool(data.get("damaged", false)):
		raw_health_state = "damaged"
	var health_state: String = normalize_cable_health_state(raw_health_state)
	data["cable_install_mode"] = install_mode
	data["install_mode"] = install_mode
	data["route_surface"] = "wall" if install_mode == "wall" else "floor"
	data["hidden_installation"] = install_mode == "hidden"
	data["is_hidden"] = install_mode == "hidden"
	data["cable_health_state"] = health_state
	data["health_state"] = health_state
	data["cut"] = health_state == "cut"
	data["broken"] = health_state == "broken"
	data["damaged"] = health_state in ["damaged", "broken", "cut"]
	if object_type == "power_cable":
		data["state"] = "ok" if health_state == "normal" else health_state
	return data


static func normalize_facing_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper()
	return side if side in FACING_SIDES else FACING_SIDE_SW

static func resolve_facing_side_from_object_data(object_data: Dictionary) -> String:
	if object_data.has("facing_side"):
		return normalize_facing_side(object_data.get("facing_side", FACING_SIDE_SW))
	var legacy_side: String = str(object_data.get("front_side", object_data.get("interaction_side", ""))).strip_edges()
	if not legacy_side.is_empty():
		return normalize_facing_side(legacy_side)
	var legacy_direction: String = str(object_data.get("facing_dir", object_data.get("direction", object_data.get("facing", "")))).strip_edges().to_lower()
	match legacy_direction:
		"se", "southeast", "south_east", "right", "east":
			return FACING_SIDE_SE
		"sw", "southwest", "south_west", "left", "south":
			return FACING_SIDE_SW
	return FACING_SIDE_SW

static func normalize_enemy_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var source_type: String = _normalized_contract_token(data.get("map_constructor_prefab_id", data.get("object_type", "")))
	if source_type in ["vagus", "bug"]:
		data["enemy_type"] = source_type
	var enemy_type: String = _normalized_contract_token(data.get("enemy_type", data.get("enemy_kind", "vagus")))
	if enemy_type not in ["vagus", "bug"]:
		enemy_type = "vagus"
	data["archetype_id"] = "enemy"
	data["object_group"] = "enemy"
	data["object_type"] = "enemy"
	data["enemy_type"] = enemy_type
	data["enemy_kind"] = enemy_type
	return data

static func normalize_world_object_contract(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = canonicalize_legacy_object_data(object_data)
	if data.is_empty():
		return data
	var object_type: String = _normalized_contract_token(data.get("object_type", ""))
	var prefab_id: String = _normalized_contract_token(data.get("map_constructor_prefab_id", object_type))
	var canonical_type: String = canonical_prefab_id(object_type)
	if is_legacy_prefab_alias(prefab_id):
		canonical_type = canonical_prefab_id(prefab_id)
		data["map_constructor_prefab_id"] = prefab_id
	data["object_type"] = canonical_type
	data = normalize_door_contract(data)
	data = normalize_terminal_contract(data)
	data = normalize_item_contract(data)
	data = normalize_archetype_object(data)
	if _normalized_contract_token(data.get("object_type", "")) == "crate" or _normalized_contract_token(data.get("archetype_id", "")) == "crate":
		data = normalize_crate_contract(data)
	if _normalized_contract_token(data.get("object_type", "")) == "enemy" or _normalized_contract_token(data.get("archetype_id", "")) == "enemy":
		data = normalize_enemy_contract(data)
	data = normalize_bipob_config_fields(data)
	data = normalize_terminal_contract(data)
	data = normalize_item_contract(data)
	data = normalize_cable_contract(data)
	var normalized_object_type: String = _normalized_contract_token(data.get("object_type", ""))
	if is_heavy_claw_movable_object(data):
		data["movable"] = true
		data["heavy_claw_movable"] = true
		if normalized_object_type in ["radiator", "cooling_radiator", "external_radiator", "external_air_cooler", "metal_cooling_block"]:
			data["object_group"] = "cooling"
		else:
			data["object_group"] = "physical_object"
		data["blocks_movement"] = true
		data["walkable"] = false
		data["passable"] = false
		data["is_obstacle"] = true
	var platform_placeable_group: String = _normalized_contract_token(data.get("object_group", data.get("group", "")))
	var platform_placeable_archetype: String = _normalized_contract_token(data.get("archetype_id", data.get("enemy_type", data.get("enemy_kind", ""))))
	var platform_placeable_types: Array[String] = ["radiator", "cooling_box", "external_air_cooler", "metal_cooling_block", "case", "crate", "normal_crate", "heavy_crate", "barrel", "box", "steel_box", "turret", "enemy", "vagus", "bug"]
	if platform_placeable_group not in ["wall", "door", "platform"] and str(data.get("placement_mode", "")).strip_edges().to_lower() != "wall_mounted" and not bool(data.get("is_wall_mounted", false)):
		if bool(data.get("movable", false)) or bool(data.get("heavy_claw_movable", false)) or normalized_object_type in platform_placeable_types or platform_placeable_archetype in platform_placeable_types or platform_placeable_group in ["enemy", "threat"]:
			data["platform_placeable"] = true
	if normalized_object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]:
		data["blocks_movement"] = true
		data["blocks_vision"] = _safe_bool_like(data.get("blocks_vision", false), false)
		data["can_interact"] = true
	if normalized_object_type in ["terminal", "fuse_box", "power_switcher", "light_switcher", "light_switch", "case", "door"] or str(data.get("object_group", "")) in ["terminal", "door"]:
		data["facing_side"] = resolve_facing_side_from_object_data(object_data)
	return data

static func normalize_bipob_config_fields(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var object_type: String = _normalized_contract_token(data.get("object_type", data.get("archetype_id", "")))
	var archetype_id: String = _normalized_contract_token(data.get("archetype_id", ""))
	if object_type != "bipob" and archetype_id != "bipob":
		return data
	data["object_type"] = "bipob"
	data["archetype_id"] = "bipob"
	data["map_constructor_prefab_id"] = "bipob"
	data["object_group"] = "bipob"
	data["configurable"] = true
	data["blocks_movement"] = true
	data["blocks_vision"] = bool(data.get("blocks_vision", false))
	data["visual_family"] = str(data.get("visual_family", "bipob"))
	data["visual_surface"] = str(data.get("visual_surface", "floor"))
	var bipob_type: String = _normalized_contract_token(data.get("bipob_type", data.get("type", "scout")))
	data["bipob_type"] = bipob_type if BIPOB_TYPES.has(bipob_type) else "scout"
	var status: String = _normalized_contract_token(data.get("bipob_status", data.get("status", data.get("state", "disabled"))))
	if status in ["corrupted", "corrupt"]:
		status = "infected"
	if status in ["damaged", "destroyed"]:
		status = "broken"
	data["bipob_status"] = status if BIPOB_STATUSES.has(status) else "disabled"
	var alignment: String = _normalized_contract_token(data.get("bipob_alignment", data.get("alignment", "friendly")))
	data["bipob_alignment"] = alignment if BIPOB_ALIGNMENTS.has(alignment) else "friendly"
	if data["bipob_status"] == "infected":
		data["bipob_alignment"] = "hostile"
	var chassis_type: String = _normalized_contract_token(data.get("chassis_type", "wheels"))
	data["chassis_type"] = chassis_type if BIPOB_CHASSIS_TYPES.has(chassis_type) else "wheels"
	var visor_type: String = _normalized_contract_token(data.get("visor_type", "basic"))
	data["visor_type"] = visor_type if BIPOB_VISOR_TYPES.has(visor_type) else "basic"
	var loadout_profile: String = _normalized_contract_token(data.get("loadout_profile", "none"))
	data["loadout_profile"] = loadout_profile if BIPOB_LOADOUT_PROFILES.has(loadout_profile) else "none"
	data["status"] = data["bipob_status"]
	data["state"] = data["bipob_status"]
	data["display_name"] = "Bipob"
	return data

static func _contains_cyrillic(value: Variant) -> bool:
	var text: String = str(value)
	for index in range(text.length()):
		var codepoint: int = text.unicode_at(index)
		if codepoint >= 0x0400 and codepoint <= 0x04ff:
			return true
	return false

static func validate_archetype_object(object_data: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var archetype_id: String = get_archetype_id_for_object(object_data)
	if _normalized_contract_token(object_data.get("archetype_id", "")).is_empty():
		warnings.append("object_missing_archetype_id")
	if archetype_id.is_empty():
		return warnings
	if not bool(object_data.get("normalized_by_archetype_catalog", false)):
		warnings.append("object_bypassed_archetype_normalization")
	for field_variant in get_archetype_property_schema(archetype_id):
		var field: Dictionary = field_variant
		var field_name: String = str(field.get("field", ""))
		if not object_data.has(field_name):
			warnings.append("object_missing_schema_field_%s" % field_name)
			continue
		var field_type: String = str(field.get("type", ""))
		var allowed: Array = Array(field.get("values", []))
		if field_type == "enum" and not allowed.has(object_data.get(field_name)):
			warnings.append("object_invalid_enum_%s" % field_name)
		elif field_type == "bool" and not _is_bool_like(object_data.get(field_name)):
			warnings.append("object_invalid_bool_%s" % field_name)
		elif field_type == "enum_array":
			for value_variant in Array(object_data.get(field_name, [])):
				if not allowed.has(value_variant):
					warnings.append("object_invalid_enum_array_%s" % field_name)
	if object_data.has("allowed_states") and not Array(object_data.get("allowed_states", [])).has(object_data.get("state")):
		warnings.append("object_state_not_allowed")
	if object_data.has("allowed_statuses") and not Array(object_data.get("allowed_statuses", [])).has(object_data.get("status")):
		warnings.append("object_status_not_allowed")
	if archetype_id == "item":
		var item_class: String = _normalized_contract_token(object_data.get("item_class", ""))
		if not ITEM_CLASSES.has(item_class):
			warnings.append("item_invalid_item_class")
		if str(object_data.get("display_name", "")) != generate_display_name(object_data):
			warnings.append("item_display_name_not_generated_from_item_class")
		var storage_route: String = _normalized_contract_token(object_data.get("storage_route", ""))
		var storage_type: String = _normalized_contract_token(object_data.get("storage_type", ""))
		if item_class == ITEM_CLASS_KEY_CARD and (storage_route != ITEM_STORAGE_ROUTE_KEYCHAIN or storage_type != ITEM_STORAGE_ROUTE_KEYCHAIN):
			warnings.append("item_key_card_storage_must_be_keychain")
		elif item_class in [ITEM_CLASS_DIGITAL_KEY, ITEM_CLASS_ACCESS_CODE, ITEM_CLASS_DATA_FILE] and (storage_route != ITEM_STORAGE_ROUTE_DIGITAL_STORAGE or storage_type != ITEM_STORAGE_ROUTE_DIGITAL_STORAGE):
			warnings.append("item_digital_storage_must_be_digital_storage")
		elif item_class == ITEM_CLASS_PHYSICAL_ITEM and (storage_route != ITEM_STORAGE_ROUTE_POCKET or storage_type != ITEM_STORAGE_ROUTE_POCKET):
			warnings.append("item_physical_storage_must_be_pocket")
		for key_field in ["item_type", "key_type", "key_kind"]:
			if _normalized_contract_token(object_data.get(key_field, "")) in ["mechanical_key", "mechanical_keycard", "keycard"]:
				warnings.append("item_legacy_key_value_remains_%s" % key_field)
	if archetype_id == "floor" and str(object_data.get("display_name", "")) != generate_display_name(object_data):
		warnings.append("floor_display_name_not_generated_from_material")
	if archetype_id == "terminal":
		if str(object_data.get("display_name", "")) != generate_display_name(object_data):
			warnings.append("terminal_display_name_not_generated_from_properties")
		if _contains_cyrillic(object_data.get("display_name", "")):
			warnings.append("terminal_display_name_contains_localized_text")
		for schema_variant in get_archetype_property_schema("terminal"):
			var labels: Dictionary = Dictionary(schema_variant).get("labels", {})
			for label_variant in labels.values():
				if _contains_cyrillic(label_variant):
					warnings.append("terminal_schema_contains_localized_label")
		if not bool(object_data.get("blocks_movement", false)):
			warnings.append("terminal_must_block_movement")
	if UTILITY_ITEM_ARCHETYPE_IDS.has(archetype_id):
		var expected_utility_type: String = _normalized_contract_token(get_archetype_definition(archetype_id).get("object_type", archetype_id))
		if _normalized_contract_token(object_data.get("object_group", "")) != "item":
			warnings.append("utility_object_group_not_item")
		if _normalized_contract_token(object_data.get("object_type", "")) != expected_utility_type:
			warnings.append("utility_object_type_not_runtime_compatible")
		if str(object_data.get("display_name", "")) != generate_display_name(object_data):
			warnings.append("utility_display_name_not_generated")
		if _contains_cyrillic(object_data.get("display_name", "")):
			warnings.append("utility_display_name_contains_localized_text")

		if archetype_id == "power_cable_reel":
			for cable_field in ["max_cable_length", "cable_path_cells", "cable_length", "cable_endpoint_a_id", "cable_endpoint_b_id", "connected", "disconnected", "end_1_target_id", "end_2_target_id"]:
				if not object_data.has(cable_field):
					warnings.append("power_cable_reel_missing_%s" % cable_field)
		elif archetype_id == "fuse":
			if not object_data.has("consumable") or not object_data.has("fits_targets"):
				warnings.append("fuse_missing_runtime_storage_fields")
			if _normalized_contract_token(object_data.get("item_class", "")) in [ITEM_CLASS_KEY_CARD, ITEM_CLASS_DIGITAL_KEY, ITEM_CLASS_ACCESS_CODE]:
				warnings.append("fuse_uses_access_item_class")
	if archetype_id == "door":
		var state: String = str(object_data.get("state", ""))
		var expected_open: bool = state == "open"
		var expected_closed: bool = state in ["closed", "locked", "jammed", "unpowered"]
		var expected_locked: bool = state == "locked"
		var expected_damaged: bool = state in ["damaged", "broken", "destroyed"]
		if _normalized_contract_token(object_data.get("object_type", "")) != "door":
			warnings.append("door_object_type_not_canonical")
		if _normalized_contract_token(object_data.get("object_group", "")) != "door":
			warnings.append("door_object_group_not_canonical")
		if _normalized_contract_token(object_data.get("control_type", "internal")) == "terminal":
			warnings.append("door_legacy_terminal_control_type_must_normalize_external")
		if _normalized_contract_token(object_data.get("control_type", "internal")) not in DOOR_CONTROL_TYPES:
			warnings.append("door_invalid_control_type")
		var door_access_type: String = normalize_access_type(object_data.get("access_type", ACCESS_TYPE_NO_KEY))
		if door_access_type in [ACCESS_TYPE_DIGITAL_KEY, ACCESS_TYPE_ACCESS_CODE] and not bool(object_data.get("has_connector_jack", false)):
			warnings.append("door_connector_jack_required_for_%s" % door_access_type)
		if str(object_data.get("display_name", "")) != generate_display_name(object_data):
			warnings.append("door_display_name_not_generated_from_properties")
		if is_legacy_door_object_type(_normalized_contract_token(object_data.get("object_type", ""))):
			warnings.append("door_legacy_object_type_remains_after_normalization")
		var movement_out_of_sync: bool = not object_data.has("blocks_movement_override") and bool(object_data.get("blocks_movement", false)) != expected_closed
		var vision_out_of_sync: bool = not object_data.has("blocks_vision_override") and bool(object_data.get("blocks_vision", false)) != (expected_closed and bool(object_data.get("blocks_vision_when_closed", false)))
		if bool(object_data.get("is_open", false)) != expected_open or bool(object_data.get("is_closed", false)) != expected_closed or bool(object_data.get("is_locked", false)) != expected_locked or bool(object_data.get("locked", false)) != expected_locked or bool(object_data.get("damaged", false)) != expected_damaged or movement_out_of_sync or vision_out_of_sync:
			warnings.append("object_derived_state_flags_out_of_sync")
		if _normalized_contract_token(object_data.get("access_type", "")) == ACCESS_TYPE_NO_KEY:
			if not _safe_string(object_data.get("required_key_id", "")).is_empty():
				warnings.append("no_key_door_requires_key")
			if state == "locked" or bool(object_data.get("is_locked", false)) or bool(object_data.get("locked", false)):
				warnings.append("no_key_door_remains_locked")
	return warnings

static func validate_object_registry_contract() -> Array[String]:
	var warnings: Array[String] = []
	var door_definition: Dictionary = get_archetype_definition("door")
	if _normalized_contract_token(door_definition.get("object_type", "")) != "door":
		warnings.append("door_archetype_object_type_not_canonical")
	var door_schema_fields: Array[String] = []
	for field_variant in get_archetype_property_schema("door"):
		door_schema_fields.append(str(Dictionary(field_variant).get("field", "")))
	for required_field in ["door_type", "material", "access_type", "door_class", "power_type", "control_type", "power_behavior", "state", "allowed_states"]:
		if required_field not in door_schema_fields:
			warnings.append("door_archetype_schema_missing_%s" % required_field)
	var door_palette_count: int = 0
	for palette_row in get_constructor_palette_rows():
		var palette_id: String = _normalized_contract_token(Dictionary(palette_row).get("id", ""))
		if palette_id == "door":
			door_palette_count += 1
		elif is_legacy_door_object_type(palette_id):
			warnings.append("door_legacy_alias_exposed_in_palette_%s" % palette_id)
	if door_palette_count != 1:
		warnings.append("door_palette_row_count_%d" % door_palette_count)
	for legacy_door_id_variant in LEGACY_DOOR_ALIAS_CONFIGS.keys():
		var legacy_door_id: String = str(legacy_door_id_variant)
		var normalized_legacy_door: Dictionary = create_world_object(legacy_door_id, "validation_%s" % legacy_door_id)
		if _normalized_contract_token(normalized_legacy_door.get("archetype_id", "")) != "door" or _normalized_contract_token(normalized_legacy_door.get("object_group", "")) != "door" or _normalized_contract_token(normalized_legacy_door.get("object_type", "")) != "door":
			warnings.append("door_legacy_alias_not_normalized_%s" % legacy_door_id)
	for legacy_object_type_variant in DOOR_MATERIAL_BY_OBJECT_TYPE.keys():
		var legacy_object_type: String = str(legacy_object_type_variant)
		if bool(Dictionary(OBJECT_LIBRARY.get(legacy_object_type, {})).get("placeable_in_constructor", true)):
			warnings.append("door_legacy_library_object_placeable_%s" % legacy_object_type)
	for alias_variant in PREFAB_ALIASES.keys():
		var alias_id: String = str(alias_variant)
		var target_id: String = canonical_prefab_id(alias_id)
		if not OBJECT_LIBRARY.has(target_id) and not ARCHETYPE_REGISTRY.has(target_id):
			warnings.append("prefab_alias_target_missing_%s_%s" % [alias_id, target_id])
			continue
		var alias_data: Dictionary = create_world_object(alias_id, "validation_%s" % alias_id)
		if alias_data.is_empty() or (not OBJECT_LIBRARY.has(str(alias_data.get("object_type", ""))) and not ARCHETYPE_REGISTRY.has(str(alias_data.get("archetype_id", "")))):
			warnings.append("prefab_alias_creates_unknown_runtime_object_%s" % alias_id)
		if target_id != "floor":
			for required_field in ["door_type", "material", "access_type", "door_class"]:
				if not alias_data.has(required_field) or _normalized_contract_token(alias_data.get(required_field, "")).is_empty():
					warnings.append("prefab_alias_missing_%s_%s" % [required_field, alias_id])
	for object_type_variant in OBJECT_LIBRARY.keys():
		var object_type: String = str(object_type_variant)
		var definition: Dictionary = OBJECT_LIBRARY[object_type]
		if _normalized_contract_token(definition.get("group", "")) != "door":
			continue
		var data: Dictionary = create_world_object(object_type, "validation_%s" % object_type)
		for required_field in ["door_type", "material", "access_type"]:
			if _normalized_contract_token(data.get(required_field, "")).is_empty():
				warnings.append("door_missing_%s_%s" % [required_field, object_type])
		if DOOR_MATERIAL_BY_OBJECT_TYPE.has(object_type) and _normalized_contract_token(data.get("material", "")).is_empty():
			warnings.append("material_like_door_missing_material_%s" % object_type)
		var access_type: String = _normalized_contract_token(data.get("access_type", ""))
		if access_type not in ACCESS_TYPES:
			warnings.append("door_access_type_unknown_%s_%s" % [object_type, access_type])
		var raw_lock_type: String = _normalized_contract_token(definition.get("lock_type", ""))
		if raw_lock_type.contains("mechanical") and normalize_access_type(raw_lock_type) != ACCESS_TYPE_KEY_CARD:
			warnings.append("door_unknown_mechanical_key_naming_%s_%s" % [object_type, raw_lock_type])
		var raw_access_type: String = normalize_access_type(definition.get("access_type", raw_lock_type))
		var raw_required_key_id: String = _safe_string(definition.get("required_key_id", ""))
		if raw_access_type == ACCESS_TYPE_NO_KEY and not raw_required_key_id.is_empty():
			warnings.append("no_key_door_requires_key_%s" % object_type)
			if bool(definition.get("is_locked", definition.get("locked", false))) or _normalized_contract_token(definition.get("state", "")) == "locked":
				warnings.append("no_key_door_locked_by_key_requirement_%s" % object_type)
		if access_type == ACCESS_TYPE_NO_KEY:
			if not _safe_string(data.get("required_key_id", "")).is_empty():
				warnings.append("normalized_no_key_door_requires_key_%s" % object_type)
			if bool(data.get("is_locked", false)):
				warnings.append("normalized_no_key_door_remains_locked_%s" % object_type)
	return warnings


static func normalize_door_state_fields(object_data: Dictionary) -> Dictionary:
	if object_data.is_empty():
		return object_data
	var group_text := _safe_string(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower()
	var type_text := _safe_string(object_data.get("object_type", "")).strip_edges().to_lower()
	if group_text != "door" and not type_text.contains("door") and not type_text.contains("gate"):
		return object_data
	var access_type: String = normalize_access_type(object_data.get("access_type", object_data.get("lock_type", ACCESS_TYPE_NO_KEY)))
	object_data["access_type"] = access_type
	object_data["lock_type"] = _legacy_lock_type_for_access_type(access_type)
	var state := _safe_string(object_data.get("state", "closed"), "closed").strip_edges().to_lower()
	var power_type: String = _normalized_contract_token(object_data.get("power_type", object_data.get("power_mode", "internal"))).trim_suffix("_power")
	if power_type == "internal" and state == "unpowered":
		state = "closed"
	if not object_data.has("allowed_states"):
		object_data["allowed_states"] = DOOR_STATES.duplicate()
	if access_type == ACCESS_TYPE_NO_KEY:
		object_data["required_key_id"] = ""
		object_data["is_locked"] = false
		object_data["locked"] = false
		if state == "locked":
			state = "closed"
	if state == "opened":
		state = "open"
	if state == "":
		state = "closed"
	var was_normalized: bool = bool(object_data.get("normalized_by_archetype_catalog", false))
	var damaged_flag: bool = state in ["damaged", "broken", "destroyed"]
	if not was_normalized:
		damaged_flag = bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)) or damaged_flag
		if bool(object_data.get("is_open", false)) and not damaged_flag and state not in ["locked", "jammed"]:
			state = "open"
		if bool(object_data.get("is_locked", object_data.get("locked", false))) and not damaged_flag and state != "open":
			state = "locked"
	var destroyed := bool(object_data.get("destroyed", false)) or state == "destroyed"
	var open_state := state == "open"
	var closed_state := state in ["closed", "locked", "jammed", "unpowered"] and not destroyed
	var locked_state := state == "locked"
	object_data["state"] = state
	object_data["is_open"] = open_state
	object_data["is_closed"] = closed_state
	object_data["is_locked"] = locked_state
	object_data["locked"] = locked_state
	object_data["damaged"] = damaged_flag
	if not object_data.has("blocks_movement_override"):
		object_data["blocks_movement"] = closed_state and not destroyed
	if not object_data.has("blocks_vision_override"):
		if not object_data.has("blocks_vision_when_closed"):
			object_data["blocks_vision_when_closed"] = bool(object_data.get("blocks_vision", false))
		object_data["blocks_vision"] = closed_state and not destroyed and bool(object_data.get("blocks_vision_when_closed", false))
	return object_data

static func get_archetype_definition(archetype_id: String) -> Dictionary:
	var definition: Variant = ARCHETYPE_REGISTRY.get(_normalized_contract_token(archetype_id), {})
	return definition.duplicate(true) if definition is Dictionary else {}

static func get_archetype_property_schema(archetype_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definition: Dictionary = get_archetype_definition(archetype_id)
	var raw_schema: Variant = definition.get("property_schema", [])
	if raw_schema is Array:
		for entry_variant in raw_schema:
			if entry_variant is Dictionary:
				result.append(Dictionary(entry_variant).duplicate(true))
	return result

static func get_archetype_id_for_object(object_data: Dictionary) -> String:
	var explicit_id: String = _normalized_contract_token(object_data.get("archetype_id", ""))
	if ARCHETYPE_REGISTRY.has(explicit_id):
		return explicit_id
	var object_type: String = _normalized_contract_token(object_data.get("object_type", ""))
	if ARCHETYPE_REGISTRY.has(object_type):
		return object_type
	var group_id: String = _normalized_contract_token(object_data.get("object_group", object_data.get("group", "")))
	if ARCHETYPE_REGISTRY.has(group_id) and group_id != "item":
		return group_id
	return ""

static func _schema_defaults(archetype_id: String) -> Dictionary:
	var defaults: Dictionary = {}
	for field_variant in get_archetype_property_schema(archetype_id):
		var field: Dictionary = field_variant
		defaults[str(field.get("field", ""))] = field.get("default")
	return defaults

static func _normalize_wall_material(value: Variant) -> String:
	var material: String = _normalized_contract_token(value)
	return material if WALL_MATERIALS.has(material) or BREACHABLE_WALL_MATERIALS.has(material) else WALL_MATERIAL_BRICK


static func normalize_breach_side(value: Variant) -> String:
	var side: String = _normalized_contract_token(value)
	match side:
		"up", "top", "n":
			return "north"
		"right", "e":
			return "east"
		"down", "bottom", "s":
			return "south"
		"left", "w":
			return "west"
	return side if WALL_SIDES.has(side) else "north"


static func normalize_breachable_wall_material(value: Variant) -> String:
	var material: String = _normalized_contract_token(value)
	if material == "concrete":
		return WALL_MATERIAL_BREACHABLE_CONCRETE
	if material == "brick":
		return WALL_MATERIAL_BREACHABLE_BRICK
	return material if BREACHABLE_WALL_MATERIALS.has(material) else WALL_MATERIAL_BREACHABLE_CONCRETE


static func normalize_breachable_wall_height(value: Variant) -> String:
	var height: String = _normalized_contract_token(value)
	height = height.replace(" ", "").replace("-", "").replace("_", "")
	match height:
		"high", "highest", "tallest":
			return "tall"
		"medium", "middle":
			return "mid"
		"half", "halfmedium", "uppermid":
			return "halfmid"
	return height if BREACHABLE_WALL_HEIGHTS.has(height) else "mid"


static func normalize_breachable_wall_breach_side(value: Variant) -> String:
	var side: String = _normalized_contract_token(value)
	match side:
		"southwest", "south_west", "left_front", "south":
			return "sw"
		"southeast", "south_east", "right_front", "east":
			return "se"
		"northwest", "north_west", "left_back", "west":
			return "nw"
		"northeast", "north_east", "right_back", "north":
			return "ne"
	return side if side in ["sw", "se", "nw", "ne"] else "sw"


static func get_grid_side_for_breachable_wall_breach_side(breach_side: Variant) -> String:
	# Grid-to-isometric projection maps grid north/east/south/west to visual
	# NE/SE/SW/NW respectively. Breachable Wall side ids are visual iso sides.
	match normalize_breachable_wall_breach_side(breach_side):
		"sw":
			return "south"
		"se":
			return "east"
		"nw":
			return "west"
		"ne":
			return "north"
	return "south"


static func is_breachable_wall(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	return _normalized_contract_token(object_data.get("archetype_id", "")) == "breachable_wall" or _normalized_contract_token(object_data.get("object_type", "")) == "breachable_wall" or _normalized_contract_token(object_data.get("legacy_object_type", "")) == "breachable_wall" or bool(object_data.get("is_breachable_wall", false))


static func wall_side_delta(side: String) -> Vector2i:
	match normalize_breach_side(side):
		"north":
			return Vector2i(0, -1)
		"east":
			return Vector2i(1, 0)
		"south":
			return Vector2i(0, 1)
		"west":
			return Vector2i(-1, 0)
	return Vector2i.ZERO


static func get_wall_side_for_adjacent_actor(wall_cell: Vector2i, actor_cell: Vector2i) -> String:
	var offset: Vector2i = actor_cell - wall_cell
	for side in WALL_SIDES:
		if wall_side_delta(side) == offset:
			return side
	return ""


static func can_heavy_claw_breach_wall_from_side(object_data: Dictionary, actor_side: String) -> bool:
	if not is_breachable_wall(object_data):
		return false
	if str(object_data.get("breach_state", object_data.get("state", "active"))).strip_edges().to_lower() in ["open", "destroyed", "breached", "removed"]:
		return false
	var breach_side: String = normalize_breachable_wall_breach_side(object_data.get("breach_side", "sw"))
	return normalize_breach_side(actor_side) == get_grid_side_for_breachable_wall_breach_side(breach_side)

static func _label_for_id(value: Variant) -> String:
	return _normalized_contract_token(value).replace("_", " ").capitalize()

static func generate_display_name(object_data: Dictionary) -> String:
	var archetype_id: String = get_archetype_id_for_object(object_data)
	if archetype_id == "item":
		return str(ITEM_DISPLAY_NAMES.get(normalize_item_class(object_data.get("item_class", "physical_item")), "Physical Item"))
	if archetype_id == "terminal":
		if _normalized_contract_token(object_data.get("terminal_type", "information")) != "control":
			return "Information Terminal"
		var target_type: String = _normalized_contract_token(object_data.get("controlled_target_type", "none"))
		if target_type == "none":
			return "Control Terminal"
		return "%s Control Terminal" % _label_for_id(target_type)
	var definition: Dictionary = get_archetype_definition(archetype_id)
	var template: String = str(definition.get("display_name_template", object_data.get("display_name", archetype_id.capitalize())))
	for field_variant in get_archetype_property_schema(archetype_id):
		var field: Dictionary = field_variant
		var field_name: String = str(field.get("field", ""))
		template = template.replace("{%s_label}" % field_name, _label_for_id(object_data.get(field_name, field.get("default", ""))))
	return template

static func normalize_archetype_object(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var archetype_id: String = get_archetype_id_for_object(data)
	if archetype_id.is_empty():
		return data
	var definition: Dictionary = get_archetype_definition(archetype_id)
	data["archetype_id"] = archetype_id
	data["object_group"] = str(definition.get("object_group", archetype_id))
	data["object_type"] = str(definition.get("object_type", archetype_id))
	for definition_key_variant in definition.keys():
		var definition_key: String = str(definition_key_variant)
		if definition_key in ["archetype_id", "object_group", "object_type", "palette_label", "display_name_template", "property_schema"]:
			continue
		if not data.has(definition_key):
			data[definition_key] = definition[definition_key]
	for fixed_field in ["material", "is_destructible", "supports_embedded_objects", "supports_cables", "configurable", "blocks_movement", "blocks_vision"]:
		if definition.has(fixed_field) and (archetype_id == "external_wall" or not data.has(fixed_field)):
			data[fixed_field] = definition[fixed_field]
	for key_variant in _schema_defaults(archetype_id).keys():
		var key: String = str(key_variant)
		if not data.has(key):
			data[key] = _schema_defaults(archetype_id)[key]
	if archetype_id == "enemy":
		data = normalize_enemy_contract(data)
	if archetype_id == "wall":
		data["material"] = _normalize_wall_material(data.get("material", WALL_MATERIAL_BRICK))
		var breachable_by_material: bool = BREACHABLE_WALL_MATERIALS.has(str(data.get("material", "")))
		data["is_breachable_wall"] = _safe_bool_like(data.get("is_breachable_wall", data.get("breachable", breachable_by_material)), breachable_by_material)
		data["wall_height"] = normalize_breachable_wall_height(data.get("wall_height", "mid"))
		data["breach_side"] = normalize_breachable_wall_breach_side(data.get("breach_side", "sw"))
		data["heavy_claw_breachable"] = bool(data.get("is_breachable_wall", false))
		if bool(data.get("is_breachable_wall", false)):
			data["supports_embedded_objects"] = false
			data["supports_cables"] = false
	if archetype_id == "power_switcher":
		if not object_data.has("switcher_type") and str(data.get("switcher_type", "")) == SWITCHER_TYPE_POWER_BREAKER:
			data.erase("switcher_type")
		data["switcher_type"] = normalize_switcher_type(data)
		data["switcher_lines"] = normalize_switcher_lines(data)
		if data["switcher_type"] == SWITCHER_TYPE_POWER_SWITCHER and not Array(data.get("switcher_lines", [])).is_empty():
			var active_line_id: String = str(data.get("active_line_id", "")).strip_edges()
			var active_found: bool = false
			var active_color_id: String = ""
			for line_variant in Array(data.get("switcher_lines", [])):
				var line: Dictionary = Dictionary(line_variant)
				if str(line.get("line_id", "")) == active_line_id:
					active_found = true
					active_color_id = str(line.get("color_id", ""))
			if active_line_id.is_empty() or not active_found:
				var first_line: Dictionary = Dictionary(Array(data.get("switcher_lines", []))[0])
				data["active_line_id"] = str(first_line.get("line_id", ""))
				active_color_id = str(first_line.get("color_id", ""))
			if not active_color_id.is_empty():
				data["line_color_id"] = active_color_id
		data["mount"] = _normalized_contract_token(data.get("mount", data.get("install_mode", "floor")))
		if data["mount"] == "wall_mounted":
			data["mount"] = "wall"
		if data["mount"] not in ["floor", "wall"]:
			data["mount"] = "floor"
		data["install_mode"] = data["mount"]
		data["placement_mode"] = "wall_mounted" if data["mount"] == "wall" else "object"
		data["switch_state"] = _normalized_contract_token(data.get("switch_state", ""))
		if data["switch_state"] not in ["on", "off"]:
			data["switch_state"] = "on" if _safe_bool_like(data.get("is_on", false), _normalized_contract_token(data.get("state", "switch_off")) in ["on", "switch_on"]) else "off"
		data["state"] = "switch_on" if data["switch_state"] == "on" else "switch_off"
		data["is_on"] = data["switch_state"] == "on"
	if archetype_id == "fuse_box":
		data["mount"] = _normalized_contract_token(data.get("mount", data.get("install_mode", "floor")))
		if data["mount"] == "wall_mounted":
			data["mount"] = "wall"
		if data["mount"] not in ["floor", "wall"]:
			data["mount"] = "floor"
		data["install_mode"] = data["mount"]
		data["placement_mode"] = "wall_mounted" if data["mount"] == "wall" else "object"
		data["fuse_present"] = _safe_bool_like(data.get("fuse_present", data.get("fuse_installed", true)), true)
		data["fuse_installed"] = data["fuse_present"]
		data["state"] = "installed" if data["fuse_present"] else "empty"
	if archetype_id == "power_socket":
		data["mount"] = _normalized_contract_token(data.get("mount", data.get("install_mode", "floor")))
		if data["mount"] == "wall_mounted":
			data["mount"] = "wall"
		if data["mount"] not in ["floor", "wall"]:
			data["mount"] = "floor"
		data["install_mode"] = data["mount"]
		data["placement_mode"] = "wall_mounted" if data["mount"] == "wall" else "object"
		data["can_connect_cable"] = _safe_bool_like(data.get("can_connect_cable", true), true)
	if archetype_id == "power_cable_reel":
		data["mount"] = _normalized_contract_token(data.get("mount", data.get("cable_install_mode", data.get("install_mode", "floor"))))
		if data["mount"] == "wall_mounted":
			data["mount"] = "wall"
		if data["mount"] not in ["floor", "wall"]:
			data["mount"] = "floor"
		data["cable_install_mode"] = data["mount"]
		data["install_mode"] = data["mount"]
		data["route_surface"] = data["mount"]
		data["placement_mode"] = "object"
		data["hidden_installation"] = false
		data["is_hidden"] = false
	if archetype_id == "door":
		data["power_mode"] = str(data.get("power_type", data.get("power_mode", "internal")))
		data["control_mode"] = str(data.get("control_type", data.get("control_mode", "internal")))
	elif archetype_id == "terminal":
		data = normalize_terminal_contract(data)
	elif archetype_id == "platform":
		data = PlatformTypesRef.normalize_platform_config(data)
		data["object_group"] = "platform"
		data["archetype_id"] = "platform"
		data["configurable"] = true
		data["blocks_movement"] = false
		data["blocks_vision"] = false
		data["walkable"] = true
	elif archetype_id == "item":
		data = normalize_item_contract(data)
	elif archetype_id == "bipob":
		data = normalize_bipob_config_fields(data)
	data["display_name"] = generate_display_name(data)
	data["normalized_by_archetype_catalog"] = true
	return data

static func create_archetype_object(archetype_id: String, id_override: String = "", overrides: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = get_archetype_definition(archetype_id)
	if definition.is_empty():
		return {}
	var runtime_type: String = str(definition.get("object_type", archetype_id))
	var data: Dictionary = _create_library_object(runtime_type, id_override) if runtime_type == archetype_id else create_world_object(runtime_type, id_override)
	if data.is_empty():
		var object_id: String = id_override if not id_override.is_empty() else "%s_%s" % [archetype_id, str(Time.get_unix_time_from_system())]
		data = WorldObjectDataRef.create_base(object_id, str(definition.get("palette_label", archetype_id.capitalize())), str(definition.get("object_group", archetype_id)), runtime_type)
	data["archetype_id"] = archetype_id
	for key_variant in overrides.keys():
		data[str(key_variant)] = overrides[key_variant]
	if archetype_id == "terminal" and overrides.has("status"):
		data["state"] = overrides["status"]
	return normalize_door_state_fields(normalize_world_object_contract(normalize_archetype_object(data)))

static func _create_library_object(object_type: String, id_override: String = "") -> Dictionary:
	var canonical_type: String = canonical_object_type(object_type)
	if ARCHETYPE_REGISTRY.has(canonical_type) and object_type != canonical_type:
		var archetype_data: Dictionary = create_archetype_object(canonical_type, id_override, get_prefab_alias_defaults(object_type))
		return mark_legacy_source(archetype_data, object_type) if is_legacy_prefab_alias(object_type) else archetype_data
	if not OBJECT_LIBRARY.has(canonical_type):
		return {}
	var def: Dictionary = OBJECT_LIBRARY[canonical_type]
	var object_id := id_override if id_override != "" else "%s_%s" % [canonical_type, str(Time.get_unix_time_from_system())]
	var data := WorldObjectDataRef.create_base(object_id, def.get("name", canonical_type), def.get("group", "physical_object"), canonical_type)
	for key in def.keys():
		if key == "name" or key == "group":
			continue
		data[key] = def[key]
	if data.has("durability"):
		data["durability_max"] = data["durability"]
		data["durability_current"] = data["durability"]
		data.erase("durability")
	if data.get("indestructible", false):
		data["invulnerable"] = true
	if data.get("invulnerable_while_powered", false) and data.get("is_powered", true):
		data["invulnerable"] = true
	data = apply_prefab_alias_defaults(canonical_type, object_type, data)
	var alias_defaults: Dictionary = get_prefab_alias_defaults(object_type)
	for key_variant in alias_defaults.keys():
		data[str(key_variant)] = alias_defaults[key_variant]
	data = normalize_world_object_contract(data)
	data = update_world_object_heat_state(data)
	return normalize_door_state_fields(data)

static func create_world_object(object_type: String, id_override: String = "") -> Dictionary:
	var normalized_type: String = _normalized_contract_token(object_type)
	if is_legacy_prefab_alias(normalized_type):
		var canonical_type: String = canonical_prefab_id(normalized_type)
		if ARCHETYPE_REGISTRY.has(canonical_type):
			var archetype_data: Dictionary = create_archetype_object(canonical_type, id_override, get_prefab_alias_defaults(normalized_type))
			return mark_legacy_source(archetype_data, normalized_type)
	if ARCHETYPE_REGISTRY.has(normalized_type):
		return create_archetype_object(normalized_type, id_override)
	return _create_library_object(object_type, id_override)

static func get_world_object_working_heat(object_data: Dictionary) -> int:
	return _safe_non_negative_int(object_data.get("working_heat", 0))

# Persistent world heat uses only working + connection heat minus cooling.
# Temporary action heat (for example terminal hack heat) is never stored in object data.
static func get_world_object_current_heat(object_data: Dictionary) -> int:
	var working_heat := get_world_object_working_heat(object_data)
	var connection_heat := _safe_non_negative_int(object_data.get("heat_from_connections", 0))
	var cooling := _safe_non_negative_int(object_data.get("cooling_received", 0))
	return maxi(0, working_heat + connection_heat - cooling)

static func get_world_object_current_heat_with_temporary_heat(object_data: Dictionary, temporary_heat: int = 0) -> int:
	var working_heat := get_world_object_working_heat(object_data)
	var connection_heat := _safe_non_negative_int(object_data.get("heat_from_connections", 0))
	var cooling := _safe_non_negative_int(object_data.get("cooling_received", 0))
	var extra_heat := maxi(0, temporary_heat)
	return maxi(0, working_heat + connection_heat + extra_heat - cooling)

static func would_world_object_overheat_with_temporary_heat(object_data: Dictionary, temporary_heat: int = 0) -> bool:
	var threshold := _safe_non_negative_int(object_data.get("overheat_threshold", 0))
	if threshold <= 0:
		return false
	return get_world_object_current_heat_with_temporary_heat(object_data, temporary_heat) >= threshold

static func get_world_object_heat_breakdown(object_data: Dictionary, temporary_heat: int = 0) -> Dictionary:
	var threshold := _safe_non_negative_int(object_data.get("overheat_threshold", 0))
	var current_heat := get_world_object_current_heat_with_temporary_heat(object_data, temporary_heat)
	var would_overheat := false
	if threshold > 0:
		would_overheat = current_heat >= threshold
	return {
		"working_heat": get_world_object_working_heat(object_data),
		"heat_from_connections": _safe_non_negative_int(object_data.get("heat_from_connections", 0)),
		"temporary_heat": maxi(0, temporary_heat),
		"cooling_received": _safe_non_negative_int(object_data.get("cooling_received", 0)),
		"current_heat": current_heat,
		"threshold": threshold,
		"would_overheat": would_overheat,
		"state": _safe_string(object_data.get("state", "active"))
	}

static func is_world_object_overheated(object_data: Dictionary) -> bool:
	var threshold := _safe_non_negative_int(object_data.get("overheat_threshold", 0))
	if threshold <= 0:
		return false
	return get_world_object_current_heat(object_data) >= threshold

static func update_world_object_heat_state(object_data: Dictionary) -> Dictionary:
	if object_data.is_empty():
		return object_data
	if not object_data.has("working_heat") and not object_data.has("overheat_threshold") and not object_data.has("cooling_received"):
		return object_data
	var state := _safe_string(object_data.get("state", "active"), "active")
	object_data["working_heat"] = get_world_object_working_heat(object_data)
	object_data["heat_from_connections"] = _safe_non_negative_int(object_data.get("heat_from_connections", 0))
	object_data["cooling_received"] = _safe_non_negative_int(object_data.get("cooling_received", 0))
	object_data["current_heat"] = get_world_object_current_heat(object_data)
	if is_world_object_overheated(object_data):
		if state != "overheated":
			if not ["destroyed", "damaged"].has(state):
				if not state.is_empty():
					object_data["overheated_state_before"] = state
				object_data["overheated_powered_before"] = bool(object_data.get("is_powered", true))
			object_data["state"] = "overheated"
		object_data["is_powered"] = false
	elif state == "overheated":
		var restore_state := _safe_string(object_data.get("overheated_state_before", "active"), "active")
		if restore_state.is_empty():
			restore_state = "active"
		if not ["destroyed", "damaged"].has(restore_state):
			object_data["state"] = restore_state
		object_data.erase("overheated_state_before")
		if object_data.has("overheated_powered_before"):
			object_data["is_powered"] = bool(object_data.get("overheated_powered_before", true))
			object_data.erase("overheated_powered_before")
	return object_data

static func set_world_object_cooling_received(object_data: Dictionary, cooling_value: int) -> Dictionary:
	object_data["cooling_received"] = maxi(0, cooling_value)
	return update_world_object_heat_state(object_data)


static func is_heavy_claw_movable_object(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if str(object_data.get("state", "active")) in ["destroyed", "damaged"]:
		return false
	var normalized_object_type: String = _normalized_contract_token(object_data.get("object_type", ""))
	if normalized_object_type in ["radiator", "cooling_radiator", "external_radiator", "external_air_cooler", "metal_cooling_block", "normal_crate", "heavy_crate", "steel_box", "barrel", "explosive_barrel", "fire_barrel"]:
		return true
	if not bool(object_data.get("movable", false)):
		return false
	if not bool(object_data.get("heavy_claw_movable", false)):
		return false
	var object_group: String = _normalized_contract_token(object_data.get("object_group", object_data.get("group", "")))
	if object_group not in ["cooling", "physical_object"]:
		return false
	var weight_class: String = _normalized_contract_token(object_data.get("weight_class", ""))
	return weight_class in ["normal", "heavy", "block"] or normalized_object_type in ["box"]

static func should_show_network_link_controls(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var normalized_object_type: String = _normalized_contract_token(object_data.get("object_type", object_data.get("item_type", "")))
	var object_group: String = _normalized_contract_token(object_data.get("object_group", object_data.get("group", "")))
	if normalized_object_type in ["normal_crate", "heavy_crate", "steel_box", "barrel", "explosive_barrel", "fire_barrel", "radiator", "fuse", "repair_kit", "reinforcement"]:
		return false
	if object_group in ["physical_object", "item", "cooling"]:
		return false
	if object_group in ["terminal", "door", "platform"]:
		return true
	if normalized_object_type in ["terminal", "door", "platform", "power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3", "power_socket", "outlet", "fuse_box", "power_switcher", "light_switch", "light_switcher", "power_cable", "power_cable_reel"]:
		return true
	if normalized_object_type.begins_with("power_source"):
		return true
	return false

static func can_world_object_be_moved_by_heavy_claw(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if not is_heavy_claw_movable_object(object_data):
		return false
	if str(object_data.get("object_type", "")).strip_edges().to_lower() == "case":
		return false
	return true

static func can_world_object_receive_cooling(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if bool(object_data.get("generic_airflow_runtime", false)) and bool(object_data.get("cooling_required", false)):
		return true
	var has_heat_metadata := object_data.has("overheat_threshold") or object_data.has("working_heat")
	if not has_heat_metadata:
		return false
	var object_group := str(object_data.get("object_group", ""))
	if object_group == "terminal":
		return true
	var object_type := str(object_data.get("object_type", ""))
	return object_type in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]

static func _to_vector2i(value: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", fallback.x)), int(value.get("y", fallback.y)))
	return fallback

static func to_world_cell(value: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	return _to_vector2i(value, fallback)

static func _is_world_object_inactive_for_cooling(object_data: Dictionary) -> bool:
	var state := str(object_data.get("state", "active"))
	return state in ["damaged", "destroyed", "overheated", "disabled", "inactive", "unpowered"]

static func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1

static func _facing_dir_to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	var dir_text := str(value).to_lower()
	match dir_text:
		"up":
			return Vector2i.UP
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.RIGHT

static func get_radiator_world_cooling_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if str(object_data.get("cooling_device_type", "")) != "radiator":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var radiator_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		if not _is_adjacent(radiator_position, target_position):
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 1)))
		for neighbor in all_objects:
			if neighbor == target_object:
				continue
			if _is_world_object_inactive_for_cooling(neighbor):
				continue
			var neighbor_position := _to_vector2i(neighbor.get("position", Vector2i(-999, -999)))
			if not _is_adjacent(radiator_position, neighbor_position):
				continue
			var is_metal := str(neighbor.get("material", "")) == "metal"
			var is_amplifier := bool(neighbor.get("cooling_amplifier", false))
			if is_metal or is_amplifier:
				output = maxi(output, 2)
				break
		strongest = maxi(strongest, output)
	return strongest

static func get_air_cooler_world_cooling_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if str(object_data.get("cooling_device_type", "")) != "air_cooler":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var cooler_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		var facing_dir := _facing_dir_to_vector2i(object_data.get("facing_dir", "right"))
		var affected_cell := cooler_position + facing_dir
		if affected_cell != target_position:
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 2)))
		strongest = maxi(strongest, output)
	strongest = maxi(strongest, get_air_duct_path_cooling_for_target(target_object, target_position, all_objects))
	return strongest

static func get_water_pipe_world_cooling_for_target(_target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if str(object_data.get("cooling_device_type", "")) != "water_pipe":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var pipe_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		if not _is_adjacent(pipe_position, target_position):
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 2)))
		strongest = maxi(strongest, output)
	return strongest

static func get_air_duct_path_cooling_for_target(_target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if str(object_data.get("cooling_device_type", "")) != "air_cooler":
			continue
		if _is_world_object_inactive_for_cooling(object_data):
			continue
		var cooler_position := _to_vector2i(object_data.get("position", Vector2i(-999, -999)))
		var facing_dir := _facing_dir_to_vector2i(object_data.get("facing_dir", "right"))
		var step_cell := cooler_position + facing_dir
		var has_duct_chain := false
		for _step in range(20):
			var found_active_duct := false
			for duct_data in all_objects:
				if str(duct_data.get("cooling_device_type", "")) != "air_duct":
					continue
				if _is_world_object_inactive_for_cooling(duct_data):
					continue
				var duct_position := _to_vector2i(duct_data.get("position", Vector2i(-999, -999)))
				if duct_position == step_cell:
					found_active_duct = true
					break
			if not found_active_duct:
				break
			has_duct_chain = true
			step_cell += facing_dir
		if not has_duct_chain:
			continue
		if step_cell != target_position:
			continue
		var output := maxi(1, int(object_data.get("cooling_output", 2)))
		strongest = maxi(strongest, output)
	return strongest

static func calculate_world_cooling_received_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	if not can_world_object_receive_cooling(target_object):
		return 0
	var radiator_cooling := get_radiator_world_cooling_for_target(target_object, target_position, all_objects)
	var air_cooling := get_air_cooler_world_cooling_for_target(target_object, target_position, all_objects)
	var water_cooling := get_water_pipe_world_cooling_for_target(target_object, target_position, all_objects)
	if air_cooling > 0 and water_cooling > 0:
		return 4
	if air_cooling > 0 and radiator_cooling > 0:
		return 3
	return maxi(radiator_cooling, maxi(air_cooling, water_cooling))

static func get_power_source_active_socket_connection_count(source_data: Dictionary) -> int:
	return Array(source_data.get("connected_device_ids", [])).size()

static func can_power_source_accept_connection(source_data: Dictionary) -> bool:
	var source_class: int = int(source_data.get("power_source_class", source_data.get("source_class", 1)))
	var object_type: String = str(source_data.get("object_type", "")).strip_edges().to_lower()
	if object_type.ends_with("class_2"):
		source_class = 2
	elif object_type.ends_with("class_3"):
		source_class = 3
	source_class = clampi(source_class, 1, 3)
	var allowed: int = maxi(1, int(source_data.get("outlet_capacity", source_class + 3)))
	return get_power_source_active_socket_connection_count(source_data) < allowed

static func add_power_source_socket_connection(source_data: Dictionary, device_id: String) -> Dictionary:
	var ids: Array = []
	var raw_ids: Variant = source_data.get("connected_device_ids", [])
	if raw_ids is Array:
		ids = Array(raw_ids)
	if not ids.has(device_id):
		if can_power_source_accept_connection(source_data):
			ids.append(device_id)
	source_data["connected_device_ids"] = ids
	source_data["heat_from_connections"] = ids.size()
	return update_world_object_heat_state(source_data)

static func remove_power_source_socket_connection(source_data: Dictionary, device_id: String) -> Dictionary:
	var ids: Array = []
	var raw_ids: Variant = source_data.get("connected_device_ids", [])
	if raw_ids is Array:
		ids = Array(raw_ids)
	if ids.has(device_id):
		ids.erase(device_id)
	source_data["connected_device_ids"] = ids
	source_data["heat_from_connections"] = ids.size()
	return update_world_object_heat_state(source_data)

static func create_test_set() -> Array[Dictionary]:
	return [
		create_archetype_object("door", "door_a1", {"material":"steel", "door_type":"mechanical"}),
		create_archetype_object("door", "door_e1", {"material":"energy", "door_type":"digital"}),
		create_world_object("door_terminal", "terminal_t1"),
		create_world_object("brick_wall", "wall_b1"),
		create_world_object("damaged_wall", "wall_d1"),
		create_world_object("power_source_class_1", "power_src_1"),
		create_world_object("power_cable", "cable_a"),
		create_world_object("circuit_breaker", "breaker_1"),
		create_world_object("fuse_box_installed", "fuse_box_1"),
		create_world_object("fuse_box_empty", "fuse_box_empty_1"),
		create_world_object("fuse", "fuse_item_1"),
		create_world_object("mechanical_keycard", "keycard_a1"),
		create_world_object("digital_key_opened", "digikey_a1"),
		create_world_object("data_file_encrypted", "datafile_enc_1"),
		create_world_object("normal_crate", "crate_n_1"),
		create_world_object("heavy_crate", "crate_h_1"),
		create_world_object("barrel", "barrel_1"),
		create_world_object("debris", "debris_1")
	]
