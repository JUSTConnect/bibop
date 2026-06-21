extends RefCounted
class_name SurfaceMaterialCatalog

const FLOOR_MATERIALS: Array[Dictionary] = [
	{"id":"concrete","display_name":"Concrete","description":"Concrete floor using the floor_concrete asset.","material":"concrete","coating":"default","tags":["concrete","floor"],"style":"concrete","is_default":true},
	{"id":"steel","display_name":"Steel","description":"Steel floor using the floor_steel asset.","material":"steel","coating":"default","tags":["steel","floor"],"style":"steel","is_default":false},
	{"id":"titan","display_name":"Titan","description":"Titanium floor using the floor_titan asset.","material":"titan","coating":"default","tags":["titan","titanium","floor"],"style":"titan","is_default":false},
	{"id":"steel_default","display_name":"Steel (legacy)","description":"Legacy steel/default floor id mapped to steel.","material":"steel","coating":"default","tags":["steel","floor","legacy"],"style":"steel","is_legacy":true},
	{"id":"concrete_default","display_name":"Concrete (legacy)","description":"Legacy concrete/default floor id mapped to concrete.","material":"concrete","coating":"default","tags":["concrete","floor","legacy"],"style":"concrete","is_legacy":true},
	{"id":"titanium_default","display_name":"Titanium (legacy)","description":"Legacy titanium/default floor id mapped to titan.","material":"titan","coating":"default","tags":["titan","titanium","floor","legacy"],"style":"titan","is_legacy":true},
	{"id":"default_floor","display_name":"Default Floor (legacy)","description":"Legacy default floor id mapped to concrete.","material":"concrete","tags":["default","floor","legacy"],"style":"concrete","is_legacy":true},
	{"id":"clean_lab_floor","display_name":"Clean Lab Floor (legacy)","description":"Legacy clean-lab id mapped to steel.","material":"steel","tags":["clean","lab","legacy"],"style":"steel","is_legacy":true},
	{"id":"dark_service_floor","display_name":"Dark Service Floor (legacy)","description":"Legacy dark-service id mapped to concrete.","material":"concrete","tags":["dark","service","legacy"],"style":"concrete","is_legacy":true},
	{"id":"hazard_floor","display_name":"Hazard Floor (legacy)","description":"Legacy hazard id mapped to concrete.","material":"concrete","tags":["hazard","legacy"],"style":"concrete","is_legacy":true},
	{"id":"power_floor","display_name":"Power Floor (legacy)","description":"Legacy power id mapped to steel.","material":"steel","tags":["power","legacy"],"style":"steel","is_legacy":true},
	{"id":"damaged_floor","display_name":"Damaged Floor (legacy)","description":"Legacy damaged id mapped to concrete.","material":"concrete","tags":["damaged","legacy"],"style":"concrete","is_legacy":true},
	{"id":"reinforced_floor","display_name":"Reinforced Floor (legacy)","description":"Legacy reinforced id mapped to steel.","material":"steel","tags":["reinforced","legacy"],"style":"steel","is_legacy":true},
	{"id":"diagnostic_floor","display_name":"Diagnostic Floor (legacy)","description":"Legacy diagnostic id mapped to steel.","material":"steel","tags":["diagnostic","legacy"],"style":"steel","is_legacy":true}
]

const WALL_MATERIALS: Array[Dictionary] = [
	{"id":"concrete","display_name":"Concrete","description":"Concrete wall using production concrete height assets.","tags":["concrete","default"],"style":"concrete","damage_level":0,"is_default":true},
	{"id":"concrete_damage","display_name":"Concrete damage","description":"Legacy damaged concrete id mapped to the production concrete wall assets.","tags":["concrete","damaged"],"style":"concrete_damage","damage_level":2,"is_default":false,"is_legacy":true},
	{"id":"brick","display_name":"Brick","description":"Brick wall using production brick height assets.","tags":["brick"],"style":"brick","damage_level":0,"is_default":false},
	{"id":"breachable_concrete","display_name":"Breachable Concrete","description":"Breachable Wall / проламываемая стена using concrete wall visuals; Heavy Claw can remove it at mid, half-mid, or tall height.","tags":["concrete","breachable"],"style":"breachable_concrete","damage_level":0,"is_default":false,"wall_archetype":"breachable","breach_tools":["heavy_claw"],"allowed_wall_heights":["mid","halfmid","tall"]},
	{"id":"breachable_brick","display_name":"Breachable Brick","description":"Breachable Wall / проламываемая стена using brick wall visuals; Heavy Claw can remove it at mid, half-mid, or tall height.","tags":["brick","breachable"],"style":"breachable_brick","damage_level":0,"is_default":false,"wall_archetype":"breachable","breach_tools":["heavy_claw"],"allowed_wall_heights":["mid","halfmid","tall"]},
	{"id":"brick_damage","display_name":"Brick damage","description":"Legacy damaged brick id mapped to the production brick wall assets.","tags":["brick","damaged"],"style":"brick_damage","damage_level":3,"is_default":false,"is_legacy":true},
	{"id":"grate","display_name":"Grate","description":"Grate wall using production grate mid/halfmid/tall assets; lower heights normalize to mid.","tags":["grate","service"],"style":"grate","damage_level":1,"is_default":false},
	{"id":"steel","display_name":"Steel","description":"Steel wall using production steel height assets.","tags":["steel"],"style":"steel","damage_level":0,"is_default":false},
	{"id":"reinforced_steel","display_name":"Reinforced Steel","description":"Reinforced steel wall using production reinforced steel height assets.","tags":["reinforced","steel"],"style":"reinforced_steel","damage_level":0,"is_default":false},
	{"id":"titan","display_name":"Titan","description":"Titan wall using production titan height assets.","tags":["titan","titanium"],"style":"titan","damage_level":0,"is_default":false},
	{"id":"outerwall","display_name":"Outerwall","description":"Outer boundary wall material using the production depth-based height gradient.","tags":["outer","boundary"],"style":"outerwall","damage_level":0,"is_default":false}
]

const FLOOR_MATERIAL_ALIASES: Dictionary = {
	"default_floor":"concrete", "floor_default":"concrete", "concrete":"concrete", "concrete_default":"concrete", "concrete_floor":"concrete", "floor_concrete":"concrete",
	"steel":"steel", "steel_default":"steel", "steel_floor":"steel", "floor_steel":"steel",
	"titan":"titan", "titan_default":"titan", "titanium":"titan", "titanium_default":"titan", "titan_floor":"titan", "titanium_floor":"titan", "floor_titan":"titan", "floor_titanium":"titan",
	"clean_lab_floor":"steel", "power_floor":"steel", "reinforced_floor":"steel", "diagnostic_floor":"steel",
	"dark_service_floor":"concrete", "hazard_floor":"concrete", "damaged_floor":"concrete"
}

const WALL_MATERIAL_ALIASES: Dictionary = {
	"default_metal":"concrete", "clean_lab":"concrete", "wall_clean_lab":"concrete", "dark_service":"grate", "wall_dark_service":"grate",
	"orange_hazard":"concrete_damage", "wall_orange_hazard":"concrete_damage", "damaged_red":"brick_damage", "wall_damaged_red":"brick_damage",
	"breachable_concrete":"breachable_concrete", "breachable_brick":"breachable_brick", "reinforced":"steel", "wall_reinforced":"steel",
	"power_room":"reinforced_steel", "wall_power_room":"reinforced_steel", "diagnostic_blue":"brick", "wall_diagnostic_blue":"brick",
	"outer_wall":"outerwall", "wall_outer":"outerwall", "wall_outerwall":"outerwall", "concrete":"concrete", "concrete_wall":"concrete", "wall_concrete":"concrete", "wall_concrete_default":"concrete",
	"concrete_damage":"concrete_damage", "concrete_damaged":"concrete_damage", "wall_concrete_damage":"concrete_damage", "wall_concrete_damaged":"concrete_damage", "damaged":"concrete_damage", "broken":"concrete_damage",
	"brick":"brick", "brick_wall":"brick", "wall_brick":"brick", "brick_damage":"brick_damage", "brick_damaged":"brick_damage", "wall_brick_damage":"brick_damage", "wall_brick_damaged":"brick_damage", "red":"brick_damage",
	"grate":"grate", "grate_wall":"grate", "wall_grate":"grate", "vent":"grate", "service":"grate", "wall_service_vent":"grate",
	"steel":"steel", "steel_wall":"steel", "wall_steel":"steel", "reinforced_steel":"reinforced_steel", "reinforce_steel":"reinforced_steel", "wall_reinforced_steel":"reinforced_steel",
	"titan":"titan", "titanium":"titan", "titan_wall":"titan", "titanium_wall":"titan", "wall_titan":"titan", "wall_titanium":"titan",
	"outer":"outerwall", "outerwall":"outerwall", "boundary":"outerwall", "wall_boundary":"outerwall", "industrial_panel":"brick", "wall_industrial_panel":"brick", "energy":"reinforced_steel", "powered":"reinforced_steel"
}

static func _normalize_key(value: String) -> String:
	var result := value.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	while result.contains("__"):
		result = result.replace("__", "_")
	return result

static func normalize_floor_material_id(material_id: String, fallback: String = "concrete") -> String:
	return str(FLOOR_MATERIAL_ALIASES.get(_normalize_key(material_id), fallback))

static func normalize_wall_material_id(material_id: String, fallback: String = "") -> String:
	var key := _normalize_key(material_id)
	return str(WALL_MATERIAL_ALIASES.get(key, fallback if not fallback.is_empty() else key))

static func is_known_floor_material_id(material_id: String) -> bool:
	return FLOOR_MATERIAL_ALIASES.has(_normalize_key(material_id))

static func is_known_wall_material_id(material_id: String) -> bool:
	return not get_wall_material(material_id).is_empty()

static func get_floor_materials(include_legacy: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in FLOOR_MATERIALS:
		if include_legacy or not bool(row.get("is_legacy", false)):
			result.append(row.duplicate(true))
	return result

static func get_wall_materials(include_legacy: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in WALL_MATERIALS:
		if include_legacy or not bool(row.get("is_legacy", false)):
			result.append(row.duplicate(true))
	return result

static func get_floor_material(material_id: String) -> Dictionary:
	var canonical := normalize_floor_material_id(material_id, "")
	for row in FLOOR_MATERIALS:
		if str(row.get("id", "")) == canonical:
			return row.duplicate(true)
	return {}

static func get_wall_material(material_id: String) -> Dictionary:
	var canonical := normalize_wall_material_id(material_id)
	for row in WALL_MATERIALS:
		if str(row.get("id", "")) == canonical:
			return row.duplicate(true)
	return {}

static func is_breachable_wall_material(material_id: String) -> bool:
	return str(get_wall_material(material_id).get("wall_archetype", "")) == "breachable"

static func get_allowed_wall_heights(material_id: String) -> Array[String]:
	var result: Array[String] = []
	for value in Array(get_wall_material(material_id).get("allowed_wall_heights", [])):
		result.append(str(value))
	return result

static func get_floor_catalog() -> Dictionary:
	return {"ok": true, "materials": get_floor_materials(true), "message": "Floor material catalog ready."}

static func get_wall_catalog() -> Dictionary:
	return {"ok": true, "materials": get_wall_materials(true), "message": "Wall material catalog ready."}

static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	var ids: Dictionary = {}
	for context in ["floor", "wall"]:
		var rows: Array[Dictionary] = FLOOR_MATERIALS if context == "floor" else WALL_MATERIALS
		for row in rows:
			var material_id := str(row.get("id", ""))
			var key := "%s:%s" % [context, material_id]
			if material_id.is_empty() or ids.has(key):
				errors.append("invalid_or_duplicate_%s" % key)
			ids[key] = true
			if str(row.get("display_name", "")).is_empty():
				errors.append("%s_missing_display_name" % key)
	for alias in FLOOR_MATERIAL_ALIASES:
		if get_floor_material(str(FLOOR_MATERIAL_ALIASES[alias])).is_empty():
			errors.append("floor_alias_missing_target_%s" % str(alias))
	for alias in WALL_MATERIAL_ALIASES:
		if get_wall_material(str(WALL_MATERIAL_ALIASES[alias])).is_empty():
			errors.append("wall_alias_missing_target_%s" % str(alias))
	return errors
