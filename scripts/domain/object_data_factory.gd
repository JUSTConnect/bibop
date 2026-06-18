extends RefCounted

const ObjectConfigSchemaRef = preload("res://scripts/domain/object_config_schema.gd")
const ObjectRuntimeStateRef = preload("res://scripts/domain/object_runtime_state.gd")

static func make_initial_object_data(definition: Dictionary) -> Dictionary:
	var base_config: Dictionary = ObjectConfigSchemaRef.make_base_config(definition)
	var data: Dictionary = base_config.duplicate(true)
	data["base_config"] = base_config
	data["config_overrides"] = {}
	data["links"] = _make_initial_links(definition)
	data["id"] = str(definition.get("id", ""))
	data["definition_id"] = str(definition.get("id", ""))
	data["object_type"] = str(definition.get("object_type", "unknown"))
	data["object_group"] = str(definition.get("object_group", "generic"))
	data["display_name"] = str(definition.get("display_name", definition.get("id", "Object")))
	data["description"] = str(definition.get("description", ""))
	data["visual_id"] = str(definition.get("visual_id", ""))
	data["power_state"] = infer_power_state(data)
	return ObjectRuntimeStateRef.merge_into_data(data, ObjectRuntimeStateRef.make_initial(definition, data))

static func infer_power_state(data: Dictionary) -> String:
	var power_mode: String = str(data.get("power_mode", "none")).to_lower()
	if power_mode == "none":
		return "none"
	if data.has("is_powered"):
		return "powered" if bool(data.get("is_powered")) else "unpowered"
	var state: String = str(data.get("state", "on")).to_lower()
	return "unpowered" if state == "off" else "powered"

static func _make_initial_links(definition: Dictionary) -> Dictionary:
	var links: Dictionary = {}
	for link_variant in Array(definition.get("links_schema", [])):
		var link: Dictionary = Dictionary(link_variant)
		var link_id: String = str(link.get("id", ""))
		if not link_id.is_empty():
			links[link_id] = [] if str(link.get("type", "")) == "object_ref_array" else ""
	return links
