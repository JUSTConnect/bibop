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
	var archetype_counts: Dictionary = {}
	var visible_wall_prefabs: Array[String] = []
	var visible_floor_prefabs: Array[String] = []
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
		"terminal":"constructor_palette_requires_exactly_one_terminal"
	}
	for required_archetype in required_archetype_warning_ids:
		if int(archetype_counts.get(required_archetype, 0)) != 1:
			warnings.append(required_archetype_warning_ids[required_archetype])
	if not archetype_counts.has("door"):
		warnings.append("constructor_palette_missing_door_archetype")
	if not archetype_counts.has("terminal"):
		warnings.append("constructor_palette_missing_terminal_archetype")
	if visible_floor_prefabs != ["floor"]:
		warnings.append("constructor_palette_floor_entries_must_be_exactly_floor")
	if WorldObjectCatalogRef.get_archetype_property_schema("terminal").is_empty():
		warnings.append("terminal_archetype_missing_property_schema")
	if visible_wall_prefabs != ["external_wall", "wall"] and visible_wall_prefabs != ["wall", "external_wall"]:
		warnings.append("constructor_palette_wall_entries_must_be_exactly_external_wall_and_wall")
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
	elif Array(floor_material_schema.get("values", [])) != WorldObjectCatalogRef.FLOOR_MATERIALS or _safe_string(floor_material_schema.get("default", "")) != "steel":
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
	var expected_floor_display_names: Dictionary = {"steel":"Steel Floor", "concrete":"Concrete Floor", "grate":"Grate Floor"}
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
