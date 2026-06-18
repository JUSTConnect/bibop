extends RefCounted

# Target class: ObjectConfigSchema
# Описывает редактируемые параметры объекта. Inspector строится из этой schema.

static func normalize_field(row: Dictionary) -> Dictionary:
	return {
		"id": str(row.get("id", row.get("field", ""))),
		"label": str(row.get("label", "")),
		"type": str(row.get("type", "string")),
		"default_value": row.get("default_value", row.get("default", null)),
		"options": Array(row.get("options", row.get("values", []))),
		"visible_if": Dictionary(row.get("visible_if", {})),
		"readonly": bool(row.get("readonly", false)),
	}
