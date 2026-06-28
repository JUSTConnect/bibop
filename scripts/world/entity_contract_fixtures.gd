extends RefCounted

const EXPECTED_CODES: Dictionary = {
	"unknown": "entity_contract.profile_unknown",
	"type": "entity_contract.profile_entity_type_mismatch",
	"required": "entity_contract.profile_capability_required",
	"forbidden": "entity_contract.profile_capability_forbidden"
}

# fixture_id: [profile_field, profile_id, valid_entity_type, enabled_caps,
# disabled_caps, invalid_kind, allowed_field_families]
const SPECS: Dictionary = {
	"status_none": ["status_profile", "none", "object", [], ["state"], "required", []],
	"status_object_standard": ["status_profile", "object_standard", "object", ["state"], [], "type", ["state", "health"]],
	"status_item_standard": ["status_profile", "item_standard", "item", ["state"], [], "type", ["state"]],
	"status_light_standard": ["status_profile", "light_standard", "light", ["state"], [], "type", ["state"]],
	"status_cable_standard": ["status_profile", "cable_standard", "cable", ["state"], [], "type", ["state", "routing"]],
	"status_movable_standard": ["status_profile", "movable_standard", "movable", ["state", "health"], [], "required", ["state", "health", "mount"]],
	"status_cooling_active": ["status_profile", "cooling_active", "cooling_system", ["state"], [], "required", ["state", "power", "control", "mount", "side"]],
	"status_cooling_passive": ["status_profile", "cooling_passive", "cooling_system", [], ["state", "power", "control", "health", "access"], "forbidden", ["mount", "side", "routing"]],
	"property_fixed": ["property_profile", "fixed", "object", [], [], "unknown", []],
	"property_definition_schema": ["property_profile", "definition_schema", "object", [], [], "unknown", []],
	"interaction_none": ["interaction_profile", "none", "object", [], [], "unknown", []],
	"interaction_standard_object": ["interaction_profile", "standard_object", "object", [], [], "type", []],
	"interaction_item": ["interaction_profile", "item", "item", [], [], "type", []],
	"interaction_light": ["interaction_profile", "light", "light", [], [], "type", []],
	"interaction_cable": ["interaction_profile", "cable", "cable", [], [], "type", []],
	"interaction_movable": ["interaction_profile", "movable", "movable", [], [], "type", []],
	"interaction_cooling": ["interaction_profile", "cooling", "cooling_system", [], [], "type", []],
	"notification_none": ["notification_profile", "none", "object", [], [], "unknown", []],
	"notification_standard_action": ["notification_profile", "standard_action", "object", ["state"], [], "required", ["state"]],
	"power_none": ["power_profile", "none", "object", [], ["power"], "forbidden", []],
	"power_configurable": ["power_profile", "configurable", "object", ["power"], [], "required", ["power"]],
	"power_internal_only": ["power_profile", "internal_only", "object", ["power"], [], "required", ["power"]],
	"power_external_only": ["power_profile", "external_only", "object", ["power"], [], "required", ["power"]],
	"control_none": ["control_profile", "none", "object", [], ["control"], "forbidden", []],
	"control_configurable": ["control_profile", "configurable", "object", ["control"], [], "required", ["control"]],
	"control_internal_only": ["control_profile", "internal_only", "object", ["control"], [], "required", ["control"]],
	"control_external_only": ["control_profile", "external_only", "object", ["control"], [], "required", ["control"]],
	"access_none": ["access_profile", "none", "object", [], ["access"], "forbidden", []],
	"access_standard": ["access_profile", "standard", "object", ["access"], [], "required", ["access"]],
	"access_multi_factor_ready": ["access_profile", "multi_factor_ready", "object", ["access"], [], "required", ["access"]],
	"binding_none": ["binding_profile", "none", "object", [], ["bindings"], "forbidden", []],
	"binding_standard": ["binding_profile", "standard", "object", ["bindings"], [], "required", ["bindings"]],
	"runtime_excluded": ["runtime_presentation_profile", "excluded", "object", [], [], "unknown", []],
	"runtime_standard_object": ["runtime_presentation_profile", "standard_object", "object", [], [], "type", []],
	"runtime_standard_item": ["runtime_presentation_profile", "standard_item", "item", [], [], "type", []],
	"runtime_standard_light": ["runtime_presentation_profile", "standard_light", "light", [], [], "type", []],
	"runtime_standard_cable": ["runtime_presentation_profile", "standard_cable", "cable", [], [], "type", []],
	"runtime_standard_movable": ["runtime_presentation_profile", "standard_movable", "movable", [], [], "type", []],
	"runtime_standard_cooling": ["runtime_presentation_profile", "standard_cooling", "cooling_system", [], [], "type", []],
	"editor_excluded": ["editor_presentation_profile", "excluded", "object", [], [], "unknown", []],
	"editor_standard_object": ["editor_presentation_profile", "standard_object", "object", [], [], "type", []],
	"editor_standard_item": ["editor_presentation_profile", "standard_item", "item", [], [], "type", []],
	"editor_standard_light": ["editor_presentation_profile", "standard_light", "light", [], [], "type", []],
	"editor_standard_cable": ["editor_presentation_profile", "standard_cable", "cable", [], [], "type", []],
	"editor_standard_movable": ["editor_presentation_profile", "standard_movable", "movable", [], [], "type", []],
	"editor_standard_cooling": ["editor_presentation_profile", "standard_cooling", "cooling_system", [], [], "type", []]
}

static func _different_entity_type(entity_type: String) -> String:
	return "item" if entity_type == "object" else "object"

static func get_fixture(fixture_id: String) -> Dictionary:
	if fixture_id == "default":
		return {
			"fixture_id": "default",
			"kind": "definition",
			"valid_sample": {"entity_contract": {"scope": "excluded", "exclusion_reason": "fixture"}},
			"invalid_mutations": [{"path": "entity_contract", "value": null, "expected_code": "entity_contract.missing"}],
			"allowed_fields": {"stored": [], "editable": [], "computed": []}
		}
	if not SPECS.has(fixture_id):
		return {}
	var spec: Array = Array(SPECS[fixture_id])
	var profile_field: String = str(spec[0])
	var profile_id: String = str(spec[1])
	var entity_type: String = str(spec[2])
	var enabled_caps: Array = Array(spec[3])
	var disabled_caps: Array = Array(spec[4])
	var invalid_kind: String = str(spec[5])
	var families: Array = Array(spec[6]).duplicate()
	var capabilities: Dictionary = {}
	for capability_value in enabled_caps:
		capabilities[str(capability_value)] = true
	for capability_value in disabled_caps:
		capabilities[str(capability_value)] = false
	var expected_code: String = str(EXPECTED_CODES.get(invalid_kind, ""))
	var mutation: Dictionary = {"path": "profile_id", "value": "missing", "expected_code": expected_code}
	if invalid_kind == "type":
		mutation = {"path": "entity_type", "value": _different_entity_type(entity_type), "expected_code": expected_code}
	elif invalid_kind == "required":
		if not enabled_caps.is_empty():
			mutation = {"path": "capabilities.%s" % str(enabled_caps[0]), "value": false, "expected_code": expected_code}
		elif not disabled_caps.is_empty():
			mutation = {"path": "capabilities.%s" % str(disabled_caps[0]), "value": true, "expected_code": expected_code}
	elif invalid_kind == "forbidden" and not disabled_caps.is_empty():
		mutation = {"path": "capabilities.%s" % str(disabled_caps[0]), "value": true, "expected_code": expected_code}
	return {
		"fixture_id": fixture_id,
		"kind": "profile",
		"profile_field": profile_field,
		"profile_id": profile_id,
		"valid_sample": {"entity_type": entity_type, "capabilities": capabilities},
		"invalid_mutations": [mutation],
		"allowed_fields": {"stored": families.duplicate(), "editable": families.duplicate(), "computed": families.duplicate()}
	}

static func get_fixture_ids() -> Array:
	var result: Array = SPECS.keys()
	result.sort()
	return result
