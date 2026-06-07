extends RefCounted
class_name ThreatTypes

# Shared constants for threat/enemy catalog data.
# This file is data-only. It must not implement combat AI or mission runtime logic.

const KIND_BUG: String = "bug"
const KIND_VAGUS: String = "vagus"
const KIND_TURRET: String = "turret"
const KIND_BIPOB: String = "bipob"

const ATTACK_TYPE_NONE: String = "none"
const ATTACK_TYPE_MELEE: String = "melee"
const ATTACK_TYPE_RANGED: String = "ranged"
const ATTACK_TYPE_MELEE_BURST: String = "melee_burst"
const ATTACK_TYPE_MELEE_AND_RANGED: String = "melee_and_ranged"

const STATS_SOURCE_FIXED: String = "fixed"
const STATS_SOURCE_CONFIGURED_BIPOB: String = "configured_bipob"

const ALIGNMENT_HOSTILE: String = "hostile"
const ALIGNMENT_FRIENDLY: String = "friendly"
const ALIGNMENT_NEUTRAL: String = "neutral"

const STATUS_ACTIVE: String = "active"
const STATUS_INFECTED: String = "infected"
const STATUS_HOSTILE: String = "hostile"
const STATUS_DISABLED: String = "disabled"

const CAPABILITY_CALL_BUGS: String = "can_call_bugs"
const CAPABILITY_CALL_VAGUS: String = "can_call_vagus"
const CAPABILITY_CORRUPT_BIPOBS: String = "can_corrupt_bipobs"
const CAPABILITY_CORRUPT_OBJECTS: String = "can_corrupt_objects"
const CAPABILITY_ANTI_HACK: String = "has_anti_hack_protection"
const CAPABILITY_SHOCKER: String = "has_shocker"
const CAPABILITY_TURRET_STATIC: String = "is_static_turret"
const CAPABILITY_NO_ALERT_BROADCAST: String = "does_not_alert_others"

const DEFAULT_THREAT_SCHEMA_VERSION: int = 1

static func make_damage_range(min_value: int, max_value: int = -1) -> Dictionary:
	var resolved_max: int = min_value if max_value < 0 else max_value
	return {
		"min": min_value,
		"max": resolved_max
	}

static func make_capabilities(flags: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for flag in flags:
		result[flag] = true
	return result

static func has_capability(definition: Dictionary, capability_id: String) -> bool:
	var capabilities: Dictionary = Dictionary(definition.get("capabilities", {}))
	return bool(capabilities.get(capability_id, false))

static func get_attack_power_min(definition: Dictionary) -> int:
	var attack_power: Dictionary = Dictionary(definition.get("attack_power", {}))
	return int(attack_power.get("min", 0))

static func get_attack_power_max(definition: Dictionary) -> int:
	var attack_power: Dictionary = Dictionary(definition.get("attack_power", {}))
	return int(attack_power.get("max", get_attack_power_min(definition)))
