extends RefCounted
class_name MapConstructorLinkReadModelService

const LINK_FIELD_NAMES: Dictionary = {
	"linked_terminal": "linked_terminal_id",
	"linked_door": "target_door_id",
	"power_network": "power_network_id",
	"control_source": "control_source_id",
	"terminal_target": "target_door_id",
	"platform_target": "target_platform_id",
	"power_source": "power_source_id",
	"control_terminal": "control_terminal_id",
	"access_terminal": "access_terminal_id"
}

static func get_link_field_name(link_type: String) -> String:
	return _to_safe_string(LINK_FIELD_NAMES.get(link_type, ""))

static func build_link_picker_model(mission_manager: Variant, entity_kind: String, entity_id: String, link_type: String) -> Dictionary:
	var field_name: String = get_link_field_name(link_type)
	var model: Dictionary = {
		"ok": false,
		"field_name": field_name,
		"current_target_id": "",
		"current_label": "Current: (none)",
		"candidates": [],
		"has_single_target": false,
		"target_cell": Vector2i(-1, -1),
		"message": "Unsupported link type."
	}
	if field_name.is_empty():
		return model
	if mission_manager == null or not mission_manager.has_method("get_map_constructor_entity_by_id"):
		model["message"] = "Map constructor entity lookup is unavailable."
		return model
	var entity_info: Dictionary = mission_manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		model["message"] = "Map constructor entity not found."
		return model
	var data: Dictionary = _to_dictionary(entity_info.get("data", {}))
	var current_target_id: String = _to_safe_string(data.get(field_name, "")).strip_edges()
	model["current_target_id"] = current_target_id
	model["current_label"] = "Current: %s" % (current_target_id if not current_target_id.is_empty() else "(none)")
	var candidate_rows: Array[Dictionary] = []
	if link_type == "platform_target":
		candidate_rows = _build_platform_mechanism_candidates(mission_manager, current_target_id)
	elif mission_manager.has_method("get_map_constructor_link_candidates"):
		for candidate_variant in _to_array(mission_manager.call("get_map_constructor_link_candidates", entity_kind, entity_id, link_type)):
			candidate_rows.append(_make_candidate_row(_to_dictionary(candidate_variant), current_target_id))
	model["candidates"] = candidate_rows
	var target_cell: Vector2i = Vector2i(-1, -1)
	var target_entity_found: bool = false
	var virtual_target_has_map_target: bool = link_type in ["power_network", "platform_target"]
	if not current_target_id.is_empty() and not virtual_target_has_map_target:
		var target_entity: Dictionary = mission_manager.call("get_map_constructor_entity_by_id", "world_object", current_target_id)
		if bool(target_entity.get("ok", false)):
			target_entity_found = true
			target_cell = _to_vector2i(target_entity.get("cell", Vector2i(-1, -1)))
	model["target_cell"] = target_cell
	model["has_single_target"] = target_entity_found
	model["ok"] = true
	model["message"] = "Link candidates ready."
	return model

static func _build_platform_mechanism_candidates(mission_manager: Variant, current_target_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var seen: Dictionary = {}
	if not mission_manager.has_method("get_map_constructor_placed_object_rows"):
		return rows
	for row_variant in _to_array(mission_manager.call("get_map_constructor_placed_object_rows")):
		var row: Dictionary = _to_dictionary(row_variant)
		var object_id: String = _to_safe_string(row.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var entity: Dictionary = mission_manager.call("get_map_constructor_entity_by_id", "world_object", object_id)
		if not bool(entity.get("ok", false)):
			continue
		var data: Dictionary = _to_dictionary(entity.get("data", {}))
		if not _is_platform_data(data):
			continue
		var mechanism_id: String = _to_safe_string(data.get("mechanism_id", "")).strip_edges()
		if mechanism_id.is_empty():
			mechanism_id = "single:%s" % object_id
		if seen.has(mechanism_id):
			continue
		seen[mechanism_id] = true
		var cell: Vector2i = _to_vector2i(row.get("cell", entity.get("cell", Vector2i(-1, -1))))
		var candidate: Dictionary = {"id": mechanism_id, "object_type": "platform_mechanism", "cell": cell, "current": mechanism_id == current_target_id}
		candidate["label"] = "%s%s [platform mechanism]" % ["✓ " if bool(candidate.get("current", false)) else "", mechanism_id]
		rows.append(candidate)
	return rows

static func _make_candidate_row(candidate: Dictionary, current_target_id: String) -> Dictionary:
	var candidate_id: String = _to_safe_string(candidate.get("id", ""))
	var row: Dictionary = candidate.duplicate(true)
	row["id"] = candidate_id
	row["current"] = bool(candidate.get("current", false)) or candidate_id == current_target_id
	row["object_type"] = _to_safe_string(candidate.get("object_type", "obj"))
	row["cell"] = _to_vector2i(candidate.get("cell", Vector2i(-1, -1)))
	row["label"] = "%s%s [%s] %s" % ["✓ " if bool(row["current"]) else "", candidate_id, _to_safe_string(row["object_type"]), str(row["cell"])]
	return row

static func _is_platform_data(data: Dictionary) -> bool:
	var object_type: String = _to_safe_string(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = _to_safe_string(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	var archetype_id: String = _to_safe_string(data.get("archetype_id", "")).strip_edges().to_lower()
	return object_type == "platform" or object_group == "platform" or archetype_id == "platform" or data.has("platform_mode")

static func _to_safe_string(value: Variant) -> String:
	if value == null:
		return ""
	if value is String or value is StringName or value is NodePath:
		return str(value)
	if value is bool or value is int or value is float:
		return str(value)
	return ""

static func _to_array(value: Variant) -> Array:
	if value is Array:
		return value
	return []

static func _to_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}

static func _to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	return Vector2i(-1, -1)
