extends RefCounted

# Target class: ValidationModel
# Чистая модель validation issue/quick fix.

static func make_issue(id: String, severity: String, message: String, entity_kind: String = "", entity_id: String = "") -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"quick_fixes": [],
	}
