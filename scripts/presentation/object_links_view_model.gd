extends RefCounted

# ObjectLinksViewModel
# Link rows for inspector. Targets later come from LinkSystem.
# UI получает готовые rows и не читает links_schema напрямую.

static func create(links_schema: Array, _data: Dictionary = {}, entity_kind: String = "world_object", entity_id: String = "") -> Dictionary:
	var rows: Array[Dictionary] = []
	for link_variant in links_schema:
		var link: Dictionary = Dictionary(link_variant)
		var link_id: String = str(link.get("id", ""))
		if link_id.is_empty():
			continue
		var link_type: String = str(link.get("type", "unknown"))
		rows.append({
			"id": link_id,
			"label": str(link.get("label", link_id.replace("_", " ").capitalize())),
			"control_type": "readonly_text",
			"value": "type=%s" % link_type,
			"readonly": true,
			"entity_kind": entity_kind,
			"entity_id": entity_id,
			"link_type": link_type,
		})
	return {"section_id": "links", "title": "4. Links", "rows": rows}
