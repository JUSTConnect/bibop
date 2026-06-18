extends RefCounted

# Target class: ObjectStatusViewModel
# Read-only status rows for inspector.

static func create(status: Dictionary) -> Dictionary:
	return {
		"section_id": "status",
		"title": "2. Status",
		"rows": [
			{"id": "object_type", "label": "Object type", "control_type": "readonly_text", "value": status.get("object_type", "unknown")},
			{"id": "total_state", "label": "Total state", "control_type": "readonly_text", "value": status.get("total_state", "unknown")},
			{"id": "power_state", "label": "Power state", "control_type": "readonly_text", "value": status.get("power_state", "none")},
		],
	}
