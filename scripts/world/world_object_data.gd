extends RefCounted
class_name WorldObjectData

const ALLOWED_OBJECT_GROUPS := [
	"door",
	"terminal",
	"wall",
	"power",
	"item",
	"physical_object",
	"threat"
]

const SCAN_UNKNOWN := 0
const SCAN_DETECTED := 1
const SCAN_IDENTIFIED := 2
const SCAN_ANALYZED := 3

static func create_base(id: String, display_name: String, object_group: String, object_type: String) -> Dictionary:
	var safe_group := object_group if object_group in ALLOWED_OBJECT_GROUPS else "physical_object"
	return {
		"id": id,
		"display_name": display_name,
		"object_group": safe_group,
		"object_type": object_type,
		"state": "active",
		"material": "unknown",
		"durability_current": 1,
		"durability_max": 1,
		"indestructible": false,
		"invulnerable": false,
		"blocks_movement": false,
		"blocks_vision": false,
		"power_mode": "external_power",
		"power_network_id": "",
		"is_powered": true,
		"control_mode": "internal_control",
		"controlled_by": [],
		"controls": [],
		"interaction_tags": [],
		"hidden_content": [],
		"embedded_objects": [],
		"scan_level": SCAN_UNKNOWN,
		"position": Vector2i.ZERO
	}

static func clamp_scan_level(level: int) -> int:
	return clampi(level, SCAN_UNKNOWN, SCAN_ANALYZED)
