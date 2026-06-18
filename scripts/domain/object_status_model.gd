extends RefCounted

# ObjectStatusModel
# Чистый расчёт read-only статуса объекта. Не создаёт UI.

static func build_status(data: Dictionary) -> Dictionary:
	var object_type: String = str(data.get("object_type", data.get("item_type", "unknown")))
	var power_state: String = get_power_state(data)
	var total_state: String = get_total_state(data, power_state)
	return {
		"object_type": object_type,
		"total_state": total_state,
		"power_state": power_state,
		"warnings": [],
	}


static func get_total_state(data: Dictionary, power_state: String = "") -> String:
	var resolved_power_state: String = power_state
	if resolved_power_state.is_empty():
		resolved_power_state = get_power_state(data)
	var raw_state: String = str(data.get("state", data.get("object_state", "on"))).to_lower()
	if raw_state in ["off", "broken", "overheat", "disabled"] or resolved_power_state == "unpowered":
		return "Not ready"
	return "Ready"


static func get_power_state(data: Dictionary) -> String:
	if data.has("object_power_state"):
		return str(data.get("object_power_state"))
	if data.has("power_state"):
		return str(data.get("power_state"))
	var power_mode: String = str(data.get("power_mode", data.get("power_type", "none"))).to_lower()
	if power_mode == "none":
		return "none"
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered")) else "unpowered"
	var state: String = str(data.get("state", data.get("object_state", "on"))).to_lower()
	return "unpowered" if state == "off" else "powered"
