extends RefCounted
class_name MapConstructorMarkerModel

static func build(entity_ids: Array, issues: Array, diagnostics_enabled: bool, override_entity_ids: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var normalized_ids: Array[String] = []
	for value in entity_ids:
		var entity_id: String = str(value).strip_edges()
		if not entity_id.is_empty() and not normalized_ids.has(entity_id):
			normalized_ids.append(entity_id)
	normalized_ids.sort()
	for entity_id in normalized_ids:
		var selected_code: String = ""
		var selected_role: String = ""
		for value in issues:
			if not value is Dictionary:
				continue
			var issue: Dictionary = Dictionary(value)
			if str(issue.get("entity_id", "")).strip_edges() != entity_id:
				continue
			if bool(issue.get("blocks_promotion", false)):
				selected_code = str(issue.get("code", ""))
				selected_role = "blocked"
				break
			if selected_role.is_empty() and str(issue.get("severity", "")).strip_edges().to_lower() == "warning":
				selected_code = str(issue.get("code", ""))
				selected_role = "warning"
		if not selected_role.is_empty():
			result.append({"entity_id":entity_id, "role":selected_role, "code":selected_code})
		elif diagnostics_enabled:
			result.append({"entity_id":entity_id, "role":"ready", "code":"map_constructor.ready"})
		if diagnostics_enabled and override_entity_ids.has(entity_id):
			result.append({"entity_id":entity_id, "role":"override", "code":"map_constructor.test_override_active"})
	return result
