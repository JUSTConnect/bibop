extends RefCounted
class_name MapConstructorMarkerModel

static func build(entity_ids: Array, _issues: Array, diagnostics_enabled: bool, _override_entity_ids: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if diagnostics_enabled:
		for value in entity_ids:
			result.append({"entity_id":str(value), "role":"ready", "code":"map_constructor.ready"})
	return result
