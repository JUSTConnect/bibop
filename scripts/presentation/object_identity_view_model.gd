extends RefCounted

# Target class: ObjectIdentityViewModel
# Identity rows: Name + Description.

static func create(entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	return {
		"section_id": "identity",
		"title": "1. Identity",
		"rows": [
			{"id": "display_name", "label": "Name", "control_type": "line_edit", "value": data.get("display_name", ""), "apply_mode": "inline", "entity_kind": entity_kind, "entity_id": entity_id},
			{"id": "description", "label": "Description", "control_type": "text_edit", "value": data.get("description", ""), "apply_mode": "inline", "entity_kind": entity_kind, "entity_id": entity_id},
		],
	}
