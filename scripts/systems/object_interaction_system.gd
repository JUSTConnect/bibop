extends RefCounted

# ObjectInteractionSystem
# Первый системный слой поверх links.
# Пока реализован только минимальный use-case:
# terminal.use -> toggles linked door states through links.controlled_targets.

static func use_object(actor_data: Dictionary, all_objects: Array[Dictionary]) -> Dictionary:
	var actor_type: String = str(actor_data.get("object_type", ""))
	if actor_type != "terminal":
		return {
			"ok": false,
			"message": "Selected object has no use behavior yet.",
			"patches": [],
		}
	return _use_terminal(actor_data, all_objects)


static func _use_terminal(actor_data: Dictionary, all_objects: Array[Dictionary]) -> Dictionary:
	var links: Dictionary = Dictionary(actor_data.get("links", {}))
	var controlled_targets: Array = _as_string_array(links.get("controlled_targets", []))
	if controlled_targets.is_empty():
		return {
			"ok": false,
			"message": "Terminal has no controlled targets.",
			"patches": [],
		}
	var objects_by_id: Dictionary = _index_objects_by_id(all_objects)
	var patches: Array[Dictionary] = []
	var changed_names: Array[String] = []
	for target_id_variant in controlled_targets:
		var target_id: String = str(target_id_variant)
		if not objects_by_id.has(target_id):
			continue
		var target: Dictionary = Dictionary(objects_by_id[target_id])
		if str(target.get("object_type", "")) != "door":
			continue
		var current_state: String = str(target.get("state", "closed")).to_lower()
		var next_state: String = "closed" if current_state == "open" else "open"
		patches.append({"instance_id": target_id, "patch": {"state": next_state}})
		changed_names.append("%s=%s" % [str(target.get("display_name", target_id)), next_state])
	if patches.is_empty():
		return {
			"ok": false,
			"message": "Terminal targets found, but no linked doors were changed.",
			"patches": [],
		}
	return {
		"ok": true,
		"message": "Terminal used: %s" % ", ".join(changed_names),
		"patches": patches,
	}


static func _index_objects_by_id(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var object_id: String = str(object_data.get("id", ""))
		if not object_id.is_empty():
			result[object_id] = object_data
	return result


static func _as_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var item_text: String = str(item).strip_edges()
			if not item_text.is_empty():
				result.append(item_text)
		return result
	for part in str(value).split(",", false):
		var part_text: String = String(part).strip_edges()
		if not part_text.is_empty():
			result.append(part_text)
	return result
