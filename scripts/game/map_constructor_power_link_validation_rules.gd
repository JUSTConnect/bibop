extends RefCounted
class_name MapConstructorPowerLinkValidationRules

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
var manager: Variant
var validation_service: Variant

func _init(manager_ref: Variant, validation_service_ref: Variant) -> void:
	manager = manager_ref
	validation_service = validation_service_ref

func _safe_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value).strip_edges()

func _map_constructor_make_validation_link(label: String, target_id: String, target_kind: String, field_name: String) -> Dictionary:
	var cell: Vector2i = Vector2i(-1, -1)
	var display_label: String = label
	var location: String = "map"
	if target_kind == "item":
		var key_entity: Dictionary = manager.find_map_constructor_key_item_by_id(target_id)
		if bool(key_entity.get("ok", false)):
			cell = Vector2i(key_entity.get("cell", Vector2i(-1, -1)))
			location = _safe_string(key_entity.get("location", "map"))
			var key_label: String = _safe_string(key_entity.get("label", "")).strip_edges()
			if not key_label.is_empty():
				display_label = "%s: %s" % [label, key_label]
	else:
		var target_entity: Dictionary = manager.get_map_constructor_entity_by_id("world_object", target_id)
		if bool(target_entity.get("ok", false)):
			cell = Vector2i(target_entity.get("cell", Vector2i(-1, -1)))
	return {"label": display_label, "target_id": target_id, "target_kind": target_kind, "field_name": field_name, "cell": cell, "location": location}

func _map_constructor_terminal_stores_key(terminal_id: String, key_id: String) -> bool:
	var normalized_terminal_id: String = terminal_id.strip_edges()
	var normalized_key_id: String = key_id.strip_edges()
	if normalized_terminal_id.is_empty() or normalized_key_id.is_empty():
		return false
	var terminal: Dictionary = manager.get_world_object_by_id(normalized_terminal_id)
	if terminal.is_empty():
		return false
	for field_name in ["stored_key_ids", "stored_access_ids", "stored_item_ids", "digital_key_ids", "access_code_ids"]:
		if manager._safe_array(terminal.get(field_name, [])).has(normalized_key_id):
			return true
	for field_name in ["stored_key_id", "access_key_id", "download_record_id"]:
		if _safe_string(terminal.get(field_name, "")).strip_edges() == normalized_key_id:
			return true
	return false


func _count_lights_linked_to_source(source_id: String) -> int:
	var normalized_source_id: String = source_id.strip_edges()
	if normalized_source_id.is_empty():
		return 0
	var count: int = 0
	for object_data in manager.mission_world_objects:
		if _safe_string(object_data.get("object_type", "")).strip_edges().to_lower() != "light":
			continue
		var linked_source: String = _safe_string(object_data.get("power_source_id", object_data.get("power_network_id", ""))).strip_edges()
		if linked_source == normalized_source_id:
			count += 1
	return count

func _count_adjacent_power_wires(cell: Vector2i, target_id: String = "") -> int:
	if cell.x < 0 or cell.y < 0:
		return 0
	var counted_ids: Dictionary = {}
	var count: int = 0
	for delta in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbor: Dictionary = manager.get_world_object_at_cell(cell + delta)
		if neighbor.is_empty():
			continue
		var neighbor_type: String = _safe_string(neighbor.get("object_type", "")).strip_edges().to_lower()
		if neighbor_type == "power_cable" or neighbor_type == "power_cable_reel":
			var neighbor_id: String = _safe_string(neighbor.get("id", "cell_%s" % str(cell + delta))).strip_edges()
			if not counted_ids.has(neighbor_id):
				counted_ids[neighbor_id] = true
				count += 1
	var normalized_target_id: String = target_id.strip_edges()
	if not normalized_target_id.is_empty():
		for object_data in manager.mission_world_objects:
			var object_type: String = _safe_string(object_data.get("object_type", "")).strip_edges().to_lower()
			if object_type != "power_cable" and object_type != "power_cable_reel":
				continue
			var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
			if counted_ids.has(object_id):
				continue
			for end_index in range(1, 3):
				if _safe_string(object_data.get("end_%d_target_id" % end_index, "")).strip_edges() == normalized_target_id:
					counted_ids[object_id] = true
					count += 1
					break
	return count


func _power_source_link_matches(object_data: Dictionary, source_id: String, source_network_id: String) -> bool:
	for field_name in ["power_source_id", "connected_power_source_id", "physical_connection_source_id"]:
		if _safe_string(object_data.get(field_name, "")).strip_edges() == source_id:
			return true
	var power_network_id: String = _safe_string(object_data.get("power_network_id", "")).strip_edges()
	if not source_network_id.is_empty() and power_network_id == source_network_id:
		return true
	if power_network_id == source_id:
		return true
	for end_index in range(1, 3):
		if _safe_string(object_data.get("end_%d_target_id" % end_index, "")).strip_edges() == source_id:
			return true
	return false


func _power_source_link_label_for_type(object_type: String) -> String:
	if object_type == "power_cable" or object_type == "power_cable_reel":
		return "Connected cable"
	if object_type in ["power_socket", "outlet"]:
		return "Connected socket/outlet"
	if object_type == "light" or object_type == "light_switch":
		return "Linked light"
	if object_type == "terminal" or object_type.find("terminal") >= 0:
		return "Linked terminal/device"
	if object_type.find("door") >= 0 or object_type.find("gate") >= 0 or object_type.find("platform") >= 0:
		return "Linked door/gate/platform"
	return "Linked terminal/device"

func validate_map_constructor_entity_links(entity_kind: String, entity_id: String) -> Dictionary:
	var warnings: Array[String] = []
	var missing: Array[String] = []
	var linked: Array[Dictionary] = []
	var entity: Dictionary = manager.get_map_constructor_entity_by_id(entity_kind, entity_id)
	if not bool(entity.get("ok", false)):
		return {"ok": false, "warnings": ["Entity not found."], "missing_links": [], "linked_targets": [], "linked": [], "missing": []}
	var data: Dictionary = manager._safe_dictionary(entity.get("data", {}))
	if entity_kind == "world_object":
		data = manager._normalize_map_constructor_active_object_fields(data)
	var type_group: String = manager.get_map_constructor_entity_type_group(entity_kind, entity_id)
	var normalized_object_type_for_validation: String = _safe_string(data.get("object_type", "")).strip_edges().to_lower()
	if normalized_object_type_for_validation in ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"]:
		var source_id: String = _safe_string(data.get("id", entity_id)).strip_edges()
		var source_network_id: String = _safe_string(data.get("power_network_id", "")).strip_edges()
		var outlet_count: int = 0
		var linked_wire_count: int = 0
		var linked_light_count: int = 0
		for object_data in manager.mission_world_objects:
			var linked_id: String = _safe_string(object_data.get("id", "")).strip_edges()
			if linked_id.is_empty() or linked_id == source_id:
				continue
			if not _power_source_link_matches(object_data, source_id, source_network_id):
				continue
			var linked_type: String = _safe_string(object_data.get("object_type", "")).strip_edges().to_lower()
			if linked_type == "light":
				linked_light_count += 1
			elif linked_type in ["power_socket", "outlet"]:
				outlet_count += 1
			elif linked_type == "power_cable" or linked_type == "power_cable_reel":
				linked_wire_count += 1
			linked.append(_map_constructor_make_validation_link(_power_source_link_label_for_type(linked_type), linked_id, "world_object", "power_source_id"))
		if linked.is_empty():
			linked.append({"display_is_dictionary": false, "display_text": "No linked objects in this circuit."})
		var source_class: int = clampi(int(data.get("power_source_class", data.get("source_class", 1))), 1, 3)
		var outlet_capacity: int = source_class + 3
		if outlet_count > outlet_capacity:
			warnings.append("Warnings: outlet capacity exceeded (%d/%d)." % [outlet_count, outlet_capacity])
		if linked_wire_count <= 0:
			warnings.append("Warnings: no linked/adjacent wires found for physical circuit.")
		var source_state: String = _safe_string(data.get("state", "on")).strip_edges().to_lower()
		if source_state in ["off", "damaged", "broken"]:
			warnings.append("Warnings: linked source is %s and will not provide power." % source_state)
		if linked_light_count <= 0:
			warnings.append("Lighting: no lights linked to this source.")
	var power_mode: String = _safe_string(data.get("power_mode", "internal")).strip_edges().to_lower()
	if power_mode == "external":
		var power_source_id: String = _safe_string(data.get("power_source_id", data.get("power_network_id", ""))).strip_edges()
		if power_source_id.is_empty():
			missing.append("external power selected but no power source linked")
		else:
			linked.append(_map_constructor_make_validation_link("linked power source", power_source_id, "world_object", "power_source_id"))
			if not manager._map_constructor_link_target_exists_for_field("power_source_id", power_source_id):
				warnings.append("linked power source is missing/off/unpowered: %s" % power_source_id)
			warnings.append("external power source is logically linked; verify physical wire/cable path exists")
	var control_mode: String = _safe_string(data.get("control_mode", "internal")).strip_edges().to_lower()
	if control_mode == "external":
		var control_terminal_id: String = _safe_string(data.get("control_terminal_id", data.get("linked_terminal_id", ""))).strip_edges()
		if control_terminal_id.is_empty():
			missing.append("external control selected but no terminal linked")
		else:
			linked.append(_map_constructor_make_validation_link("linked control terminal", control_terminal_id, "world_object", "control_terminal_id"))
			var terminal_data: Dictionary = manager.get_world_object_by_id(control_terminal_id)
			if terminal_data.is_empty():
				warnings.append("external control terminal linked but missing: %s" % control_terminal_id)
			elif not manager._is_terminal_powered_for_interaction(terminal_data):
				warnings.append("external control terminal linked but terminal cannot currently operate due to power/connection issues")
	if normalized_object_type_for_validation == "circuit_switch":
		var has_input: bool = not _safe_string(data.get("input_wire_id", data.get("input_direction", ""))).strip_edges().is_empty()
		if not has_input:
			warnings.append("Circuit switch has no input/source wire.")
		var output_count: int = 0
		for output_index in range(1, 4):
			var output_value: String = _safe_string(data.get("output_%d_wire_id" % output_index, data.get("output_%d_direction" % output_index, ""))).strip_edges().to_lower()
			if not output_value.is_empty() and output_value != "none":
				output_count += 1
		if output_count <= 0:
			warnings.append("Circuit switch has no output wires.")
		var active_output_index: int = int(data.get("active_output_index", 0))
		if output_count > 0:
			var active_output_value: String = ""
			if active_output_index >= 1 and active_output_index <= 3:
				active_output_value = _safe_string(data.get("output_%d_wire_id" % active_output_index, data.get("output_%d_direction" % active_output_index, ""))).strip_edges().to_lower()
			if active_output_value.is_empty() or active_output_value == "none":
				warnings.append("Circuit switch active output points to a missing/none output.")
	if normalized_object_type_for_validation.begins_with("fuse_box") or normalized_object_type_for_validation == "fuse_block":
		if not bool(data.get("fuse_installed", _safe_string(data.get("state", "")) == "installed")):
			warnings.append("Fuse block has no fuse installed; circuit is open.")
		if _safe_string(data.get("power_source_id", data.get("power_network_id", ""))).strip_edges().is_empty():
			warnings.append("Fuse block linked source missing.")
		var fuse_cell: Vector2i = manager._deserialize_cell_variant(data.get("position", Vector2i(-1, -1)))
		var adjacent_wires: int = _count_adjacent_power_wires(fuse_cell, _safe_string(data.get("id", entity_id)))
		if adjacent_wires > 2:
			warnings.append("Fuse block has more than 2 adjacent/connected wires (%d)." % adjacent_wires)
	if normalized_object_type_for_validation in ["circuit_breaker", "power_breaker", "power_knife_switch"]:
		if _safe_string(data.get("power_source_id", data.get("power_network_id", ""))).strip_edges().is_empty():
			warnings.append("Power breaker linked source missing.")
	if normalized_object_type_for_validation == "light_switch":
		var light_switch_source_id: String = _safe_string(data.get("power_source_id", data.get("power_network_id", ""))).strip_edges()
		if light_switch_source_id.is_empty():
			warnings.append("Light switch source missing.")
		elif _count_lights_linked_to_source(light_switch_source_id) <= 0:
			warnings.append("Light switch has no lights linked to its source.")
	if type_group == "door":
		var access_type: String = _safe_string(data.get("access_type", manager._normalize_map_constructor_access_type(data.get("lock_type", ""), manager._default_map_constructor_access_type_for_object(data)))).strip_edges().to_lower()
		var required_key_id: String = _safe_string(data.get("required_key_id", "")).strip_edges()
		var access_terminal_id: String = _safe_string(data.get("access_terminal_id", "")).strip_edges()
		if access_type == "mechanical_key":
			if required_key_id.is_empty():
				missing.append("mechanical key selected but no physical key linked")
			else:
				var mechanical_key_resolved: Dictionary = manager.find_map_constructor_key_item_by_id(required_key_id)
				if bool(mechanical_key_resolved.get("ok", false)):
					linked.append(_map_constructor_make_validation_link("linked key/access item", required_key_id, "item", "required_key_id"))
					if _safe_string(mechanical_key_resolved.get("location", "map")) == "inventory":
						warnings.append("linked key is currently in player inventory")
				else:
					missing.append("mechanical key selected but linked key is missing")
		elif access_type in [WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY, WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE]:
			var access_key_resolved: Dictionary = {}
			if required_key_id.is_empty():
				missing.append("%s selected but no key/access item linked" % access_type)
			else:
				access_key_resolved = manager.find_map_constructor_key_item_by_id(required_key_id)
				if bool(access_key_resolved.get("ok", false)):
					linked.append(_map_constructor_make_validation_link("linked key/access item", required_key_id, "item", "required_key_id"))
					var key_location: String = _safe_string(access_key_resolved.get("location", "map"))
					if key_location == "inventory":
						warnings.append("linked key/access item is currently in player inventory")
				else:
					missing.append("%s selected but linked key/access item is missing" % access_type)
			if access_terminal_id.is_empty():
				if _safe_string(access_key_resolved.get("location", "")) == "terminal":
					warnings.append("linked key/access item is stored in a terminal; select that terminal if this door requires explicit storage binding")
				elif not required_key_id.is_empty():
					warnings.append("digital key/access code selected but no terminal storage linked")
				else:
					missing.append("digital key/access code selected but no terminal storage linked")
			else:
				linked.append(_map_constructor_make_validation_link("linked information/access terminal", access_terminal_id, "world_object", "access_terminal_id"))
				if not required_key_id.is_empty() and not _map_constructor_terminal_stores_key(access_terminal_id, required_key_id):
					warnings.append("selected door has digital key/access code linked, but that key/code is not stored in the selected information terminal")
		elif access_type == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL:
			if access_terminal_id.is_empty():
				missing.append("terminal access selected but no terminal linked")
			else:
				linked.append(_map_constructor_make_validation_link("linked information/access terminal", access_terminal_id, "world_object", "access_terminal_id"))
	for key in ["target_door_id", "linked_terminal_id", "control_source_id", "linked_door_id"]:
		var tid: String = _safe_string(data.get(key, "")).strip_edges()
		if tid.is_empty():
			continue
		linked.append(_map_constructor_make_validation_link(key, tid, "world_object", key))
		if not manager._map_constructor_link_target_exists_for_field(key, tid):
			warnings.append("Missing link target for %s: %s" % [key, tid])
	return {"ok": missing.is_empty(), "warnings": warnings, "missing_links": missing, "linked_targets": linked, "linked": linked, "missing": missing}

func get_map_constructor_object_dependency_status(object_data: Dictionary) -> Dictionary:
	var messages: Array[String] = []
	var link_targets: Array[Dictionary] = []
	var severity: String = "none"
	var object_id: String = _safe_string(object_data.get("id", "")).strip_edges()
	var expected_invalid: bool = manager.is_task_test_expected_invalid_object_id(object_id)
	var object_ids: Dictionary = {}
	var object_id_to_cell: Dictionary = {}
	var item_ids: Dictionary = {}
	var item_id_to_cell: Dictionary = {}
	var power_source_network_ids: Dictionary = {}
	for existing_object in manager.mission_world_objects:
		if typeof(existing_object) != TYPE_DICTIONARY:
			continue
		var existing_data: Dictionary = manager._safe_dictionary(existing_object)
		var existing_id: String = _safe_string(existing_data.get("id", "")).strip_edges()
		if not existing_id.is_empty():
			object_ids[existing_id] = true
			object_id_to_cell[existing_id] = Vector2i(existing_data.get("position", Vector2i(-1, -1)))
		var existing_type: String = _safe_string(existing_data.get("object_type", "")).to_lower()
		if existing_type.begins_with("power_source"):
			var existing_network_id: String = _safe_string(existing_data.get("power_network_id", "")).strip_edges()
			if not existing_network_id.is_empty():
				power_source_network_ids[existing_network_id] = true
	for cell_variant in manager.cell_items.keys():
		for item_variant in manager._safe_array(manager.cell_items.get(cell_variant, [])):
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item_id: String = _safe_string(manager._safe_dictionary(item_variant).get("id", "")).strip_edges()
			if not item_id.is_empty():
				item_ids[item_id] = true
				item_id_to_cell[item_id] = Vector2i(cell_variant)

	for field_name in ["required_key_id", "linked_terminal_id", "target_door_id", "target_platform_id"]:
		var ref_id: String = _safe_string(object_data.get(field_name, "")).strip_edges()
		if ref_id.is_empty():
			continue
		var exists: bool = object_ids.has(ref_id) or (field_name == "required_key_id" and item_ids.has(ref_id))
		var ref_cell: Vector2i = Vector2i(-1, -1)
		if field_name == "required_key_id" and item_id_to_cell.has(ref_id):
			ref_cell = Vector2i(item_id_to_cell[ref_id])
		elif object_id_to_cell.has(ref_id):
			ref_cell = Vector2i(object_id_to_cell[ref_id])
		if exists:
			link_targets.append({"field": field_name, "target_id": ref_id, "target_cell": ref_cell, "status": "valid", "reason": "exists"})
			if severity == "none":
				severity = "valid"
		else:
			messages.append("%s points to missing id: %s" % [field_name, ref_id])
			link_targets.append({"field": field_name, "target_id": ref_id, "target_cell": ref_cell, "status": "error", "reason": "missing"})
			severity = "error"

	var controlled_target_type: String = _safe_string(object_data.get("controlled_target_type", "none")).to_lower()
	for schema_variant in WorldObjectCatalogRef.get_archetype_property_schema(_safe_string(object_data.get("archetype_id", ""))):
		var schema_field: Dictionary = Dictionary(schema_variant)
		if _safe_string(schema_field.get("type", "")) != "object_ref_array":
			continue
		var field_name: String = _safe_string(schema_field.get("field", ""))
		var target_group: String = _safe_string(schema_field.get("target_group", "")).to_lower()
		for target_variant in manager._safe_array(object_data.get(field_name, [])):
			var target_id: String = _safe_string(target_variant).strip_edges()
			if target_id.is_empty():
				continue
			var target_cell: Vector2i = Vector2i(object_id_to_cell.get(target_id, Vector2i(-1, -1)))
			if not object_ids.has(target_id):
				messages.append("%s contains missing id: %s" % [field_name, target_id])
				link_targets.append({"field":field_name,"target_id":target_id,"target_cell":target_cell,"status":"error","reason":"missing"})
				severity = "error"
				continue
			var target_data: Dictionary = manager.get_world_object_by_id(target_id)
			if not target_group.is_empty() and _safe_string(target_data.get("object_group", "")).to_lower() != target_group:
				messages.append("%s target %s must belong to group %s" % [field_name, target_id, target_group])
				link_targets.append({"field":field_name,"target_id":target_id,"target_cell":target_cell,"status":"error","reason":"wrong_group"})
				severity = "error"
				continue
			link_targets.append({"field":field_name,"target_id":target_id,"target_cell":target_cell,"status":"valid","reason":"exists"})
			if severity == "none":
				severity = "valid"
	if controlled_target_type in ["door", "cooling", "platform", "power", "lighting"]:
		var expected_link_field: String = "linked_%s_ids" % controlled_target_type
		for typed_link_field in ["linked_door_ids", "linked_cooling_ids", "linked_platform_ids", "linked_power_ids", "linked_lighting_ids"]:
			if typed_link_field != expected_link_field and not manager._safe_array(object_data.get(typed_link_field, [])).is_empty():
				messages.append("%s does not match controlled_target_type %s" % [typed_link_field, controlled_target_type])
				severity = "error"

	var control_source_id: String = _safe_string(object_data.get("control_source_id", "")).strip_edges()
	if not control_source_id.is_empty():
		var control_source_cell: Vector2i = Vector2i(object_id_to_cell.get(control_source_id, Vector2i(-1, -1)))
		if object_ids.has(control_source_id):
			link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"valid","reason":"exists"})
			if severity == "none":
				severity = "valid"
		else:
			if expected_invalid:
				messages.append("control_source_id missing (expected test sample)")
				link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"warning","reason":"expected_missing"})
				if severity != "error":
					severity = "warning"
			else:
				messages.append("control_source_id points to missing id: %s" % control_source_id)
				link_targets.append({"field":"control_source_id","target_id":control_source_id,"target_cell":control_source_cell,"status":"error","reason":"missing"})
				severity = "error"

	var requires_external_power: bool = bool(object_data.get("requires_external_power", false))
	var power_network_id: String = _safe_string(object_data.get("power_network_id", "")).strip_edges()
	if requires_external_power:
		if power_network_id.is_empty():
			if expected_invalid:
				messages.append("power_network_id missing (expected test sample)")
				if severity != "error":
					severity = "warning"
			else:
				messages.append("requires_external_power=true but power_network_id is empty")
				severity = "error"
		elif power_source_network_ids.has(power_network_id):
			link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"valid","reason":"network_found"})
			if severity == "none":
				severity = "valid"
		else:
			if expected_invalid:
				messages.append("power_network_id %s has no source (expected test sample)" % power_network_id)
				link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"warning","reason":"expected_missing_network"})
				if severity != "error":
					severity = "warning"
			else:
				messages.append("power_network_id %s has no power source" % power_network_id)
				link_targets.append({"field":"power_network_id","target_id":power_network_id,"target_cell":Vector2i(-1, -1),"status":"error","reason":"missing_network"})
				severity = "error"

	for connected_id_variant in manager._safe_array(object_data.get("connected_device_ids", [])):
		var connected_id: String = _safe_string(connected_id_variant).strip_edges()
		if connected_id.is_empty():
			continue
		var connected_cell: Vector2i = Vector2i(object_id_to_cell.get(connected_id, Vector2i(-1, -1)))
		if object_ids.has(connected_id):
			link_targets.append({"field":"connected_device_ids","target_id":connected_id,"target_cell":connected_cell,"status":"valid","reason":"exists"})
			if severity == "none":
				severity = "valid"
		else:
			messages.append("connected_device_ids contains missing id: %s" % connected_id)
			link_targets.append({"field":"connected_device_ids","target_id":connected_id,"target_cell":connected_cell,"status":"error","reason":"missing"})
			severity = "error"

	return {"severity": severity, "messages": messages, "link_targets": link_targets}


func append_object_power_link_consistency_issues(data: Dictionary, object_cell: Vector2i, source_name: String, entity_kind: String, issues: Array[Dictionary]) -> void:
	var object_id: String = _safe_string(data.get("id", "")).strip_edges()
	var object_type: String = _safe_string(data.get("object_type", "")).strip_edges()
	var object_group: String = _safe_string(data.get("object_group", "")).strip_edges()
	var normalized_power_mode: String = _safe_string(data.get("power_type", data.get("power_mode", "internal"))).strip_edges().to_lower().trim_suffix("_power")
	var normalized_control_mode: String = _safe_string(data.get("control_type", data.get("control_mode", "internal"))).strip_edges().to_lower().trim_suffix("_control")
	if normalized_control_mode == "terminal":
		issues.append(validation_service._make_map_constructor_issue("door_legacy_terminal_control_%s" % object_id, "error", "Legacy Door control_type=terminal must normalize to external.", object_cell, source_name, entity_kind, object_id, "Reload or resave the map to normalize Control Type to External."))
		normalized_control_mode = "external"
	var power_source_id: String = _safe_string(data.get("power_source_id", data.get("connected_power_source_id", data.get("physical_connection_source_id", "")))).strip_edges()
	var power_network_id: String = _safe_string(data.get("power_network_id", "")).strip_edges()
	if normalized_power_mode == "external":
		if power_source_id.is_empty():
			issues.append(validation_service._make_map_constructor_issue("external_power_missing_source_%s" % object_id, "warning", "External-power object is missing a Power Source binding.", object_cell, source_name, entity_kind, object_id, "Bind an installed Power Source."))
		if power_network_id.is_empty():
			issues.append(validation_service._make_map_constructor_issue("external_power_missing_network_%s" % object_id, "warning", "External-power object is missing a Power Network binding.", object_cell, source_name, entity_kind, object_id, "Bind main_power_net or a source-owned network."))
	elif normalized_power_mode == "internal" and (_safe_string(data.get("state", data.get("status", ""))).strip_edges().to_lower() == "unpowered" or _safe_string(data.get("status", "")).strip_edges().to_lower() == "unpowered"):
		issues.append(validation_service._make_map_constructor_issue("internal_power_unpowered_%s" % object_id, "warning", "Internal-power object is authored as unpowered.", object_cell, source_name, entity_kind, object_id, "Use an active internal state or switch Power Type to External."))
	if object_type.to_lower().begins_with("power_source") and not bool(data.get("blocks_movement", false)):
		issues.append(validation_service._make_map_constructor_issue("power_source_not_blocking_%s" % object_id, "warning", "Power Source must block movement.", object_cell, source_name, entity_kind, object_id, "Normalize the Power Source object."))
	if object_type.to_lower().begins_with("power_source") and not power_source_id.is_empty():
		var linked_source: Dictionary = manager.get_world_object_by_id(power_source_id)
		if not linked_source.is_empty() and _safe_string(linked_source.get("object_type", "")).strip_edges().to_lower().begins_with("power_source"):
			issues.append(validation_service._make_map_constructor_issue("power_source_linked_to_source_%s" % object_id, "error", "Power Source must not bind to another Power Source.", object_cell, source_name, entity_kind, object_id, "Clear the Linked Power Source binding."))
	if object_group == "door":
		var linked_terminal_id: String = _safe_string(data.get("control_terminal_id", data.get("linked_terminal_id", data.get("required_terminal_id", "")))).strip_edges()
		if normalized_control_mode in ["external", "terminal"] and linked_terminal_id.is_empty():
			issues.append(validation_service._make_map_constructor_issue("door_external_control_missing_terminal_%s" % object_id, "warning", "External-control door is missing a Linked Terminal.", object_cell, source_name, entity_kind, object_id, "Bind an installed Terminal."))
		elif normalized_control_mode == "internal" and not linked_terminal_id.is_empty():
			issues.append(validation_service._make_map_constructor_issue("door_internal_control_has_terminal_%s" % object_id, "warning", "Internal-control door incorrectly retains a Linked Terminal.", object_cell, source_name, entity_kind, object_id, "Clear the terminal link or switch Control Type to External."))
	if object_group == "terminal":
		if not bool(data.get("blocks_movement", false)):
			issues.append(validation_service._make_map_constructor_issue("terminal_not_blocking_%s" % object_id, "warning", "Terminal must block movement.", object_cell, source_name, entity_kind, object_id, "Normalize the Terminal object."))
		for linked_door_id_variant in Array(data.get("linked_door_ids", [])):
			var linked_door_id: String = _safe_string(linked_door_id_variant).strip_edges()
			var linked_door: Dictionary = manager.get_world_object_by_id(linked_door_id)
			if linked_door.is_empty() or _safe_string(linked_door.get("control_terminal_id", linked_door.get("linked_terminal_id", ""))).strip_edges() != object_id:
				issues.append(validation_service._make_map_constructor_issue("terminal_door_link_not_mirrored_%s_%s" % [object_id, linked_door_id], "warning", "Terminal linked_door_ids is not mirrored by the Door Linked Terminal field.", object_cell, source_name, entity_kind, object_id, "Relink the Terminal and Door."))


func append_key_door_link_issues(source_name: String, issues: Array[Dictionary]) -> void:
	var key_link_counts_by_door: Dictionary = {}
	for cell_variant in manager.cell_items.keys():
		var key_cell: Vector2i = manager._deserialize_cell_variant(cell_variant)
		for item_variant in manager._safe_array(manager.cell_items.get(cell_variant, [])):
			if not (item_variant is Dictionary):
				continue
			var key_data: Dictionary = manager._safe_dictionary(item_variant)
			if not validation_service._is_map_constructor_key_data(key_data):
				continue
			var key_id: String = _safe_string(key_data.get("id", "")).strip_edges()
			var linked_door_id: String = _safe_string(key_data.get("linked_door_id", "")).strip_edges()
			if linked_door_id.is_empty():
				issues.append(validation_service._make_map_constructor_issue("key_missing_door_%s" % key_id, "warning", "Key is not linked to any door.", key_cell, source_name, "item", key_id, "Link this key to an installed door."))
			else:
				if not bool(manager.get_map_constructor_entity_by_id("world_object", linked_door_id).get("ok", false)):
					issues.append(validation_service._make_map_constructor_issue("key_linked_door_missing_%s" % key_id, "error", "Linked door not found.", key_cell, source_name, "item", key_id, "Relink or clear linked_door_id."))
				if not key_link_counts_by_door.has(linked_door_id):
					key_link_counts_by_door[linked_door_id] = []
				key_link_counts_by_door[linked_door_id].append(key_id)
	for door_variant in manager.mission_world_objects:
		if not (door_variant is Dictionary):
			continue
		var door_data_for_link: Dictionary = manager._safe_dictionary(door_variant)
		if not validation_service._is_map_constructor_door_data(door_data_for_link):
			continue
		var door_id_for_link: String = _safe_string(door_data_for_link.get("id", "")).strip_edges()
		var door_cell_for_link: Vector2i = manager._deserialize_cell_variant(door_data_for_link.get("position", Vector2i(-1, -1)))
		var required_key_id: String = _safe_string(door_data_for_link.get("required_key_id", "")).strip_edges()
		var access_type: String = _safe_string(door_data_for_link.get("access_type", "")).strip_edges().to_lower()
		var door_requires_key: bool = access_type in [WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD, WorldObjectCatalogRef.ACCESS_TYPE_DIGITAL_KEY, WorldObjectCatalogRef.ACCESS_TYPE_ACCESS_CODE] or not required_key_id.is_empty()
		var door_uses_terminal: bool = access_type == WorldObjectCatalogRef.ACCESS_TYPE_TERMINAL
		if door_uses_terminal:
			door_requires_key = false
		if door_requires_key and required_key_id.is_empty():
			issues.append(validation_service._make_map_constructor_issue("door_missing_key_%s" % door_id_for_link, "warning", "Door requires a key but no key is linked.", door_cell_for_link, source_name, "world_object", door_id_for_link, "Link a compatible key."))
		elif not required_key_id.is_empty() and not bool(manager.find_map_constructor_key_item_by_id(required_key_id).get("ok", false)):
			issues.append(validation_service._make_map_constructor_issue("door_linked_key_missing_%s" % door_id_for_link, "error", "Linked key not found.", door_cell_for_link, source_name, "world_object", door_id_for_link, "Relink or clear required_key_id."))
	for door_id_variant in key_link_counts_by_door.keys():
		var linked_keys: Array = manager._safe_array(key_link_counts_by_door.get(door_id_variant, []))
		if linked_keys.size() > 1:
			var door_entity_for_duplicate: Dictionary = manager.get_map_constructor_entity_by_id("world_object", _safe_string(door_id_variant))
			issues.append(validation_service._make_map_constructor_issue("door_duplicate_key_links_%s" % _safe_string(door_id_variant), "error", "Multiple keys link to the same door.", Vector2i(door_entity_for_duplicate.get("cell", Vector2i(-1, -1))), source_name, "world_object", _safe_string(door_id_variant), "Keep one key-door link."))
