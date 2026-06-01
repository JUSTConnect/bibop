extends RefCounted
class_name MapConstructorValidationService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
var manager: Variant

const MAP_CONSTRUCTOR_WALL_SIDE_DELTAS: Array[Dictionary] = [
	{"side":"north", "delta": Vector2i(0, -1)},
	{"side":"east", "delta": Vector2i(1, 0)},
	{"side":"south", "delta": Vector2i(0, 1)},
	{"side":"west", "delta": Vector2i(-1, 0)}
]

func _init(manager_ref: Node) -> void:
	manager = manager_ref

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

func validate_constructor_palette_contract() -> Array[String]:
	var warnings: Array[String] = []
	var visible_archetypes: Dictionary = {}
	var visible_wall_prefabs: Array[String] = []
	for row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var prefab_id: String = _safe_string(row.get("prefab_id", row.get("id", ""))).strip_edges()
		var archetype_id: String = _safe_string(row.get("archetype_id", "")).strip_edges()
		if prefab_id.is_empty():
			warnings.append("constructor_palette_row_missing_prefab_id")
			continue
		if WorldObjectCatalogRef.LEGACY_DOOR_IDS.has(prefab_id) or WorldObjectCatalogRef.is_constructor_door_preset(prefab_id) or WorldObjectCatalogRef.LEGACY_WALL_ALIAS_CONFIGS.has(prefab_id) or WorldObjectCatalogRef.LEGACY_TERMINAL_ALIAS_CONFIGS.has(prefab_id):
			warnings.append("constructor_palette_exposes_legacy_alias_%s" % prefab_id)
		if _safe_string(row.get("object_group", "")) == "wall":
			visible_wall_prefabs.append(prefab_id)
		if not archetype_id.is_empty():
			if visible_archetypes.has(archetype_id):
				warnings.append("constructor_palette_duplicate_archetype_%s" % archetype_id)
			visible_archetypes[archetype_id] = true
		var object_data: Dictionary = WorldObjectCatalogRef.create_world_object(prefab_id, "validation_%s" % prefab_id)
		if object_data.is_empty():
			warnings.append("constructor_palette_prefab_creates_empty_object_%s" % prefab_id)
	if not visible_archetypes.has("door"):
		warnings.append("constructor_palette_missing_door_archetype")
	if not visible_archetypes.has("terminal"):
		warnings.append("constructor_palette_missing_terminal_archetype")
	if WorldObjectCatalogRef.get_archetype_property_schema("terminal").is_empty():
		warnings.append("terminal_archetype_missing_property_schema")
	if visible_wall_prefabs != ["external_wall", "wall"] and visible_wall_prefabs != ["wall", "external_wall"]:
		warnings.append("constructor_palette_wall_entries_must_be_exactly_external_wall_and_wall")
	for required_wall_archetype in ["external_wall", "wall"]:
		if visible_wall_prefabs.count(required_wall_archetype) != 1:
			warnings.append("constructor_palette_requires_exactly_one_%s" % required_wall_archetype)
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
		linked.append({"label":"Lighting", "target_id":"section", "target_kind":"world_object", "field_name":"power_source_id", "location":"summary"})
		linked.append({"label":"Outlets", "target_id":"section", "target_kind":"world_object", "field_name":"power_source_id", "location":"summary"})
		linked.append({"label":"Wires / physical circuit", "target_id":"section", "target_kind":"world_object", "field_name":"power_source_id", "location":"summary"})
		var outlet_count: int = 0
		var linked_wire_count: int = 0
		var linked_light_count: int = 0
		for object_data in manager.mission_world_objects:
			var linked_source: String = _safe_string(object_data.get("power_source_id", object_data.get("connected_power_source_id", object_data.get("power_network_id", "")))).strip_edges()
			if linked_source != source_id:
				continue
			var linked_type: String = _safe_string(object_data.get("object_type", "")).strip_edges().to_lower()
			if linked_type == "light":
				linked_light_count += 1
			elif linked_type in ["power_socket", "outlet"]:
				outlet_count += 1
			elif linked_type == "power_cable":
				linked_wire_count += 1
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
	var explicit_prefab_metadata: Dictionary = manager._get_map_constructor_prefab_metadata_catalog()
	for palette_entry in manager.get_map_constructor_prefab_catalog():
		var palette_prefab_id: String = _safe_string(palette_entry.get("id", "")).strip_edges().to_lower()
		palette_ids[palette_prefab_id] = true
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
	for catalog_row in WorldObjectCatalogRef.get_constructor_palette_rows():
		var catalog_prefab_id: String = _safe_string(catalog_row.get("prefab_id", "")).strip_edges().to_lower()
		if not palette_ids.has(catalog_prefab_id):
			issues.append(_make_map_constructor_issue("palette_missing_catalog_object_%s" % catalog_prefab_id, "error", "Constructor-placeable catalog object missing from Map Constructor palette: %s." % catalog_prefab_id, Vector2i(-1, -1), source_name, "palette", catalog_prefab_id, "Generate object palette rows from WorldObjectCatalog."))
	for index in range(manager.mission_world_objects.size()):
		var data: Dictionary = manager._safe_dictionary(manager.mission_world_objects[index])
		var entity_kind: String = _map_constructor_entity_kind(data)
		if entity_kind == "item":
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
		elif bool(data.get("created_by_map_constructor", false)) and not WorldObjectCatalogRef.OBJECT_LIBRARY.has(object_type):
			issues.append(_make_map_constructor_issue("obj_unknown_constructor_type_%s" % object_id, "error", "Constructor object_type is not in WorldObjectCatalog: %s." % object_type, object_cell, source_name, entity_kind, object_id, "Use a canonical WorldObjectCatalog runtime object type."))
		var raw_access_type: String = _safe_string(data.get("access_type", "")).strip_edges().to_lower()
		if raw_access_type == "none":
			issues.append(_make_map_constructor_issue("obj_legacy_access_none_%s" % object_id, "error", "Legacy access_type=none must be normalized to no_key.", object_cell, source_name, entity_kind, object_id, "Normalize access_type through WorldObjectCatalog."))
		elif not raw_access_type.is_empty():
			var normalized_access_type: String = WorldObjectCatalogRef.normalize_access_type(raw_access_type)
			if normalized_access_type != raw_access_type or not normalized_access_type in WorldObjectCatalogRef.ACCESS_TYPES:
				issues.append(_make_map_constructor_issue("obj_invalid_access_type_%s" % object_id, "error", "Object access_type is not canonical: %s." % raw_access_type, object_cell, source_name, entity_kind, object_id, "Use no_key, key_card, digital_key, access_code, or terminal."))
		if data.has("lock_type") and not data.has("access_type"):
			issues.append(_make_map_constructor_issue("obj_lock_without_access_%s" % object_id, "error", "Legacy lock_type is present without canonical access_type.", object_cell, source_name, entity_kind, object_id, "Populate canonical access_type while retaining lock_type only as compatibility metadata."))
		if object_group == "door" and WorldObjectCatalogRef.is_material_named_door_object_type(object_type) and _safe_string(data.get("door_type", "")).strip_edges().is_empty():
			issues.append(_make_map_constructor_issue("obj_material_door_missing_mechanism_%s" % object_id, "error", "Material-named door is missing canonical door_type mechanism.", object_cell, source_name, entity_kind, object_id, "Populate canonical door_type."))
		if object_group == "door":
			for contract_warning in WorldObjectCatalogRef.validate_archetype_object(data):
				issues.append(_make_map_constructor_issue("obj_archetype_%s_%s" % [object_id, contract_warning], "error", "Door archetype contract violation: %s." % contract_warning, object_cell, source_name, entity_kind, object_id, "Normalize through WorldObjectCatalog archetype creation and schema validation."))
		if object_group.is_empty():
			issues.append(_make_map_constructor_issue("obj_missing_group_%d" % index, "error", "Object missing object_group.", object_cell, source_name, entity_kind, object_id))
		if object_cell.x < 0 or object_cell.y < 0:
			issues.append(_make_map_constructor_issue("obj_invalid_cell_%d" % index, "error", "Object position invalid or negative.", object_cell, source_name, entity_kind, object_id))
		elif has_grid_bounds and not bool(manager.grid_manager.call("is_in_bounds", object_cell)):
			issues.append(_make_map_constructor_issue("obj_out_of_bounds_%d" % index, "error", "Object out of bounds.", object_cell, source_name, entity_kind, object_id))
		var allow_overlap: bool = bool(data.get("allow_cell_overlap", false))
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
		if _safe_string(data.get("placement_mode", "")).to_lower() != "wall_mounted" and not normalized_object_type.contains("door") and not normalized_object_type.contains("gate") and manager._is_map_constructor_wall_cell(object_cell):
			issues.append(_make_map_constructor_issue("grounding_floor_on_wall_%d" % index, "warning", "Floor-standing object is placed on a wall cell.", object_cell, source_name, entity_kind, object_id))
		if (normalized_object_type.contains("door") or normalized_object_type.contains("gate")) and manager.grid_manager != null and manager.grid_manager.has_method("get_tile") and manager._is_valid_grid_cell(object_cell):
			var door_tile: int = int(manager.grid_manager.call("get_tile", object_cell))
			if door_tile != GridManager.TILE_DOOR and door_tile != GridManager.TILE_DIGITAL_DOOR and door_tile != GridManager.TILE_POWERED_GATE:
				issues.append(_make_map_constructor_issue("door_grounding_mismatch_%d" % index, "warning", "Door/gate object is not on door/gate tile.", object_cell, source_name, entity_kind, object_id))
		if (normalized_object_type.contains("key") or normalized_object_type.contains("kit") or normalized_object_type.contains("card") or normalized_object_type.contains("code")) and manager._is_map_constructor_wall_cell(object_cell):
			issues.append(_make_map_constructor_issue("pickup_on_wall_%d" % index, "warning", "Pickup object overlaps blocked wall cell.", object_cell, source_name, entity_kind, object_id))
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
	var key_link_counts_by_door: Dictionary = {}
	for cell_variant in manager.cell_items.keys():
		var key_cell: Vector2i = manager._deserialize_cell_variant(cell_variant)
		for item_variant in manager._safe_array(manager.cell_items.get(cell_variant, [])):
			if not (item_variant is Dictionary):
				continue
			var key_data: Dictionary = manager._safe_dictionary(item_variant)
			if not _is_map_constructor_key_data(key_data):
				continue
			var key_id: String = _safe_string(key_data.get("id", "")).strip_edges()
			var linked_door_id: String = _safe_string(key_data.get("linked_door_id", "")).strip_edges()
			if linked_door_id.is_empty():
				issues.append(_make_map_constructor_issue("key_missing_door_%s" % key_id, "warning", "Key is not linked to any door.", key_cell, source_name, "item", key_id, "Link this key to an installed door."))
			else:
				if not bool(manager.get_map_constructor_entity_by_id("world_object", linked_door_id).get("ok", false)):
					issues.append(_make_map_constructor_issue("key_linked_door_missing_%s" % key_id, "error", "Linked door not found.", key_cell, source_name, "item", key_id, "Relink or clear linked_door_id."))
				if not key_link_counts_by_door.has(linked_door_id):
					key_link_counts_by_door[linked_door_id] = []
				key_link_counts_by_door[linked_door_id].append(key_id)
	for door_variant in manager.mission_world_objects:
		if not (door_variant is Dictionary):
			continue
		var door_data_for_link: Dictionary = manager._safe_dictionary(door_variant)
		if not _is_map_constructor_door_data(door_data_for_link):
			continue
		var door_id_for_link: String = _safe_string(door_data_for_link.get("id", "")).strip_edges()
		var door_cell_for_link: Vector2i = manager._deserialize_cell_variant(door_data_for_link.get("position", Vector2i(-1, -1)))
		var required_key_id: String = _safe_string(door_data_for_link.get("required_key_id", "")).strip_edges()
		var lock_type: String = _safe_string(door_data_for_link.get("lock_type", "")).strip_edges().to_lower()
		var door_requires_key: bool = lock_type.contains("key") or not required_key_id.is_empty()
		if door_requires_key and required_key_id.is_empty():
			issues.append(_make_map_constructor_issue("door_missing_key_%s" % door_id_for_link, "warning", "Door requires a key but no key is linked.", door_cell_for_link, source_name, "world_object", door_id_for_link, "Link a compatible key."))
		elif not required_key_id.is_empty() and not bool(manager.find_map_constructor_key_item_by_id(required_key_id).get("ok", false)):
			issues.append(_make_map_constructor_issue("door_linked_key_missing_%s" % door_id_for_link, "error", "Linked key not found.", door_cell_for_link, source_name, "world_object", door_id_for_link, "Relink or clear required_key_id."))
	for door_id_variant in key_link_counts_by_door.keys():
		var linked_keys: Array = manager._safe_array(key_link_counts_by_door.get(door_id_variant, []))
		if linked_keys.size() > 1:
			var door_entity_for_duplicate: Dictionary = manager.get_map_constructor_entity_by_id("world_object", _safe_string(door_id_variant))
			issues.append(_make_map_constructor_issue("door_duplicate_key_links_%s" % _safe_string(door_id_variant), "error", "Multiple keys link to the same door.", Vector2i(door_entity_for_duplicate.get("cell", Vector2i(-1, -1))), source_name, "world_object", _safe_string(door_id_variant), "Keep one key-door link."))
	return issues

func _map_constructor_issue_is_expected_invalid(issue: Dictionary) -> bool:
	var entity_id: String = str(issue.get("entity_id", "")).strip_edges()
	if entity_id.is_empty():
		return false
	return manager.is_task_test_expected_invalid_object_id(entity_id)

func _map_constructor_build_readiness_check(issue: Dictionary, status: String) -> Dictionary:
	var count: int = 1
	var issue_id: String = _safe_string(issue.get("id", ""))
	var label: String = "Validation check"
	if issue_id.find("wm_") == 0:
		label = "Wall-mounted attachment"
	elif issue_id.find("link_") == 0:
		label = "Entity links"
	elif issue_id.find("duplicate_") == 0:
		label = "Duplicate occupancy"
	elif issue_id.find("missing_marker_") == 0:
		label = "Mission markers"
	return {
		"id": issue_id,
		"label": label,
		"status": status,
		"message": str(issue.get("message", "")),
		"count": count,
		"entity_kind": str(issue.get("entity_kind", "")),
		"entity_id": str(issue.get("entity_id", "")),
		"cell": Vector2i(issue.get("cell", Vector2i(-1, -1))),
		"issue_id": issue_id
	}

func get_map_constructor_mission_readiness_report() -> Dictionary:
	var report: Dictionary = {
		"ok": false,
		"playable": false,
		"status": "unknown",
		"summary": "Mission readiness unavailable.",
		"blocking_count": 0,
		"warning_count": 0,
		"info_count": 0,
		"expected_invalid_count": 0,
		"checks": [],
		"blocking_issues": [],
		"warning_issues": [],
		"expected_invalid_issues": [],
		"recommended_actions": []
	}
	if not manager._is_task_test_constructor_context():
		report["summary"] = "Readiness works only in TASK TEST constructor mode."
		return report
	var checks: Array[Dictionary] = []
	var blocking: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	var expected_invalid: Array[Dictionary] = []
	var recommended: Array[Dictionary] = []
	var constructor_issues: Array[Dictionary] = []
	constructor_issues = manager._safe_dictionary_array(get_map_constructor_validation_issues())
	for issue in constructor_issues:
		var issue_row: Dictionary = manager._safe_dictionary(issue)
		var severity: String = _safe_string(issue_row.get("severity", "info")).to_lower()
		var expected: bool = _map_constructor_issue_is_expected_invalid(issue_row)
		if expected:
			expected_invalid.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "expected_invalid"))
			continue
		if severity == "error":
			blocking.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "fail"))
			var issue_fix_options: Array[Dictionary] = []
			issue_fix_options.append_array(manager.get_map_constructor_issue_autofix_options(issue_row))
			for fix_opt in issue_fix_options:
				var option: Dictionary = manager._safe_dictionary(fix_opt)
				recommended.append({"label": _safe_string(option.get("label", "Fix issue")), "action_type": "autofix", "fix_type": _safe_string(option.get("fix_type", "")), "cleanup_type": "", "options": manager._safe_dictionary(option.get("options", {})), "target_issue_id": _safe_string(issue_row.get("id", ""))})
			var message_text: String = _safe_string(issue_row.get("message", "")).to_lower()
			if message_text.find("missing") >= 0:
				recommended.append({"label":"Clean invalid references", "action_type":"cleanup", "fix_type":"", "cleanup_type":"invalid_references", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			if message_text.find("broken") >= 0 or message_text.find("missing") >= 0:
				recommended.append({"label":"Fix broken references", "action_type":"autofix", "fix_type":"clear_all_broken_references", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			if _safe_string(issue_row.get("id", "")).begins_with("wm_"):
				recommended.append({"label":"Repair wall-mounted attachments", "action_type":"autofix", "fix_type":"repair_all_wall_mounted_attachments", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
			recommended.append({"label":"Jump to issue", "action_type":"jump", "fix_type":"", "cleanup_type":"", "options":{}, "target_issue_id":_safe_string(issue_row.get("id", ""))})
		elif severity == "warning":
			warnings.append(issue_row)
			checks.append(_map_constructor_build_readiness_check(issue_row, "warning"))
		else:
			checks.append(_map_constructor_build_readiness_check(issue_row, "info"))
	var audit_summary: Dictionary = get_map_constructor_audit_summary()
	checks.append({"id":"audit_summary","label":"Audit coverage","status":"info","message":"missing=%d invalid=%d runtime_warn=%d duplicates=%d" % [int(audit_summary.get("missing_coverage_count",0)), int(audit_summary.get("invalid_links_count",0)), int(audit_summary.get("runtime_warnings_count",0)), int(audit_summary.get("duplicate_cell_warnings_count",0))],"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var task_audit: Dictionary = manager.get_task_test_system_audit_report()
	var runtime_warnings: Array = manager._safe_array(task_audit.get("runtime_cell_warnings", []))
	for rw in runtime_warnings:
		warnings.append({"id":"runtime_warning_%d" % warnings.size(), "severity":"warning", "message":_safe_string(rw)})
		checks.append({"id":"runtime_warning_%d" % warnings.size(),"label":"Runtime warning","status":"warning","message":_safe_string(rw),"count":1,"entity_kind":"","entity_id":"","cell":Vector2i(-1,-1),"issue_id":""})
	var blocking_count: int = blocking.size()
	var warning_count: int = warnings.size()
	var expected_count: int = expected_invalid.size()
	var info_count: int = maxi(0, checks.size() - blocking_count - warning_count - expected_count)
	var status: String = "playable"
	if blocking_count > 0:
		status = "blocked"
	elif warning_count > 0:
		status = "warning"
	report["ok"] = true
	report["playable"] = blocking_count == 0
	report["status"] = status
	report["summary"] = "Readiness %s | blocking=%d warnings=%d expected-invalid=%d info=%d" % [status.to_upper(), blocking_count, warning_count, expected_count, info_count]
	report["blocking_count"] = blocking_count
	report["warning_count"] = warning_count
	report["info_count"] = info_count
	report["expected_invalid_count"] = expected_count
	report["checks"] = checks
	report["blocking_issues"] = blocking
	report["warning_issues"] = warnings
	report["expected_invalid_issues"] = expected_invalid
	report["recommended_actions"] = recommended
	return report

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
