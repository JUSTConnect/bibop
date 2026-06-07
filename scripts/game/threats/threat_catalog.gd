extends RefCounted
class_name ThreatCatalog

# First-pass enemy/threat catalog for BIPOB.
# Data-only foundation for Map Constructor / future runtime systems.
# Do not add AI loops, combat resolvers, mission mutation or UI logic here.

const ThreatTypesRef = preload("res://scripts/game/threats/threat_types.gd")

const THREAT_BUG_1: String = "bug_1"
const THREAT_BUG_2: String = "bug_2"
const THREAT_BUG_3: String = "bug_3"
const THREAT_BUG_4: String = "bug_4"
const THREAT_BUG_5: String = "bug_5"

const THREAT_VAGUS_1: String = "vagus_1"
const THREAT_VAGUS_2: String = "vagus_2"
const THREAT_VAGUS_3: String = "vagus_3"

const THREAT_TURRET_1: String = "turret_1"
const THREAT_TURRET_2: String = "turret_2"
const THREAT_TURRET_3: String = "turret_3"

const THREAT_INFECTED_BIPOB: String = "infected_bipob"
const THREAT_HOSTILE_BIPOB: String = "hostile_bipob"

const BUG_IDS: Array[String] = [
	THREAT_BUG_1,
	THREAT_BUG_2,
	THREAT_BUG_3,
	THREAT_BUG_4,
	THREAT_BUG_5
]

const VAGUS_IDS: Array[String] = [
	THREAT_VAGUS_1,
	THREAT_VAGUS_2,
	THREAT_VAGUS_3
]

const TURRET_IDS: Array[String] = [
	THREAT_TURRET_1,
	THREAT_TURRET_2,
	THREAT_TURRET_3
]

const BIPOB_THREAT_IDS: Array[String] = [
	THREAT_INFECTED_BIPOB,
	THREAT_HOSTILE_BIPOB
]

static func get_all_threat_ids() -> Array[String]:
	var result: Array[String] = []
	result.append_array(BUG_IDS)
	result.append_array(VAGUS_IDS)
	result.append_array(TURRET_IDS)
	result.append_array(BIPOB_THREAT_IDS)
	return result

static func get_bug_ids() -> Array[String]:
	return BUG_IDS.duplicate()

static func get_vagus_ids() -> Array[String]:
	return VAGUS_IDS.duplicate()

static func get_turret_ids() -> Array[String]:
	return TURRET_IDS.duplicate()

static func get_bipob_threat_ids() -> Array[String]:
	return BIPOB_THREAT_IDS.duplicate()

static func has_threat(threat_id: String) -> bool:
	return _definitions().has(str(threat_id).strip_edges())

static func get_threat_definition(threat_id: String) -> Dictionary:
	var normalized_id: String = str(threat_id).strip_edges()
	return Dictionary(_definitions().get(normalized_id, {})).duplicate(true)

static func get_threat_display_name(threat_id: String) -> String:
	return str(get_threat_definition(threat_id).get("display_name", threat_id))

static func get_threats_by_kind(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var normalized_kind: String = str(kind).strip_edges()
	for threat_id in get_all_threat_ids():
		var definition: Dictionary = get_threat_definition(threat_id)
		if str(definition.get("kind", "")) == normalized_kind:
			result.append(definition)
	return result

static func get_map_constructor_palette_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for threat_id in get_all_threat_ids():
		var definition: Dictionary = get_threat_definition(threat_id)
		entries.append({
			"id": threat_id,
			"display_name": definition.get("display_name", threat_id),
			"category": "Threats",
			"kind": definition.get("kind", ""),
			"threat_id": threat_id,
			"placement": "floor",
			"visual_id": definition.get("visual_id", "object_generic"),
			"is_catalog_only": true
		})
	return entries

static func is_configured_bipob_threat(threat_id: String) -> bool:
	return str(get_threat_definition(threat_id).get("stats_source", "")) == ThreatTypesRef.STATS_SOURCE_CONFIGURED_BIPOB

static func is_static_turret(threat_id: String) -> bool:
	return ThreatTypesRef.has_capability(get_threat_definition(threat_id), ThreatTypesRef.CAPABILITY_TURRET_STATIC)

static func can_alert_others(threat_id: String) -> bool:
	return not ThreatTypesRef.has_capability(get_threat_definition(threat_id), ThreatTypesRef.CAPABILITY_NO_ALERT_BROADCAST)

static func get_attack_power_range(threat_id: String) -> Dictionary:
	var definition: Dictionary = get_threat_definition(threat_id)
	return Dictionary(definition.get("attack_power", {"min": 0, "max": 0})).duplicate(true)

static func get_overheat_limit(threat_id: String) -> int:
	return int(get_threat_definition(threat_id).get("overheat_limit", 0))

static func get_melee_evasion_percent(threat_id: String) -> int:
	return int(get_threat_definition(threat_id).get("melee_evasion_percent", 0))

static func validate_catalog() -> Array[String]:
	var warnings: Array[String] = []
	for threat_id in get_all_threat_ids():
		var definition: Dictionary = get_threat_definition(threat_id)
		if definition.is_empty():
			warnings.append("missing_definition:%s" % threat_id)
			continue
		if str(definition.get("id", "")) != threat_id:
			warnings.append("id_mismatch:%s" % threat_id)
		if str(definition.get("display_name", "")).strip_edges().is_empty():
			warnings.append("missing_display_name:%s" % threat_id)
		if str(definition.get("kind", "")).strip_edges().is_empty():
			warnings.append("missing_kind:%s" % threat_id)
		if not definition.has("attack_power"):
			warnings.append("missing_attack_power:%s" % threat_id)
	return warnings

static func _base_definition(
	threat_id: String,
	display_name: String,
	kind: String,
	model_tier: int,
	view_radius: int,
	attack_radius: Variant,
	attack_type: String,
	attack_power: Dictionary,
	health: int,
	overheat_limit: int,
	capabilities: Dictionary = {},
	extra: Dictionary = {}
) -> Dictionary:
	var definition: Dictionary = {
		"schema_version": ThreatTypesRef.DEFAULT_THREAT_SCHEMA_VERSION,
		"id": threat_id,
		"display_name": display_name,
		"kind": kind,
		"model_tier": model_tier,
		"stats_source": ThreatTypesRef.STATS_SOURCE_FIXED,
		"view_radius": view_radius,
		"attack_radius": attack_radius,
		"attack_type": attack_type,
		"attack_power": attack_power.duplicate(true),
		"health": health,
		"overheat_limit": overheat_limit,
		"capabilities": capabilities.duplicate(true),
		"alignment": ThreatTypesRef.ALIGNMENT_HOSTILE,
		"default_status": ThreatTypesRef.STATUS_ACTIVE,
		"visual_id": "object_generic"
	}
	for key_variant in extra.keys():
		definition[key_variant] = extra.get(key_variant)
	return definition

static func _definitions() -> Dictionary:
	return {
		THREAT_BUG_1: _base_definition(
			THREAT_BUG_1,
			"Bug 1 — Base Model",
			ThreatTypesRef.KIND_BUG,
			1,
			5,
			1,
			ThreatTypesRef.ATTACK_TYPE_MELEE,
			ThreatTypesRef.make_damage_range(1),
			2,
			2,
			{},
			{"melee_evasion_percent": 50, "notes": "Lowest-tier bug. Disabled by heat threshold effects."
			}
		),
		THREAT_BUG_2: _base_definition(
			THREAT_BUG_2,
			"Bug 2 — Reinforced Model",
			ThreatTypesRef.KIND_BUG,
			2,
			5,
			1,
			ThreatTypesRef.ATTACK_TYPE_MELEE,
			ThreatTypesRef.make_damage_range(1, 2),
			4,
			3,
			{},
			{"melee_evasion_percent": 50}
		),
		THREAT_BUG_3: _base_definition(
			THREAT_BUG_3,
			"Bug 3 — Burst Model",
			ThreatTypesRef.KIND_BUG,
			3,
			5,
			1,
			ThreatTypesRef.ATTACK_TYPE_MELEE_BURST,
			ThreatTypesRef.make_damage_range(4),
			2,
			2,
			{},
			{"melee_evasion_percent": 50, "attack_area": "around_self"}
		),
		THREAT_BUG_4: _base_definition(
			THREAT_BUG_4,
			"Bug 4 — Ranged Model",
			ThreatTypesRef.KIND_BUG,
			4,
			7,
			5,
			ThreatTypesRef.ATTACK_TYPE_RANGED,
			ThreatTypesRef.make_damage_range(1, 2),
			2,
			2,
			{},
			{"melee_evasion_percent": 50}
		),
		THREAT_BUG_5: _base_definition(
			THREAT_BUG_5,
			"Bug 5 — Elite Ranged Model",
			ThreatTypesRef.KIND_BUG,
			5,
			7,
			5,
			ThreatTypesRef.ATTACK_TYPE_RANGED,
			ThreatTypesRef.make_damage_range(2, 3),
			4,
			4,
			{},
			{"melee_evasion_percent": 50}
		),
		THREAT_VAGUS_1: _base_definition(
			THREAT_VAGUS_1,
			"Vagus 1 — Base Model",
			ThreatTypesRef.KIND_VAGUS,
			1,
			9,
			{"min": 1, "max": 9},
			ThreatTypesRef.ATTACK_TYPE_MELEE_AND_RANGED,
			ThreatTypesRef.make_damage_range(3, 5),
			10,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_SHOCKER,
				ThreatTypesRef.CAPABILITY_ANTI_HACK,
				ThreatTypesRef.CAPABILITY_CALL_BUGS
			]),
			{"evasion_percent": 0}
		),
		THREAT_VAGUS_2: _base_definition(
			THREAT_VAGUS_2,
			"Vagus 2 — Improved Model",
			ThreatTypesRef.KIND_VAGUS,
			2,
			9,
			{"min": 1, "max": 9},
			ThreatTypesRef.ATTACK_TYPE_MELEE_AND_RANGED,
			ThreatTypesRef.make_damage_range(3, 5),
			20,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_SHOCKER,
				ThreatTypesRef.CAPABILITY_ANTI_HACK,
				ThreatTypesRef.CAPABILITY_CALL_BUGS,
				ThreatTypesRef.CAPABILITY_CORRUPT_BIPOBS,
				ThreatTypesRef.CAPABILITY_CORRUPT_OBJECTS
			]),
			{"evasion_percent": 0, "corruption_default": "permanent_conversion"}
		),
		THREAT_VAGUS_3: _base_definition(
			THREAT_VAGUS_3,
			"Vagus 3 — Elite Model",
			ThreatTypesRef.KIND_VAGUS,
			3,
			9,
			{"min": 1, "max": 9},
			ThreatTypesRef.ATTACK_TYPE_MELEE_AND_RANGED,
			ThreatTypesRef.make_damage_range(3, 5),
			30,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_SHOCKER,
				ThreatTypesRef.CAPABILITY_ANTI_HACK,
				ThreatTypesRef.CAPABILITY_CALL_BUGS,
				ThreatTypesRef.CAPABILITY_CALL_VAGUS,
				ThreatTypesRef.CAPABILITY_CORRUPT_BIPOBS,
				ThreatTypesRef.CAPABILITY_CORRUPT_OBJECTS
			]),
			{"evasion_percent": 0, "corruption_default": "permanent_conversion"}
		),
		THREAT_TURRET_1: _base_definition(
			THREAT_TURRET_1,
			"Turret 1 — Base Model",
			ThreatTypesRef.KIND_TURRET,
			1,
			12,
			12,
			ThreatTypesRef.ATTACK_TYPE_RANGED,
			ThreatTypesRef.make_damage_range(1, 7),
			10,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_TURRET_STATIC,
				ThreatTypesRef.CAPABILITY_NO_ALERT_BROADCAST
			]),
			{"vision_angle": 45}
		),
		THREAT_TURRET_2: _base_definition(
			THREAT_TURRET_2,
			"Turret 2 — Improved Model",
			ThreatTypesRef.KIND_TURRET,
			2,
			12,
			12,
			ThreatTypesRef.ATTACK_TYPE_RANGED,
			ThreatTypesRef.make_damage_range(1, 7),
			20,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_TURRET_STATIC,
				ThreatTypesRef.CAPABILITY_NO_ALERT_BROADCAST
			]),
			{"vision_angle": 45}
		),
		THREAT_TURRET_3: _base_definition(
			THREAT_TURRET_3,
			"Turret 3 — Elite Model",
			ThreatTypesRef.KIND_TURRET,
			3,
			12,
			12,
			ThreatTypesRef.ATTACK_TYPE_RANGED,
			ThreatTypesRef.make_damage_range(1, 7),
			30,
			5,
			ThreatTypesRef.make_capabilities([
				ThreatTypesRef.CAPABILITY_TURRET_STATIC,
				ThreatTypesRef.CAPABILITY_NO_ALERT_BROADCAST
			]),
			{"vision_angle": 60}
		),
		THREAT_INFECTED_BIPOB: {
			"schema_version": ThreatTypesRef.DEFAULT_THREAT_SCHEMA_VERSION,
			"id": THREAT_INFECTED_BIPOB,
			"display_name": "Infected Bipob",
			"kind": ThreatTypesRef.KIND_BIPOB,
			"model_tier": 0,
			"stats_source": ThreatTypesRef.STATS_SOURCE_CONFIGURED_BIPOB,
			"alignment": ThreatTypesRef.ALIGNMENT_HOSTILE,
			"default_status": ThreatTypesRef.STATUS_INFECTED,
			"attack_power": ThreatTypesRef.make_damage_range(0),
			"capabilities": {},
			"visual_id": "object_generic",
			"notes": "Uses configured Bipob template/model/loadout. Infected implies hostile. Recovery requires disabling and Programmer flow later."
		},
		THREAT_HOSTILE_BIPOB: {
			"schema_version": ThreatTypesRef.DEFAULT_THREAT_SCHEMA_VERSION,
			"id": THREAT_HOSTILE_BIPOB,
			"display_name": "Hostile Bipob",
			"kind": ThreatTypesRef.KIND_BIPOB,
			"model_tier": 0,
			"stats_source": ThreatTypesRef.STATS_SOURCE_CONFIGURED_BIPOB,
			"alignment": ThreatTypesRef.ALIGNMENT_HOSTILE,
			"default_status": ThreatTypesRef.STATUS_HOSTILE,
			"attack_power": ThreatTypesRef.make_damage_range(0),
			"capabilities": {},
			"visual_id": "object_generic",
			"notes": "Uses configured Bipob template/model/loadout. Current config fields remain placeholder until templates drive stats."
		}
	}
