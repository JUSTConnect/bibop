extends RefCounted
class_name FirewallService

const STATUS_ACTIVE := "active"
const STATUS_UNPOWERED := "unpowered"
const STATUS_LOCKED := "locked"
const STATUS_DISABLED := "disabled"
const STATUS_DAMAGED := "damaged"
const STATUS_ERROR := "error"

const FIREWALL_STATUSES: Array[String] = [
	STATUS_ACTIVE,
	STATUS_UNPOWERED,
	STATUS_LOCKED,
	STATUS_DISABLED,
	STATUS_DAMAGED,
	STATUS_ERROR
]

static func normalize_status(value: Variant) -> String:
	var status: String = str(value).strip_edges().to_lower()
	return status if FIREWALL_STATUSES.has(status) else STATUS_UNPOWERED

static func is_firewall_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var archetype_id: String = str(object_data.get("archetype_id", "")).strip_edges().to_lower()
	return object_type == "firewall" or archetype_id == "firewall"

static func is_interactable(object_data: Dictionary) -> bool:
	var status: String = normalize_status(object_data.get("status", STATUS_UNPOWERED))
	return status == STATUS_ACTIVE

static func get_visual_state_hint(object_data: Dictionary) -> String:
	var status: String = normalize_status(object_data.get("status", STATUS_UNPOWERED))
	if status == STATUS_UNPOWERED:
		return "base"
	if status == STATUS_ACTIVE:
		return "on"
	return "off"
