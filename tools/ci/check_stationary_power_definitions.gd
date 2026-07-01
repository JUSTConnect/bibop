extends SceneTree

const Catalog = preload("res://scripts/world/world_object_catalog.gd")
const CanonicalCatalog = preload("res://scripts/world/stationary_power_entity_catalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _has_any(value: Dictionary, fields: Array[String]) -> bool:
	for field_name in fields:
		if value.has(field_name):
			return true
	return false

func _run() -> void:
	await process_frame
	for family_id in CanonicalCatalog.FAMILY_IDS:
		var definition: Dictionary = Catalog.get_constructor_prefab_definition(family_id)
		var report: Dictionary = Catalog.validate_entity_definition_contract(family_id)
		_check(not definition.is_empty(), "definition missing: %s" % family_id)
		_check(bool(report.get("valid", false)), "definition invalid: %s %s" % [family_id, str(report.get("errors", []))])
		_check(not definition.has("legacy_semantic_exceptions"), "legacy semantic exception remains: %s" % family_id)
		_check(not _has_any(definition, CanonicalCatalog.COMPUTED_POWER_FIELDS), "computed truth stored in definition: %s" % family_id)

	var cable_definition: Dictionary = Catalog.get_constructor_prefab_definition("power_cable")
	var cable_contract: Dictionary = Dictionary(cable_definition.get("entity_contract", {}))
	_check(not bool(Dictionary(cable_contract.get("capabilities", {})).get("bindings", true)), "stationary cable still uses BindingStore")
	_check(not _has_any(cable_definition, ["durability", "current_health", "max_health", "wall_side", "wall_side_1", "wall_side_2", "power_source_id", "physical_connection_source_id"]), "stationary cable keeps forbidden authoring truth")
	_check(str(cable_definition.get("health_state", "")) == "healthy", "stationary cable discrete health missing")

	for alias_id in ["power_source_class_1", "power_source_class_2", "power_source_class_3", "circuit_breaker", "circuit_switch", "light_switch", "fuse_box_installed", "fuse_box_empty", "outlet", "legacy_light_library"]:
		var canonical_id: String = CanonicalCatalog.canonical_id(alias_id)
		_check(Catalog.get_entity_definition_contract(alias_id) == Catalog.get_entity_definition_contract(canonical_id), "alias contract mismatch: %s" % alias_id)
		_check(not Catalog.create_world_object(alias_id, "alias_%s" % alias_id).is_empty(), "legacy alias failed to load: %s" % alias_id)

	for source_class in [1, 2, 3]:
		var source_alias: String = "power_source_class_%d" % source_class
		var source_record: Dictionary = Catalog.create_world_object(source_alias, "source_class_%d" % source_class)
		_check(str(source_record.get("object_type", "")) == "power_source", "source alias did not normalize: %s" % source_alias)
		_check(int(source_record.get("power_source_class", 0)) == source_class, "source class lost: %s" % source_alias)
		_check(not _has_any(source_record, CanonicalCatalog.COMPUTED_POWER_FIELDS), "source record persists computed truth: %s" % source_alias)

	var new_records: Array[Dictionary] = [
		Catalog.create_world_object("power_cable", "new_cable"),
		Catalog.create_world_object("power_socket", "new_socket"),
		Catalog.create_world_object("fuse_box", "new_fuse"),
		Catalog.create_world_object("power_switcher", "new_switch"),
		Catalog.create_world_object("light", "new_light")
	]
	for record in new_records:
		_check(not _has_any(record, CanonicalCatalog.COMPUTED_POWER_FIELDS), "new record persists computed truth: %s" % str(record.get("id", "")))
	var new_fuse: Dictionary = new_records[2]
	var new_switch: Dictionary = new_records[3]
	var new_light: Dictionary = new_records[4]
	_check(not _has_any(new_light, ["state", "status", "is_on", "light_enabled"]), "new light keeps state/on double truth")
	_check(str(new_light.get("intent_state", "")) == "on" and str(new_light.get("health_state", "")) == "healthy" and str(new_light.get("thermal_state", "")) == "normal", "new light axes are incomplete")
	_check(not _has_any(new_switch, ["state", "switch_state", "is_on"]), "new switch keeps legacy truth")
	_check(not _has_any(new_fuse, ["state", "fuse_present", "fuse_installed"]), "new fuse keeps legacy truth")

	var legacy_record: Dictionary = {"id":"legacy_cable", "object_type":"power_cable", "state":"broken", "broken":true, "durability":0, "power_state":"unpowered", "power_source_id":"old_source", "wall_side":"north"}
	var legacy_before: Dictionary = legacy_record.duplicate(true)
	var adapted: Dictionary = Catalog.adapt_legacy_stationary_power_record(legacy_record)
	_check(legacy_record == legacy_before, "legacy adapter mutated source")
	_check(str(adapted.get("health_state", "")) == "broken", "legacy cable health not adapted")
	_check(not _has_any(adapted, CanonicalCatalog.COMPUTED_POWER_FIELDS), "legacy adapter emitted computed truth")
	_check(not _has_any(adapted, ["durability", "wall_side", "power_source_id"]), "legacy adapter emitted forbidden authoring truth")

	if failures.is_empty():
		print("STATIONARY_POWER_DEFINITIONS_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("STATIONARY_POWER_DEFINITIONS_GATE: FAIL: %s" % failure)
	quit(1)
