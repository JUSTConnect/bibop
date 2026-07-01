extends RefCounted
class_name EntityDefinitionContract

const FixtureData = preload("res://scripts/world/entity_contract_fixtures.gd")

const ENTITY_TYPES = FixtureData.ENTITY_TYPES
const CAPABILITY_KEYS = FixtureData.CAPABILITY_KEYS
const PROFILE_REGISTRIES = FixtureData.PROFILE_REGISTRIES
const REQUIRED_PROFILE_FIELDS = FixtureData.REQUIRED_PROFILE_FIELDS
const CAPABILITY_PROFILE_FIELDS = FixtureData.CAPABILITY_PROFILE_FIELDS
const ERROR_CODES = FixtureData.ERROR_CODES
const TEMPORARY_LEGACY_MIGRATION_ISSUES = FixtureData.TEMPORARY_LEGACY_MIGRATION_ISSUES
const VALIDATION_FIXTURE_REGISTRY = FixtureData.SPECS
const SCOPE_ENTITY := "entity"
const SCOPE_EXCLUDED := "excluded"

const FIELD_SEMANTICS: Dictionary = {
	"state":{"family":"state", "storage":"stored", "capability":"state"}, "allowed_states":{"family":"state", "storage":"stored", "capability":"state"}, "status":{"family":"state", "storage":"stored", "capability":"state"}, "allowed_statuses":{"family":"state", "storage":"stored", "capability":"state"}, "intent_state":{"family":"state", "storage":"stored", "capability":"state"}, "operational_state":{"family":"state", "storage":"stored", "capability":"state"}, "effective_state":{"family":"state", "storage":"computed", "capability":"state", "editable":false}, "is_operational":{"family":"state", "storage":"computed", "capability":"state", "editable":false}, "blocking_reason":{"family":"state", "storage":"computed", "capability":"state", "editable":false},
	"health":{"family":"health", "storage":"stored", "capability":"health"}, "current_health":{"family":"health", "storage":"stored", "capability":"health"}, "max_health":{"family":"health", "storage":"stored", "capability":"health"}, "durability":{"family":"health", "storage":"legacy", "capability":"health", "editable":false}, "health_state":{"family":"health", "storage":"stored", "capability":"health"}, "damaged":{"family":"health", "storage":"legacy", "capability":"health", "editable":false}, "broken":{"family":"health", "storage":"legacy", "capability":"health", "editable":false},
	"overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "current_overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "max_overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "thermal_state":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "overheated":{"family":"thermal", "storage":"stored", "capability":"overheat"},
	"energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "current_energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "max_energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "energy_capacity":{"family":"energy", "storage":"stored", "capability":"energy"},
	"power_type":{"family":"power", "storage":"stored", "capability":"power"}, "power_mode":{"family":"power", "storage":"stored", "capability":"power"}, "is_powered":{"family":"power", "storage":"stored", "capability":"power"}, "power_state":{"family":"power", "storage":"legacy", "computed":true, "capability":"power", "editable":false}, "power_source_id":{"family":"power", "storage":"legacy", "capability":"power", "editable":false}, "physical_connection_source_id":{"family":"power", "storage":"legacy", "computed":true, "capability":"power", "editable":false}, "preferred_source_id":{"family":"power", "storage":"stored", "capability":"power"}, "resolved_source_id":{"family":"power", "storage":"computed", "capability":"power", "editable":false}, "resolved_circuit_id":{"family":"power", "storage":"computed", "capability":"power", "editable":false}, "main_power_net":{"family":"power", "storage":"legacy", "capability":"power", "editable":false}, "power_network_id":{"family":"power", "storage":"legacy", "capability":"power", "editable":false}, "power_required":{"family":"power", "storage":"legacy", "capability":"power", "editable":false}, "power_received":{"family":"power", "storage":"legacy", "capability":"power", "editable":false},
	"control_type":{"family":"control", "storage":"stored", "capability":"control"}, "control_mode":{"family":"control", "storage":"stored", "capability":"control"}, "control_loss_behavior":{"family":"control", "storage":"stored", "capability":"control"}, "controlled_target_type":{"family":"control", "storage":"stored", "capability":"control"}, "control_terminal_id":{"family":"control", "storage":"legacy", "capability":"control", "editable":false}, "requires_external_control":{"family":"control", "storage":"legacy", "capability":"control", "editable":false},
	"access_type":{"family":"access", "storage":"stored", "capability":"access"}, "required_key_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_terminal_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_access_code_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_digital_key_id":{"family":"access", "storage":"stored", "capability":"access"},
	"linked_terminal_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_terminal_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_door_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_door_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "target_door_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_light_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "target_light_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_object_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_cooling_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_platform_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_power_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_lighting_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "chain_input_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "chain_output_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "connected_device_ids":{"family":"bindings", "storage":"legacy", "capability":"bindings", "editable":false, "legacy_presence_aliases":["connected_endpoint_count", "socket_connected_endpoint_count"]},
	"mount":{"family":"mount", "storage":"stored", "capability":"mount"}, "install_mode":{"family":"mount", "storage":"stored", "capability":"mount"}, "is_wall_mounted":{"family":"mount", "storage":"stored", "capability":"mount"}, "facing_side":{"family":"side", "storage":"stored", "capability":"side"}, "mount_side":{"family":"side", "storage":"stored", "capability":"side"}, "route_side_1":{"family":"routing", "storage":"stored", "capability":"routing"}, "route_side_2":{"family":"routing", "storage":"stored", "capability":"routing"}, "wall_side_1":{"family":"side", "storage":"legacy", "capability":"side"}, "wall_side_2":{"family":"side", "storage":"legacy", "capability":"side"},
	"route_mode":{"family":"routing", "storage":"stored", "capability":"routing"}, "route_shape":{"family":"routing", "storage":"derived", "capability":"routing"}, "passive_route":{"family":"routing", "storage":"derived", "capability":"routing"}, "wall_routing_mode":{"family":"routing", "storage":"legacy", "capability":"routing"}, "cooling_contour_id":{"family":"routing", "storage":"legacy", "capability":"routing"}, "cooling_contour_mode":{"family":"routing", "storage":"legacy", "capability":"routing"}, "cooling_contour_member_ids":{"family":"routing", "storage":"legacy", "capability":"routing"},
	"connection_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "source_object_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "sink_object_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "socket_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "endpoint_a_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "endpoint_b_id":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "end_1":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "end_2":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "path_cells":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false}, "connection_state":{"family":"physical_topology", "storage":"stored", "capability":"", "editable":false},
	"editor_readiness":{"family":"test_override", "storage":"computed", "capability":"test_override", "editable":false}, "editor_issues":{"family":"test_override", "storage":"computed", "capability":"test_override", "editable":false}
}

# Closed compatibility list for authoring-reachable OBJECT_LIBRARY fallbacks.
# New definitions must declare their own exact legacy_semantic_exceptions.
const LEGACY_LIBRARY_EXCEPTIONS: Dictionary = {
	"turret":[
		{"field":"durability", "reason":"Legacy turret health field pending #1192.", "migration_issue":1192},
		{"field":"power_network_id", "reason":"Legacy turret power field pending #1192.", "migration_issue":1192}
	],
	"debris":[
		{"field":"durability", "reason":"Legacy movable health field pending #1190.", "migration_issue":1190}
	]
}

static func has_profile(profile_field: String, profile_id: String) -> bool:
	return FixtureData.has_profile(profile_field, profile_id)

static func get_profile_descriptor(profile_field: String, profile_id: String) -> Dictionary:
	return FixtureData.get_profile_descriptor(profile_field, profile_id)

static func get_profile_ids(profile_field: String) -> Array:
	return FixtureData.get_profile_ids(profile_field)

static func resolve_validation_fixture(fixture_id: String) -> Dictionary:
	return FixtureData.get_fixture(fixture_id.strip_edges())

static func _diagnostic(code: String, severity: String, field: String, message: String, details: Dictionary = {}, fix_hint: String = "") -> Dictionary:
	var hint: String = fix_hint
	if hint.is_empty():
		hint = "Align %s with the canonical entity contract." % field
	return {"code":code, "severity":severity, "field":field, "message_key":code, "message":message, "fallback":message, "fix_hint":hint, "details":details.duplicate(true)}

static func _error(code: String, field: String, message: String, details: Dictionary = {}, fix_hint: String = "") -> Dictionary:
	return _diagnostic(code, "error", field, message, details, fix_hint)

static func _warning(code: String, field: String, message: String, details: Dictionary = {}, fix_hint: String = "") -> Dictionary:
	return _diagnostic(code, "warning", field, message, details, fix_hint)

static func _missing(errors: Array, field: String) -> void:
	errors.append(_error("entity_contract.%s_missing" % field, field, "Entity definition is missing %s." % field))

static func _property_fields(definition: Dictionary, errors: Array, definition_id: String) -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	var schema: Variant = definition.get("property_schema", [])
	if not (schema is Array):
		return result
	for value in Array(schema):
		if not (value is Dictionary):
			continue
		var field_name: String = str(Dictionary(value).get("field", "")).strip_edges()
		if field_name.is_empty():
			continue
		if seen.has(field_name):
			errors.append(_error("entity_contract.property_schema_duplicate_field", "property_schema", "Duplicate property_schema field %s." % field_name, {"definition_id":definition_id, "field_name":field_name}))
		else:
			seen[field_name] = true
		result.append(field_name)
	return result

static func _validate_profiles(definition_id: String, contract: Dictionary, entity_type: String, capabilities: Dictionary, errors: Array, applied_fixtures: Array) -> void:
	for field in REQUIRED_PROFILE_FIELDS:
		var profile_id: String = str(contract.get(field, "")).strip_edges()
		if profile_id.is_empty():
			_missing(errors, field)
			continue
		if not has_profile(field, profile_id):
			errors.append(_error("entity_contract.profile_unknown", field, "Unknown profile %s." % profile_id, {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id}))
			continue
		var descriptor: Dictionary = get_profile_descriptor(field, profile_id)
		var fixture_ids: Array = Array(descriptor.get("fixture_ids", []))
		if fixture_ids.is_empty():
			errors.append(_error("entity_contract.profile_fixture_missing", field, "Profile has no fixture coverage.", {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id}))
		for fixture_value in fixture_ids:
			var fixture_id: String = str(fixture_value)
			applied_fixtures.append(fixture_id)
			if resolve_validation_fixture(fixture_id).is_empty():
				errors.append(_error("entity_contract.profile_fixture_missing", field, "Profile fixture is missing.", {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id, "fixture_id":fixture_id}))
		var allowed_types: Array = Array(descriptor.get("allowed_entity_types", []))
		if not allowed_types.is_empty() and not allowed_types.has(entity_type):
			errors.append(_error("entity_contract.profile_entity_type_mismatch", field, "Profile %s is not valid for %s." % [profile_id, entity_type], {"definition_id":definition_id, "entity_type":entity_type, "profile_field":field, "profile_id":profile_id}))
		for value in Array(descriptor.get("required_capabilities", [])):
			var capability: String = str(value)
			if not bool(capabilities.get(capability, false)):
				errors.append(_error("entity_contract.profile_capability_required", field, "Profile %s requires %s." % [profile_id, capability], {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id, "capability":capability}))
		for value in Array(descriptor.get("forbidden_capabilities", [])):
			var capability: String = str(value)
			if bool(capabilities.get(capability, false)):
				errors.append(_error("entity_contract.profile_capability_forbidden", field, "Profile %s forbids %s." % [profile_id, capability], {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id, "capability":capability}))
	if str(contract.get("status_profile", "")) == "none" and bool(capabilities.get("state", false)):
		errors.append(_error("entity_contract.profile_capability_required", "status_profile", "State capability requires a non-none status profile.", {"definition_id":definition_id, "profile_field":"status_profile", "profile_id":"none", "capability":"state"}))

static func _exception_map(definition_id: String, definition: Dictionary, errors: Array) -> Dictionary:
	var result: Dictionary = {}
	var entries: Array = Array(LEGACY_LIBRARY_EXCEPTIONS.get(definition_id, [])).duplicate(true)
	var raw: Variant = definition.get("legacy_semantic_exceptions", [])
	if not (raw is Array):
		errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy exceptions must be an array.", {"definition_id":definition_id}))
		return result
	entries.append_array(Array(raw))
	var allowed_issues: Array = TEMPORARY_LEGACY_MIGRATION_ISSUES.values()
	for value in entries:
		if not (value is Dictionary):
			errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy exception must be a dictionary.", {"definition_id":definition_id}))
			continue
		var entry: Dictionary = Dictionary(value)
		var field_name: String = str(entry.get("field", "")).strip_edges()
		var reason: String = str(entry.get("reason", "")).strip_edges()
		var issue: int = int(entry.get("migration_issue", 0))
		if field_name.is_empty() or field_name.find("*") >= 0 or reason.is_empty() or not FIELD_SEMANTICS.has(field_name) or not allowed_issues.has(issue) or result.has(field_name):
			errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy exception is invalid.", {"definition_id":definition_id, "field_name":field_name, "migration_issue":issue}))
			continue
		result[field_name] = {"reason":reason, "migration_issue":issue, "source":"legacy_library" if LEGACY_LIBRARY_EXCEPTIONS.has(definition_id) and Array(LEGACY_LIBRARY_EXCEPTIONS[definition_id]).has(value) else "definition"}
	return result

static func _presence_field(definition: Dictionary, field_name: String) -> String:
	if definition.has(field_name):
		return field_name
	var semantics: Dictionary = Dictionary(FIELD_SEMANTICS.get(field_name, {}))
	for value in Array(semantics.get("legacy_presence_aliases", [])):
		var alias_name: String = str(value)
		if definition.has(alias_name):
			return alias_name
	return ""

static func _details(definition_id: String, entity_type: String, field_name: String, semantics: Dictionary) -> Dictionary:
	return {"definition_id":definition_id, "entity_type":entity_type, "field_name":field_name, "field_family":str(semantics.get("family", "")), "capability":str(semantics.get("capability", "")), "storage":str(semantics.get("storage", ""))}

static func _validate_fields(definition_id: String, definition: Dictionary, entity_type: String, capabilities: Dictionary, errors: Array, warnings: Array) -> Dictionary:
	var exposed: Dictionary = {}
	var exceptions: Dictionary = _exception_map(definition_id, definition, errors)
	var consumed: Dictionary = {}
	for field_name in _property_fields(definition, errors, definition_id):
		if not FIELD_SEMANTICS.has(field_name):
			continue
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS[field_name])
		exposed[field_name] = semantics.duplicate(true)
		var storage: String = str(semantics.get("storage", ""))
		var capability: String = str(semantics.get("capability", ""))
		var details: Dictionary = _details(definition_id, entity_type, field_name, semantics)
		if storage == "computed" or bool(semantics.get("computed", false)):
			errors.append(_error("entity_contract.computed_field_editable", field_name, "Computed field cannot be editable.", details))
		elif not bool(semantics.get("editable", true)) or storage == "legacy" or (not capability.is_empty() and not bool(capabilities.get(capability, false))):
			errors.append(_error("entity_contract.property_schema_field_forbidden", field_name, "Field is not editable under this contract.", details))
	var fields: Array = FIELD_SEMANTICS.keys()
	fields.sort()
	for value in fields:
		var field_name: String = str(value)
		if not definition.has(field_name):
			continue
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS[field_name])
		exposed[field_name] = semantics.duplicate(true)
		var storage: String = str(semantics.get("storage", ""))
		var capability: String = str(semantics.get("capability", ""))
		var details: Dictionary = _details(definition_id, entity_type, field_name, semantics)
		if storage == "computed":
			errors.append(_error("entity_contract.computed_field_stored", field_name, "Computed field cannot be stored.", details))
		elif storage == "legacy":
			if exceptions.has(field_name):
				var exception: Dictionary = Dictionary(exceptions[field_name])
				details["migration_issue"] = int(exception.get("migration_issue", 0))
				details["exception_source"] = str(exception.get("source", "definition"))
				warnings.append(_warning("entity_contract.legacy_semantic_exception", field_name, "Legacy field is temporarily allowed.", details))
				consumed[field_name] = true
			elif not capability.is_empty() and not bool(capabilities.get(capability, false)):
				errors.append(_error("entity_contract.capability_field_forbidden", field_name, "Field requires a disabled capability.", details))
			else:
				errors.append(_error("entity_contract.legacy_exception_invalid", field_name, "Legacy field requires an explicit migration exception.", details))
		elif not capability.is_empty() and not bool(capabilities.get(capability, false)):
			if exceptions.has(field_name):
				var exception: Dictionary = Dictionary(exceptions[field_name])
				details["migration_issue"] = int(exception.get("migration_issue", 0))
				details["exception_source"] = str(exception.get("source", "definition"))
				warnings.append(_warning("entity_contract.legacy_semantic_exception", field_name, "Legacy contradiction is temporarily allowed.", details))
				consumed[field_name] = true
			else:
				errors.append(_error("entity_contract.capability_field_forbidden", field_name, "Field requires a disabled capability.", details))
	var exception_fields: Array = exceptions.keys()
	exception_fields.sort()
	for value in exception_fields:
		var field_name: String = str(value)
		if consumed.has(field_name):
			continue
		var presence: String = _presence_field(definition, field_name)
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS.get(field_name, {}))
		var capability: String = str(semantics.get("capability", ""))
		if not presence.is_empty() and (str(semantics.get("storage", "")) == "legacy" or (not capability.is_empty() and not bool(capabilities.get(capability, false)))):
			var exception: Dictionary = Dictionary(exceptions[field_name])
			var details: Dictionary = _details(definition_id, entity_type, field_name, semantics)
			details["migration_issue"] = int(exception.get("migration_issue", 0))
			details["legacy_presence_field"] = presence
			details["exception_source"] = str(exception.get("source", "definition"))
			warnings.append(_warning("entity_contract.legacy_semantic_exception", field_name, "Legacy field is temporarily allowed.", details))
			consumed[field_name] = true
		else:
			errors.append(_error("entity_contract.legacy_exception_invalid", field_name, "Exception does not match a contradictory present field.", {"definition_id":definition_id, "field_name":field_name, "migration_issue":int(Dictionary(exceptions[field_name]).get("migration_issue", 0))}))
	return exposed

static func validate_definition(definition_id: String, definition: Dictionary) -> Dictionary:
	var contract: Dictionary = {}
	if definition.get("entity_contract", {}) is Dictionary:
		contract = Dictionary(definition.get("entity_contract", {})).duplicate(true)
	var report: Dictionary = {"valid":false, "semantic_valid":false, "palette_eligible":false, "definition_id":definition_id, "scope":str(contract.get("scope", "")), "entity_type":str(contract.get("entity_type", "")), "entity_subtype":str(contract.get("entity_subtype", "")), "capabilities":{}, "validation_fixture":{}, "applied_fixture_ids":[], "resolved_profiles":{}, "legacy_exceptions":[], "field_semantics":{}, "contract":contract.duplicate(true), "errors":[], "warnings":[]}
	var errors: Array = report["errors"]
	var warnings: Array = report["warnings"]
	if contract.is_empty():
		errors.append(_error("entity_contract.missing", "entity_contract", "Entity definition is missing entity_contract.", {"definition_id":definition_id}))
		return report
	var scope: String = str(contract.get("scope", "")).strip_edges()
	report["scope"] = scope
	if scope.is_empty():
		_missing(errors, "scope")
	elif scope not in [SCOPE_ENTITY, SCOPE_EXCLUDED]:
		errors.append(_error("entity_contract.scope_invalid", "scope", "Entity definition scope is invalid."))
	if scope == SCOPE_EXCLUDED:
		if str(contract.get("exclusion_reason", "")).strip_edges().is_empty():
			errors.append(_error("entity_contract.exclusion_reason_missing", "exclusion_reason", "Excluded definition is missing exclusion_reason."))
		report["valid"] = errors.is_empty()
		report["semantic_valid"] = report["valid"]
		report["palette_eligible"] = is_palette_eligible(report)
		return report
	var entity_type: String = str(contract.get("entity_type", "")).strip_edges()
	if entity_type.is_empty():
		_missing(errors, "entity_type")
	elif entity_type not in ENTITY_TYPES:
		errors.append(_error("entity_contract.entity_type_invalid", "entity_type", "Entity type is invalid."))
	if str(contract.get("entity_subtype", "")).strip_edges().is_empty():
		_missing(errors, "entity_subtype")
	var capabilities: Dictionary = {}
	if contract.get("capabilities", {}) is Dictionary:
		capabilities = Dictionary(contract.get("capabilities", {}))
	for key in CAPABILITY_KEYS:
		if not capabilities.has(key):
			errors.append(_error("entity_contract.capability_missing", "capabilities.%s" % key, "Capability is missing."))
		elif not (capabilities[key] is bool):
			errors.append(_error("entity_contract.capability_invalid", "capabilities.%s" % key, "Capability must be boolean."))
	report["capabilities"] = capabilities.duplicate(true)
	_validate_profiles(definition_id, contract, entity_type, capabilities, errors, report["applied_fixture_ids"])
	var resolved: Dictionary = {}
	for field in REQUIRED_PROFILE_FIELDS:
		var profile_id: String = str(contract.get(field, ""))
		if has_profile(field, profile_id):
			resolved[field] = get_profile_descriptor(field, profile_id)
	report["resolved_profiles"] = resolved
	var fixture_id: String = str(contract.get("validation_fixture", "")).strip_edges()
	if fixture_id.is_empty():
		_missing(errors, "validation_fixture")
	else:
		var fixture: Dictionary = resolve_validation_fixture(fixture_id)
		if fixture.is_empty():
			errors.append(_error("entity_contract.validation_fixture_unknown", "validation_fixture", "Validation fixture is unknown."))
		else:
			report["validation_fixture"] = fixture
	var schema: Variant = definition.get("property_schema", [])
	var property_profile: String = str(contract.get("property_profile", ""))
	if bool(definition.get("configurable", false)) and property_profile == "fixed":
		errors.append(_error("entity_contract.property_profile_configurable_mismatch", "property_profile", "Configurable definitions require definition_schema."))
	if (bool(definition.get("configurable", false)) or property_profile == "definition_schema") and (not (schema is Array) or Array(schema).is_empty()):
		errors.append(_error("entity_contract.property_schema_missing", "property_schema", "Property schema is required."))
	report["field_semantics"] = _validate_fields(definition_id, definition, entity_type, capabilities, errors, warnings)
	var report_exceptions: Array = Array(LEGACY_LIBRARY_EXCEPTIONS.get(definition_id, [])).duplicate(true)
	if definition.get("legacy_semantic_exceptions", []) is Array:
		report_exceptions.append_array(Array(definition.get("legacy_semantic_exceptions", [])).duplicate(true))
	report["legacy_exceptions"] = report_exceptions
	report["valid"] = errors.is_empty()
	report["semantic_valid"] = report["valid"]
	report["palette_eligible"] = is_palette_eligible(report)
	return report

static func _fixture_shape_valid(fixture: Dictionary) -> bool:
	if str(fixture.get("fixture_id", "")).is_empty() or not (fixture.get("valid_sample", {}) is Dictionary):
		return false
	if not (fixture.get("invalid_mutations", []) is Array) or Array(fixture.get("invalid_mutations", [])).is_empty():
		return false
	var allowed: Variant = fixture.get("allowed_fields", {})
	if not (allowed is Dictionary):
		return false
	for key in ["stored", "editable", "computed"]:
		if not (Dictionary(allowed).get(key, []) is Array):
			return false
	return true

static func validate_fixture_registry() -> Array:
	var errors: Array = []
	var covered: Dictionary = {}
	for profile_field_value in PROFILE_REGISTRIES.keys():
		var profile_field: String = str(profile_field_value)
		for profile_id_value in get_profile_ids(profile_field):
			var profile_id: String = str(profile_id_value)
			var descriptor: Dictionary = get_profile_descriptor(profile_field, profile_id)
			var fixture_ids: Array = Array(descriptor.get("fixture_ids", []))
			if fixture_ids.is_empty():
				errors.append(_error("entity_contract.profile_fixture_missing", profile_field, "Profile fixture is missing.", {"profile_field":profile_field, "profile_id":profile_id}))
				continue
			for fixture_value in fixture_ids:
				var fixture_id: String = str(fixture_value)
				var fixture: Dictionary = resolve_validation_fixture(fixture_id)
				if fixture.is_empty() or not _fixture_shape_valid(fixture):
					errors.append(_error("entity_contract.fixture_invalid", profile_field, "Fixture is missing or malformed.", {"profile_field":profile_field, "profile_id":profile_id, "fixture_id":fixture_id}))
					continue
				if str(fixture.get("profile_field", "")) != profile_field or str(fixture.get("profile_id", "")) != profile_id:
					errors.append(_error("entity_contract.fixture_invalid", profile_field, "Fixture points at another profile.", {"fixture_id":fixture_id}))
				for mutation_value in Array(fixture.get("invalid_mutations", [])):
					if not (mutation_value is Dictionary) or not ERROR_CODES.has(str(Dictionary(mutation_value).get("expected_code", ""))):
						errors.append(_error("entity_contract.fixture_invalid", profile_field, "Fixture mutation has an unknown expected code.", {"fixture_id":fixture_id}))
				covered["%s/%s" % [profile_field, profile_id]] = true
	for fixture_value in FixtureData.get_fixture_ids():
		var fixture: Dictionary = resolve_validation_fixture(str(fixture_value))
		if not has_profile(str(fixture.get("profile_field", "")), str(fixture.get("profile_id", ""))):
			errors.append(_error("entity_contract.fixture_invalid", "validation_fixture", "Fixture references an unknown profile.", {"fixture_id":str(fixture_value)}))
	if covered.size() != FixtureData.SPECS.size():
		errors.append(_error("entity_contract.fixture_invalid", "validation_fixture", "Every profile needs independent fixture coverage.", {"covered_profiles":covered.size(), "fixture_profiles":FixtureData.SPECS.size()}))
	return errors

static func is_palette_eligible(report: Dictionary) -> bool:
	return bool(report.get("valid", false))
