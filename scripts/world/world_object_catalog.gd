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
const DIGITAL_ITEM_TYPE_ALIASES: Array[String] = ["digital_key", "access_code", "data_file", "info_key", "record"]
const POWER_BEHAVIOR_NONE := "none"
const POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED := "opens_when_unpowered"

const PREFAB_ALIASES: Dictionary = {
	"mechanical_door": "steel_door",
	"digital_door": "energy_door",
	"powered_gate": "energy_door"
}

const LEGACY_SOURCE_METADATA_FIELDS: Array[String] = ["legacy_prefab_id", "map_constructor_prefab_id", "legacy_object_type", "source_prefab_id"]

const PREFAB_ALIAS_DEFAULTS: Dictionary = {
	"mechanical_door": {"object_group":"door", "door_type":DOOR_TYPE_MECHANICAL, "access_type":ACCESS_TYPE_KEY_CARD},
	"digital_door": {"object_group":"door", "door_type":DOOR_TYPE_DIGITAL, "access_type":ACCESS_TYPE_DIGITAL_KEY},
	"powered_gate": {"object_group":"door", "door_type":DOOR_TYPE_POWERED, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"}
}

# Hidden compatibility mappings for loading old constructor/runtime data only.
# These aliases must never be emitted as user-facing palette entries or presets.
const LEGACY_DOOR_ALIAS_CONFIGS: Dictionary = {
	"mechanical_steel_door": {"object_type":"steel_door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_reinforced_steel_door": {"object_type":"reinforced_steel_door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_titanium_door": {"object_type":"titanium_door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"mechanical_energy_door": {"object_type":"energy_door", "door_type":DOOR_TYPE_MECHANICAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_KEY_CARD, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_steel_door": {"object_type":"steel_door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_reinforced_steel_door": {"object_type":"reinforced_steel_door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_titanium_door": {"object_type":"titanium_door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"digital_energy_door": {"object_type":"energy_door", "door_type":DOOR_TYPE_DIGITAL, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_DIGITAL_KEY, "power_behavior":POWER_BEHAVIOR_NONE},
	"powered_steel_door": {"object_type":"steel_door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_STEEL, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_reinforced_steel_door": {"object_type":"reinforced_steel_door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_REINFORCED_STEEL, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_titanium_door": {"object_type":"titanium_door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_TITANIUM, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"},
	"powered_energy_door": {"object_type":"energy_door", "door_type":DOOR_TYPE_POWERED, "material":DOOR_MATERIAL_ENERGY, "access_type":ACCESS_TYPE_NO_KEY, "power_behavior":POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED, "requires_external_power":true, "power_mode":"external_power"}
}

const WALL_MATERIAL_BRICK := "brick"
const WALL_MATERIAL_CONCRETE := "concrete"
const WALL_MATERIAL_STEEL := "steel"
const WALL_MATERIAL_REINFORCED_STEEL := "reinforced_steel"
const WALL_MATERIAL_TITANIUM := "titanium"
const WALL_MATERIAL_GRATE := "grate"
const WALL_MATERIAL_ELECTROMAGNETIC := "electromagnetic"
const WALL_MATERIALS: Array[String] = [WALL_MATERIAL_BRICK, WALL_MATERIAL_CONCRETE, WALL_MATERIAL_STEEL, WALL_MATERIAL_REINFORCED_STEEL, WALL_MATERIAL_TITANIUM, WALL_MATERIAL_GRATE, WALL_MATERIAL_ELECTROMAGNETIC]
const WALL_DISPLAY_NAMES: Dictionary = {
	WALL_MATERIAL_BRICK: "Brick Wall",
	WALL_MATERIAL_CONCRETE: "Concrete Wall",
	WALL_MATERIAL_STEEL: "Steel Wall",
	WALL_MATERIAL_REINFORCED_STEEL: "Reinforced Steel Wall",
	WALL_MATERIAL_TITANIUM: "Titanium Wall",
	WALL_MATERIAL_GRATE: "Grate Wall",
	WALL_MATERIAL_ELECTROMAGNETIC: "Electromagnetic Wall"
}

# Hidden compatibility mappings for historic wall ids. Constructor palettes must
# expose only external_wall and wall; old ids normalize while loading legacy data.
const LEGACY_WALL_ALIAS_CONFIGS: Dictionary = {
	"outer_wall": {"object_type":"external_wall"},
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
	"external_wall": {
		"archetype_id":"external_wall", "object_group":"wall", "object_type":"external_wall", "palette_label":"External Wall", "palette_label_ru":"Стена внешняя",
		"display_name_template":"External Wall", "material":"external_structural", "is_destructible":false, "supports_embedded_objects":true, "supports_cables":true, "configurable":false, "blocks_movement":true, "blocks_vision":true,
		"property_schema":[]
	},
	"wall": {
		"archetype_id":"wall", "object_group":"wall", "object_type":"wall", "palette_label":"Wall", "palette_label_ru":"Стена",
		"display_name_template":"{material_label} Wall", "is_destructible":true, "supports_embedded_objects":true, "supports_cables":true, "configurable":true, "blocks_movement":true, "blocks_vision":true,
		"property_schema":[
			{"field":"material", "type":"enum", "values":["brick", "concrete", "steel", "reinforced_steel", "titanium", "grate", "electromagnetic"], "default":"brick", "labels_ru":{"brick":"Кирпичная стена", "concrete":"Бетонная стена", "steel":"Стальная стена", "reinforced_steel":"Стена из усиленной стали", "titanium":"Титановая стена", "grate":"Стена из решётки", "electromagnetic":"Электромагнитная стена"}}
		]
	},
	"door": {
		"archetype_id":"door", "object_group":"door", "object_type":"steel_door", "palette_label":"Door",
		"display_name_template":"{material_label} {door_type_label} Door",
		"property_schema":[
			{"field":"door_type", "type":"enum", "values":["mechanical", "digital", "powered"], "default":"mechanical"},
			{"field":"material", "type":"enum", "values":["steel", "reinforced_steel", "titanium", "energy"], "default":"steel"},
			{"field":"access_type", "type":"enum", "values":["no_key", "key_card", "digital_key", "access_code", "terminal"], "default":"no_key"},
			{"field":"door_class", "type":"int", "default":1},
			{"field":"power_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal"},
			{"field":"control_type", "type":"enum", "values":["internal", "external", "none"], "default":"internal"},
			{"field":"power_behavior", "type":"enum", "values":["none", "opens_when_unpowered"], "default":"none"},
			{"field":"state", "type":"enum", "values":["closed", "open", "damaged", "jammed", "locked", "unpowered"], "default":"closed"},
			{"field":"allowed_states", "type":"enum_array", "values":["closed", "open", "damaged", "jammed", "locked", "unpowered"], "default":["closed", "open", "damaged"]},
			{"field":"required_key_id", "type":"string", "default":""},
			{"field":"required_terminal_id", "type":"string", "default":""},
			{"field":"required_access_code_id", "type":"string", "default":""},
			{"field":"required_digital_key_id", "type":"string", "default":""},
			{"field":"required_manipulator_level", "type":"int", "default":0},
			{"field":"required_connector_level", "type":"int", "default":0},
			{"field":"required_processor_level", "type":"int", "default":0}
		]
	}
}

const LEGACY_DOOR_IDS: Array[String] = ["steel_door", "reinforced_steel_door", "titanium_door", "energy_door", "grid_door", "mechanical_door", "digital_door", "powered_gate", "digital_steel_door", "digital_titanium_door", "mechanical_titanium_door"]

static func canonical_prefab_id(prefab_id: String) -> String:
	var normalized_type: String = prefab_id.strip_edges().to_lower()
	if PREFAB_ALIASES.has(normalized_type):
		return String(PREFAB_ALIASES[normalized_type])
	var preset_variant: Variant = LEGACY_DOOR_ALIAS_CONFIGS.get(normalized_type, LEGACY_WALL_ALIAS_CONFIGS.get(normalized_type, {}))
	if preset_variant is Dictionary:
		return String(preset_variant.get("object_type", normalized_type))
	return normalized_type

# Compatibility name retained for existing constructor and runtime callers.
static func canonical_object_type(object_type: String) -> String:
	return canonical_prefab_id(object_type)

static func is_legacy_prefab_alias(value: String) -> bool:
	var normalized_value: String = value.strip_edges().to_lower()
	return PREFAB_ALIASES.has(normalized_value) or LEGACY_WALL_ALIAS_CONFIGS.has(normalized_value)

static func is_legacy_door_object_type(value: String) -> bool:
	return is_legacy_prefab_alias(value)

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
	elif is_legacy_prefab_alias(source_id):
		data = mark_legacy_source(data, source_id)
	if data.has("access_type") or data.has("lock_type"):
		data["access_type"] = normalize_access_type(data.get("access_type", data.get("lock_type", ACCESS_TYPE_NO_KEY)))
	return data

static func get_prefab_alias_defaults(prefab_id: String) -> Dictionary:
	var normalized_prefab_id: String = prefab_id.strip_edges().to_lower()
	var raw_defaults: Variant = PREFAB_ALIAS_DEFAULTS.get(normalized_prefab_id, {})
	if raw_defaults is Dictionary and not raw_defaults.is_empty():
		return raw_defaults.duplicate(true)
	var preset_variant: Variant = LEGACY_DOOR_ALIAS_CONFIGS.get(normalized_prefab_id, LEGACY_WALL_ALIAS_CONFIGS.get(normalized_prefab_id, {}))
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
	for archetype_id_variant in ARCHETYPE_REGISTRY.keys():
		var archetype_id: String = String(archetype_id_variant)
		var definition: Dictionary = ARCHETYPE_REGISTRY[archetype_id]
		rows.append({"id":archetype_id, "prefab_id":archetype_id, "archetype_id":archetype_id, "canonical_object_type":String(definition.get("object_type", archetype_id)), "display_name":String(definition.get("palette_label", archetype_id.capitalize())), "label":String(definition.get("palette_label", archetype_id.capitalize())), "label_ru":String(definition.get("palette_label_ru", "")), "category":String(definition.get("object_group", "Objects")).capitalize(), "object_group":String(definition.get("object_group", "physical_object")), "placement_mode":String(definition.get("placement_mode", "object")), "blocks_movement":bool(definition.get("blocks_movement", true)), "is_alias":false})
	for object_type_variant in OBJECT_LIBRARY.keys():
		var object_type: String = String(object_type_variant)
		var definition: Dictionary = OBJECT_LIBRARY[object_type]
		if ARCHETYPE_REGISTRY.has(object_type) or not bool(definition.get("placeable_in_constructor", true)) or String(definition.get("group", "")) == "door":
			continue
		rows.append(_build_constructor_palette_row(object_type, object_type, definition, false))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("display_name", "")) < String(b.get("display_name", "")))
	return rows

static func _build_constructor_palette_row(prefab_id: String, canonical_type: String, definition: Dictionary, is_alias: bool) -> Dictionary:
	var object_group: String = String(definition.get("group", definition.get("object_group", "physical_object")))
	var category: String = String(definition.get("constructor_category", object_group.capitalize()))
	var placement_mode: String = String(definition.get("placement_mode", "object"))
	var row: Dictionary = {
		"id": prefab_id,
		"prefab_id": prefab_id,
		"canonical_object_type": canonical_type,
		"display_name": String(definition.get("name", prefab_id.capitalize())),
		"label": String(definition.get("name", prefab_id.capitalize())),
		"category": category,
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
		var object_type: String = String(object_type_variant)
		var definition: Dictionary = OBJECT_LIBRARY[object_type]
		if String(definition.get("group", "")) == "door" and bool(definition.get("placeable_in_constructor", true)):
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
		var key: String = String(key_variant)
		if not data.has(key):
			data[key] = defaults[key]
	if normalized_original_type == "powered_gate":
		data["requires_external_power"] = bool(data.get("requires_external_power", true))
		data["power_mode"] = String(data.get("power_mode", "external_power"))
	return normalize_world_object_contract(data)

const OBJECT_LIBRARY := {
	"steel_door": {"group":"door","name":"Steel Door","door_type":"mechanical","material":"steel","access_type":"key_card","power_behavior":"none","durability":30,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":1,"lock_type":"mechanical_key","required_manipulator_level":1,"required_connector_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"reinforced_steel_door": {"group":"door","name":"Reinforced Steel Door","door_type":"digital","material":"reinforced_steel","access_type":"terminal","power_behavior":"none","durability":40,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":2,"lock_type":"terminal_lock","required_manipulator_level":2,"required_connector_level":0,"power_mode":"external_power","control_mode":"external_control"},
	"titanium_door": {"group":"door","name":"Titanium Door","door_type":"digital","material":"titanium","access_type":"access_code","power_behavior":"none","durability":100,"state":"closed","blocks_movement":true,"blocks_vision":true,"door_class":3,"lock_type":"password","required_manipulator_level":3,"required_connector_level":0},
	"energy_door": {"group":"door","name":"Energy Door","door_type":"digital","material":"energy","access_type":"digital_key","power_behavior":"none","durability":1,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"digital_key","required_manipulator_level":1,"required_connector_level":1,"invulnerable_while_powered":true,"power_mode":"external_power","control_mode":"external_control"},
	"grid_door": {"group":"door","name":"Grid Door","door_type":"mechanical","material":"steel","access_type":"no_key","power_behavior":"none","durability":15,"state":"closed","blocks_movement":true,"blocks_vision":false,"door_class":1,"lock_type":"none","required_manipulator_level":1,"required_connector_level":0},
	"door_terminal": {"group":"terminal","name":"Door Terminal","placement_mode":"wall_mounted","state":"active","is_powered":true,"power_mode":"internal_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","connection_type":"wired","terminal_class":1,"required_connector_level":1,"required_processor_level":1,"encrypts_data":false,"drain_pool":10,"durability":10,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"elevator_terminal": {"group":"terminal","name":"Elevator Terminal","connection_type":"high_bandwidth","terminal_class":2,"required_connector_level":2,"required_processor_level":2,"encrypts_data":true,"drain_pool":20,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"information_terminal": {"group":"terminal","name":"Information Terminal","connection_type":"optical","terminal_class":2,"required_connector_level":2,"required_processor_level":2,"encrypts_data":true,"drain_pool":20,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"turret_terminal": {"group":"terminal","name":"Turret Terminal","connection_type":"wireless","terminal_class":3,"required_connector_level":3,"required_processor_level":3,"can_attack":true,"encrypts_data":true,"drain_pool":30,"durability":10,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":2,"overheated_state_before":""},
	"platform_terminal": {"group":"terminal","name":"Platform Terminal","placement_mode":"wall_mounted","terminal_type":"platform","connection_type":"wired","required_connector_level":1,"target_platform_id":"","state":"active","is_powered":true,"power_mode":"internal_power","power_type":"internal","control_mode":"internal_control","control_type":"internal","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","damageable":true,"destructible":false,"platform_control_enabled":true,"platform_remote_control":true,"durability":12},
	"rotating_platform": {"group":"platform","name":"Rotating Platform","platform_type":"rotating","platform_id":"","platform_cells":[],"state":"active","is_powered":true,"power_type":"internal","control_type":"internal","requires_terminal_enabled":false,"linked_terminal_id":"","local_switch_cell":[0,0],"local_switch_facing_dir":"up","non_destructible":true,"destructible":false,"movable":false,"heavy_claw_movable":false,"activation_mode":"instant","timer_turns":0,"timer_remaining_turns":0,"period_turns":0,"periodic_active":false,"permanent_state":false,"pending_activation":false,"rotation_direction":"clockwise"},
	"lifting_platform": {"group":"platform","name":"Lifting Platform","platform_type":"lifting","platform_id":"","platform_cells":[],"state":"active","is_powered":true,"power_type":"internal","control_type":"internal","requires_terminal_enabled":false,"linked_terminal_id":"","local_switch_cell":[0,0],"local_switch_facing_dir":"up","non_destructible":true,"destructible":false,"movable":false,"heavy_claw_movable":false,"height_level":0,"min_height_level":0,"max_height_level":1,"activation_mode":"instant","timer_turns":0,"timer_remaining_turns":0,"period_turns":0,"periodic_active":false,"permanent_state":false,"pending_activation":false},
	"cooling_terminal": {"group":"terminal","name":"Cooling Terminal","placement_mode":"wall_mounted","state":"active","is_powered":true,"power_mode":"internal_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","connection_type":"wired","terminal_class":1,"required_connector_level":1,"required_processor_level":1,"encrypts_data":false,"drain_pool":10,"durability":10,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"hack_heat":1,"overheated_state_before":""},
	"firewall": {"group":"terminal","name":"Firewall","placement_mode":"wall_mounted","state":"active","required_connector_level":1,"required_processor_level":1,"durability":10},
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
	"power_cable": {"group":"power","name":"Power Cable","state":"ok","durability":5,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","connected":true,"disconnected":false,"connected_side":true,"cut":false,"damaged":false,"broken":false,"is_hidden":false,"route_surface":"floor","cable_path_cells":[],"cable_length":0},
	"circuit_breaker": {"group":"power","name":"Circuit Breaker","placement_mode":"wall_mounted","state":"switch_on","durability":8,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"is_on":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"circuit_switch": {"group":"power","name":"Circuit Switch","state":"switch_off","durability":8,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false,"input_wire_id":"","output_1_wire_id":"","output_2_wire_id":"","output_3_wire_id":"","active_output_index":1},
	"fuse_box": {"group":"power","name":"Fuse Box","placement_mode":"wall_mounted","state":"installed","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"fuse_box_installed": {"group":"power","name":"Fuse Box Installed","placement_mode":"wall_mounted","state":"installed","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"fuse_box_empty": {"group":"power","name":"Fuse Box Empty","placement_mode":"wall_mounted","state":"empty","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"requires_fuse":true,"fuse_installed":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"light": {"group":"power","name":"Light","placement_mode":"wall_mounted","state":"active","durability":6,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false,"brightness":1.0,"color":"#ffffff"},
	"light_switch": {"group":"power","name":"Light Switch","placement_mode":"wall_mounted","state":"switch_off","durability":6,"power_mode":"external_power","control_mode":"internal_control","requires_external_control":false,"control_terminal_id":"","linked_terminal_id":"","is_powered":false,"is_on":false,"can_be_switched":true,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","damaged":false,"broken":false},
	"power_socket": {"group":"power","name":"Power Socket","state":"disconnected","durability":8,"power_mode":"external_power","control_mode":"internal_control","is_powered":false,"power_network_id":"","power_source_id":"","physical_connection_source_id":"","connected":false,"disconnected":true,"connected_side":false,"damaged":false,"broken":false,"can_connect_cable":true},
	"power_cable_reel": {"group":"item","name":"Power Cable Reel","placement_mode":"wall_mounted","state":"disconnected","item_form":"physical","storage_type":"pocket","can_connect_socket":true,"max_cable_length":5,"connected":false,"disconnected":true,"connected_side":false,"connected_side_1":false,"connected_side_2":false,"end_1_state":"on_reel","end_1_target_id":"","end_1_path_cells":[],"end_1_cable_length":0,"end_2_state":"on_reel","end_2_target_id":"","end_2_path_cells":[],"end_2_cable_length":0,"cable_endpoint_a_id":"","cable_endpoint_b_id":"","cable_path_cells":[],"cable_length":0,"cut":false,"damaged":false,"broken":false},
	"power_source_class_1": {"group":"power","name":"Power Source C1","state":"on","power_mode":"internal","control_mode":"internal","requires_external_control":false,"is_powered":true,"power_network_id":"","damaged":false,"broken":false,"durability":30,"power_source_class":1,"outlet_capacity":4,"drain_pool":60,"working_heat":1,"current_heat":1,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":1,"connected_device_ids":[]},
	"power_source_class_2": {"group":"power","name":"Power Source C2","state":"on","power_mode":"internal","control_mode":"internal","requires_external_control":false,"is_powered":true,"power_network_id":"","damaged":false,"broken":false,"durability":30,"power_source_class":2,"outlet_capacity":5,"drain_pool":120,"working_heat":2,"current_heat":2,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":2,"connected_device_ids":[]},
	"power_source_class_3": {"group":"power","name":"Power Source C3","state":"on","power_mode":"internal","control_mode":"internal","requires_external_control":false,"is_powered":true,"power_network_id":"","damaged":false,"broken":false,"durability":30,"power_source_class":3,"outlet_capacity":6,"drain_pool":240,"working_heat":3,"current_heat":3,"overheat_threshold":3,"heat_from_connections":0,"cooling_received":0,"overheated_state_before":"","allowed_socket_connections":3,"connected_device_ids":[]},
	"external_radiator": {"group":"cooling","name":"External Radiator","state":"active","cooling_device_type":"radiator","cooling_output":1,"movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20},
	"external_air_cooler": {"group":"cooling","name":"External Air Cooler","state":"active","cooling_device_type":"air_cooler","cooling_output":2,"directed_airflow":true,"facing_dir":"right","movable":true,"heavy_claw_movable":true,"material":"metal","blocks_movement":true,"blocks_vision":false,"durability":20},
	"metal_cooling_block": {"group":"physical","name":"Metal Cooling Block","state":"active","material":"metal","cooling_amplifier":true,"movable":true,"heavy_claw_movable":true,"blocks_movement":true,"blocks_vision":false,"durability":30},
	"external_water_pipe": {"group":"cooling","name":"External Water Pipe","state":"active","cooling_device_type":"water_pipe","cooling_output":2,"passive_cooling":true,"movable":false,"material":"metal","blocks_movement":false,"blocks_vision":false,"durability":15},
	"external_air_duct": {"group":"cooling","name":"External Air Duct","state":"active","cooling_device_type":"air_duct","carries_airflow":true,"passive_cooling":true,"movable":false,"material":"metal","blocks_movement":false,"blocks_vision":false,"durability":12},
	"module_external": {"group":"item","name":"Module External","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"module_internal": {"group":"item","name":"Module Internal","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mechanical_keycard": {"group":"item","name":"Key-Card","item_form":"physical","storage_type":"pocket","can_place_in_digital_buffer":false,"consumable":false,"fits_targets":["door"],"key_kind":"mechanical"},
	"fuse": {"group":"item","name":"Fuse","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["fuse_box","fuse_box_empty"]},
	"repair_kit": {"group":"item","name":"Repair Kit","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door","terminal","power"]},
	"reinforcement": {"group":"item","name":"Reinforcement","item_form":"physical","storage_type":"manipulator_hold","can_place_in_digital_buffer":false,"consumable":true,"fits_targets":["door"],"damage":2},
	"parts": {"group":"item","name":"Parts","item_form":"physical","storage_type":"pocket","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_small": {"group":"item","name":"Parts (Small)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":5,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_medium": {"group":"item","name":"Parts (Medium)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":10,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"parts_large": {"group":"item","name":"Parts (Large)","item_form":"physical","storage_type":"pocket","can_pickup":true,"amount":20,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"sample": {"group":"item","name":"Sample","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"mission_item": {"group":"item","name":"Mission Item","item_form":"physical","storage_type":"box_storage","can_pickup":true,"can_place_in_digital_buffer":false,"consumable":false,"fits_targets":[]},
	"digital_key_opened": {"group":"item","name":"Digital Key Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"opened","consumable":false,"fits_targets":["door"]},
	"digital_key_encrypted": {"group":"item","name":"Digital Key Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"encrypted","consumable":false,"fits_targets":["door"]},
	"digital_key_damaged": {"group":"item","name":"Digital Key Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"digital_key","digital_state":"damaged","consumable":false,"fits_targets":["door"]},
	"access_code": {"group":"item","name":"Access Code","item_form":"digital","storage_type":"digital_storage","can_place_in_digital_buffer":false,"digital_state":"opened","consumable":false,"fits_targets":["door","terminal"]},
	"data_file_opened": {"group":"item","name":"Data File Opened","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"opened","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_encrypted": {"group":"item","name":"Data File Encrypted","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"encrypted","consumable":false,"fits_targets":["terminal","firewall"]},
	"data_file_damaged": {"group":"item","name":"Data File Damaged","item_form":"digital","storage_type":"digital_buffer","can_place_in_digital_buffer":true,"item_family":"data_file","digital_state":"damaged","consumable":false,"fits_targets":["terminal","firewall"]},
	"normal_crate": {"group":"physical_object","name":"Normal Crate","weight_class":"normal","required_bipob_power_class":"scout","durability":8,"blocks_movement":true},"heavy_crate": {"group":"physical_object","name":"Heavy Crate","weight_class":"heavy","required_bipob_power_class":"engineer","durability":14,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"movable_platform_block": {"group":"physical_object","name":"Movable Platform Block","weight_class":"block","required_bipob_power_class":"juggernaut","durability":20,"blocks_movement":true,"magnetic":true,"material_tags":["metal"]},"disabled_bipop_scout": {"group":"physical_object","name":"Disabled Bipop Scout","weight_class":"normal","required_bipob_power_class":"scout","durability":10},"disabled_bipop_engineer": {"group":"physical_object","name":"Disabled Bipop Engineer","weight_class":"heavy","required_bipob_power_class":"engineer","durability":15},"disabled_bipop_juggernaut": {"group":"physical_object","name":"Disabled Bipop Juggernaut","weight_class":"block","required_bipob_power_class":"juggernaut","durability":25},"barrel": {"group":"physical_object","name":"Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":8},"explosive_barrel": {"group":"physical_object","name":"Explosive Barrel","weight_class":"normal","required_bipob_power_class":"scout","durability":6,"on_destroy":"explode"},"debris": {"group":"physical_object","name":"Debris","weight_class":"normal","required_bipob_power_class":"scout","durability":1,"blocks_movement":false,"terrain_tag":"debris","movement_debuff":-1},
	"enemy_robot": {"group":"threat","name":"Enemy Robot","state":"active","behavior_state":"patrolling","durability":20,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":20,"drained_this_turn":false,"detection_range":3,"vision_range":3,"radar_range":3,"thermal_range":0,"detection_modes":["vision","radar"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":5,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"turret": {"group":"threat","name":"Turret","state":"active","behavior_state":"idle","durability":15,"blocks_movement":true,"blocks_vision":false,"power_mode":"external_power","power_network_id":"power_net_A","is_powered":true,"control_mode":"external_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_light"],"heat_signature":true,"magnetic":true,"drain_energy_pool":15,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":0,"thermal_range":4,"detection_modes":["vision","thermal"],"detection_shape":"cardinal","detection_cone_enabled":false,"detection_direction":"forward","attack_range":4,"attack_damage":4,"can_be_controlled_by_terminal":true,"required_processor_level":1,"drops":["parts_medium"],"on_destroy":["drop_items","debris"]},
	"bug": {"group":"threat","name":"Bug","state":"active","behavior_state":"patrolling","durability":8,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["organic"],"heat_signature":true,"magnetic":false,"drain_energy_pool":5,"drained_this_turn":false,"detection_range":2,"vision_range":2,"radar_range":0,"thermal_range":0,"detection_modes":["vision"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":1,"attack_damage":2,"drops":["sample","parts_small"],"on_destroy":["drop_items"]},
	"vagus": {"group":"threat","name":"Vagus","state":"active","behavior_state":"idle","durability":30,"blocks_movement":true,"blocks_vision":false,"power_mode":"internal_power","power_network_id":"","is_powered":true,"control_mode":"internal_control","controlled_by":[],"scan_level":0,"material_tags":["metal","armor_heavy"],"heat_signature":true,"magnetic":true,"drain_energy_pool":30,"drained_this_turn":false,"detection_range":4,"vision_range":4,"radar_range":4,"thermal_range":4,"detection_modes":["vision","radar","thermal"],"detection_shape":"radius","detection_cone_enabled":false,"detection_direction":"forward","attack_range":2,"attack_damage":7,"drops":["mission_item","parts_large"],"on_destroy":["drop_items","debris"]}
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
	return String(DOOR_MATERIAL_BY_OBJECT_TYPE.get(object_type, DOOR_MATERIAL_STEEL))

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
		var key: String = String(key_variant)
		if not data.has(key):
			data[key] = defaults[key]
	var group_text: String = _normalized_contract_token(data.get("object_group", data.get("group", "")))
	if group_text != "door" and not object_type.contains("door") and not object_type.contains("gate") and defaults.is_empty():
		return data
	data["object_group"] = "door"
	var raw_access_type: Variant = data.get("access_type", data.get("lock_type", ACCESS_TYPE_NO_KEY))
	var access_type: String = normalize_access_type(raw_access_type)
	data["access_type"] = access_type
	data["lock_type"] = _legacy_lock_type_for_access_type(access_type)
	var power_behavior: String = _normalized_contract_token(data.get("power_behavior", POWER_BEHAVIOR_NONE))
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
		elif power_behavior == POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED:
			door_type = DOOR_TYPE_POWERED
		else:
			door_type = DOOR_TYPE_MECHANICAL
	data["door_type"] = door_type
	if door_type == DOOR_TYPE_POWERED and power_behavior == POWER_BEHAVIOR_NONE:
		power_behavior = POWER_BEHAVIOR_OPENS_WHEN_UNPOWERED
	elif door_type != DOOR_TYPE_POWERED:
		power_behavior = POWER_BEHAVIOR_NONE
	data["power_behavior"] = power_behavior
	data["material"] = _normalize_door_material(data.get("material", ""), object_type)
	data["door_class"] = clampi(int(data.get("door_class", 1)), 1, 3)
	if access_type == ACCESS_TYPE_NO_KEY:
		data["required_key_id"] = ""
		if _normalized_contract_token(data.get("state", "closed")) == "locked":
			data["state"] = "closed"
		data["is_locked"] = false
		data["locked"] = false
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
	data = normalize_archetype_object(data)
	return data

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
		var field_name: String = String(field.get("field", ""))
		if not object_data.has(field_name):
			warnings.append("object_missing_schema_field_%s" % field_name)
			continue
		var field_type: String = String(field.get("type", ""))
		var allowed: Array = Array(field.get("values", []))
		if field_type == "enum" and not allowed.has(object_data.get(field_name)):
			warnings.append("object_invalid_enum_%s" % field_name)
		elif field_type == "enum_array":
			for value_variant in Array(object_data.get(field_name, [])):
				if not allowed.has(value_variant):
					warnings.append("object_invalid_enum_array_%s" % field_name)
	if object_data.has("allowed_states") and not Array(object_data.get("allowed_states", [])).has(object_data.get("state")):
		warnings.append("object_state_not_allowed")
	if archetype_id == "door":
		var state: String = String(object_data.get("state", ""))
		if bool(object_data.get("is_open", false)) != (state == "open") or bool(object_data.get("is_locked", false)) != (state == "locked"):
			warnings.append("object_derived_state_flags_out_of_sync")
	return warnings

static func validate_object_registry_contract() -> Array[String]:
	var warnings: Array[String] = []
	for alias_variant in PREFAB_ALIASES.keys():
		var alias_id: String = String(alias_variant)
		var target_id: String = canonical_prefab_id(alias_id)
		if not OBJECT_LIBRARY.has(target_id):
			warnings.append("prefab_alias_target_missing_%s_%s" % [alias_id, target_id])
			continue
		var alias_data: Dictionary = create_world_object(alias_id, "validation_%s" % alias_id)
		if alias_data.is_empty() or not OBJECT_LIBRARY.has(String(alias_data.get("object_type", ""))):
			warnings.append("prefab_alias_creates_unknown_runtime_object_%s" % alias_id)
		for required_field in ["door_type", "material", "access_type", "door_class"]:
			if not alias_data.has(required_field) or _normalized_contract_token(alias_data.get(required_field, "")).is_empty():
				warnings.append("prefab_alias_missing_%s_%s" % [required_field, alias_id])
	for object_type_variant in OBJECT_LIBRARY.keys():
		var object_type: String = String(object_type_variant)
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
	if not object_data.has("allowed_states"):
		object_data["allowed_states"] = ["closed", "open", "damaged"]
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
	var damaged_flag := bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false)) or state in ["damaged", "broken", "destroyed"]
	if not bool(object_data.get("normalized_by_archetype_catalog", false)):
		if bool(object_data.get("is_open", false)) and not damaged_flag and state not in ["locked", "jammed"]:
			state = "open"
		if bool(object_data.get("is_locked", object_data.get("locked", false))) and not damaged_flag and state != "open":
			state = "locked"
	var destroyed := bool(object_data.get("destroyed", false)) or state == "destroyed"
	var open_state := state == "open"
	var closed_state := state in ["closed", "locked", "jammed", "unpowered"] and not destroyed
	var locked_state := state == "locked" or (bool(object_data.get("locked", false)) and not open_state and not destroyed)
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
	return Array(get_archetype_definition(archetype_id).get("property_schema", [])).duplicate(true)

static func get_archetype_id_for_object(object_data: Dictionary) -> String:
	var explicit_id: String = _normalized_contract_token(object_data.get("archetype_id", ""))
	if ARCHETYPE_REGISTRY.has(explicit_id):
		return explicit_id
	var object_type: String = _normalized_contract_token(object_data.get("object_type", ""))
	if ARCHETYPE_REGISTRY.has(object_type):
		return object_type
	var group_id: String = _normalized_contract_token(object_data.get("object_group", object_data.get("group", "")))
	if ARCHETYPE_REGISTRY.has(group_id):
		return group_id
	return ""

static func _schema_defaults(archetype_id: String) -> Dictionary:
	var defaults: Dictionary = {}
	for field_variant in get_archetype_property_schema(archetype_id):
		var field: Dictionary = field_variant
		defaults[String(field.get("field", ""))] = field.get("default")
	return defaults

static func _normalize_wall_material(value: Variant) -> String:
	var material: String = _normalized_contract_token(value)
	return material if WALL_MATERIALS.has(material) else WALL_MATERIAL_BRICK

static func _label_for_id(value: Variant) -> String:
	return _normalized_contract_token(value).replace("_", " ").capitalize()

static func generate_display_name(object_data: Dictionary) -> String:
	var archetype_id: String = get_archetype_id_for_object(object_data)
	var definition: Dictionary = get_archetype_definition(archetype_id)
	var template: String = String(definition.get("display_name_template", object_data.get("display_name", archetype_id.capitalize())))
	for field_variant in get_archetype_property_schema(archetype_id):
		var field: Dictionary = field_variant
		var field_name: String = String(field.get("field", ""))
		template = template.replace("{%s_label}" % field_name, _label_for_id(object_data.get(field_name, field.get("default", ""))))
	return template

static func normalize_archetype_object(object_data: Dictionary) -> Dictionary:
	var data: Dictionary = object_data.duplicate(true)
	var archetype_id: String = get_archetype_id_for_object(data)
	if archetype_id.is_empty():
		return data
	var definition: Dictionary = get_archetype_definition(archetype_id)
	data["archetype_id"] = archetype_id
	data["object_group"] = String(definition.get("object_group", archetype_id))
	for fixed_field in ["material", "is_destructible", "supports_embedded_objects", "supports_cables", "configurable", "blocks_movement", "blocks_vision"]:
		if definition.has(fixed_field) and (archetype_id == "external_wall" or not data.has(fixed_field)):
			data[fixed_field] = definition[fixed_field]
	for key_variant in _schema_defaults(archetype_id).keys():
		var key: String = String(key_variant)
		if not data.has(key):
			data[key] = _schema_defaults(archetype_id)[key]
	if archetype_id == "wall":
		data["material"] = _normalize_wall_material(data.get("material", WALL_MATERIAL_BRICK))
	if archetype_id == "door":
		data["power_mode"] = String(data.get("power_type", data.get("power_mode", "internal")))
		data["control_mode"] = String(data.get("control_type", data.get("control_mode", "internal")))
	data["display_name"] = generate_display_name(data)
	data["normalized_by_archetype_catalog"] = true
	return data

static func create_archetype_object(archetype_id: String, id_override: String = "", overrides: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = get_archetype_definition(archetype_id)
	if definition.is_empty():
		return {}
	var runtime_type: String = String(definition.get("object_type", archetype_id))
	var data: Dictionary = _create_library_object(runtime_type, id_override) if runtime_type == archetype_id else create_world_object(runtime_type, id_override)
	data["archetype_id"] = archetype_id
	for key_variant in overrides.keys():
		data[String(key_variant)] = overrides[key_variant]
	return normalize_door_state_fields(normalize_world_object_contract(normalize_archetype_object(data)))

static func _create_library_object(object_type: String, id_override: String = "") -> Dictionary:
	var canonical_type: String = canonical_object_type(object_type)
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
		data[String(key_variant)] = alias_defaults[key_variant]
	data = normalize_world_object_contract(data)
	data = update_world_object_heat_state(data)
	return normalize_door_state_fields(data)

static func create_world_object(object_type: String, id_override: String = "") -> Dictionary:
	if ARCHETYPE_REGISTRY.has(_normalized_contract_token(object_type)):
		return create_archetype_object(_normalized_contract_token(object_type), id_override)
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


static func can_world_object_be_moved_by_heavy_claw(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if not bool(object_data.get("movable", false)):
		return false
	if not bool(object_data.get("heavy_claw_movable", false)):
		return false
	if String(object_data.get("state", "active")) in ["destroyed", "damaged"]:
		return false
	var object_group := String(object_data.get("object_group", ""))
	if object_group not in ["cooling", "physical"]:
		return false
	var object_type := String(object_data.get("object_type", ""))
	return object_type in ["external_radiator", "external_air_cooler", "metal_cooling_block"]

static func can_world_object_receive_cooling(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var has_heat_metadata := object_data.has("overheat_threshold") or object_data.has("working_heat")
	if not has_heat_metadata:
		return false
	var object_group := String(object_data.get("object_group", ""))
	if object_group == "terminal":
		return true
	var object_type := String(object_data.get("object_type", ""))
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
	var state := String(object_data.get("state", "active"))
	return state in ["damaged", "destroyed", "overheated", "disabled", "inactive", "unpowered"]

static func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1

static func _facing_dir_to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	var dir_text := String(value).to_lower()
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
		if String(object_data.get("cooling_device_type", "")) != "radiator":
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
			var is_metal := String(neighbor.get("material", "")) == "metal"
			var is_amplifier := bool(neighbor.get("cooling_amplifier", false))
			if is_metal or is_amplifier:
				output = maxi(output, 2)
				break
		strongest = maxi(strongest, output)
	return strongest

static func get_air_cooler_world_cooling_for_target(target_object: Dictionary, target_position: Vector2i, all_objects: Array[Dictionary]) -> int:
	var strongest := 0
	for object_data in all_objects:
		if String(object_data.get("cooling_device_type", "")) != "air_cooler":
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
		if String(object_data.get("cooling_device_type", "")) != "water_pipe":
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
		if String(object_data.get("cooling_device_type", "")) != "air_cooler":
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
				if String(duct_data.get("cooling_device_type", "")) != "air_duct":
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
	var object_type: String = String(source_data.get("object_type", "")).strip_edges().to_lower()
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
