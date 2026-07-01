extends RefCounted

const ENTITY_TYPES: Array[String] = ["object", "item", "light", "cable", "movable", "cooling_system"]
const CAPABILITY_KEYS: Array[String] = ["state", "power", "health", "energy", "overheat", "control", "access", "bindings", "mount", "side", "routing", "test_override"]
const REQUIRED_PROFILE_FIELDS: Array[String] = ["status_profile", "property_profile", "interaction_profile", "notification_profile", "power_profile", "control_profile", "access_profile", "binding_profile", "runtime_presentation_profile", "editor_presentation_profile"]
const CAPABILITY_PROFILE_FIELDS: Dictionary = {"power_profile":"power", "control_profile":"control", "access_profile":"access", "binding_profile":"bindings"}
const ERROR_CODES: Array[String] = [
	"entity_contract.missing", "entity_contract.profile_entity_type_mismatch", "entity_contract.profile_capability_required", "entity_contract.profile_capability_forbidden",
	"entity_contract.capability_field_forbidden", "entity_contract.property_schema_field_forbidden", "entity_contract.property_schema_duplicate_field",
	"entity_contract.computed_field_editable", "entity_contract.computed_field_stored", "entity_contract.profile_fixture_missing",
	"entity_contract.fixture_invalid", "entity_contract.legacy_exception_invalid", "entity_contract.legacy_semantic_exception",
	"entity_contract.profile_unknown", "entity_contract.validation_fixture_unknown"
]
const TEMPORARY_LEGACY_MIGRATION_ISSUES: Dictionary = {
	"stationary_power_cables":1181, "doors_terminals_access":1182, "machines_cooling_box":1183, "runtime_cable_reel":1188,
	"items_details":1189, "movable_crates":1190, "passive_ducts_pipes":1191, "final_versioned_migration":1192
}

const PROFILE_REGISTRIES: Dictionary = {
	"status_profile":{"none":{"allowed_entity_types":[], "fixture_ids":["status_none"]}, "object_standard":{"allowed_entity_types":["object"], "required_capabilities":["state"], "fixture_ids":["status_object_standard"]}, "object_thermal":{"allowed_entity_types":["object"], "required_capabilities":["state", "health", "overheat"], "fixture_ids":["status_object_thermal"]}, "item_standard":{"allowed_entity_types":["item"], "required_capabilities":["state"], "fixture_ids":["status_item_standard"]}, "light_standard":{"allowed_entity_types":["light"], "required_capabilities":["state", "health", "overheat"], "fixture_ids":["status_light_standard"]}, "cable_standard":{"allowed_entity_types":["cable"], "required_capabilities":["state", "health"], "fixture_ids":["status_cable_standard"]}, "movable_standard":{"allowed_entity_types":["movable"], "required_capabilities":["state", "health"], "fixture_ids":["status_movable_standard"]}, "cooling_active":{"allowed_entity_types":["cooling_system"], "required_capabilities":["state"], "fixture_ids":["status_cooling_active"]}, "cooling_passive":{"allowed_entity_types":["cooling_system"], "forbidden_capabilities":["state", "power", "control", "health", "access"], "fixture_ids":["status_cooling_passive"]}},
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

const EXPECTED_CODES: Dictionary = {
	"unknown":"entity_contract.profile_unknown", "type":"entity_contract.profile_entity_type_mismatch",
	"required":"entity_contract.profile_capability_required", "forbidden":"entity_contract.profile_capability_forbidden"
}

# fixture_id: [profile_field, profile_id, valid_entity_type, enabled_caps, disabled_caps, invalid_kind, allowed_field_families]
const SPECS: Dictionary = {
	"status_none":["status_profile", "none", "object", [], ["state"], "required", []],
	"status_object_standard":["status_profile", "object_standard", "object", ["state"], [], "type", ["state", "health"]],
	"status_object_thermal":["status_profile", "object_thermal", "object", ["state", "health", "overheat"], [], "type", ["state", "health", "thermal"]],
	"status_item_standard":["status_profile", "item_standard", "item", ["state"], [], "type", ["state"]],
	"status_light_standard":["status_profile", "light_standard", "light", ["state", "health", "overheat"], [], "type", ["state", "health", "thermal"]],
	"status_cable_standard":["status_profile", "cable_standard", "cable", ["state", "health"], [], "type", ["state", "health", "routing", "mount"]],
	"status_movable_standard":["status_profile", "movable_standard", "movable", ["state", "health"], [], "required", ["state", "health", "mount"]],
	"status_cooling_active":["status_profile", "cooling_active", "cooling_system", ["state"], [], "required", ["state", "power", "control", "mount", "side"]],
	"status_cooling_passive":["status_profile", "cooling_passive", "cooling_system", [], ["state", "power", "control", "health", "access"], "forbidden", ["mount", "side", "routing"]],
	"property_fixed":["property_profile", "fixed", "object", [], [], "unknown", []], "property_definition_schema":["property_profile", "definition_schema", "object", [], [], "unknown", []],
	"interaction_none":["interaction_profile", "none", "object", [], [], "unknown", []], "interaction_standard_object":["interaction_profile", "standard_object", "object", [], [], "type", []],
	"interaction_item":["interaction_profile", "item", "item", [], [], "type", []], "interaction_light":["interaction_profile", "light", "light", [], [], "type", []],
	"interaction_cable":["interaction_profile", "cable", "cable", [], [], "type", []], "interaction_movable":["interaction_profile", "movable", "movable", [], [], "type", []],
	"interaction_cooling":["interaction_profile", "cooling", "cooling_system", [], [], "type", []], "notification_none":["notification_profile", "none", "object", [], [], "unknown", []],
	"notification_standard_action":["notification_profile", "standard_action", "object", ["state"], [], "required", ["state"]],
	"power_none":["power_profile", "none", "object", [], ["power"], "forbidden", []], "power_configurable":["power_profile", "configurable", "object", ["power"], [], "required", ["power"]],
	"power_internal_only":["power_profile", "internal_only", "object", ["power"], [], "required", ["power"]], "power_external_only":["power_profile", "external_only", "object", ["power"], [], "required", ["power"]],
	"control_none":["control_profile", "none", "object", [], ["control"], "forbidden", []], "control_configurable":["control_profile", "configurable", "object", ["control"], [], "required", ["control"]],
	"control_internal_only":["control_profile", "internal_only", "object", ["control"], [], "required", ["control"]], "control_external_only":["control_profile", "external_only", "object", ["control"], [], "required", ["control"]],
	"access_none":["access_profile", "none", "object", [], ["access"], "forbidden", []], "access_standard":["access_profile", "standard", "object", ["access"], [], "required", ["access"]],
	"access_multi_factor_ready":["access_profile", "multi_factor_ready", "object", ["access"], [], "required", ["access"]], "binding_none":["binding_profile", "none", "object", [], ["bindings"], "forbidden", []],
	"binding_standard":["binding_profile", "standard", "object", ["bindings"], [], "required", ["bindings"]],
	"runtime_excluded":["runtime_presentation_profile", "excluded", "object", [], [], "unknown", []], "runtime_standard_object":["runtime_presentation_profile", "standard_object", "object", [], [], "type", []],
	"runtime_standard_item":["runtime_presentation_profile", "standard_item", "item", [], [], "type", []], "runtime_standard_light":["runtime_presentation_profile", "standard_light", "light", [], [], "type", []],
	"runtime_standard_cable":["runtime_presentation_profile", "standard_cable", "cable", [], [], "type", []], "runtime_standard_movable":["runtime_presentation_profile", "standard_movable", "movable", [], [], "type", []],
	"runtime_standard_cooling":["runtime_presentation_profile", "standard_cooling", "cooling_system", [], [], "type", []],
	"editor_excluded":["editor_presentation_profile", "excluded", "object", [], [], "unknown", []], "editor_standard_object":["editor_presentation_profile", "standard_object", "object", [], [], "type", []],
	"editor_standard_item":["editor_presentation_profile", "standard_item", "item", [], [], "type", []], "editor_standard_light":["editor_presentation_profile", "standard_light", "light", [], [], "type", []],
	"editor_standard_cable":["editor_presentation_profile", "standard_cable", "cable", [], [], "type", []], "editor_standard_movable":["editor_presentation_profile", "standard_movable", "movable", [], [], "type", []],
	"editor_standard_cooling":["editor_presentation_profile", "standard_cooling", "cooling_system", [], [], "type", []]
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
	var result: Array = Dictionary(PROFILE_REGISTRIES[profile_field]).keys()
	result.sort()
	return result

static func _different_entity_type(entity_type: String) -> String:
	if entity_type == "object":
		return "item"
	return "object"

static func get_fixture(fixture_id: String) -> Dictionary:
	if fixture_id == "default":
		return {"fixture_id":"default", "kind":"definition", "valid_sample":{"entity_contract":{"scope":"excluded", "exclusion_reason":"fixture"}}, "invalid_mutations":[{"path":"entity_contract", "value":null, "expected_code":"entity_contract.missing"}], "allowed_fields":{"stored":[], "editable":[], "computed":[]}}
	if not SPECS.has(fixture_id):
		return {}
	var spec: Array = Array(SPECS[fixture_id])
	var enabled_caps: Array = Array(spec[3])
	var disabled_caps: Array = Array(spec[4])
	var capabilities: Dictionary = {}
	for value in enabled_caps:
		capabilities[str(value)] = true
	for value in disabled_caps:
		capabilities[str(value)] = false
	var invalid_kind: String = str(spec[5])
	var expected_code: String = str(EXPECTED_CODES.get(invalid_kind, ""))
	var mutation: Dictionary = {"path":"profile_id", "value":"missing", "expected_code":expected_code}
	if invalid_kind == "type":
		mutation = {"path":"entity_type", "value":_different_entity_type(str(spec[2])), "expected_code":expected_code}
	elif invalid_kind == "required":
		if not enabled_caps.is_empty():
			mutation = {"path":"capabilities.%s" % str(enabled_caps[0]), "value":false, "expected_code":expected_code}
		elif not disabled_caps.is_empty():
			mutation = {"path":"capabilities.%s" % str(disabled_caps[0]), "value":true, "expected_code":expected_code}
	elif invalid_kind == "forbidden" and not disabled_caps.is_empty():
		mutation = {"path":"capabilities.%s" % str(disabled_caps[0]), "value":true, "expected_code":expected_code}
	var families: Array = Array(spec[6]).duplicate()
	return {"fixture_id":fixture_id, "kind":"profile", "profile_field":str(spec[0]), "profile_id":str(spec[1]), "valid_sample":{"entity_type":str(spec[2]), "capabilities":capabilities}, "invalid_mutations":[mutation], "allowed_fields":{"stored":families.duplicate(), "editable":families.duplicate(), "computed":families.duplicate()}}

static func get_fixture_ids() -> Array:
	var result: Array = SPECS.keys()
	result.sort()
	return result
