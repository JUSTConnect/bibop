extends RefCounted

const ObjectLinkSystemRef = preload("res://scripts/systems/object_link_system.gd")

static func create(links_schema: Array, data: Dictionary = {}, entity_kind: String = "world_object", entity_id: String = "", link_targets: Array = []) -> Dictionary:
	var rows: Array[Dictionary] = []
	if links_schema.is_empty():
		return {"section_id": "links", "title": "4. Links", "rows": [_info_row(entity_kind, entity_id, "No links.")]}
	var links: Dictionary = Dictionary(data.get("links", {}))
	var typed_targets: Array[Dictionary] = []
	for target_variant: Variant in link_targets:
		typed_targets.append(Dictionary(target_variant))
	var warnings: Array[String] = ObjectLinkSystemRef.validate_links(links, links_schema, entity_id, typed_targets)
	for link_variant: Variant in links_schema:
		var link: Dictionary = Dictionary(link_variant)
		var link_id: String = str(link.get("id", ""))
		if link_id.is_empty():
			continue
		var link_type: String = str(link.get("type", "unknown"))
		var default_value: Variant = _default_value_for_link_type(link_type)
		var current_value: Variant = links.get(link_id, default_value)
		rows.append(_make_link_row(link, link_id, link_type, current_value, entity_kind, entity_id, typed_targets))
	for warning: String in warnings:
		rows.append(_info_row(entity_kind, entity_id, warning))
	return {"section_id": "links", "title": "4. Links", "rows": rows}

static func _make_link_row(link: Dictionary, link_id: String, link_type: String, value: Variant, entity_kind: String, entity_id: String, link_targets: Array[Dictionary]) -> Dictionary:
	var control_type: String = _control_type_for_link_type(link_type)
	return {
		"id": link_id,
		"label": str(link.get("label", link_id.replace("_", " ").capitalize())),
		"control_type": control_type,
		"value": _normalize_value(value, link_type),
		"readonly": entity_kind != "placed_object",
		"options": _make_options(link_id, link_type, entity_id, link_targets),
		"apply_mode": "auto" if control_type == "enum" else "inline",
		"row_kind": "link_field",
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"link_type": link_type,
	}

static func _info_row(entity_kind: String, entity_id: String, text: String) -> Dictionary:
	return {"id": "links_info", "label": "Info", "control_type": "readonly_text", "value": text, "readonly": true, "entity_kind": entity_kind, "entity_id": entity_id}

static func _control_type_for_link_type(link_type: String) -> String:
	match link_type:
		"object_ref", "object_ref_array":
			return "enum"
		_:
			return "line_edit"

static func _make_options(link_id: String, link_type: String, entity_id: String, link_targets: Array[Dictionary]) -> Array[String]:
	if link_type != "object_ref" and link_type != "object_ref_array":
		return []
	var options: Array[String] = [""]
	options.append_array(ObjectLinkSystemRef.get_allowed_target_ids(link_id, link_type, entity_id, link_targets))
	return options

static func _normalize_value(value: Variant, link_type: String) -> Variant:
	if link_type == "object_ref_array":
		if value is Array:
			var values: Array = Array(value)
			if values.is_empty():
				return ""
			return str(values[0])
		return str(value)
	return value

static func _default_value_for_link_type(link_type: String) -> Variant:
	if link_type == "object_ref_array":
		return []
	return ""
