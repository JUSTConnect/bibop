extends RefCounted
class_name MapConstructorPropertyUpdateService

static func apply_property_updates(mission_manager: Variant, entity_kind: String, entity_id: String, updates: Dictionary, fallback_message: String = "Updated.") -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("update_map_constructor_entity_properties"):
		return normalize_mutation_result({}, fallback_message)
	return normalize_mutation_result(mission_manager.call("update_map_constructor_entity_properties", entity_kind, entity_id, updates), fallback_message)

static func apply_property_preset(mission_manager: Variant, entity_kind: String, entity_id: String, preset_id: String) -> Dictionary:
	if mission_manager == null or not mission_manager.has_method("apply_map_constructor_property_preset"):
		return normalize_mutation_result({}, "Preset applied.")
	return normalize_mutation_result(mission_manager.call("apply_map_constructor_property_preset", entity_kind, entity_id, preset_id), "Preset applied.")

static func normalize_mutation_result(result: Variant, fallback_message: String = "Updated.") -> Dictionary:
	var normalized: Dictionary = result.duplicate(true) if result is Dictionary else {}
	if not normalized.has("message"):
		normalized["message"] = fallback_message
	return normalized
