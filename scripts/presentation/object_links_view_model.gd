extends RefCounted

# ObjectLinksViewModel
# Link rows for inspector.
# Первый рабочий слой: object_ref можно выбрать из placed objects.

static func create(links_schema: Array, data: Dictionary = {}, entity_kind: String = "world_object", entity_id: String = "", link_targets: Array = []) -> Dictionary:
	var rows: Array[Dictionary] = []
	if links_schema.is_empty():
		rows.append({
			"id": "links_info",
			"label": "Info",
			"control_type": "readonly_text",
			"value": "No links.",
			"readonly": true,
			"entity_kind": entity_kind,
			"entity_id": entity_id,
		})
		return {"section_id": "links", "title": "4. Links", "rows": rows}
	var links: Dictionary = Dictionary(data.get("links", {}))
	for link_variant in links_schema:
		var link: Dictionary = Dictionary(link_variant)
		var link_id: String = str(link.get("id", ""))
		if link_id.is_empty():
			continue
		var link_type: String = str(link.get("type", "unknown"))
		rows.append(_make_link_row(link, link_id, link_type, links.get(link_id, _default_value_for_link_type(link_type)), entity_kind, entity_id, link_targets))
	return {"section_id": "links", "title": "4. Links", "rows": rows}


static func _make_link_row(link: Dictionary, link_id: String, link_type: String, value: Variant, entity_kind: String, entity_id: String, link_targets: Array) -> Dictionary:
	var control_type: String = _control_type_for_link_type(link_type)
	return {
		"id": link_id,
		"label": str(link.get("label", link_id.replace("_", " ").capitalize())),
		"control_type": control_type,
		"value": _normalize_value(value, link_type),
		"readonly": entity_kind != "placed_object",
		"options": _make_options(link_type, link_targets),
		"apply_mode": "auto" if control_type == "enum" else "inline",
		"row_kind": "link_field",
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"link_type": link_type,
	}


static func _control_type_for_link_type(link_type: String) -> String:
	match link_type:
		"object_ref":
			return "enum"
		"object_ref_array":
			return "line_edit"
		_:
			return "line_edit"


static func _make_options(link_type: String, link_targets: Array) -> Array[String]:
	if link_type != "object_ref":
		return []
	var options: Array[String] = [""]
	for target_variant in link_targets:
		var target: Dictionary = Dictionary(target_variant)
		var target_id: String = str(target.get("id", ""))
		if not target_id.is_empty():
			options.append(target_id)
	return options


static func _normalize_value(value: Variant, link_type: String) -> Variant:
	if link_type == "object_ref_array":
		if value is Array:
			var parts: Array[String] = []
			for item in Array(value):
				parts.append(str(item))
			return ", ".join(parts)
		return str(value)
	return value


static func _default_value_for_link_type(link_type: String) -> Variant:
	if link_type == "object_ref_array":
		return []
	return ""
