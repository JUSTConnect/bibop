extends RefCounted

# ObjectDataFactory
# Создаёт начальное runtime/config data из ObjectDefinition.
# Не создаёт UI и не знает про scenes.

static func make_initial_object_data(definition: Dictionary) -> Dictionary:
	var data: Dictionary = Dictionary(definition.get("base_parameters", {})).duplicate(true)
	data["id"] = str(definition.get("id", ""))
	data["definition_id"] = str(definition.get("id", ""))
	data["object_type"] = str(definition.get("object_type", "unknown"))
	data["object_group"] = str(definition.get("object_group", "generic"))
	data["display_name"] = str(definition.get("display_name", definition.get("id", "Object")))
	data["description"] = str(definition.get("description", ""))
	data["visual_id"] = str(definition.get("visual_id", ""))
	data["power_state"] = infer_power_state(data)
	return data


static func infer_power_state(data: Dictionary) -> String:
	var power_mode: String = str(data.get("power_mode", "none")).to_lower()
	if power_mode == "none":
		return "none"
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered")) else "unpowered"
	var state: String = str(data.get("state", "on")).to_lower()
	return "unpowered" if state == "off" else "powered"
