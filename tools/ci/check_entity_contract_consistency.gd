extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const Contract = preload("res://scripts/world/entity_definition_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _has_error(report: Dictionary, code: String) -> bool:
	for value in Array(report.get("errors", [])):
		if value is Dictionary and str(Dictionary(value).get("code", "")) == code:
			return true
	return false

func _has_warning(report: Dictionary, code: String, field_name: String = "") -> bool:
	for value in Array(report.get("warnings", [])):
		if not (value is Dictionary):
			continue
		var warning: Dictionary = Dictionary(value)
		if str(warning.get("code", "")) != code:
			continue
		if field_name.is_empty() or str(warning.get("field", "")) == field_name:
			return true
	return false

func _diagnostic_shape_valid(diagnostic: Dictionary, severity: String) -> bool:
	if str(diagnostic.get("severity", "")) != severity:
		return false
	for field_name in ["code", "field", "message_key", "message", "fallback", "fix_hint"]:
		if str(diagnostic.get(field_name, "")).strip_edges().is_empty():
			return false
	return diagnostic.get("details", {}) is Dictionary

func _report_diagnostics_have_shape(report: Dictionary) -> bool:
	for value in Array(report.get("errors", [])):
		if not (value is Dictionary) or not _diagnostic_shape_valid(Dictionary(value), "error"):
			return false
	for value in Array(report.get("warnings", [])):
		if not (value is Dictionary) or not _diagnostic_shape_valid(Dictionary(value), "warning"):
			return false
	return true

func _diagnostic_has(diagnostics: Array[Dictionary], prefab_id: String, code: String) -> bool:
	for diagnostic in diagnostics:
		if str(diagnostic.get("prefab_id", "")) != prefab_id:
			continue
		for value in Array(diagnostic.get("errors", [])):
			if value is Dictionary and str(Dictionary(value).get("code", "")) == code:
				return true
	return false

func _door_definition() -> Dictionary:
	return WorldObjectCatalog.get_constructor_prefab_definition("door")

func _with_contract(definition: Dictionary, contract: Dictionary) -> Dictionary:
	var copy: Dictionary = definition.duplicate(true)
	copy["entity_contract"] = contract.duplicate(true)
	return copy

func _mutated_door_report(profile_field: String, profile_value: String, capability: String, capability_value: bool) -> Dictionary:
	var definition: Dictionary = _door_definition()
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})).duplicate(true)
	contract[profile_field] = profile_value
	capabilities[capability] = capability_value
	contract["capabilities"] = capabilities
	return Contract.validate_definition("door", _with_contract(definition, contract))

func _raw_field_report(field_name: String, value: Variant, capability: String, capability_value: bool) -> Dictionary:
	var definition: Dictionary = _door_definition()
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})).duplicate(true)
	capabilities[capability] = capability_value
	contract["capabilities"] = capabilities
	if capability == "power":
		contract["power_profile"] = "none" if not capability_value else "configurable"
	if capability == "health":
		contract["status_profile"] = "cooling_passive" if not capability_value else "object_standard"
	definition[field_name] = value
	definition["entity_contract"] = contract
	return Contract.validate_definition("synthetic", definition)

func _editable_field_report(field_name: String, capability: String, capability_value: bool) -> Dictionary:
	var definition: Dictionary = _door_definition()
	var schema: Array = Array(definition.get("property_schema", [])).duplicate(true)
	schema.append({"field": field_name, "type":"string", "default":""})
	definition["property_schema"] = schema
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})).duplicate(true)
	capabilities[capability] = capability_value
	contract["capabilities"] = capabilities
	if capability == "power" and not capability_value:
		contract["power_profile"] = "none"
	definition["entity_contract"] = contract
	return Contract.validate_definition("synthetic", definition)

func _run() -> void:
	await process_frame
	_assert(_has_error(_mutated_door_report("power_profile", "none", "power", true), "entity_contract.profile_capability_forbidden"), "enabled power with none profile was accepted")
	_assert(_has_error(_mutated_door_report("power_profile", "configurable", "power", false), "entity_contract.profile_capability_required"), "disabled power with active profile was accepted")
	_assert(_has_error(_mutated_door_report("status_profile", "none", "state", true), "entity_contract.profile_capability_required"), "state with none status profile was accepted")
	_assert(_has_error(_raw_field_report("durability", 1, "health", false), "entity_contract.capability_field_forbidden"), "health=false + durability was accepted")
	_assert(_has_error(_editable_field_report("power_type", "power", false), "entity_contract.property_schema_field_forbidden"), "power=false + editable power_type was accepted")
	_assert(_has_error(_editable_field_report("power_state", "power", true), "entity_contract.computed_field_editable"), "computed power_state editable was accepted")
	_assert(_has_error(_raw_field_report("resolved_source_id", "source", "power", true), "entity_contract.computed_field_stored"), "computed resolved_source_id stored was accepted")
	_assert(_has_error(_mutated_door_report("status_profile", "item_standard", "state", true), "entity_contract.profile_entity_type_mismatch"), "wrong profile/entity_type was accepted")
	_assert(_has_error(_mutated_door_report("status_profile", "cooling_passive", "health", true), "entity_contract.profile_capability_forbidden"), "forbidden profile capability was accepted")

	var duplicate_definition: Dictionary = _door_definition()
	var duplicate_schema: Array = Array(duplicate_definition.get("property_schema", [])).duplicate(true)
	duplicate_schema.append({"field":"state", "type":"enum", "values":["closed"], "default":"closed"})
	duplicate_definition["property_schema"] = duplicate_schema
	_assert(_has_error(Contract.validate_definition("door", duplicate_definition), "entity_contract.property_schema_duplicate_field"), "duplicate property_schema field was accepted")
	var unknown_contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	unknown_contract["status_profile"] = "unknown_profile"
	_assert(_has_error(Contract.validate_definition("door", _with_contract(_door_definition(), unknown_contract)), "entity_contract.profile_unknown"), "unknown profile was accepted")
	_assert(Contract.validate_fixture_registry().is_empty(), "profile fixture registry invalid: %s" % str(Contract.validate_fixture_registry()))

	var fixture_count: int = 0
	for profile_field_value in Contract.PROFILE_REGISTRIES.keys():
		var profile_field: String = str(profile_field_value)
		for profile_id_value in Contract.get_profile_ids(profile_field):
			var profile_id: String = str(profile_id_value)
			var descriptor: Dictionary = Contract.get_profile_descriptor(profile_field, profile_id)
			for fixture_id_value in Array(descriptor.get("fixture_ids", [])):
				fixture_count += 1
				var fixture: Dictionary = Contract.resolve_validation_fixture(str(fixture_id_value))
				_assert(not fixture.is_empty(), "fixture did not resolve: %s" % str(fixture_id_value))
				_assert(str(fixture.get("profile_field", "")) == profile_field, "fixture profile field mismatch: %s" % str(fixture_id_value))
				_assert(str(fixture.get("profile_id", "")) == profile_id, "fixture profile id mismatch: %s" % str(fixture_id_value))
				_assert(fixture.get("valid_sample", {}) is Dictionary, "fixture valid sample missing: %s" % str(fixture_id_value))
				_assert(fixture.get("invalid_mutations", []) is Array and not Array(fixture.get("invalid_mutations", [])).is_empty(), "fixture mutations missing: %s" % str(fixture_id_value))
				var allowed_fields: Variant = fixture.get("allowed_fields", {})
				_assert(allowed_fields is Dictionary, "fixture allowed fields missing: %s" % str(fixture_id_value))
				if allowed_fields is Dictionary:
					for field_class in ["stored", "editable", "computed"]:
						_assert(Dictionary(allowed_fields).get(field_class, []) is Array, "fixture field class missing: %s/%s" % [str(fixture_id_value), field_class])
	_assert(fixture_count > 1, "default remained the only fixture")

	var invalid_exception: Dictionary = _door_definition()
	invalid_exception["legacy_semantic_exceptions"] = [{"field":"durability"}]
	_assert(_has_error(Contract.validate_definition("door", invalid_exception), "entity_contract.legacy_exception_invalid"), "invalid legacy exception was accepted")
	var absent_exception: Dictionary = _door_definition()
	absent_exception["legacy_semantic_exceptions"] = [{"field":"durability", "reason":"Absent", "migration_issue":1190}]
	_assert(_has_error(Contract.validate_definition("door", absent_exception), "entity_contract.legacy_exception_invalid"), "exception for absent field was accepted")
	var unknown_issue_definition: Dictionary = _door_definition()
	unknown_issue_definition["durability"] = 1
	unknown_issue_definition["legacy_semantic_exceptions"] = [{"field":"durability", "reason":"Unknown migration", "migration_issue":9999}]
	_assert(_has_error(Contract.validate_definition("synthetic_unknown_issue", unknown_issue_definition), "entity_contract.legacy_exception_invalid"), "unknown migration issue was accepted")
	var enabled_legacy_definition: Dictionary = _door_definition()
	enabled_legacy_definition["durability"] = 1
	_assert(_has_error(Contract.validate_definition("synthetic_enabled_legacy", enabled_legacy_definition), "entity_contract.legacy_exception_invalid"), "legacy field with enabled capability was accepted without exception")
	var legacy_definition: Dictionary = _door_definition()
	legacy_definition["durability"] = 1
	legacy_definition["legacy_semantic_exceptions"] = [{"field":"durability", "reason":"Legacy", "migration_issue":1190}]
	var legacy_contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	var legacy_caps: Dictionary = Dictionary(legacy_contract.get("capabilities", {})).duplicate(true)
	legacy_caps["health"] = false
	legacy_contract["capabilities"] = legacy_caps
	legacy_contract["status_profile"] = "cooling_passive"
	legacy_definition["entity_contract"] = legacy_contract
	var legacy_report: Dictionary = Contract.validate_definition("legacy", legacy_definition)
	_assert(_has_warning(legacy_report, "entity_contract.legacy_semantic_exception", "durability"), "valid legacy exception did not warn")
	_assert(_report_diagnostics_have_shape(legacy_report), "legacy warning has incomplete diagnostic shape")

	var computed_report: Dictionary = _raw_field_report("resolved_source_id", "source", "power", true)
	_assert(_report_diagnostics_have_shape(computed_report), "semantic error has incomplete diagnostic shape")
	var socket_report: Dictionary = WorldObjectCatalog.validate_entity_definition_contract("power_socket")
	_assert(bool(socket_report.get("valid", false)), "power socket contract invalid: %s" % str(socket_report.get("errors", [])))
	_assert(not _has_warning(socket_report, "entity_contract.legacy_semantic_exception"), "migrated power socket still reports a legacy semantic exception")
	_assert(not WorldObjectCatalog.get_constructor_prefab_definition("power_socket").has("legacy_semantic_exceptions"), "migrated power socket definition still declares #1181 exceptions")
	_assert(_report_diagnostics_have_shape(socket_report), "power socket diagnostics have incomplete diagnostic shape")

	_assert(not Contract.resolve_validation_fixture("default").is_empty(), "default validation fixture did not resolve")
	_assert(not Contract.resolve_validation_fixture("status_object_standard").is_empty(), "profile validation fixture did not resolve")
	var definition: Dictionary = _door_definition()
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	contract["validation_fixture"] = "unknown_fixture"
	definition["entity_contract"] = contract
	_assert(_has_error(Contract.validate_definition("door", definition), "entity_contract.validation_fixture_unknown"), "unknown validation fixture was accepted")
	var before: Dictionary = _door_definition()
	var before_copy: Dictionary = before.duplicate(true)
	Contract.validate_definition("door", before)
	_assert(before == before_copy, "validator mutated source definition")

	var synthetic_order: Array[String] = ["missing_contract_prefab"]
	_assert(Catalog.get_catalog_entries(synthetic_order).is_empty(), "incomplete prefab leaked into palette")
	var diagnostics: Array[Dictionary] = Catalog.get_entity_contract_diagnostics()
	_assert(_diagnostic_has(diagnostics, "missing_contract_prefab", "entity_contract.missing"), "entity-contract diagnostic missing")
	_assert(_diagnostic_has(diagnostics, "missing_contract_prefab", "placement_contract.missing"), "placement-contract diagnostic missing")
	Catalog.get_catalog_entries()
	_assert(Catalog.get_entity_contract_diagnostics().is_empty(), "production catalog diagnostics should be empty")

	await process_frame
	if failures.is_empty():
		print("ENTITY_CONTRACT_CONSISTENCY_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ENTITY_CONTRACT_CONSISTENCY_GATE: FAIL: %s" % failure)
	quit(1)
