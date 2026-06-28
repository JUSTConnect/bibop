extends RefCounted
class_name EntityDefinitionContract

const ENTITY_TYPES: Array[String] = ["object", "item", "light", "cable", "movable", "cooling_system"]
const SCOPE_ENTITY := "entity"
const SCOPE_EXCLUDED := "excluded"
const CAPABILITY_KEYS: Array[String] = ["state", "power", "health", "energy", "overheat", "control", "access", "bindings", "mount", "side", "routing", "test_override"]
const ERROR_CODES: Array[String] = [
	"entity_contract.profile_entity_type_mismatch", "entity_contract.profile_capability_required", "entity_contract.profile_capability_forbidden",
	"entity_contract.capability_field_forbidden", "entity_contract.property_schema_field_forbidden", "entity_contract.property_schema_duplicate_field",
	"entity_contract.computed_field_editable", "entity_contract.computed_field_stored", "entity_contract.profile_fixture_missing",
	"entity_contract.fixture_invalid", "entity_contract.legacy_exception_invalid", "entity_contract.profile_unknown"
]

const TEMPORARY_LEGACY_MIGRATION_ISSUES: Dictionary = {
	"stationary_power_cables": 1181,
	"doors_terminals_access": 1182,
	"machines_cooling_box": 1183,
	"runtime_cable_reel": 1188,
	"items_details": 1189,
	"movable_crates": 1190,
	"passive_ducts_pipes": 1191,
	"final_versioned_migration": 1192
}

const FIELD_SEMANTICS: Dictionary = {
	"state":{"family":"state", "storage":"stored", "capability":"state"}, "allowed_states":{"family":"state", "storage":"stored", "capability":"state"}, "intent_state":{"family":"state", "storage":"stored", "capability":"state"}, "operational_state":{"family":"state", "storage":"stored", "capability":"state"}, "effective_state":{"family":"state", "storage":"computed", "capability":"state"}, "is_operational":{"family":"state", "storage":"computed", "capability":"state"}, "blocking_reason":{"family":"state", "storage":"computed", "capability":"state"},
	"health":{"family":"health", "storage":"stored", "capability":"health"}, "current_health":{"family":"health", "storage":"stored", "capability":"health"}, "max_health":{"family":"health", "storage":"stored", "capability":"health"}, "durability":{"family":"health", "storage":"legacy", "capability":"health"}, "health_state":{"family":"health", "storage":"stored", "capability":"health"},
	"overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "current_overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "max_overheat":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "thermal_state":{"family":"thermal", "storage":"stored", "capability":"overheat"}, "overheated":{"family":"thermal", "storage":"stored", "capability":"overheat"},
	"energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "current_energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "max_energy":{"family":"energy", "storage":"stored", "capability":"energy"}, "energy_capacity":{"family":"energy", "storage":"stored", "capability":"energy"},
	"power_type":{"family":"power", "storage":"stored", "capability":"power"}, "power_mode":{"family":"power", "storage":"stored", "capability":"power"}, "is_powered":{"family":"power", "storage":"stored", "capability":"power"}, "power_state":{"family":"power", "storage":"legacy", "computed":true, "capability":"power"}, "power_source_id":{"family":"power", "storage":"stored", "capability":"power"}, "physical_connection_source_id":{"family":"power", "storage":"legacy", "computed":true, "capability":"power"}, "preferred_source_id":{"family":"power", "storage":"stored", "capability":"power"}, "resolved_source_id":{"family":"power", "storage":"computed", "capability":"power"}, "resolved_circuit_id":{"family":"power", "storage":"computed", "capability":"power"}, "main_power_net":{"family":"power", "storage":"stored", "capability":"power"},
	"control_type":{"family":"control", "storage":"stored", "capability":"control"}, "control_mode":{"family":"control", "storage":"stored", "capability":"control"}, "control_loss_behavior":{"family":"control", "storage":"stored", "capability":"control"}, "controlled_target_type":{"family":"control", "storage":"stored", "capability":"control"},
	"access_type":{"family":"access", "storage":"stored", "capability":"access"}, "required_key_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_terminal_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_access_code_id":{"family":"access", "storage":"stored", "capability":"access"}, "required_digital_key_id":{"family":"access", "storage":"stored", "capability":"access"},
	"linked_terminal_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_door_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "target_door_id":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_light_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "target_light_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "linked_object_ids":{"family":"bindings", "storage":"stored", "capability":"bindings"}, "connected_device_ids":{"family":"bindings", "storage":"legacy", "capability":"bindings", "legacy_presence_aliases":["connected_endpoint_count", "socket_connected_endpoint_count"]},
	"mount":{"family":"mount", "storage":"stored", "capability":"mount"}, "install_mode":{"family":"mount", "storage":"stored", "capability":"mount"}, "is_wall_mounted":{"family":"mount", "storage":"stored", "capability":"mount"}, "facing_side":{"family":"side", "storage":"stored", "capability":"side"}, "wall_side_1":{"family":"side", "storage":"stored", "capability":"side"}, "wall_side_2":{"family":"side", "storage":"stored", "capability":"side"}, "route_mode":{"family":"routing", "storage":"stored", "capability":"routing"}, "wall_routing_mode":{"family":"routing", "storage":"stored", "capability":"routing"}, "cooling_contour_id":{"family":"routing", "storage":"legacy", "capability":"routing"}, "cooling_contour_mode":{"family":"routing", "storage":"legacy", "capability":"routing"}, "cooling_contour_member_ids":{"family":"routing", "storage":"legacy", "capability":"routing"},
	"editor_readiness":{"family":"test_override", "storage":"computed", "capability":"test_override"}, "editor_issues":{"family":"test_override", "storage":"computed", "capability":"test_override"}
}

const PROFILE_REGISTRIES: Dictionary = {
	"status_profile":{"none":{"allowed_entity_types":[], "fixture_ids":["status_none"]}, "object_standard":{"allowed_entity_types":["object"], "required_capabilities":["state"], "fixture_ids":["status_object_standard"]}, "item_standard":{"allowed_entity_types":["item"], "required_capabilities":["state"], "fixture_ids":["status_item_standard"]}, "light_standard":{"allowed_entity_types":["light"], "required_capabilities":["state"], "fixture_ids":["status_light_standard"]}, "cable_standard":{"allowed_entity_types":["cable"], "required_capabilities":["state"], "fixture_ids":["status_cable_standard"]}, "movable_standard":{"allowed_entity_types":["movable"], "required_capabilities":["state", "health"], "fixture_ids":["status_movable_standard"]}, "cooling_active":{"allowed_entity_types":["cooling_system"], "required_capabilities":["state"], "fixture_ids":["status_cooling_active"]}, "cooling_passive":{"allowed_entity_types":["cooling_system"], "forbidden_capabilities":["state", "power", "control", "health", "access"], "fixture_ids":["status_cooling_passive"]}},
	"property_profile":{"fixed":{"fixture_ids":["property_fixed"]}, "definition_schema":{"fixture_ids":["property_definition_schema"]}},
	"interaction_profile":{"none":{"fixture_ids":["interaction_none"]}, "standard_object":{"allowed_entity_types":["object"], "fixture_ids":["interaction_standard_object"]}, "item":{"allowed_entity_types":["item"], "fixture_ids":["interaction_item"]}, "light":{"allowed_entity_types":["light"], "fixture_ids":["interaction_light"]}, "cable":{"allowed_entity_types":["cable"], "fixture_ids":["interaction_cable"]}, "movable":{"allowed_entity_types":["movable"], "fixture_ids":["interaction_movable"]}, "cooling":{"allowed_entity_types":["cooling_system"], "fixture_ids":["interaction_cooling"]}},
	"notification_profile":{"none":{"fixture_ids":["notification_none"]}, "standard_action":{"required_capabilities":["state"], "fixture_ids":["notification_standard_action"]}},
	"power_profile":{"none":{"forbidden_capabilities":["power"], "fixture_ids":["power_none"]}, "configurable":{"required_capabilities":["power"], "fixture_ids":["power_configurable"]}, "internal_only":{"required_capabilities":["power"], "fixture_ids":["power_internal_only"]}, "external_only":{"required_capabilities":["power"], "fixture_ids":["power_external_only"]}},
	"control_profile":{"none":{"forbidden_capabilities":["control"], "fixture_ids":["control_none"]}, "configurable":{"required_capabilities":["control"], "fixture_ids":["control_configurable"]}, "internal_only":{"required_capabilities":["control"], "fixture_ids":["control_internal_only"]}, "external_only":{"required_capabilities":["control"], "fixture_ids":["control_external_only"]}},
	"access_profile":{"none":{"forbidden_capabilities":["access"], "fixture_ids":["access_none"]}, "standard":{"required_capabilities":["access"], "fixture_ids":["access_standard"]}, "multi_factor_ready":{"required_capabilities":["access"], "fixture_ids":["access_multi_factor_ready"]}},
	"binding_profile":{"none":{"forbidden_capabilities":["bindings"], "fixture_ids":["binding_none"]}, "standard":{"required_capabilities":["bindings"], "fixture_ids":["binding_standard"]}},
	"runtime_presentation_profile":{"excluded":{"fixture_ids":["runtime_excluded"]}, "standard_object":{"allowed_entity_types":["object"], "fixture_ids":["runtime_standard_object"]}, "standard_item":{"allowed_entity_types":["item"], "fixture_ids":["runtime_standard_item"]}, "standard_light":{"allowed_entity_types":["light"], "fixture_ids":["runtime_standard_light"]}, "standard_cable":{"allowed_entity_types":["cable"], "fixture_ids":["runtime_standard_cable"]}, "standard_movable":{"allowed_entity_types":["movable"], "fixture_ids":["runtime_standard_movable"]}, "standard_cooling":{"allowed_entity_types":["cooling_system"], "fixture_ids":["runtime_standard_cooling"]}},
	"editor_presentation_profile":{"excluded":{"fixture_ids":["editor_excluded"]}, "standard_object":{"allowed_entity_types":["object"], "fixture_ids":["editor_standard_object"]}, "standard_item":{"allowed_entity_types":["item"], "fixture_ids":["editor_standard_item"]}, "standard_light":{"allowed_entity_types":["light"], "fixture_ids":["editor_standard_light"]}, "standard_cable":{"allowed_entity_types":["cable"], "fixture_ids":["editor_standard_cable"]}, "standard_movable":{"allowed_entity_types":["movable"], "fixture_ids":["editor_standard_movable"]}, "standard_cooling":{"allowed_entity_types":["cooling_system"], "fixture_ids":["editor_standard_cooling"]}}
}

const REQUIRED_PROFILE_FIELDS: Array[String] = ["status_profile", "property_profile", "interaction_profile", "notification_profile", "power_profile", "control_profile", "access_profile", "binding_profile", "runtime_presentation_profile", "editor_presentation_profile"]
const CAPABILITY_PROFILE_FIELDS: Dictionary = {"power_profile":"power", "control_profile":"control", "access_profile":"access", "binding_profile":"bindings"}
const VALIDATION_FIXTURE_REGISTRY: Dictionary = {
	"default":{"fixture_id":"default", "kind":"definition", "description":"Legacy compatibility fixture."}
}

static func has_profile(profile_field: String, profile_id: String) -> bool:
	return PROFILE_REGISTRIES.has(profile_field) and Dictionary(PROFILE_REGISTRIES[profile_field]).has(profile_id)

static func get_profile_descriptor(profile_field: String, profile_id: String) -> Dictionary:
	if not has_profile(profile_field, profile_id):
		return {}
	return Dictionary(Dictionary(PROFILE_REGISTRIES[profile_field])[profile_id]).duplicate(true)

static func get_profile_ids(profile_field: String) -> Array:
	if not PROFILE_REGISTRIES.has(profile_field):
		return []
	return Dictionary(PROFILE_REGISTRIES[profile_field]).keys()

static func _error(code: String, field: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {"code": code, "field": field, "message": message, "details": details.duplicate(true)}

static func _add_missing(errors: Array, field: String) -> void:
	errors.append(_error("entity_contract.%s_missing" % field, field, "Entity definition is missing %s." % field))

static func _has_non_empty_schema(definition: Dictionary) -> bool:
	var schema: Variant = definition.get("property_schema", [])
	return schema is Array and not Array(schema).is_empty()

static func resolve_validation_fixture(fixture_id: String) -> Dictionary:
	var normalized_id: String = fixture_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	if VALIDATION_FIXTURE_REGISTRY.has(normalized_id):
		return Dictionary(VALIDATION_FIXTURE_REGISTRY[normalized_id]).duplicate(true)
	for profile_field in PROFILE_REGISTRIES.keys():
		for profile_id in Dictionary(PROFILE_REGISTRIES[profile_field]).keys():
			var descriptor: Dictionary = get_profile_descriptor(str(profile_field), str(profile_id))
			if Array(descriptor.get("fixture_ids", [])).has(normalized_id):
				return {"fixture_id": normalized_id, "kind":"profile", "profile_field":str(profile_field), "profile_id":str(profile_id)}
	return {}

static func _field_detail(definition_id: String, entity_type: String, field_name: String, semantics: Dictionary, capability: String) -> Dictionary:
	return {"definition_id":definition_id, "entity_type":entity_type, "capability":capability, "field_name":field_name, "field_family":str(semantics.get("family", ""))}

static func _property_fields(definition: Dictionary, errors: Array, definition_id: String) -> Array[String]:
	var fields: Array[String] = []
	var seen: Dictionary = {}
	var schema: Variant = definition.get("property_schema", [])
	if not (schema is Array):
		return fields
	for entry in Array(schema):
		if not (entry is Dictionary):
			continue
		var field_name: String = str(Dictionary(entry).get("field", "")).strip_edges()
		if field_name.is_empty():
			continue
		if seen.has(field_name):
			errors.append(_error("entity_contract.property_schema_duplicate_field", "property_schema", "Duplicate property_schema field %s." % field_name, {"definition_id":definition_id, "field_name":field_name}))
		else:
			seen[field_name] = true
		fields.append(field_name)
	return fields

static func _validate_profiles(definition_id: String, contract: Dictionary, entity_type: String, capabilities: Dictionary, errors: Array, applied_fixture_ids: Array) -> void:
	for field in REQUIRED_PROFILE_FIELDS:
		if not contract.has(field) or str(contract.get(field, "")).strip_edges().is_empty():
			_add_missing(errors, field)
			continue
		var profile_id: String = str(contract[field]).strip_edges()
		if not has_profile(field, profile_id):
			errors.append(_error("entity_contract.profile_unknown", field, "Entity definition references unknown profile %s." % profile_id, {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id}))
			continue
		var descriptor: Dictionary = get_profile_descriptor(field, profile_id)
		for fixture_id in Array(descriptor.get("fixture_ids", [])):
			applied_fixture_ids.append(str(fixture_id))
		if Array(descriptor.get("fixture_ids", [])).is_empty():
			errors.append(_error("entity_contract.profile_fixture_missing", field, "Profile is missing fixture coverage.", {"definition_id":definition_id, "profile_field":field, "profile_id":profile_id}))
		var allowed_types: Array = Array(descriptor.get("allowed_entity_types", []))
		if not allowed_types.is_empty() and not allowed_types.has(entity_type):
			errors.append(_error("entity_contract.profile_entity_type_mismatch", field, "Profile %s is not valid for %s." % [profile_id, entity_type], {"definition_id":definition_id, "entity_type":entity_type, "profile_field":field, "profile_id":profile_id}))
		for capability in Array(descriptor.get("required_capabilities", [])):
			if not bool(capabilities.get(str(capability), false)):
				errors.append(_error("entity_contract.profile_capability_required", field, "Profile %s requires capability %s." % [profile_id, str(capability)], {"definition_id":definition_id, "entity_type":entity_type, "profile_field":field, "profile_id":profile_id, "capability":str(capability)}))
		for capability in Array(descriptor.get("forbidden_capabilities", [])):
			if bool(capabilities.get(str(capability), false)):
				errors.append(_error("entity_contract.profile_capability_forbidden", field, "Profile %s forbids capability %s." % [profile_id, str(capability)], {"definition_id":definition_id, "entity_type":entity_type, "profile_field":field, "profile_id":profile_id, "capability":str(capability)}))
	if str(contract.get("status_profile", "")).strip_edges() == "none" and bool(capabilities.get("state", false)):
		errors.append(_error("entity_contract.profile_capability_required", "status_profile", "State capability requires a non-none status profile.", {"definition_id":definition_id, "entity_type":entity_type, "profile_field":"status_profile", "profile_id":"none", "capability":"state"}))

static func _allowed_migration_issues() -> Array:
	return TEMPORARY_LEGACY_MIGRATION_ISSUES.values()

static func _legacy_presence_field(definition: Dictionary, field_name: String) -> String:
	if definition.has(field_name):
		return field_name
	if not FIELD_SEMANTICS.has(field_name):
		return ""
	var semantics: Dictionary = Dictionary(FIELD_SEMANTICS[field_name])
	for alias_value in Array(semantics.get("legacy_presence_aliases", [])):
		var alias_name: String = str(alias_value).strip_edges()
		if not alias_name.is_empty() and definition.has(alias_name):
			return alias_name
	return ""

static func _exception_map(definition: Dictionary, errors: Array, definition_id: String) -> Dictionary:
	var result: Dictionary = {}
	var raw: Variant = definition.get("legacy_semantic_exceptions", [])
	if raw == null:
		return result
	if not (raw is Array):
		errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy semantic exceptions must be an array.", {"definition_id":definition_id}))
		return result
	var allowed_issues: Array = _allowed_migration_issues()
	for entry in Array(raw):
		if not (entry is Dictionary):
			errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy semantic exception must be a dictionary.", {"definition_id":definition_id}))
			continue
		var item: Dictionary = Dictionary(entry)
		var field_name: String = str(item.get("field", "")).strip_edges()
		var reason: String = str(item.get("reason", "")).strip_edges()
		var issue_value: Variant = item.get("migration_issue", 0)
		var issue: int = int(issue_value) if (issue_value is int or issue_value is float) else 0
		if field_name.is_empty() or field_name.find("*") >= 0 or reason.is_empty() or not FIELD_SEMANTICS.has(field_name) or not allowed_issues.has(issue) or result.has(field_name):
			errors.append(_error("entity_contract.legacy_exception_invalid", "legacy_semantic_exceptions", "Legacy semantic exception is invalid.", {"definition_id":definition_id, "field_name":field_name, "migration_issue":issue}))
			continue
		result[field_name] = {"reason":reason, "migration_issue":issue}
	return result

static func _validate_fields(definition_id: String, definition: Dictionary, entity_type: String, capabilities: Dictionary, errors: Array, warnings: Array) -> Dictionary:
	var field_semantics: Dictionary = {}
	var exceptions: Dictionary = _exception_map(definition, errors, definition_id)
	var consumed_exceptions: Dictionary = {}
	var property_fields: Array[String] = _property_fields(definition, errors, definition_id)
	for field_name in property_fields:
		if not FIELD_SEMANTICS.has(field_name):
			continue
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS[field_name])
		field_semantics[field_name] = semantics.duplicate(true)
		var capability: String = str(semantics.get("capability", ""))
		var details: Dictionary = _field_detail(definition_id, entity_type, field_name, semantics, capability)
		if bool(semantics.get("computed", false)) or str(semantics.get("storage", "")) == "computed":
			errors.append(_error("entity_contract.computed_field_editable", field_name, "Computed field %s cannot be editable." % field_name, details))
		elif not bool(capabilities.get(capability, false)):
			errors.append(_error("entity_contract.property_schema_field_forbidden", field_name, "Property field %s requires disabled capability %s." % [field_name, capability], details))
	for field_name in FIELD_SEMANTICS.keys():
		if not definition.has(field_name):
			continue
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS[field_name])
		field_semantics[str(field_name)] = semantics.duplicate(true)
		var capability: String = str(semantics.get("capability", ""))
		var details: Dictionary = _field_detail(definition_id, entity_type, str(field_name), semantics, capability)
		if str(semantics.get("storage", "")) == "computed":
			if exceptions.has(field_name):
				errors.append(_error("entity_contract.legacy_exception_invalid", str(field_name), "Legacy exception cannot authorize computed canonical field.", details))
			else:
				errors.append(_error("entity_contract.computed_field_stored", str(field_name), "Computed field %s cannot be stored as canonical truth." % str(field_name), details))
		elif not bool(capabilities.get(capability, false)):
			if exceptions.has(field_name):
				var exception: Dictionary = Dictionary(exceptions[field_name])
				details["migration_issue"] = int(exception.get("migration_issue", 0))
				warnings.append(_error("entity_contract.legacy_semantic_exception", str(field_name), "Legacy field %s is temporarily allowed by migration exception." % str(field_name), details))
				consumed_exceptions[field_name] = true
			else:
				errors.append(_error("entity_contract.capability_field_forbidden", str(field_name), "Field %s requires disabled capability %s." % [str(field_name), capability], details))
	for field_name in exceptions.keys():
		if consumed_exceptions.has(field_name):
			continue
		var field_key: String = str(field_name)
		var presence_field: String = _legacy_presence_field(definition, field_key)
		var semantics: Dictionary = Dictionary(FIELD_SEMANTICS.get(field_key, {}))
		var capability: String = str(semantics.get("capability", ""))
		if not presence_field.is_empty() and not bool(capabilities.get(capability, false)):
			var exception: Dictionary = Dictionary(exceptions[field_name])
			var details: Dictionary = _field_detail(definition_id, entity_type, field_key, semantics, capability)
			details["migration_issue"] = int(exception.get("migration_issue", 0))
			details["legacy_presence_field"] = presence_field
			warnings.append(_error("entity_contract.legacy_semantic_exception", field_key, "Legacy field %s is temporarily allowed by migration exception." % field_key, details))
			consumed_exceptions[field_name] = true
		else:
			errors.append(_error("entity_contract.legacy_exception_invalid", field_key, "Legacy exception does not match a contradictory present field.", {"definition_id":definition_id, "field_name":field_key, "migration_issue":int(Dictionary(exceptions[field_name]).get("migration_issue", 0))}))
	return field_semantics

static func validate_definition(definition_id: String, definition: Dictionary) -> Dictionary:
	var contract: Dictionary = Dictionary(definition.get("entity_contract", {})).duplicate(true) if definition.get("entity_contract", {}) is Dictionary else {}
	var report: Dictionary = {"valid": false, "semantic_valid": false, "palette_eligible": false, "definition_id": definition_id, "scope": str(contract.get("scope", "")), "entity_type": str(contract.get("entity_type", "")), "entity_subtype": str(contract.get("entity_subtype", "")), "capabilities": {}, "validation_fixture": {}, "applied_fixture_ids": [], "resolved_profiles": {}, "legacy_exceptions": [], "field_semantics": {}, "contract": contract.duplicate(true), "errors": [], "warnings": []}
	var errors: Array = report["errors"]
	var warnings: Array = report["warnings"]
	if contract.is_empty():
		errors.append(_error("entity_contract.missing", "entity_contract", "Entity definition is missing entity_contract.", {"definition_id":definition_id}))
		return report
	var scope: String = str(contract.get("scope", "")).strip_edges()
	report["scope"] = scope
	if scope.is_empty():
		errors.append(_error("entity_contract.scope_missing", "scope", "Entity definition is missing scope."))
	elif scope not in [SCOPE_ENTITY, SCOPE_EXCLUDED]:
		errors.append(_error("entity_contract.scope_invalid", "scope", "Entity definition scope is invalid."))
	if scope == SCOPE_EXCLUDED:
		if str(contract.get("exclusion_reason", "")).strip_edges().is_empty():
			errors.append(_error("entity_contract.exclusion_reason_missing", "exclusion_reason", "Excluded entity definition is missing exclusion_reason."))
		report["valid"] = errors.is_empty()
		report["semantic_valid"] = report["valid"]
		report["palette_eligible"] = is_palette_eligible(report)
		return report
	var entity_type: String = str(contract.get("entity_type", "")).strip_edges()
	if entity_type.is_empty():
		errors.append(_error("entity_contract.entity_type_missing", "entity_type", "Entity definition is missing entity_type."))
	elif entity_type not in ENTITY_TYPES:
		errors.append(_error("entity_contract.entity_type_invalid", "entity_type", "Entity definition entity_type is invalid."))
	if str(contract.get("entity_subtype", "")).strip_edges().is_empty():
		errors.append(_error("entity_contract.entity_subtype_missing", "entity_subtype", "Entity definition is missing entity_subtype."))
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})) if contract.get("capabilities", {}) is Dictionary else {}
	if capabilities.is_empty():
		errors.append(_error("entity_contract.capabilities_missing", "capabilities", "Entity definition is missing capabilities."))
	for key in CAPABILITY_KEYS:
		if not capabilities.has(key):
			errors.append(_error("entity_contract.capability_missing", "capabilities.%s" % key, "Entity definition is missing capability %s." % key))
		elif not (capabilities[key] is bool):
			errors.append(_error("entity_contract.capability_invalid", "capabilities.%s" % key, "Entity definition capability %s must be boolean." % key))
	report["capabilities"] = capabilities.duplicate(true)
	var applied_fixture_ids: Array = report["applied_fixture_ids"]
	_validate_profiles(definition_id, contract, entity_type, capabilities, errors, applied_fixture_ids)
	var resolved_profiles: Dictionary = {}
	for profile_field in REQUIRED_PROFILE_FIELDS:
		var profile_id: String = str(contract.get(profile_field, "")).strip_edges()
		if has_profile(profile_field, profile_id):
			resolved_profiles[profile_field] = get_profile_descriptor(profile_field, profile_id)
	report["resolved_profiles"] = resolved_profiles
	var fixture_id: String = str(contract.get("validation_fixture", "")).strip_edges()
	if fixture_id.is_empty():
		errors.append(_error("entity_contract.validation_fixture_missing", "validation_fixture", "Entity definition is missing validation_fixture."))
	else:
		var resolved_fixture: Dictionary = resolve_validation_fixture(fixture_id)
		if resolved_fixture.is_empty():
			errors.append(_error("entity_contract.validation_fixture_unknown", "validation_fixture", "Entity definition references an unknown validation fixture."))
		else:
			report["validation_fixture"] = resolved_fixture
	var property_profile: String = str(contract.get("property_profile", "")).strip_edges()
	var configurable: bool = bool(definition.get("configurable", false))
	if configurable and property_profile == "fixed":
		errors.append(_error("entity_contract.property_profile_configurable_mismatch", "property_profile", "Configurable definitions require property_profile=definition_schema."))
	if (configurable or property_profile == "definition_schema") and not _has_non_empty_schema(definition):
		errors.append(_error("entity_contract.property_schema_missing", "property_schema", "Entity definition is missing required property_schema."))
	report["field_semantics"] = _validate_fields(definition_id, definition, entity_type, capabilities, errors, warnings)
	report["legacy_exceptions"] = Array(definition.get("legacy_semantic_exceptions", [])).duplicate(true) if definition.get("legacy_semantic_exceptions", []) is Array else []
	report["valid"] = errors.is_empty()
	report["semantic_valid"] = errors.is_empty()
	report["palette_eligible"] = is_palette_eligible(report)
	return report

static func validate_fixture_registry() -> Array:
	var errors: Array = []
	var fixture_count: int = 0
	for profile_field in PROFILE_REGISTRIES.keys():
		for profile_id in Dictionary(PROFILE_REGISTRIES[profile_field]).keys():
			var descriptor: Dictionary = get_profile_descriptor(str(profile_field), str(profile_id))
			var fixture_ids: Array = Array(descriptor.get("fixture_ids", []))
			if fixture_ids.is_empty():
				errors.append(_error("entity_contract.profile_fixture_missing", str(profile_field), "Profile fixture missing.", {"profile_field":str(profile_field), "profile_id":str(profile_id)}))
			for fixture_id in fixture_ids:
				fixture_count += 1
				if resolve_validation_fixture(str(fixture_id)).is_empty():
					errors.append(_error("entity_contract.fixture_invalid", str(profile_field), "Profile fixture does not resolve.", {"profile_field":str(profile_field), "profile_id":str(profile_id), "fixture_id":str(fixture_id)}))
	if fixture_count <= 1:
		errors.append(_error("entity_contract.fixture_invalid", "validation_fixture", "Generic default cannot be the only fixture."))
	return errors

static func is_palette_eligible(report: Dictionary) -> bool:
	return bool(report.get("valid", false))
