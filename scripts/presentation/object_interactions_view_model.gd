extends RefCounted

static func create(data: Dictionary, entity_kind: String = "world_object", entity_id: String = "") -> Dictionary:
	var rows: Array[Dictionary] = []
	var interactions: Array = Array(data.get("interactions", []))
	if interactions.is_empty():
		rows.append(_row("interaction_info", "Info", "No interactions.", entity_kind, entity_id))
	else:
		rows.append(_row("available_interactions", "Available", ", ".join(_to_strings(interactions)), entity_kind, entity_id))
	return {"section_id": "interactions", "title": "5. Interactions", "rows": rows}

static func _row(id: String, label: String, value: String, entity_kind: String, entity_id: String) -> Dictionary:
	return {"id": id, "label": label, "control_type": "readonly_text", "value": value, "readonly": true, "entity_kind": entity_kind, "entity_id": entity_id}

static func _to_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
