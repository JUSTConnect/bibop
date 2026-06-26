extends RefCounted
class_name EntityDefinitionContract

const ENTITY_TYPES: Array[String] = ["object", "item", "light", "cable", "movable", "cooling_system"]
const SCOPE_ENTITY := "entity"
const SCOPE_EXCLUDED := "excluded"
const CAPABILITY_KEYS: Array[String] = ["state", "power", "health", "energy", "overheat", "control", "access", "bindings", "mount", "side", "routing", "test_override"]

const PROFILE_REGISTRIES: Dictionary = {
	"status_profile": ["none", "object_standard", "item_standard", "light_standard", "cable_standard", "movable_standard", "cooling_active", "cooling_passive"],
	"property_profile": ["fixed", "definition_schema"],
	"interaction_profile": ["none", "standard_object", "item", "light", "cable", "movable", "cooling"],
	"notification_profile": ["none", "standard_action"],
	"power_profile": ["none", "configurable", "internal_only", "external_only"],
	"control_profile": ["none", "configurable", "internal_only", "external_only"],
	"access_profile": ["none", "standard", "multi_factor_ready"],
	"binding_profile": ["none", "standard"],
	"runtime_presentation_profile": ["excluded", "standard_object", "standard_item", "standard_light", "standard_cable", "standard_movable", "standard_cooling"],
	"editor_presentation_profile": ["excluded", "standard_object", "standard_item", "standard_light", "standard_cable", "standard_movable", "standard_cooling"]
}

const REQUIRED_PROFILE_FIELDS: Array[String] = ["status_profile", "property_profile", "interaction_profile", "notification_profile", "power_profile", "control_profile", "access_profile", "binding_profile", "runtime_presentation_profile", "editor_presentation_profile"]

static func _error(code: String, field: String, message: String) -> Dictionary:
	return {"code": code, "field": field, "message": message}

static func _add_missing(errors: Array, field: String) -> void:
	errors.append(_error("entity_contract.%s_missing" % field, field, "Entity definition is missing %s." % field))

static func _has_non_empty_schema(definition: Dictionary) -> bool:
	var schema: Variant = definition.get("property_schema", [])
	return schema is Array and not Array(schema).is_empty()

static func validate_definition(definition_id: String, definition: Dictionary) -> Dictionary:
	var contract: Dictionary = Dictionary(definition.get("entity_contract", {})).duplicate(true) if definition.get("entity_contract", {}) is Dictionary else {}
	var report: Dictionary = {"valid": false, "palette_eligible": false, "definition_id": definition_id, "scope": str(contract.get("scope", "")), "entity_type": str(contract.get("entity_type", "")), "entity_subtype": str(contract.get("entity_subtype", "")), "capabilities": {}, "contract": contract.duplicate(true), "errors": [], "warnings": []}
	var errors: Array = report["errors"]
	if contract.is_empty():
		errors.append(_error("entity_contract.missing", "entity_contract", "Entity definition is missing entity_contract."))
		return report
	var scope := str(contract.get("scope", "")).strip_edges()
	if scope.is_empty():
		errors.append(_error("entity_contract.scope_missing", "scope", "Entity definition is missing scope."))
	elif scope not in [SCOPE_ENTITY, SCOPE_EXCLUDED]:
		errors.append(_error("entity_contract.scope_invalid", "scope", "Entity definition scope is invalid."))
	if scope == SCOPE_EXCLUDED:
		if str(contract.get("exclusion_reason", "")).strip_edges().is_empty():
			errors.append(_error("entity_contract.exclusion_reason_missing", "exclusion_reason", "Excluded entity definition is missing exclusion_reason."))
		report["valid"] = errors.is_empty()
		report["palette_eligible"] = is_palette_eligible(report)
		return report
	var entity_type := str(contract.get("entity_type", "")).strip_edges()
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
	for field in REQUIRED_PROFILE_FIELDS:
		if not contract.has(field) or str(contract.get(field, "")).strip_edges().is_empty():
			_add_missing(errors, field)
		elif not Array(PROFILE_REGISTRIES[field]).has(str(contract[field])):
			errors.append(_error("entity_contract.profile_unknown", field, "Entity definition references unknown profile %s." % str(contract[field])))
	if not contract.has("validation_fixture") or str(contract.get("validation_fixture", "")).strip_edges().is_empty():
		errors.append(_error("entity_contract.validation_fixture_missing", "validation_fixture", "Entity definition is missing validation_fixture."))
	if bool(definition.get("configurable", false)) and not _has_non_empty_schema(definition):
		errors.append(_error("entity_contract.property_schema_missing", "property_schema", "Configurable entity definition is missing property_schema."))
	report["valid"] = errors.is_empty()
	report["palette_eligible"] = is_palette_eligible(report)
	return report

static func is_palette_eligible(report: Dictionary) -> bool:
	return bool(report.get("valid", false))
