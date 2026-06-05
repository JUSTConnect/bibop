extends RefCounted
class_name PlatformTypes

const OBJECT_TYPE := "platform"
const MODE_ELEVATOR := "elevator"
const MODE_ROTATOR := "rotator"
const MODE_ELEVATOR_ROTATOR := "elevator_rotator"
const MODES: Array[String] = [MODE_ELEVATOR, MODE_ROTATOR, MODE_ELEVATOR_ROTATOR]
const ROLE_SINGLE := "single"
const ROLES: Array[String] = [ROLE_SINGLE, "member", "controller"]
const CONTROL_INTERNAL := "internal"
const CONTROL_EXTERNAL := "external"
const CONTROL_TYPES: Array[String] = [CONTROL_INTERNAL, CONTROL_EXTERNAL]
const POWER_NONE := "none"
const POWER_INTERNAL := "internal"
const POWER_EXTERNAL := "external"
const POWER_TYPES: Array[String] = [POWER_NONE, POWER_INTERNAL, POWER_EXTERNAL]
const ACTIVATION_INSTANT := "instant"
const ACTIVATION_DELAYED := "delayed"
const ACTIVATION_MODES: Array[String] = [ACTIVATION_INSTANT, ACTIVATION_DELAYED]

const DEFAULT_PLATFORM_CONFIG: Dictionary = {
	"object_type": OBJECT_TYPE,
	"platform_mode": MODE_ELEVATOR,
	"platform_level": 0,
	"max_level": 1,
	"mechanism_id": "",
	"mechanism_role": ROLE_SINGLE,
	"control_type": CONTROL_INTERNAL,
	"power_type": POWER_NONE,
	"activation_mode": ACTIVATION_INSTANT,
	"activation_delay_turns": 0,
	"control_cell_x": 0,
	"control_cell_y": 0
}

static func is_platform_data(platform_data: Dictionary) -> bool:
	return str(platform_data.get("object_type", "")).strip_edges().to_lower() == OBJECT_TYPE or str(platform_data.get("archetype_id", "")).strip_edges().to_lower() == OBJECT_TYPE

static func default_platform_config() -> Dictionary:
	return DEFAULT_PLATFORM_CONFIG.duplicate(true)

static func normalize_platform_config(platform_data: Dictionary) -> Dictionary:
	var data: Dictionary = default_platform_config()
	for key_variant in platform_data.keys():
		data[str(key_variant)] = platform_data[key_variant]
	data["object_type"] = OBJECT_TYPE
	data["platform_mode"] = _normalize_enum(data.get("platform_mode", MODE_ELEVATOR), MODES, MODE_ELEVATOR)
	data["mechanism_role"] = _normalize_enum(data.get("mechanism_role", ROLE_SINGLE), ROLES, ROLE_SINGLE)
	data["control_type"] = _normalize_enum(data.get("control_type", CONTROL_INTERNAL), CONTROL_TYPES, CONTROL_INTERNAL)
	data["power_type"] = _normalize_enum(data.get("power_type", POWER_NONE), POWER_TYPES, POWER_NONE)
	data["activation_mode"] = _normalize_enum(data.get("activation_mode", ACTIVATION_INSTANT), ACTIVATION_MODES, ACTIVATION_INSTANT)
	data["platform_level"] = maxi(0, int(data.get("platform_level", 0)))
	data["max_level"] = maxi(1, int(data.get("max_level", 1)))
	data["platform_level"] = mini(int(data["platform_level"]), int(data["max_level"]))
	data["activation_delay_turns"] = maxi(0, int(data.get("activation_delay_turns", 0)))
	data["control_cell_x"] = int(data.get("control_cell_x", 0))
	data["control_cell_y"] = int(data.get("control_cell_y", 0))
	return data

static func _normalize_enum(value: Variant, values: Array[String], fallback: String) -> String:
	var text: String = str(value).strip_edges().to_lower()
	return text if values.has(text) else fallback
