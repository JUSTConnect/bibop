extends RefCounted

const DoorInteractionRulesRef = preload("res://scripts/systems/door_interaction_rules.gd")

static func use_object(actor_data: Dictionary, all_objects: Array[Dictionary]) -> Dictionary:
	var actor_type: String = str(actor_data.get("object_type", ""))
	match actor_type:
		"power_source":
			return _use_power_source(actor_data)
		"terminal":
			return _use_terminal(actor_data, all_objects)
		"door":
			return DoorInteractionRulesRef.use_door(actor_data, false)
		_:
			return {"ok": false, "message": "Selected object has no use behavior yet.", "patches": []}

static func _use_power_source(actor_data: Dictionary) -> Dictionary:
	var actor_id: String = str(actor_data.get("id", ""))
	var current_state: String = str(actor_data.get("state", "on")).to_lower()
	var next_state: String = "off" if current_state == "on" else "on"
	var next_power_state: String = "unpowered" if next_state == "off" else "powered"
	return {
		"ok": true,
		"message": "Power source %s." % next_state,
		"patches": [{"instance_id": actor_id, "patch": {"state": next_state, "power_state": next_power_state}}],
	}

static func _use_terminal(actor_data: Dictionary, all_objects: Array[Dictionary]) -> Dictionary:
	var objects_by_id: Dictionary = _index_objects_by_id(all_objects)
	var power_check: Dictionary = _check_terminal_power(actor_data, objects_by_id)
	if not bool(power_check.get("ok", false)):
		return power_check
	var links: Dictionary = Dictionary(actor_data.get("links", {}))
	var controlled_targets: Array[String] = _as_string_array(links.get("controlled_targets", []))
	if controlled_targets.is_empty():
		return {"ok": false, "message": "Terminal has no controlled targets.", "patches": []}
	var patches: Array[Dictionary] = []
	var changed_names: Array[String] = []
	for target_id: String in controlled_targets:
		if not objects_by_id.has(target_id):
			continue
		var target: Dictionary = Dictionary(objects_by_id[target_id])
		if str(target.get("object_type", "")) != "door":
			continue
		var result: Dictionary = DoorInteractionRulesRef.use_door(target, true)
		for patch_variant: Variant in Array(result.get("patches", [])):
			patches.append(Dictionary(patch_variant))
		if bool(result.get("ok", false)):
			changed_names.append(str(target.get("display_name", target_id)))
	if patches.is_empty():
		return {"ok": false, "message": "Terminal targets found, but no linked doors were changed.", "patches": []}
	return {"ok": true, "message": "Terminal used: %s" % ", ".join(changed_names), "patches": patches}

static func _check_terminal_power(actor_data: Dictionary, objects_by_id: Dictionary) -> Dictionary:
	var power_mode: String = str(actor_data.get("power_mode", "none")).to_lower()
	if power_mode != "external":
		return {"ok": true, "patches": []}
	if str(actor_data.get("power_state", "none")).to_lower() == "unpowered":
		return {"ok": false, "message": "Terminal is unpowered.", "patches": []}
	var links: Dictionary = Dictionary(actor_data.get("links", {}))
	var power_source_id: String = str(links.get("power_source", ""))
	if power_source_id.is_empty() or not objects_by_id.has(power_source_id):
		return {"ok": false, "message": "Terminal requires a linked power source.", "patches": []}
	var source: Dictionary = Dictionary(objects_by_id[power_source_id])
	if str(source.get("object_type", "")) != "power_source":
		return {"ok": false, "message": "Linked object is not a power source.", "patches": []}
	if str(source.get("state", "on")).to_lower() == "off":
		return {"ok": false, "message": "Terminal is unpowered: linked power source is off.", "patches": []}
	return {"ok": true, "patches": []}

static func _index_objects_by_id(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data: Dictionary in objects:
		var object_id: String = str(object_data.get("id", ""))
		if not object_id.is_empty():
			result[object_id] = object_data
	return result

static func _as_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in Array(value):
			var item_text: String = str(item).strip_edges()
			if not item_text.is_empty():
				result.append(item_text)
		return result
	for part: String in str(value).split(",", false):
		var part_text: String = part.strip_edges()
		if not part_text.is_empty():
			result.append(part_text)
	return result
