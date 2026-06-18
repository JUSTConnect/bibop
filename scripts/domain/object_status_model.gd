extends RefCounted

# Target class: ObjectStatusModel
# Чистый расчёт read-only статуса объекта. Не создаёт UI.

static func build_status(data: Dictionary) -> Dictionary:
	var object_type: String = str(data.get("object_type", data.get("item_type", "unknown")))
	var power_state: String = get_power_state(data)
	var total_state: String = "ready"
	var raw_state: String = str(data.get("state", data.get("object_state", "on"))).to_lower()
	if raw_state in ["off", "broken", "overheat", "disabled"] or power_state == "unpowered":
		total_state = "not_ready"
	return {
		"object_type": object_type,
		"total_state": total_state,
		"power_state": power_state,
		"warnings": [],
	}

static func get_power_state(data: Dictionary) -> String:
	if data.has("object_power_state"):
		return str(data.get("object_power_state"))
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered")) else "unpowered"
	return "none"
