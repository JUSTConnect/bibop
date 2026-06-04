extends RefCounted
class_name MapConstructorValidationService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const MapConstructorPowerLinkValidationRulesRef = preload("res://scripts/game/map_constructor_power_link_validation_rules.gd")
const MapConstructorReadinessValidationServiceRef = preload("res://scripts/game/map_constructor_readiness_validation_service.gd")
const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")
const BipobCableRuntimeServiceRef = preload("res://scripts/game/bipob_cable_runtime_service.gd")
const BipobAirflowRuntimeServiceRef = preload("res://scripts/game/bipob_airflow_runtime_service.gd")
var manager: Variant
var power_link_validation_rules: Variant = null

const MAP_CONSTRUCTOR_WALL_SIDE_DELTAS: Array[Dictionary] = [
	{"side":"north", "delta": Vector2i(0, -1)},
	{"side":"east", "delta": Vector2i(1, 0)},
	{"side":"south", "delta": Vector2i(0, 1)},
	{"side":"west", "delta": Vector2i(-1, 0)}
]

func _init(manager_ref: Node) -> void:
	manager = manager_ref

func _get_power_link_validation_rules() -> Variant:
	if power_link_validation_rules == null:
		power_link_validation_rules = MapConstructorPowerLinkValidationRulesRef.new(manager, self)
	return power_link_validation_rules

func _safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value).strip_edges()

func _map_constructor_token_is_key(value: Variant) -> bool:
	var token: String = _safe_string(value).to_lower()
	return token == "key" or token.begins_with("key_") or token.ends_with("_key") or token.contains("_key_") or token == "access_key" or token == "physical_key" or token == "digital_key"

func _map_constructor_metadata_says_key(data: Dictionary) -> bool:
	for field_name in ["prefab", "prefab_id", "category", "item_category", "metadata_category", "object_group", "item_group", "kind", "role"]:
		if _map_constructor_token_is_key(data.get(field_name, "")):
			return true
	return false

func _map_constructor_entity_kind(data: Dictionary) -> String:
	var object_group: String = _safe_string(data.get("object_group", "")).to_lower()
	var object_type: String = _safe_string(data.get("object_type", "")).to_lower()
	var prefab_id: String = _safe_string(data.get("map_constructor_prefab_id", object_type)).to_lower()
	var classifier: String = "%s|%s|%s" % [object_group, object_type, prefab_id]
	if "door" in classifier or "gate" in classifier:
		return "door"
	if "terminal" in classifier:
		return "terminal"
	if "power" in classifier or "socket" in classifier or "cable" in classifier or "switch" in classifier or "fuse" in classifier or "cool" in classifier or "control" in classifier:
		return "power_control_cooling"
	if object_group == "item" or object_type == "item" or manager.is_map_constructor_item_prefab(prefab_id):
		return "item"
	return "generic"

func _is_map_constructor_door_data(data: Dictionary) -> bool:
	for field_name in ["object_type", "category", "object_group", "group", "prefab", "prefab_id", "metadata_category", "kind", "role"]:
		var token: String = _safe_string(data.get(field_name, "")).to_lower()
		if token in ["door", "gate", "locked_door", "mechanical_door", "digital_door", "powered_gate", "security_door", "blast_door", "airlock_door"]:
			return true
		if token.begins_with("door_") or token.ends_with("_door") or token.contains("_door_") or token.begins_with("gate_") or token.ends_with("_gate") or token.contains("_gate_"):
			return true
	var id_token: String = _safe_string(data.get("id", "")).to_lower()
	return id_token.contains("door") or id_token.contains("gate")

func _is_map_constructor_key_data(data: Dictionary) -> bool:
	if _safe_string(data.get("item_type", "")).to_lower() == "key":
		return true
	if not _safe_string(data.get("key_type", "")).is_empty() or not _safe_string(data.get("key_kind", "")).is_empty():
		return true
	if _map_constructor_metadata_says_key(data):
		return true
	return _map_constructor_token_is_key(data.get("id", ""))

func get_cable_install_mode(object_data: Dictionary) -> String:
	if bool(object_data.get("hidden_installation", object_data.get("is_hidden", object_data.get("hidden", false)))):
		return "hidden"
	var raw_mode_value: Variant = object_data.get("cable_install_mode", object_data.get("install_mode", object_data.get("placement_mode", object_data.get("route_surface", "floor"))))
	var raw_mode: String = _safe_string(raw_mode_value).strip_edges().to_lower()
	match raw_mode:
		"hidden", "concealed", "embedded":
			return "hidden"
		"wall", "wall_cable", "wall_surface":
			return "wall"
		_:
			return "floor"

func get_cable_health_state(object_data: Dictionary) -> String:
	if bool(object_data.get("cut", false)):
		return "cut"
	if bool(object_data.get("broken", false)):
		return "broken"
	if bool(object_data.get("damaged", false)):
		return "damaged"
	var raw_state: String = _safe_string(object_data.get("cable_health_state", object_data.get("health_state", object_data.get("state", "normal")))).strip_edges().to_lower()
	if raw_state in ["damaged", "broken", "cut"]:
		return raw_state
	return "normal"

func _is_cable_object_data(object_data: Dictionary) -> bool:
	var object_type: String = _safe_string(object_data.get("object_type", object_data.get("item_type", ""))).strip_edges().to_lower()
	var object_group: String = _safe_string(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower()
	return object_type.contains("cable") or object_type.contains("wire") or object_group == "cable"

func _cell_has_wall_for_cable(cell: Vector2i) -> bool:
	if manager == null or not manager.has_method("_is_map_constructor_wall_cell"):
		return false
	return bool(manager.call("_is_map_constructor_wall_cell", cell))

func validate_constructor_palette_contract() -> Array[String]:
	var warnings: Array[String] = []
	var archetype_counts: Dictionary = {}
	var visible_wall_prefabs: Array[String] = []
	var visible_floor_prefabs: Array[String] = []
	var visible_item_prefabs: Array[String] = []
	for row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var prefab_id: String = _safe_string(row.get("prefab_id", row.get("id", ""))).strip_edges()
		var archetype_id: String = _safe_string(row.get("archetype_id", "")).strip_edges()
		if prefab_id.is_empty():
			warnings.append("constructor_palette_row_missing_prefab_id")
			continue
		if WorldObjectCatalogRef.LEGACY_DOOR_IDS.has(prefab_id) or WorldObjectCatalogRef.is_constructor_door_preset(prefab_id) or WorldObjectCatalogRef.LEGACY_WALL_ALIAS_CONFIGS.has(prefab_id) or WorldObjectCatalogRef.LEGACY_TERMINAL_ALIAS_CONFIGS.has(prefab_id):
			warnings.append("constructor_palette_exposes_legacy_alias_%s" % prefab_id)
		if archetype_id == "floor" or prefab_id == "floor":
			visible_floor_prefabs.append(prefab_id)
		if archetype_id == "item" or prefab_id == "item":
			visible_item_prefabs.append(prefab_id)
		if WorldObjectCatalogRef.LEGACY_ITEM_ALIAS_CONFIGS.has(prefab_id):
			warnings.append("constructor_palette_exposes_item_alias_%s" % prefab_id)
		if prefab_id == "stepped_floor" or WorldObjectCatalogRef.LEGACY_FLOOR_IDS.has(prefab_id):
			warnings.append("constructor_palette_exposes_floor_variant_%s" % prefab_id)
		if _safe_string(row.get("object_group", "")) == "wall":
			visible_wall_prefabs.append(prefab_id)
		if not archetype_id.is_empty():
			archetype_counts[archetype_id] = int(archetype_counts.get(archetype_id, 0)) + 1
			if int(archetype_counts[archetype_id]) > 1:
				warnings.append("constructor_palette_duplicate_archetype_%s" % archetype_id)
		var object_data: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, "validation_%s" % prefab_id)
		if object_data.is_empty():
			warnings.append("constructor_palette_prefab_creates_empty_object_%s" % prefab_id)
	var required_archetype_warning_ids: Dictionary = {
		"door":"constructor_palette_requires_exactly_one_door",
		"floor":"constructor_palette_requires_exactly_one_floor",
		"external_wall":"constructor_palette_requires_exactly_one_external_wall",
		"wall":"constructor_palette_requires_exactly_one_wall",
		"terminal":"constructor_palette_requires_exactly_one_terminal",
		"item":"constructor_palette_requires_exactly_one_item"
	}
	for required_archetype in required_archetype_warning_ids:
		if int(archetype_counts.get(required_archetype, 0)) != 1:
			warnings.append(required_archetype_warning_ids[required_archetype])
	if not archetype_counts.has("door"):
		warnings.append("constructor_palette_missing_door_archetype")
	if not archetype_counts.has("terminal"):
		warnings.append("constructor_palette_missing_terminal_archetype")
	if WorldObjectCatalogRef.get_archetype_property_schema("terminal").is_empty():
		warnings.append("terminal_archetype_missing_property_schema")
	if visible_wall_prefabs != ["external_wall", "wall"] and visible_wall_prefabs != ["wall", "external_wall"]:
		warnings.append("constructor_palette_wall_entries_must_be_exactly_external_wall_and_wall")
	if visible_floor_prefabs != ["floor"]:
		warnings.append("constructor_palette_floor_entries_must_be_exactly_floor")
	if visible_item_prefabs != ["item"]:
		warnings.append("constructor_palette_item_entries_must_be_exactly_item")
	if WorldObjectCatalogRef.get_archetype_property_schema("item").is_empty():
		warnings.append("item_archetype_missing_property_schema")
	var external_wall: Dictionary = WorldObjectCatalogRef.create_world_object("external_wall", "validation_external_wall")
	if bool(external_wall.get("configurable", true)):
		warnings.append("external_wall_must_not_be_configurable")
	if bool(external_wall.get("is_destructible", true)):
		warnings.append("external_wall_must_not_be_destructible")
	if not bool(external_wall.get("supports_embedded_objects", false)) or not bool(external_wall.get("supports_cables", false)):
		warnings.append("external_wall_must_support_embedded_objects_and_cables")
	var wall_schema: Array[Dictionary] = WorldObjectCatalogRef.get_archetype_property_schema("wall")
	var wall_material_schema: Dictionary = {}
	for field in wall_schema:
		if _safe_string(field.get("field", "")) == "material":
			wall_material_schema = field
	if wall_material_schema.is_empty():
		warnings.append("wall_archetype_missing_material_field")
	elif Array(wall_material_schema.get("values", [])) != WorldObjectCatalogRef.WALL_MATERIALS or _safe_string(wall_material_schema.get("default", "")) != WorldObjectCatalogRef.WALL_MATERIAL_BRICK:
		warnings.append("wall_archetype_material_contract_invalid")
	for material in WorldObjectCatalogRef.WALL_MATERIALS:
		var generated_wall: Dictionary = WorldObjectCatalogRef.create_archetype_object("wall", "validation_wall_%s" % material, {"material":material})
		if _safe_string(generated_wall.get("display_name", "")) != _safe_string(WorldObjectCatalogRef.WALL_DISPLAY_NAMES.get(material, "")):
			warnings.append("wall_display_name_not_generated_%s" % material)
	if not WorldObjectCatalogRef.get_wall_material_quick_presets().is_empty():
		warnings.append("wall_material_quick_presets_forbidden")
	var floor_schema: Array[Dictionary] = WorldObjectCatalogRef.get_archetype_property_schema("floor")
	if floor_schema.is_empty():
		warnings.append("floor_archetype_missing_property_schema")
	var floor_schema_fields: Dictionary = {}
	for field in floor_schema:
		floor_schema_fields[_safe_string(field.get("field", ""))] = field
	var floor_material_schema: Dictionary = floor_schema_fields.get("material", {})
	if floor_material_schema.is_empty():
		warnings.append("floor_archetype_missing_material_field")
	elif Array(floor_material_schema.get("values", [])) != WorldObjectCatalogRef.FLOOR_MATERIALS or _safe_string(floor_material_schema.get("default", "")) != "concrete":
		warnings.append("floor_archetype_material_contract_invalid")
	var floor_covering_schema: Dictionary = floor_schema_fields.get("covering", {})
	if floor_covering_schema.is_empty():
		warnings.append("floor_archetype_missing_covering_field")
	elif Array(floor_covering_schema.get("values", [])) != WorldObjectCatalogRef.FLOOR_COVERINGS or _safe_string(floor_covering_schema.get("default", "")) != "default":
		warnings.append("floor_archetype_covering_contract_invalid")
	var floor_visual_style_schema: Dictionary = floor_schema_fields.get("visual_style", {})
	if floor_visual_style_schema.is_empty():
		warnings.append("floor_archetype_missing_visual_style_field")
	elif Array(floor_visual_style_schema.get("values", [])) != WorldObjectCatalogRef.FLOOR_VISUAL_STYLES or _safe_string(floor_visual_style_schema.get("default", "")) != "default":
		warnings.append("floor_archetype_visual_style_contract_invalid")
	var expected_floor_display_names: Dictionary = {"concrete":"Concrete Floor", "steel":"Steel Floor", "titan":"Titan Floor"}
	for material in expected_floor_display_names:
		var generated_floor: Dictionary = WorldObjectCatalogRef.create_archetype_object("floor", "validation_floor_%s" % material, {"material":material})
		if _safe_string(generated_floor.get("display_name", "")) != _safe_string(expected_floor_display_names[material]):
			warnings.append("floor_display_name_not_generated_%s" % material)
	if manager != null and is_instance_valid(manager):
		var floor_palette_count: int = 0
		var terminal_palette_count: int = 0
		for palette_row in manager.get_map_constructor_prefab_catalog():
			var palette_id: String = _safe_string(palette_row.get("id", "")).strip_edges().to_lower()
			if palette_id == "floor":
				floor_palette_count += 1
			elif palette_id == "terminal":
				terminal_palette_count += 1
			elif WorldObjectCatalogRef.LEGACY_TERMINAL_ALIAS_CONFIGS.has(palette_id):
				warnings.append("constructor_palette_exposes_terminal_variant_%s" % palette_id)
			elif palette_id == "stepped_floor" or WorldObjectCatalogRef.LEGACY_FLOOR_IDS.has(palette_id):
				warnings.append("constructor_palette_exposes_floor_variant_%s" % palette_id)
		if floor_palette_count != 1:
			warnings.append("constructor_palette_expected_one_floor_row_got_%d" % floor_palette_count)
		if terminal_palette_count != 1:
			warnings.append("constructor_palette_expected_one_terminal_row_got_%d" % terminal_palette_count)
		for object_variant in manager.mission_world_objects:
			if typeof(object_variant) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_variant
			if _safe_string(object_data.get("archetype_id", "")).is_empty():
				continue
			var object_id: String = _safe_string(object_data.get("id", ""))
			for contract_warning in WorldObjectCatalogRef.validate_archetype_object(object_data):
				warnings.append("constructor_runtime_%s_%s" % [object_id, contract_warning])
	return warnings

func _get_manager_dictionary_property(property_name: String) -> Variant:
	if manager == null or not is_instance_valid(manager):
		return null
	for property_data in manager.get_property_list():
		if _safe_string(property_data.get("name", "")) != property_name:
			continue
		var property_value: Variant = manager.get(property_name)
		if typeof(property_value) == TYPE_DICTIONARY:
			return property_value
		return null
	return null

func _get_constructor_start_marker() -> Variant:
	return _get_manager_dictionary_property("constructor_start_marker")

func _get_constructor_exit_marker() -> Variant:
	return _get_manager_dictionary_property("constructor_exit_marker")

func _map_constructor_make_validation_link(label: String, target_id: String, target_kind: String, field_name: String) -> Dictionary:
	return _get_power_link_validation_rules()._map_constructor_make_validation_link(label, target_id, target_kind, field_name)

func _map_constructor_terminal_stores_key(terminal_id: String, key_id: String) -> bool:
	return _get_power_link_validation_rules()._map_constructor_terminal_stores_key(terminal_id, key_id)

func _count_lights_linked_to_source(source_id: String) -> int:
	return _get_power_link_validation_rules()._count_lights_linked_to_source(source_id)

func _count_adjacent_power_wires(cell: Vector2i, target_id: String = "") -> int:
	return _get_power_link_validation_rules()._count_adjacent_power_wires(cell, target_id)

func validate_map_constructor_entity_links(entity_kind: String, entity_id: String) -> Dictionary:
	return _get_power_link_validation_rules().validate_map_constructor_entity_links(entity_kind, entity_id)

func get_map_constructor_object_dependency_status(object_data: Dictionary) -> Dictionary:
	return _get_power_link_validation_rules().get_map_constructor_object_dependency_status(object_data)


func _map_constructor_merge_overlay_issue(overlay_objects: Dictionary, overlay_cells: Dictionary, object_id: String, severity: String, message: String) -> void:
	if not overlay_objects.has(object_id):
		return
	var row: Dictionary = manager._safe_dictionary(overlay_objects[object_id])
	var messages: Array = manager._safe_array(row.get("messages", []))
	messages.append(message)
	row["messages"] = messages
	var previous_severity: String = _safe_string(row.get("severity", "none"))
	if previous_severity != "error":
		if severity == "error" or (severity == "warning" and previous_severity == "none"):
			row["severity"] = severity
	overlay_objects[object_id] = row
	var object_cell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
	if overlay_cells.has(object_cell):
		var cell_row: Dictionary = manager._safe_dictionary(overlay_cells[object_cell])
		var cell_messages: Array = manager._safe_array(cell_row.get("messages", []))
		cell_messages.append(message)
		cell_row["messages"] = cell_messages
		var cell_prev_severity: String = _safe_string(cell_row.get("severity", "none"))
		if cell_prev_severity != "error":
			if severity == "error" or (severity == "warning" and cell_prev_severity == "none"):
				cell_row["severity"] = severity
		overlay_cells[object_cell] = cell_row

func get_map_constructor_validation_overlay() -> Dictionary:
	var overlay_cells: Dictionary = {}
	var overlay_objects: Dictionary = {}
	var audit: Dictionary = manager.get_task_test_system_audit_report()
	for object_data in manager.mission_world_objects:
		if typeof(object_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = manager._safe_dictionary(object_data)
		var object_id: String = _safe_string(data.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var object_cell: Vector2i = Vector2i(data.get("position", Vector2i(-1, -1)))
		var dependency: Dictionary = get_map_constructor_object_dependency_status(data)
		var object_severity: String = _safe_string(dependency.get("severity", "none"))
		var object_messages: Array[String] = []
		for msg in manager._safe_array(dependency.get("messages", [])):
			object_messages.append(_safe_string(msg))
		overlay_objects[object_id] = {"severity": object_severity, "cell": object_cell, "messages": object_messages, "link_targets": manager._safe_array(dependency.get("link_targets", []))}
		overlay_cells[object_cell] = {"severity": object_severity, "object_id": object_id, "messages": object_messages, "link_targets": manager._safe_array(dependency.get("link_targets", []))}
		if _safe_string(data.get("placement_mode", "")) == "wall_mounted":
			var anchor_cell: Vector2i = manager._deserialize_cell_variant(data.get("anchor_floor_cell", data.get("position", "-1,-1")))
			var attached_cell: Vector2i = manager._deserialize_cell_variant(data.get("attached_wall_cell", "-1,-1"))
			var wall_side: String = _safe_string(data.get("wall_side", "")).to_lower()
			var side_ok: bool = wall_side in ["north", "east", "south", "west"]
			if not side_ok:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted invalid wall_side.")
			if not manager._is_valid_grid_cell(anchor_cell):
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted invalid anchor_floor_cell.")
			if not manager._is_wall_or_boundary_cell(attached_cell):
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted attached_wall_cell is not wall/boundary.")
			if manager._is_valid_grid_cell(anchor_cell) and manager._is_wall_or_boundary_cell(attached_cell):
				if not (abs(anchor_cell.x - attached_cell.x) + abs(anchor_cell.y - attached_cell.y) == 1):
					_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted anchor and attached wall are not adjacent.")
				var expected_side: String = ""
				for side_entry in MAP_CONSTRUCTOR_WALL_SIDE_DELTAS:
					var delta: Vector2i = Vector2i(side_entry.get("delta", Vector2i.ZERO))
					if anchor_cell + delta == attached_cell:
						expected_side = _safe_string(side_entry.get("side", ""))
						break
				if not expected_side.is_empty() and wall_side != expected_side:
					_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells, object_id, "error", "Wall-mounted wall_side does not match attached wall cell.")

	for row_variant in manager._safe_array(audit.get("invalid_links", [])):
		var row_invalid: Dictionary = manager._safe_dictionary(row_variant)
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,_safe_string(row_invalid.get("object_id", "")), "error", "Invalid link: %s -> %s" % [_safe_string(row_invalid.get("field", "")), _safe_string(row_invalid.get("target_id", ""))])
	for row_variant in manager._safe_array(audit.get("expected_invalid_links", [])):
		var row_expected: Dictionary = manager._safe_dictionary(row_variant)
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,_safe_string(row_expected.get("object_id", "")), "warning", "Expected invalid link: %s -> %s" % [_safe_string(row_expected.get("field", "")), _safe_string(row_expected.get("target_id", ""))])
	for warning_variant in manager._safe_array(audit.get("runtime_cell_warnings", [])):
		var warning_text: String = _safe_string(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text: String = _safe_string(object_id_variant)
			if warning_text.find(object_id_text) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text, "error", warning_text)
	for warning_variant in manager._safe_array(audit.get("expected_runtime_warnings", [])):
		var warning_text_expected: String = _safe_string(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text_expected: String = _safe_string(object_id_variant)
			if warning_text_expected.find(object_id_text_expected) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text_expected, "warning", warning_text_expected)
	for warning_variant in manager._safe_array(audit.get("duplicate_cell_warnings", [])):
		var warning_text_dup: String = _safe_string(warning_variant)
		for object_id_variant in overlay_objects.keys():
			var object_id_text_dup: String = _safe_string(object_id_variant)
			if warning_text_dup.find(object_id_text_dup) != -1:
				_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,object_id_text_dup, "error", warning_text_dup)
	for object_id_variant in manager._safe_array(audit.get("objects_without_audit_tags", [])):
		_map_constructor_merge_overlay_issue(overlay_objects, overlay_cells,_safe_string(object_id_variant), "warning", "Object has no TASK TEST audit tag.")

	var summary: Dictionary = {"valid_count": 0, "warning_count": 0, "error_count": 0, "expected_warning_count": 0}
	var has_error_severity: bool = false
	for object_id_key in overlay_objects.keys():
		var object_row: Dictionary = manager._safe_dictionary(overlay_objects[object_id_key])
		var final_severity: String = _safe_string(object_row.get("severity", "none"))
		if final_severity == "valid":
			summary["valid_count"] = int(summary.get("valid_count", 0)) + 1
		elif final_severity == "warning":
			summary["warning_count"] = int(summary.get("warning_count", 0)) + 1
			if manager.is_task_test_expected_invalid_object_id(_safe_string(object_id_key)):
				summary["expected_warning_count"] = int(summary.get("expected_warning_count", 0)) + 1
		elif final_severity == "error":
			summary["error_count"] = int(summary.get("error_count", 0)) + 1
			has_error_severity = true

	for cell_row_variant in overlay_cells.values():
		var cell_row: Dictionary = manager._safe_dictionary(cell_row_variant)
		if _safe_string(cell_row.get("severity", "none")) == "error":
			has_error_severity = true
			break
	var has_errors: bool = int(summary.get("error_count", 0)) > 0 or has_error_severity
	var start_marker: Variant = _get_constructor_start_marker()
	var exit_marker: Variant = _get_constructor_exit_marker()
	var start_validation: Dictionary = {"ok": false, "message": "Start marker missing."}
	var exit_validation: Dictionary = {"ok": false, "message": "Exit marker missing."}
	if typeof(start_marker) == TYPE_DICTIONARY:
		start_validation = manager._validate_constructor_marker(start_marker, "start")
	if typeof(exit_marker) == TYPE_DICTIONARY:
		exit_validation = manager._validate_constructor_marker(exit_marker, "exit")
	if not bool(start_validation.get("ok", false)):
		summary["error_count"] = int(summary.get("error_count", 0)) + 1
		has_errors = true
		summary["start_marker_error"] = _safe_string(start_validation.get("message", "Start marker error."))
	if not bool(exit_validation.get("ok", false)):
		summary["error_count"] = int(summary.get("error_count", 0)) + 1
		has_errors = true
		summary["exit_marker_error"] = _safe_string(exit_validation.get("message", "Exit marker error."))
	return {"ok": not has_errors, "cells": overlay_cells, "objects": overlay_objects, "summary": summary}

func _make_map_constructor_issue(issue_id: String, severity: String, message: String, cell: Vector2i, source: String, entity_kind: String = "", entity_id: String = "", fix_hint: String = "") -> Dictionary:
	return {
		"id": issue_id,
		"severity": severity,
		"message": message,
		"cell": cell,
		"entity_kind": entity_kind,
		"entity_id": entity_id,
		"source": source,
		"fix_hint": fix_hint
	}

func _is_map_constructor_door_like_tile_type(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_DOOR:
		return true
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return true
	if tile_type == GridManager.TILE_POWERED_GATE:
		return true
	return false

func _get_map_constructor_door_object_for_cell(cell: Vector2i) -> Dictionary:
	for object_variant in manager.mission_world_objects:
		var object_data: Dictionary = manager._safe_dictionary(object_variant)
		var object_type: String = _safe_string(object_data.get("object_type", object_data.get("type", ""))).to_lower()
		var object_group: String = str(object_data.get("object_group", "")).to_lower()
		if not object_type.contains("door") and not object_type.contains("gate") and object_group != "door":
			continue
		var object_cell: Vector2i = manager._deserialize_cell_variant(object_data.get("position", Vector2i(-1, -1)))
		if object_cell == cell:
			return object_data
	return {}

func _get_map_constructor_door_opening_probe(cell: Vector2i) -> Dictionary:
	var result: Dictionary = {"ok": false, "has_wall_support": false, "orientation": "unknown", "ambiguous": false, "adjacent_wall_count": 0, "east_west_support": 0, "north_south_support": 0}
	if manager.grid_manager == null or not manager.grid_manager.has_method("get_tile") or not manager.grid_manager.has_method("is_in_bounds"):
		return result
	if not bool(manager.grid_manager.call("is_in_bounds", cell)):
		return result
	var tile_type: int = int(manager.grid_manager.call("get_tile", cell))
	if not _is_map_constructor_door_like_tile_type(tile_type):
		return result
	var east_cell: Vector2i = cell + Vector2i(1, 0)
	var west_cell: Vector2i = cell + Vector2i(-1, 0)
	var north_cell: Vector2i = cell + Vector2i(0, -1)
	var south_cell: Vector2i = cell + Vector2i(0, 1)
	var has_east_wall: bool = manager._is_map_constructor_wall_cell(east_cell)
	var has_west_wall: bool = manager._is_map_constructor_wall_cell(west_cell)
	var has_north_wall: bool = manager._is_map_constructor_wall_cell(north_cell)
	var has_south_wall: bool = manager._is_map_constructor_wall_cell(south_cell)
	var east_west_support: int = (1 if has_east_wall else 0) + (1 if has_west_wall else 0)
	var north_south_support: int = (1 if has_north_wall else 0) + (1 if has_south_wall else 0)
	var orientation: String = "unknown"
	if east_west_support > north_south_support:
		orientation = "axis_x"
	elif north_south_support > east_west_support:
		orientation = "axis_y"
	elif east_west_support > 0 and north_south_support > 0:
		orientation = "axis_x"
	elif east_west_support > 0:
		orientation = "axis_x"
	elif north_south_support > 0:
		orientation = "axis_y"
	var adjacent_wall_count: int = east_west_support + north_south_support
	var ambiguous: bool = false
	if east_west_support == north_south_support and east_west_support > 0:
		ambiguous = true
	elif adjacent_wall_count == 1:
		ambiguous = true
	return {"ok": true, "has_wall_support": adjacent_wall_count > 0, "orientation": orientation, "ambiguous": ambiguous, "adjacent_wall_count": adjacent_wall_count, "east_west_support": east_west_support, "north_south_support": north_south_support}

func get_map_constructor_door_opening_summary() -> Dictionary:
	var summary: Dictionary = {"door_count": 0, "digital_door_count": 0, "powered_gate_count": 0, "doors_with_wall_support": 0, "doors_without_wall_support": 0, "locked_count": 0, "damaged_count": 0, "powered_count": 0}
	if manager.grid_manager == null or not manager.grid_manager.has_method("get_tile") or not manager.grid_manager.has_method("get_map_width") or not manager.grid_manager.has_method("get_map_height"):
		return summary
	var width: int = int(manager.grid_manager.call("get_map_width"))
	var height: int = int(manager.grid_manager.call("get_map_height"))
	for y in range(height):
		for x in range(width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = int(manager.grid_manager.call("get_tile", cell))
			if not _is_map_constructor_door_like_tile_type(tile_type):
				continue
			summary["door_count"] = int(summary.get("door_count", 0)) + 1
			if tile_type == GridManager.TILE_DIGITAL_DOOR:
				summary["digital_door_count"] = int(summary.get("digital_door_count", 0)) + 1
			elif tile_type == GridManager.TILE_POWERED_GATE:
				summary["powered_gate_count"] = int(summary.get("powered_gate_count", 0)) + 1
			var probe: Dictionary = _get_map_constructor_door_opening_probe(cell)
			if bool(probe.get("has_wall_support", false)):
				summary["doors_with_wall_support"] = int(summary.get("doors_with_wall_support", 0)) + 1
			else:
				summary["doors_without_wall_support"] = int(summary.get("doors_without_wall_support", 0)) + 1
			var object_data: Dictionary = _get_map_constructor_door_object_for_cell(cell)
			if object_data.is_empty():
				continue
			var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
			var door_visual: Dictionary = manager.get_map_constructor_door_visual_state(object_id)
			var door_state: String = _safe_string(door_visual.get("state", object_data.get("state", "closed"))).to_lower()
			if door_state == "locked" or bool(object_data.get("is_locked", object_data.get("locked", false))):
				summary["locked_count"] = int(summary.get("locked_count", 0)) + 1
			if door_state == "broken" or door_state == "damaged" or bool(object_data.get("damaged", object_data.get("broken", false))):
				summary["damaged_count"] = int(summary.get("damaged_count", 0)) + 1
			if door_state == "powered" or bool(object_data.get("is_powered", object_data.get("powered", false))):
				summary["powered_count"] = int(summary.get("powered_count", 0)) + 1
	return summary


func _duplicate_world_objects_for_validation() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for object_variant in manager.mission_world_objects:
		if typeof(object_variant) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = Dictionary(object_variant).duplicate(true)
		result.append(object_data)
	return result

func _build_object_id_index(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
		if not object_id.is_empty():
			result[object_id] = object_data
	return result

func _get_object_cell_read_only(object_data: Dictionary) -> Vector2i:
	return manager._deserialize_cell_variant(object_data.get("position", Vector2i(-1, -1)))

func _is_generic_power_validation_candidate(object_data: Dictionary) -> bool:
	if bool(object_data.get("generic_power_runtime", false)) or bool(object_data.get("uses_generic_cable_runtime", false)):
		return true
	if not _safe_string(object_data.get("generic_power_role", object_data.get("power_role", object_data.get("cable_role", "")))).strip_edges().is_empty():
		return true
	for field_name in ["connection_id", "source_object_id", "sink_object_id", "socket_id", "endpoint_a_id", "endpoint_b_id"]:
		if not _safe_string(object_data.get(field_name, "")).strip_edges().is_empty():
			return true
	return false

func _generic_power_role(object_data: Dictionary) -> String:
	return BipobCableRuntimeServiceRef.get_generic_power_role(object_data)

func _role_is_power_sink(role: String, object_data: Dictionary) -> bool:
	return role in ["power_sink", "powered_device"] or bool(object_data.get("power_required", false)) or bool(object_data.get("requires_external_power", false))

func _role_is_socket(role: String) -> bool:
	return role in ["socket_input", "socket_output", "cable_endpoint"]

func _role_is_cable_link(role: String) -> bool:
	return role in ["cable_link", "cable_segment"]

func _append_generic_cable_validation_issues(source_name: String, issues: Array[Dictionary]) -> void:
	var runtime_objects: Array[Dictionary] = _duplicate_world_objects_for_validation()
	var object_by_id: Dictionary = _build_object_id_index(runtime_objects)
	var runtime_report: Dictionary = BipobCableRuntimeServiceRef.apply_generic_power_runtime(runtime_objects)
	var powered_ids: Dictionary = {}
	for powered_id_variant in manager._safe_array(runtime_report.get("powered_ids", [])):
		powered_ids[_safe_string(powered_id_variant).strip_edges()] = true
	var network_has_source: Dictionary = {}
	var network_has_sink: Dictionary = {}
	for object_data in runtime_objects:
		if not _is_generic_power_validation_candidate(object_data):
			continue
		var role: String = _generic_power_role(object_data)
		var network_id: String = _safe_string(object_data.get("power_network_id", "")).strip_edges()
		if role == "power_source" and not network_id.is_empty():
			network_has_source[network_id] = true
		if _role_is_power_sink(role, object_data) and not network_id.is_empty():
			network_has_sink[network_id] = true
	for object_data in runtime_objects:
		if not _is_generic_power_validation_candidate(object_data):
			continue
		var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
		var object_cell: Vector2i = _get_object_cell_read_only(object_data)
		var role: String = _generic_power_role(object_data)
		var network_id: String = _safe_string(object_data.get("power_network_id", "")).strip_edges()
		var connection_id: String = _safe_string(object_data.get("connection_id", "")).strip_edges()
		var source_object_id: String = _safe_string(object_data.get("source_object_id", object_data.get("power_source_id", ""))).strip_edges()
		var socket_id: String = _safe_string(object_data.get("socket_id", "")).strip_edges()
		if network_id.is_empty():
			issues.append(_make_map_constructor_issue("generic_cable_missing_network_%s" % object_id, "warning", "Generic cable/power object is missing power_network_id.", object_cell, source_name, "world_object", object_id, "Assign a power_network_id shared by the source, sockets, cable, and powered device."))
		elif role == "power_source" and not bool(network_has_sink.get(network_id, false)):
			issues.append(_make_map_constructor_issue("generic_cable_incomplete_chain_%s" % object_id, "warning", "Generic power source has no sink/powered device on its power network.", object_cell, source_name, "world_object", object_id, "Add a powered sink/device on the same power_network_id or remove the unused source."))
		elif _role_is_power_sink(role, object_data) and not bool(network_has_source.get(network_id, false)):
			issues.append(_make_map_constructor_issue("generic_cable_missing_source_%s" % object_id, "warning", "Generic powered device requires power but its network has no valid source.", object_cell, source_name, "world_object", object_id, "Add a generic power source on the same power_network_id."))
		if connection_id.is_empty() and role in ["socket_input", "socket_output", "cable_endpoint", "cable_link", "cable_segment", "power_sink", "powered_device"]:
			issues.append(_make_map_constructor_issue("generic_cable_incomplete_chain_%s_connection" % object_id, "warning", "Generic cable/socket chain is missing connection_id.", object_cell, source_name, "world_object", object_id, "Use a shared connection_id for connected generic cable objects."))
		if role != "power_source" and source_object_id.is_empty():
			issues.append(_make_map_constructor_issue("generic_cable_missing_source_%s" % object_id, "warning", "Generic cable/socket object is missing source_object_id.", object_cell, source_name, "world_object", object_id, "Link this object to a generic power source id."))
		elif role != "power_source" and not object_by_id.has(source_object_id):
			issues.append(_make_map_constructor_issue("generic_cable_missing_source_%s" % object_id, "warning", "Generic cable/socket object references a missing source_object_id: %s." % source_object_id, object_cell, source_name, "world_object", object_id, "Point source_object_id at an existing generic power source."))
		elif role != "power_source":
			var source_data: Dictionary = manager._safe_dictionary(object_by_id.get(source_object_id, {}))
			if _generic_power_role(source_data) != "power_source":
				issues.append(_make_map_constructor_issue("generic_cable_missing_source_%s" % object_id, "warning", "Generic cable/socket source_object_id does not point to a power source: %s." % source_object_id, object_cell, source_name, "world_object", object_id, "Point source_object_id at a generic power source."))
		if _role_is_power_sink(role, object_data):
			if socket_id.is_empty():
				issues.append(_make_map_constructor_issue("generic_cable_missing_socket_%s" % object_id, "warning", "Generic powered device is missing socket_id.", object_cell, source_name, "world_object", object_id, "Set socket_id to the output socket feeding this powered device."))
			elif not object_by_id.has(socket_id):
				issues.append(_make_map_constructor_issue("generic_cable_missing_socket_%s" % object_id, "warning", "Generic powered device references a missing socket_id: %s." % socket_id, object_cell, source_name, "world_object", object_id, "Point socket_id at an existing generic socket."))
			else:
				var socket_data: Dictionary = manager._safe_dictionary(object_by_id.get(socket_id, {}))
				if not _role_is_socket(_generic_power_role(socket_data)):
					issues.append(_make_map_constructor_issue("generic_cable_missing_socket_%s" % object_id, "warning", "Generic powered device socket_id points to an incompatible object: %s." % socket_id, object_cell, source_name, "world_object", object_id, "Point socket_id at a generic socket endpoint."))
			if not bool(powered_ids.get(object_id, false)):
				issues.append(_make_map_constructor_issue("generic_cable_sink_unpowered_%s" % object_id, "warning", "Generic powered device requires power but is unpowered in read-only validation.", object_cell, source_name, "world_object", object_id, "Complete the source/socket/cable chain."))
		if _role_is_cable_link(role):
			var endpoint_a_id: String = _safe_string(object_data.get("endpoint_a_id", "")).strip_edges()
			var endpoint_b_id: String = _safe_string(object_data.get("endpoint_b_id", "")).strip_edges()
			if endpoint_a_id.is_empty() or endpoint_b_id.is_empty():
				issues.append(_make_map_constructor_issue("generic_cable_incomplete_chain_%s" % object_id, "warning", "Generic cable link has a dangling cable endpoint.", object_cell, source_name, "world_object", object_id, "Connect both endpoint_a_id and endpoint_b_id."))
			for endpoint_id in [endpoint_a_id, endpoint_b_id]:
				if endpoint_id.is_empty():
					continue
				if not object_by_id.has(endpoint_id):
					issues.append(_make_map_constructor_issue("generic_cable_incomplete_chain_%s_%s" % [object_id, endpoint_id], "warning", "Generic cable endpoint references a missing object: %s." % endpoint_id, object_cell, source_name, "world_object", object_id, "Connect cable endpoints to existing socket/cable objects."))
				else:
					var endpoint_data: Dictionary = manager._safe_dictionary(object_by_id.get(endpoint_id, {}))
					var endpoint_role: String = _generic_power_role(endpoint_data)
					if not _role_is_socket(endpoint_role) and not _role_is_cable_link(endpoint_role):
						issues.append(_make_map_constructor_issue("generic_cable_incomplete_chain_%s_%s" % [object_id, endpoint_id], "warning", "Generic cable endpoint is connected to an incompatible object: %s." % endpoint_id, object_cell, source_name, "world_object", object_id, "Connect cable endpoints to generic sockets or cable links."))

func _is_generic_airflow_validation_candidate(object_data: Dictionary) -> bool:
	if bool(object_data.get("generic_airflow_runtime", false)):
		return true
	if not _safe_string(object_data.get("airflow_network_id", "")).strip_edges().is_empty():
		return object_data.has("generic_airflow_role") or object_data.has("airflow_roles") or object_data.has("cooling_required")
	return bool(object_data.get("cooling_required", false))

func _get_airflow_roles(object_data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var single_role: String = _safe_string(object_data.get("generic_airflow_role", "")).strip_edges()
	if not single_role.is_empty():
		result.append(single_role)
	var roles_variant: Variant = object_data.get("airflow_roles", [])
	if roles_variant is Array:
		for role_variant in Array(roles_variant):
			var role: String = _safe_string(role_variant).strip_edges()
			if not role.is_empty() and not result.has(role):
				result.append(role)
	return result

func _has_airflow_role(object_data: Dictionary, role: String) -> bool:
	return _get_airflow_roles(object_data).has(role)

func _is_airflow_fan(object_data: Dictionary) -> bool:
	return _has_airflow_role(object_data, "fan") or _has_airflow_role(object_data, "airflow_source")

func _is_airflow_target(object_data: Dictionary) -> bool:
	return _has_airflow_role(object_data, "cooling_target") or _has_airflow_role(object_data, "heat_sensitive_terminal") or bool(object_data.get("cooling_required", false))

func _is_airflow_blocker(object_data: Dictionary) -> bool:
	return _has_airflow_role(object_data, "airflow_blocker") or bool(object_data.get("blocks_airflow", false))

func _direction_to_vector2i_for_validation(value: Variant) -> Vector2i:
	var direction_text: String = _safe_string(value).strip_edges().to_lower()
	match direction_text:
		"up", "north":
			return Vector2i.UP
		"down", "south":
			return Vector2i.DOWN
		"left", "west":
			return Vector2i.LEFT
		"right", "east":
			return Vector2i.RIGHT
	return Vector2i.ZERO

func _get_airflow_linked_target_ids(fan_object: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for field_name in ["linked_cooling_ids", "linked_target_ids", "cooled_target_ids", "target_object_ids"]:
		var value: Variant = fan_object.get(field_name, [])
		if value is Array:
			for id_variant in Array(value):
				var target_id: String = _safe_string(id_variant).strip_edges()
				if not target_id.is_empty() and not result.has(target_id):
					result.append(target_id)
	var single_target_id: String = _safe_string(fan_object.get("target_object_id", "")).strip_edges()
	if not single_target_id.is_empty() and not result.has(single_target_id):
		result.append(single_target_id)
	return result

func _classify_airflow_uncooled_reason(target_data: Dictionary, fans: Array[Dictionary], objects: Array[Dictionary]) -> String:
	var target_cell: Vector2i = _get_object_cell_read_only(target_data)
	var target_network_id: String = _safe_string(target_data.get("airflow_network_id", "")).strip_edges()
	for fan_data in fans:
		if _safe_string(fan_data.get("airflow_network_id", "")).strip_edges() != target_network_id:
			continue
		var linked_ids: Array[String] = _get_airflow_linked_target_ids(fan_data)
		var target_id: String = _safe_string(target_data.get("id", "")).strip_edges()
		if not linked_ids.is_empty() and not linked_ids.has(target_id):
			continue
		if not bool(fan_data.get("fan_enabled", fan_data.get("enabled", false))):
			return "disabled"
		var direction: Vector2i = _direction_to_vector2i_for_validation(fan_data.get("fan_direction", fan_data.get("facing_dir", "")))
		if direction == Vector2i.ZERO:
			continue
		var fan_cell: Vector2i = _get_object_cell_read_only(fan_data)
		var delta: Vector2i = target_cell - fan_cell
		var aligned: bool = false
		var distance: int = 0
		if direction.x != 0 and delta.y == 0 and ((delta.x > 0 and direction.x > 0) or (delta.x < 0 and direction.x < 0)):
			aligned = true
			distance = abs(delta.x)
		elif direction.y != 0 and delta.x == 0 and ((delta.y > 0 and direction.y > 0) or (delta.y < 0 and direction.y < 0)):
			aligned = true
			distance = abs(delta.y)
		if not aligned:
			continue
		var airflow_range: int = maxi(0, int(fan_data.get("airflow_range", fan_data.get("fan_speed", 0))))
		if distance > airflow_range:
			return "out_of_range"
		var probe_cell: Vector2i = fan_cell + direction
		while probe_cell != target_cell:
			for object_data in objects:
				if _get_object_cell_read_only(object_data) == probe_cell and _is_airflow_blocker(object_data):
					return "blocked"
			probe_cell += direction
	return "uncooled"

func _append_generic_airflow_validation_issues(source_name: String, issues: Array[Dictionary]) -> void:
	var runtime_objects: Array[Dictionary] = _duplicate_world_objects_for_validation()
	var object_by_id: Dictionary = _build_object_id_index(runtime_objects)
	BipobAirflowRuntimeServiceRef.apply_generic_airflow_runtime(runtime_objects)
	var fans: Array[Dictionary] = []
	var network_has_enabled_fan: Dictionary = {}
	for object_data in runtime_objects:
		if not _is_generic_airflow_validation_candidate(object_data):
			continue
		if _is_airflow_fan(object_data):
			fans.append(object_data)
			var fan_network_id: String = _safe_string(object_data.get("airflow_network_id", "")).strip_edges()
			if not fan_network_id.is_empty() and bool(object_data.get("fan_enabled", object_data.get("enabled", false))):
				network_has_enabled_fan[fan_network_id] = true
	for object_data in runtime_objects:
		if not _is_generic_airflow_validation_candidate(object_data):
			continue
		var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
		var object_cell: Vector2i = _get_object_cell_read_only(object_data)
		var network_id: String = _safe_string(object_data.get("airflow_network_id", "")).strip_edges()
		if network_id.is_empty():
			issues.append(_make_map_constructor_issue("generic_airflow_missing_network_%s" % object_id, "warning", "Generic airflow/cooling object is missing airflow_network_id.", object_cell, source_name, "world_object", object_id, "Assign an airflow_network_id shared by fan, path, blocker, and cooling target."))
		if _is_airflow_fan(object_data):
			var raw_direction: String = _safe_string(object_data.get("fan_direction", object_data.get("facing_dir", ""))).strip_edges()
			if raw_direction.is_empty() or _direction_to_vector2i_for_validation(raw_direction) == Vector2i.ZERO:
				issues.append(_make_map_constructor_issue("generic_airflow_fan_missing_direction_%s" % object_id, "warning", "Generic airflow fan is missing a valid fan_direction.", object_cell, source_name, "world_object", object_id, "Set fan_direction to up/down/left/right or north/south/east/west."))
			for target_id in _get_airflow_linked_target_ids(object_data):
				if not object_by_id.has(target_id):
					issues.append(_make_map_constructor_issue("generic_airflow_target_uncooled_%s_%s" % [object_id, target_id], "warning", "Generic airflow fan links to a missing cooling target: %s." % target_id, object_cell, source_name, "world_object", object_id, "Fix linked target id or add the target object."))
				else:
					var linked_target: Dictionary = manager._safe_dictionary(object_by_id.get(target_id, {}))
					if not _is_airflow_target(linked_target):
						issues.append(_make_map_constructor_issue("generic_airflow_target_uncooled_%s_%s" % [object_id, target_id], "warning", "Generic airflow fan links to an object that is not a cooling target: %s." % target_id, object_cell, source_name, "world_object", object_id, "Link fans only to generic cooling targets."))
		if _is_airflow_target(object_data) and bool(object_data.get("cooling_required", false)):
			if not network_id.is_empty() and not bool(network_has_enabled_fan.get(network_id, false)):
				issues.append(_make_map_constructor_issue("generic_airflow_target_uncooled_%s_disabled_fan" % object_id, "warning", "Generic cooling target requires airflow but has no enabled fan on its network.", object_cell, source_name, "world_object", object_id, "Enable a fan on the same airflow_network_id."))
			if not bool(object_data.get("is_cooled", false)):
				var reason: String = _classify_airflow_uncooled_reason(object_data, fans, runtime_objects)
				var issue_id: String = "generic_airflow_target_uncooled_%s" % object_id
				var message: String = "Generic cooling target requires airflow but is uncooled in read-only validation."
				if reason == "blocked":
					issue_id = "generic_airflow_path_blocked_%s" % object_id
					message = "Generic cooling target is uncooled because the airflow path is blocked."
				elif reason == "out_of_range":
					issue_id = "generic_airflow_target_out_of_range_%s" % object_id
					message = "Generic cooling target is outside the fan airflow range."
				elif reason == "disabled":
					message = "Generic cooling target requires airflow but its matching fan is disabled."
				issues.append(_make_map_constructor_issue(issue_id, "warning", message, object_cell, source_name, "world_object", object_id, "Complete a clear fan-to-target airflow path."))

func _append_legacy_mission_removal_readiness_issues(source_name: String, issues: Array[Dictionary]) -> void:
	if FileAccess.file_exists("res://scripts/game/bipob_legacy_cable_flow_service.gd"):
		issues.append(_make_map_constructor_issue("legacy_mission7_dependency_present", "warning", "Legacy Mission 7 cable/socket/power adapter is still present; deletion is not ready in this PR.", Vector2i(-1, -1), source_name, "legacy_dependency", "mission7", "Review docs/bipob_legacy_mission7_8_removal_readiness_audit.md before deleting Mission 7 files."))
	if FileAccess.file_exists("res://scripts/game/bipob_legacy_airflow_flow_service.gd"):
		issues.append(_make_map_constructor_issue("legacy_mission8_dependency_present", "warning", "Legacy Mission 8 fan/airflow/cooling adapter is still present; deletion is not ready in this PR.", Vector2i(-1, -1), source_name, "legacy_dependency", "mission8", "Review docs/bipob_legacy_mission7_8_removal_readiness_audit.md before deleting Mission 8 files."))

func get_map_constructor_validation_issues() -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	var source_name: String = "map_constructor_validation"
	var seen_object_ids: Dictionary = {}
	var seen_occupancy_cells: Dictionary = {}
	var seen_item_ids: Dictionary = {}
	var has_grid_bounds: bool = false
	if manager.grid_manager != null and manager.grid_manager.has_method("is_in_bounds"):
		has_grid_bounds = true
	var palette_ids: Dictionary = {}
	var utility_palette_counts: Dictionary = {}
	var explicit_prefab_metadata: Dictionary = manager._get_map_constructor_prefab_metadata_catalog()
	for palette_entry in manager.get_map_constructor_prefab_catalog():
		var palette_prefab_id: String = _safe_string(palette_entry.get("id", "")).strip_edges().to_lower()
		palette_ids[palette_prefab_id] = true
		if WorldObjectCatalogRef.UTILITY_ITEM_ARCHETYPE_IDS.has(palette_prefab_id):
			utility_palette_counts[palette_prefab_id] = int(utility_palette_counts.get(palette_prefab_id, 0)) + 1
			if _safe_string(palette_entry.get("archetype_id", "")).strip_edges().to_lower() != palette_prefab_id:
				issues.append(_make_map_constructor_issue("palette_utility_not_archetype_%s" % palette_prefab_id, "error", "Utility palette row is not archetype-backed: %s." % palette_prefab_id, Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Expose the dedicated utility archetype row, not the raw OBJECT_LIBRARY item row."))
		if WorldObjectCatalogRef.is_legacy_prefab_alias(palette_prefab_id):
			issues.append(_make_map_constructor_issue("palette_legacy_alias_%s" % palette_prefab_id, "error", "Map Constructor palette exposes legacy alias: %s." % palette_prefab_id, Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Expose its canonical WorldObjectCatalog type instead."))
		var canonical_palette_prefab_id: String = _safe_string(palette_entry.get("canonical_object_type", WorldObjectCatalogRef.canonical_object_type(palette_prefab_id))).strip_edges().to_lower()
		var is_constructor_only_prefab: bool = explicit_prefab_metadata.has(palette_prefab_id) and not palette_entry.has("canonical_object_type")
		var is_archetype_prefab: bool = not WorldObjectCatalogRef.get_archetype_definition(palette_prefab_id).is_empty()
		if not WorldObjectCatalogRef.OBJECT_LIBRARY.has(canonical_palette_prefab_id) and not is_archetype_prefab and not is_constructor_only_prefab:
			issues.append(_make_map_constructor_issue("palette_unknown_prefab_%s" % palette_prefab_id, "error", "Map Constructor palette prefab has no canonical WorldObjectCatalog runtime type: %s." % palette_prefab_id, Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Add a canonical catalog object or keep this as an explicit constructor-only tile/item shortcut."))
		if WorldObjectCatalogRef.OBJECT_LIBRARY.has(canonical_palette_prefab_id) or is_archetype_prefab:
			var normalized_palette_object: Dictionary = WorldObjectCatalogRef.create_world_object(palette_prefab_id, "validation_palette_%s" % palette_prefab_id)
			var runtime_object_type: String = _safe_string(normalized_palette_object.get("object_type", "")).strip_edges().to_lower()
			if not WorldObjectCatalogRef.OBJECT_LIBRARY.has(runtime_object_type) and not is_archetype_prefab:
				issues.append(_make_map_constructor_issue("palette_unknown_runtime_type_%s" % palette_prefab_id, "error", "Map Constructor palette prefab would create unknown runtime object_type: %s." % runtime_object_type, Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Normalize placement through WorldObjectCatalog."))
			if WorldObjectCatalogRef.is_legacy_prefab_alias(runtime_object_type):
				issues.append(_make_map_constructor_issue("palette_runtime_legacy_alias_%s" % palette_prefab_id, "error", "Map Constructor palette prefab normalizes to legacy runtime object_type: %s." % runtime_object_type, Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Store legacy ids only as map_constructor_prefab_id metadata."))
			if _safe_string(normalized_palette_object.get("object_group", "")) == "door":
				for required_door_field in ["door_type", "material", "access_type", "door_class"]:
					if _safe_string(normalized_palette_object.get(required_door_field, "")).strip_edges().is_empty():
						issues.append(_make_map_constructor_issue("palette_door_missing_%s_%s" % [required_door_field, palette_prefab_id], "error", "Door palette prefab is missing %s after normalization: %s." % [required_door_field, palette_prefab_id], Vector2i(-1, -1), source_name, "palette", palette_prefab_id, "Complete the canonical door preset contract."))
	for utility_archetype_id in WorldObjectCatalogRef.UTILITY_ITEM_ARCHETYPE_IDS:
		if not WorldObjectCatalogRef.OBJECT_LIBRARY.has(utility_archetype_id):
			continue
		var utility_palette_count: int = int(utility_palette_counts.get(utility_archetype_id, 0))
		if utility_palette_count != 1:
			issues.append(_make_map_constructor_issue("palette_utility_count_%s" % utility_archetype_id, "error", "Utility archetype must appear exactly once in the Map Constructor palette: %s (found %d)." % [utility_archetype_id, utility_palette_count], Vector2i(-1, -1), source_name, "palette", utility_archetype_id, "Expose one dedicated utility archetype row."))
		var utility_palette_object: Dictionary = WorldObjectCatalogRef.create_world_object(utility_archetype_id, "validation_palette_utility_%s" % utility_archetype_id)
		for contract_warning in WorldObjectCatalogRef.validate_archetype_object(utility_palette_object):
			issues.append(_make_map_constructor_issue("palette_utility_contract_%s_%s" % [utility_archetype_id, contract_warning], "error", "Utility palette archetype contract violation: %s." % contract_warning, Vector2i(-1, -1), source_name, "palette", utility_archetype_id, "Normalize utility placement through the dedicated WorldObjectCatalog archetype."))
	for library_object_type_variant in WorldObjectCatalogRef.OBJECT_LIBRARY.keys():
		var library_object_type: String = _safe_string(library_object_type_variant).strip_edges().to_lower()
		var library_definition: Dictionary = Dictionary(WorldObjectCatalogRef.OBJECT_LIBRARY[library_object_type])
		if _safe_string(library_definition.get("group", "")).strip_edges().to_lower() == "item" and palette_ids.has(library_object_type) and WorldObjectCatalogRef.get_archetype_definition(library_object_type).is_empty():
			issues.append(_make_map_constructor_issue("palette_raw_item_row_%s" % library_object_type, "error", "Map Constructor palette exposes raw OBJECT_LIBRARY item row: %s." % library_object_type, Vector2i(-1, -1), source_name, "palette", library_object_type, "Expose a dedicated archetype row or keep the raw item hidden."))
	for catalog_row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var catalog_prefab_id: String = _safe_string(catalog_row.get("prefab_id", "")).strip_edges().to_lower()
		if not palette_ids.has(catalog_prefab_id):
			issues.append(_make_map_constructor_issue("palette_missing_catalog_object_%s" % catalog_prefab_id, "error", "Constructor-placeable catalog object missing from Map Constructor palette: %s." % catalog_prefab_id, Vector2i(-1, -1), source_name, "palette", catalog_prefab_id, "Generate object palette rows from WorldObjectCatalog."))
	for index in range(manager.mission_world_objects.size()):
		var data: Dictionary = manager._safe_dictionary(manager.mission_world_objects[index])
		var entity_kind: String = _map_constructor_entity_kind(data)
		if entity_kind == "item":
			var visible_item_id: String = _safe_string(data.get("id", "")).strip_edges()
			var visible_item_cell: Vector2i = manager._deserialize_cell_variant(data.get("position", Vector2i(-1, -1)))
			if not visible_item_id.is_empty() and manager.get_cell_item_by_id(visible_item_id).is_empty():
				issues.append(_make_map_constructor_issue("visible_item_missing_cell_item_%s" % visible_item_id, "error", "Visible dropped item is missing from cell_items pickup storage.", visible_item_cell, source_name, entity_kind, visible_item_id, "Store visible dropped items through add_item_at_cell()."))
			continue
		var object_id: String = _safe_string(data.get("id", "")).strip_edges()
		var object_type: String = _safe_string(data.get("object_type", "")).strip_edges()
		var object_group: String = _safe_string(data.get("object_group", "")).strip_edges()
		var object_cell: Vector2i = manager._deserialize_cell_variant(data.get("position", Vector2i(-1, -1)))
		if object_id.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_id_%d" % index, "error", "Object missing id.", object_cell, source_name, entity_kind, "", "Set unique id."))
		elif seen_object_ids.has(object_id):
			issues.append(_make_map_constructor_issue("obj_duplicate_id_%s_%d" % [object_id, index], "error", "Duplicate object id: %s." % object_id, object_cell, source_name, entity_kind, object_id, "Use unique ids."))
		else:
			seen_object_ids[object_id] = true
		if object_type.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_type_%d" % index, "error", "Object missing object_type.", object_cell, source_name, entity_kind, object_id))
		elif WorldObjectCatalogRef.is_legacy_prefab_alias(object_type):
			issues.append(_make_map_constructor_issue("obj_legacy_alias_%s" % object_id, "error", "Legacy alias object_type was not normalized: %s." % object_type, object_cell, source_name, entity_kind, object_id, "Normalize saved constructor data through WorldObjectCatalog."))
		elif bool(data.get("created_by_map_constructor", false)) and not WorldObjectCatalogRef.OBJECT_LIBRARY.has(object_type) and WorldObjectCatalogRef.get_archetype_definition(object_type).is_empty():
			issues.append(_make_map_constructor_issue("obj_unknown_constructor_type_%s" % object_id, "error", "Constructor object_type is not in WorldObjectCatalog: %s." % object_type, object_cell, source_name, entity_kind, object_id, "Use a canonical WorldObjectCatalog runtime object type."))
		var raw_access_type: String = _safe_string(data.get("access_type", "")).strip_edges().to_lower()
		if raw_access_type == "none":
			issues.append(_make_map_constructor_issue("obj_legacy_access_none_%s" % object_id, "error", "Legacy access_type=none must be normalized to no_key.", object_cell, source_name, entity_kind, object_id, "Normalize access_type through WorldObjectCatalog."))
		elif not raw_access_type.is_empty():
			var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_access_type)
			var canonical_link_access_types: Array[String] = [WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD, WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY, WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE, WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL]
			if normalized_access_type != raw_access_type or not normalized_access_type in WorldObjectCatalogRef.ACCESS_TYPES:
				issues.append(_make_map_constructor_issue("obj_invalid_access_type_%s" % object_id, "error", "Object access_type is not canonical: %s." % raw_access_type, object_cell, source_name, entity_kind, object_id, "Use %s, %s, %s, %s, or %s." % [WorldObjectCatalogRef.ACCESS_TYPE_NO_KEY, canonical_link_access_types[0], canonical_link_access_types[1], canonical_link_access_types[2], canonical_link_access_types[3]]))
		if data.has("lock_type") and not data.has("access_type"):
			issues.append(_make_map_constructor_issue("obj_lock_without_access_%s" % object_id, "error", "Legacy lock_type is present without canonical access_type.", object_cell, source_name, entity_kind, object_id, "Populate canonical access_type while retaining lock_type only as compatibility metadata."))
		_get_power_link_validation_rules().append_object_power_link_consistency_issues(data, object_cell, source_name, entity_kind, issues)
		if object_group == "door" and WorldObjectCatalogRef.is_material_named_door_object_type(object_type) and _safe_string(data.get("door_type", "")).strip_edges().is_empty():
			issues.append(_make_map_constructor_issue("obj_material_door_missing_mechanism_%s" % object_id, "error", "Material-named door is missing canonical door_type mechanism.", object_cell, source_name, entity_kind, object_id, "Populate canonical door_type."))
		if bool(data.get("created_by_map_constructor", false)) and WorldObjectCatalogRef.UTILITY_ITEM_ARCHETYPE_IDS.has(object_type):
			var runtime_utility_archetype_id: String = _safe_string(data.get("archetype_id", "")).strip_edges().to_lower()
			if runtime_utility_archetype_id != object_type:
				issues.append(_make_map_constructor_issue("obj_utility_missing_archetype_%s" % object_id, "error", "Constructor utility item is missing its dedicated archetype_id: %s." % object_type, object_cell, source_name, entity_kind, object_id, "Create utility placement through WorldObjectCatalog.create_world_object."))
			else:
				for contract_warning in WorldObjectCatalogRef.validate_archetype_object(data):
					issues.append(_make_map_constructor_issue("obj_utility_archetype_%s_%s" % [object_id, contract_warning], "error", "Utility item archetype contract violation: %s." % contract_warning, object_cell, source_name, entity_kind, object_id, "Normalize utility placement through WorldObjectCatalog archetype creation."))
		if object_group == "door":
			var raw_door_type: String = _safe_string(data.get("door_type", "")).strip_edges().to_lower()
			if raw_door_type not in WorldObjectCatalogRef.DOOR_TYPES:
				issues.append(_make_map_constructor_issue("obj_invalid_door_type_%s" % object_id, "error", "Door door_type is not canonical: %s." % raw_door_type, object_cell, source_name, entity_kind, object_id, "Use mechanical, digital, or powered."))
			var raw_power_behavior: String = _safe_string(data.get("power_behavior", "")).strip_edges().to_lower()
			if not raw_power_behavior.is_empty() and raw_power_behavior not in WorldObjectCatalogRef.POWER_BEHAVIORS:
				issues.append(_make_map_constructor_issue("obj_invalid_door_power_behavior_%s" % object_id, "error", "Door power_behavior is not canonical: %s." % raw_power_behavior, object_cell, source_name, entity_kind, object_id, "Use none, opens_when_unpowered, or requires_power_to_open."))
			for contract_warning in WorldObjectCatalogRef.validate_archetype_object(data):
				issues.append(_make_map_constructor_issue("obj_archetype_%s_%s" % [object_id, contract_warning], "error", "Door archetype contract violation: %s." % contract_warning, object_cell, source_name, entity_kind, object_id, "Normalize through WorldObjectCatalog archetype creation and schema validation."))
		if object_group.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_group_%d" % index, "error", "Object missing object_group.", object_cell, source_name, entity_kind, object_id))
		if object_cell.x < 0 or object_cell.y < 0:
			issues.append(_make_map_constructor_issue("obj_invalid_cell_%d" % index, "error", "Object position invalid or negative.", object_cell, source_name, entity_kind, object_id))
		elif has_grid_bounds and not bool(manager.grid_manager.call("is_in_bounds", object_cell)):
			issues.append(_make_map_constructor_issue("obj_out_of_bounds_%d" % index, "error", "Object out of bounds.", object_cell, source_name, entity_kind, object_id))
		if _is_cable_object_data(data) and get_cable_install_mode(data) == "wall":
			var cable_wall_cells: Array[Vector2i] = []
			cable_wall_cells.append(object_cell)
			for path_cell_variant in manager._safe_array(data.get("cable_path_cells", [])):
				var path_cell: Vector2i = manager._deserialize_cell_variant(path_cell_variant)
				if path_cell.x >= 0 and path_cell.y >= 0 and not cable_wall_cells.has(path_cell):
					cable_wall_cells.append(path_cell)
			for cable_wall_cell in cable_wall_cells:
				if cable_wall_cell.x >= 0 and cable_wall_cell.y >= 0 and not _cell_has_wall_for_cable(cable_wall_cell):
					issues.append(_make_map_constructor_issue("cable_wall_requires_wall_%s_%d_%d" % [object_id, cable_wall_cell.x, cable_wall_cell.y], "warning", "Wall cable requires a wall in this cell.", cable_wall_cell, source_name, entity_kind, object_id, "Place a wall in the same cell or set the cable install mode to Floor/Hidden."))
		var _cable_health_state_for_validation: String = get_cable_health_state(data) if _is_cable_object_data(data) else "normal"
		var allow_overlap: bool = bool(data.get("allow_cell_overlap", false)) or _is_cable_object_data(data)
		if not allow_overlap and object_group != "item" and object_group != "visual" and object_cell.x >= 0 and object_cell.y >= 0:
			var occupancy_key: String = "%d,%d" % [object_cell.x, object_cell.y]
			if seen_occupancy_cells.has(occupancy_key):
				issues.append(_make_map_constructor_issue("obj_duplicate_cell_%s_%d" % [occupancy_key, index], "warning", "Duplicate non-overlap cell occupancy at %s." % occupancy_key, object_cell, source_name, entity_kind, object_id))
			else:
				seen_occupancy_cells[occupancy_key] = object_id
		if _safe_string(data.get("placement_mode", "")).to_lower() == "wall_mounted":
			var anchor_floor_cell: Vector2i = manager._deserialize_cell_variant(data.get("anchor_floor_cell", Vector2i(-1, -1)))
			var attached_wall_cell: Vector2i = manager._deserialize_cell_variant(data.get("attached_wall_cell", Vector2i(-1, -1)))
			var wall_side: String = _safe_string(data.get("wall_side", "")).strip_edges().to_lower()
			if anchor_floor_cell.x < 0 or anchor_floor_cell.y < 0:
				issues.append(_make_map_constructor_issue("wm_missing_anchor_%d" % index, "error", "Wall-mounted object missing anchor_floor_cell.", object_cell, source_name, entity_kind, object_id))
			if attached_wall_cell.x < 0 or attached_wall_cell.y < 0:
				issues.append(_make_map_constructor_issue("wm_missing_attached_%d" % index, "error", "Wall-mounted object missing attached_wall_cell.", object_cell, source_name, entity_kind, object_id))
			if wall_side.is_empty():
				issues.append(_make_map_constructor_issue("wm_missing_side_%d" % index, "error", "Wall-mounted object missing wall_side.", object_cell, source_name, entity_kind, object_id))
			if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0 and has_grid_bounds and not bool(manager.grid_manager.call("is_in_bounds", attached_wall_cell)):
				issues.append(_make_map_constructor_issue("wm_attached_oob_%d" % index, "error", "Wall-mounted attached wall cell out of bounds.", attached_wall_cell, source_name, entity_kind, object_id))
			if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0 and not manager._is_map_constructor_wall_cell(attached_wall_cell):
				issues.append(_make_map_constructor_issue("wm_attached_not_wall_%d" % index, "warning", "Wall-mounted object attached_wall_cell is not a wall tile.", attached_wall_cell, source_name, entity_kind, object_id))
			if wall_side.is_empty():
				issues.append(_make_map_constructor_issue("wm_missing_side_warning_%d" % index, "warning", "Wall-mounted object has no wall_side metadata.", object_cell, source_name, entity_kind, object_id))
			if wall_side in ["north", "east", "south", "west"] and attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0:
				var expected_anchor: Vector2i = attached_wall_cell + manager._get_map_constructor_wall_side_delta(wall_side)
				if anchor_floor_cell.x >= 0 and anchor_floor_cell.y >= 0 and anchor_floor_cell != expected_anchor:
					issues.append(_make_map_constructor_issue("wm_anchor_mismatch_%d" % index, "warning", "Wall-mounted anchor_floor_cell does not match wall_side.", object_cell, source_name, entity_kind, object_id))
				if manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager._is_valid_grid_cell(expected_anchor):
					var neighbor_tile: int = int(manager.grid_manager.call("get_tile", expected_anchor))
					if not manager._is_wall_mount_neighbor_tile_type(neighbor_tile) or neighbor_tile == GridManager.TILE_WALL:
						issues.append(_make_map_constructor_issue("wm_side_not_visible_%d" % index, "warning", "Wall-mounted wall_side has no visible/mountable zone.", object_cell, source_name, entity_kind, object_id))
			elif _safe_string(data.get("placement_mode", "")).to_lower() == "wall_mounted":
				issues.append(_make_map_constructor_issue("wm_floating_%d" % index, "warning", "Wall-mounted object is floating without complete wall attachment metadata.", object_cell, source_name, entity_kind, object_id))
		var normalized_object_type: String = object_type.to_lower()
		if not _is_cable_object_data(data) and _safe_string(data.get("placement_mode", "")).to_lower() != "wall_mounted" and not normalized_object_type.contains("door") and not normalized_object_type.contains("gate") and manager._is_map_constructor_wall_cell(object_cell):
			issues.append(_make_map_constructor_issue("grounding_floor_on_wall_%d" % index, "warning", "Floor-standing object is placed on a wall cell.", object_cell, source_name, entity_kind, object_id))
		if (normalized_object_type.contains("door") or normalized_object_type.contains("gate")) and manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager._is_valid_grid_cell(object_cell):
			var door_tile: int = int(manager.grid_manager.call("get_tile", object_cell))
			if door_tile != GridManager.TILE_DOOR and door_tile != GridManager.TILE_DIGITAL_DOOR and door_tile != GridManager.TILE_POWERED_GATE:
				issues.append(_make_map_constructor_issue("door_grounding_mismatch_%d" % index, "warning", "Door/gate object is not on door/gate tile.", object_cell, source_name, entity_kind, object_id))
		if (normalized_object_type.contains("key") or normalized_object_type.contains("kit") or normalized_object_type.contains("card") or normalized_object_type.contains("code")) and manager._is_map_constructor_wall_cell(object_cell):
			issues.append(_make_map_constructor_issue("pickup_on_wall_%d" % index, "warning", "Pickup object overlaps blocked wall cell.", object_cell, source_name, entity_kind, object_id))
	_append_generic_cable_validation_issues(source_name, issues)
	_append_generic_airflow_validation_issues(source_name, issues)
	_append_legacy_mission_removal_readiness_issues(source_name, issues)
	var cable_cells: Dictionary = CableTopologyServiceRef.build_cable_cell_map(manager.mission_world_objects)
	for cable_cell_variant in cable_cells.keys():
		var cable_cell: Vector2i = Vector2i(cable_cell_variant)
		var cable_topology: Dictionary = CableTopologyServiceRef.classify_cell(cable_cell, manager.mission_world_objects)
		if not bool(cable_topology.get("valid", true)):
			issues.append(_make_map_constructor_issue("cable_junction_requires_switch_%d_%d" % [cable_cell.x, cable_cell.y], "error", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH, cable_cell, source_name, "world_object", "", "Place a circuit switch on the junction cell or remove an extra cable branch."))
		elif not str(cable_topology.get("message", "")).is_empty():
			issues.append(_make_map_constructor_issue("cable_extra_branch_skipped_%d_%d" % [cable_cell.x, cable_cell.y], "warning", str(cable_topology.get("message", CableTopologyServiceRef.WARNING_MESSAGE_EXTRA_BRANCH_SKIPPED)), cable_cell, source_name, "world_object", "", "Use a circuit switch if this cable should branch."))
	# validate explicit manager.cell_items map
	for cell_variant in manager.cell_items.keys():
		var item_cell: Vector2i = manager._deserialize_cell_variant(cell_variant)
		if item_cell.x >= 0 and item_cell.y >= 0 and manager._is_map_constructor_wall_cell(item_cell):
			issues.append(_make_map_constructor_issue("pickup_cell_item_on_wall_%d_%d" % [item_cell.x, item_cell.y], "warning", "Pickup object overlaps blocked wall cell.", item_cell, source_name, "item", "", ""))
		for item_variant in manager._safe_array(manager.cell_items.get(cell_variant, [])):
			var item_data: Dictionary = manager._safe_dictionary(item_variant)
			var item_id: String = _safe_string(item_data.get("id", "")).strip_edges()
			if item_id.is_empty():
				issues.append(_make_map_constructor_issue("item_missing_id_%d_%d" % [item_cell.x, item_cell.y], "error", "Item missing id.", item_cell, source_name, "item", ""))
			elif seen_item_ids.has(item_id):
				issues.append(_make_map_constructor_issue("item_duplicate_id_%s" % item_id, "warning", "Duplicate item id: %s." % item_id, item_cell, source_name, "item", item_id))
			else:
				seen_item_ids[item_id] = true
			if item_cell.x < 0 or item_cell.y < 0:
				issues.append(_make_map_constructor_issue("item_invalid_cell_%s" % item_id, "error", "Item cell invalid or negative.", item_cell, source_name, "item", item_id))
			var normalized_item: Dictionary = WorldObjectCatalogRef.normalize_item_contract(WorldObjectCatalogRef.normalize_archetype_object(WorldObjectCatalogRef.normalize_world_object_contract(item_data)))
			if _safe_string(item_data.get("archetype_id", "")) == "item" or _safe_string(normalized_item.get("archetype_id", "")) == "item":
				for contract_warning in WorldObjectCatalogRef.validate_archetype_object(item_data):
					issues.append(_make_map_constructor_issue("item_contract_%s_%s" % [item_id, contract_warning], "error", "Item archetype contract violation: %s." % contract_warning, item_cell, source_name, "item", item_id, "Normalize through the Item archetype catalog contract."))
				for canonical_field in ["item_class", "item_form", "storage_route", "storage_type", "item_type", "display_name"]:
					if item_data.get(canonical_field) != normalized_item.get(canonical_field):
						issues.append(_make_map_constructor_issue("item_not_normalized_%s_%s" % [item_id, canonical_field], "error", "Item field is not normalized: %s." % canonical_field, item_cell, source_name, "item", item_id, "Re-save the item through the Item archetype catalog contract."))
	for item_id_variant in seen_item_ids.keys():
		var item_id_for_link: String = _safe_string(item_id_variant)
		var item_for_link: Dictionary = manager.get_cell_item_by_id(item_id_for_link)
		var linked_door_id: String = _safe_string(item_for_link.get("linked_door_id", "")).strip_edges()
		if linked_door_id.is_empty():
			continue
		var linked_door: Dictionary = manager.get_world_object_by_id(linked_door_id)
		var item_cell_for_link: Vector2i = manager._get_world_object_cell_from_data(item_for_link)
		if linked_door.is_empty():
			issues.append(_make_map_constructor_issue("key_link_missing_door_%s" % item_id_for_link, "error", "Key is linked to a missing door: %s." % linked_door_id, item_cell_for_link, source_name, "item", item_id_for_link))
		elif _safe_string(linked_door.get("required_key_id", "")).strip_edges() != item_id_for_link:
			issues.append(_make_map_constructor_issue("key_link_one_way_%s" % item_id_for_link, "warning", "Key-door link is not two-way at runtime.", item_cell_for_link, source_name, "item", item_id_for_link))
		if not bool(item_for_link.get("can_pickup", true)):
			issues.append(_make_map_constructor_issue("key_not_pickup_capable_%s" % item_id_for_link, "error", "Linked key is not pickup-capable at runtime.", item_cell_for_link, source_name, "item", item_id_for_link))
	for object_id_variant in seen_object_ids.keys():
		var door_id_for_link: String = _safe_string(object_id_variant)
		var door_for_link: Dictionary = manager.get_world_object_by_id(door_id_for_link)
		var required_key_id: String = _safe_string(door_for_link.get("required_key_id", "")).strip_edges()
		if required_key_id.is_empty():
			continue
		var door_cell_for_link: Vector2i = manager._get_world_object_cell_from_data(door_for_link)
		var required_key: Dictionary = manager.get_cell_item_by_id(required_key_id)
		if required_key.is_empty():
			issues.append(_make_map_constructor_issue("door_required_key_missing_%s" % door_id_for_link, "error", "Door requires a missing key: %s." % required_key_id, door_cell_for_link, source_name, "world_object", door_id_for_link))
		elif _safe_string(required_key.get("linked_door_id", "")).strip_edges() != door_id_for_link:
			issues.append(_make_map_constructor_issue("door_key_one_way_%s" % door_id_for_link, "warning", "Door required_key_id is not mirrored by key linked_door_id.", door_cell_for_link, source_name, "world_object", door_id_for_link))
		elif not bool(required_key.get("can_pickup", true)):
			issues.append(_make_map_constructor_issue("door_key_not_pickup_%s" % door_id_for_link, "error", "Door requires a key that cannot be picked up at runtime.", door_cell_for_link, source_name, "world_object", door_id_for_link))
	var catalog_ids: Dictionary = {}
	for row_variant in manager._safe_array(manager.get_map_constructor_wall_material_catalog().get("materials", [])):
		var row: Dictionary = manager._safe_dictionary(row_variant)
		catalog_ids[_safe_string(row.get("id", "")).to_lower()] = true
	for key_variant in manager._map_constructor_wall_material_overrides.keys():
		var override_row: Dictionary = manager._safe_dictionary(manager._map_constructor_wall_material_overrides.get(_safe_string(key_variant), {}))
		var override_cell: Vector2i = Vector2i(override_row.get("cell", Vector2i(-1, -1)))
		var override_side: String = _safe_string(override_row.get("side", "")).to_lower().strip_edges()
		var override_material_id: String = _safe_string(override_row.get("material_id", "")).to_lower().strip_edges()
		if not catalog_ids.has(override_material_id):
			issues.append(_make_map_constructor_issue("wall_material_unknown_%s" % _safe_string(key_variant), "warning", "Unknown wall material override id: %s." % override_material_id, override_cell, source_name, "wall_material", _safe_string(key_variant)))
		var attached_wall_cell: Vector2i = override_cell + manager._get_map_constructor_wall_side_delta(override_side)
		if manager._get_map_constructor_wall_side_delta(override_side) == Vector2i.ZERO or not manager._is_wall_or_boundary_cell(attached_wall_cell):
			issues.append(_make_map_constructor_issue("wall_material_missing_wall_%s" % _safe_string(key_variant), "warning", "Wall material override points to a missing wall.", override_cell, source_name, "wall_material", _safe_string(key_variant)))
	var floor_catalog_ids: Dictionary = {}
	for floor_row_variant in manager._safe_array(manager.get_map_constructor_floor_material_catalog().get("materials", [])):
		var floor_row: Dictionary = manager._safe_dictionary(floor_row_variant)
		floor_catalog_ids[_safe_string(floor_row.get("id", "")).to_lower()] = true
	for floor_key_variant in manager._map_constructor_floor_material_overrides.keys():
		var floor_override: Dictionary = manager._safe_dictionary(manager._map_constructor_floor_material_overrides.get(_safe_string(floor_key_variant), {}))
		var floor_cell: Vector2i = Vector2i(floor_override.get("cell", manager._deserialize_cell_key(_safe_string(floor_key_variant))))
		var floor_material_id: String = _safe_string(floor_override.get("material_id", "")).to_lower().strip_edges()
		if floor_material_id.is_empty() or not floor_catalog_ids.has(floor_material_id):
			issues.append(_make_map_constructor_issue("floor_material_unknown_%s" % _safe_string(floor_key_variant), "warning", "Unknown floor material override id: %s." % floor_material_id, floor_cell, source_name, "floor_material", _safe_string(floor_key_variant)))
		if manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager._is_valid_grid_cell(floor_cell):
			var floor_tile_type: int = int(manager.grid_manager.call("get_tile", floor_cell))
			if floor_tile_type != GridManager.TILE_FLOOR and floor_tile_type != GridManager.TILE_STEPPED_FLOOR:
				issues.append(_make_map_constructor_issue("floor_material_non_floor_%s" % _safe_string(floor_key_variant), "warning", "Floor material override points to non-floor cell.", floor_cell, source_name, "floor_material", _safe_string(floor_key_variant)))
	if manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager.grid_manager.has_method("get_map_width") and manager.grid_manager.has_method("get_map_height"):
		var grid_width: int = int(manager.grid_manager.call("get_map_width"))
		var grid_height: int = int(manager.grid_manager.call("get_map_height"))
		for door_y in range(grid_height):
			for door_x in range(grid_width):
				var door_cell: Vector2i = Vector2i(door_x, door_y)
				var door_tile_type: int = int(manager.grid_manager.call("get_tile", door_cell))
				if not _is_map_constructor_door_like_tile_type(door_tile_type):
					continue
				var opening_probe: Dictionary = _get_map_constructor_door_opening_probe(door_cell)
				if not bool(opening_probe.get("has_wall_support", false)):
					issues.append(_make_map_constructor_issue("door_opening_no_wall_support_%d_%d" % [door_cell.x, door_cell.y], "warning", "Door/gate tile has no adjacent wall support for visual opening.", door_cell, source_name, "door_opening", "", "Place door/gate between wall cells or accept floating visual."))
				elif bool(opening_probe.get("ambiguous", false)):
					issues.append(_make_map_constructor_issue("door_opening_ambiguous_%d_%d" % [door_cell.x, door_cell.y], "warning", "Door/gate tile has ambiguous wall support and may render with fallback orientation.", door_cell, source_name, "door_opening", "", "Prefer opposite wall cells on one axis."))
	for door_object_variant in manager.mission_world_objects:
		var door_object_data: Dictionary = manager._safe_dictionary(door_object_variant)
		if door_object_data.is_empty() or not _is_map_constructor_door_data(door_object_data):
			continue
		var door_object_id: String = _safe_string(door_object_data.get("id", "")).strip_edges()
		var door_object_cell: Vector2i = manager._deserialize_cell_variant(door_object_data.get("position", Vector2i(-1, -1)))
		if manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager._is_valid_grid_cell(door_object_cell):
			var door_object_tile: int = int(manager.grid_manager.call("get_tile", door_object_cell))
			if not _is_map_constructor_door_like_tile_type(door_object_tile):
				issues.append(_make_map_constructor_issue("door_metadata_not_on_door_tile_%s" % door_object_id, "warning", "Door/gate object metadata is not on a door/gate tile.", door_object_cell, source_name, "world_object", door_object_id, "Move metadata onto matching door/gate tile."))
			elif door_object_tile == GridManager.TILE_POWERED_GATE:
				var has_power_metadata: bool = door_object_data.has("is_powered") or door_object_data.has("powered") or door_object_data.has("requires_power") or door_object_data.has("requires_external_power") or not _safe_string(door_object_data.get("power_network_id", "")).strip_edges().is_empty()
				if not has_power_metadata:
					issues.append(_make_map_constructor_issue("powered_gate_missing_power_metadata_%s" % door_object_id, "warning", "Powered gate has no power metadata for visual state diagnostics.", door_object_cell, source_name, "world_object", door_object_id, "Add optional power metadata if this gate should show powered/unpowered state."))
	_get_power_link_validation_rules().append_key_door_link_issues(source_name, issues)
	return issues

func _map_constructor_issue_is_expected_invalid(issue: Dictionary) -> bool:
	return MapConstructorReadinessValidationServiceRef.issue_is_expected_invalid(manager, issue)

func _map_constructor_build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	return MapConstructorReadinessValidationServiceRef.build_readiness_check(issue, status)

func get_map_constructor_mission_readiness_report() -> Dictionary:
	return MapConstructorReadinessValidationServiceRef.build_promotion_readiness_report(manager)

func get_map_constructor_audit_summary() -> Dictionary:
	var audit: Dictionary = manager.get_task_test_system_audit_report()
	return {
		"ok": bool(audit.get("ok", false)),
		"missing_coverage_count": manager._safe_array(audit.get("missing_coverage", [])).size(),
		"invalid_links_count": manager._safe_array(audit.get("invalid_links", [])).size(),
		"expected_invalid_links_count": manager._safe_array(audit.get("expected_invalid_links", [])).size(),
		"runtime_warnings_count": manager._safe_array(audit.get("runtime_cell_warnings", [])).size(),
		"duplicate_cell_warnings_count": manager._safe_array(audit.get("duplicate_cell_warnings", [])).size(),
		"objects_without_tags_count": manager._safe_array(audit.get("objects_without_audit_tags", [])).size()
	}

func get_map_constructor_audit_summary_text() -> String:
	var summary: Dictionary = get_map_constructor_audit_summary()
	var status: String = "WARN"
	if bool(summary.get("ok", false)):
		status = "OK"
	return "Audit %s | missing=%d invalid=%d runtime=%d duplicates=%d" % [
		status,
		int(summary.get("missing_coverage_count", 0)),
		int(summary.get("invalid_links_count", 0)),
		int(summary.get("runtime_warnings_count", 0)),
		int(summary.get("duplicate_cell_warnings_count", 0))
	]
